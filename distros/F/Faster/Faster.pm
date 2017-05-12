=head1 NAME

Faster - do some things faster

=head1 SYNOPSIS

 use Faster;

 perl -MFaster ...

=head1 DESCRIPTION

This module implements a very simple-minded "JIT" (or actually AIT, ahead
of time compiler). It works by more or less translating every function it
sees into a C program, compiling it and then replacing the function by the
compiled code.

As a result, startup times are immense, as every function might lead to a
full-blown compilation.

The speed improvements are also not great, you can expect 20% or so on
average, for code that runs very often. The reason for this is that data
handling is mostly being done by the same old code, it just gets called
a bit faster. Regexes and string operations won't get faster. Airhtmetic
doresn't become any faster. Just the operands and other stuff is put on
the stack faster, and the opcodes themselves have a bit less overhead.

Faster is in the early stages of development. Due to its design its
relatively safe to use (it will either work or simply slowdown the program
immensely, but rarely cause bugs).

More intelligent algorithms (loop optimisation, type inference) could
improve that easily, but requires a much more elaborate presentation and
optimiser than what is in place. There are no plans to improve Faster in
this way, yet, but it would provide a reasonably good place to start.

Usage is very easy, just C<use Faster> and every function called from then
on will be compiled.

Right now, Faster can leave lots of F<*.c> and F<*.so> files in your
F<$FASTER_CACHEDIR> (by default F<$HOME/.perl-faster-cache>), and it will
even create those temporary files in an insecure manner, so watch out.

=over 4

=cut

package Faster;

no warnings;

use strict;
use Config;
use B ();
use DynaLoader ();
use Digest::MD5 ();
use Storable ();
use Fcntl ();

BEGIN {
   our $VERSION = '0.1';

   require XSLoader;
   XSLoader::load __PACKAGE__, $VERSION;
}

my $CACHEDIR =
   $ENV{FASTER_CACHE}
   || (exists $ENV{HOME} && "$ENV{HOME}/.perl-faster-cache")
   || do {
      require File::Temp;
      File::Temp::tempdir (CLEANUP => 1)
   };

my $COMPILE = "$Config{cc} -c -I$Config{archlibexp}/CORE $Config{optimize} $Config{ccflags} $Config{cccdlflags}";
my $LINK    = "$Config{ld} $Config{ldflags} $Config{lddlflags} $Config{ccdlflags}";
my $LIBS    = "";
my $_o      = $Config{_o};
my $_so     = ".so";

# we don't need no steenking PIC on x86
$COMPILE =~ s/-f(?:PIC|pic)//g
   if $Config{archname} =~ /^(i[3456]86)-/;

my $opt_assert = $ENV{FASTER_DEBUG} & 2;
my $verbose    = $ENV{FASTER_VERBOSE}+0;

warn "Faster: CACHEDIR is $CACHEDIR\n" if $verbose > 2;

our $source;

our @ops;
our $insn;
our $op;
our $op_name;
our %op_regcomp;

# ops that cause immediate return to the interpreter
my %f_unsafe = map +($_ => undef), qw(
   leavesub leavesublv return
   goto last redo next
   eval flip leaveeval entertry
   formline grepstart mapstart
   substcont entereval require
);

# ops with known stack extend behaviour
# the values given are maximum values
my %extend = (
  pushmark  => 0,
  nextstate => 0, # might reduce the stack
  unstack   => 0,
  enter     => 0,

  stringify => 0,
  not       => 0,
  and       => 0,
  or        => 0,
  gvsv      => 0,
  rv2gv     => 0,
  preinc    => 0,
  predec    => 0,
  postinc   => 0,
  postdec   => 0,
  aelem     => 0,
  helem     => 0,
  qr        => 1, #???
  pushre    => 1,
  gv        => 1,
  aelemfast => 1,
  aelem     => 0,
  padsv     => 1,
  const	    => 1,
  pop       => 1,
  shift     => 1,
  eq        => -1,
  ne        => -1,
  gt        => -1,
  lt        => -1,
  ge        => -1,
  lt        => -1,
  cond_expr => -1,
  add       => -1,
  subtract  => -1,
  multiply  => -1,
  divide    => -1,
  aassign   => 0,
  sassign   => -2,
  method    => 0,
  method_named => 1,
);

# ops that do not need an ASYNC_CHECK
my %f_noasync = map +($_ => undef), qw(
   mapstart grepstart match entereval
   enteriter entersub leaveloop

   pushmark nextstate caller

   const stub unstack
   last next redo goto seq
   padsv padav padhv padany
   aassign sassign orassign
   rv2av rv2cv rv2gv rv2hv refgen
   gv gvsv
   add subtract multiply divide
   complement cond_expr and or not
   bit_and bit_or bit_xor
   defined
   method method_named bless
   preinc postinc predec postdec
   aelem aelemfast helem delete exists
   pushre subst list lslice join split concat
   length substr stringify ord
   push pop shift unshift
   eq ne gt lt ge le
   regcomp regcreset regcmaybe
);

my %callop = (
   entersub => "(PL_op->op_ppaddr) (aTHX)",
   mapstart => "Perl_pp_grepstart (aTHX)",
);

sub callop {
   $callop{$op_name} || "Perl_pp_$op_name (aTHX)"
}

sub assert {
   return unless $opt_assert;
   $source .= "  assert ((\"$op_name\", ($_[0])));\n";
}

sub out_callop {
   assert "nextop == (OP *)$$op";
   $source .= "  PL_op = nextop; nextop = " . (callop $op) . ";\n";
}

sub out_jump {
   assert "nextop == (OP *)${$_[0]}L";
   $source .= "  goto op_${$_[0]};\n";
}

sub out_cond_jump {
   $source .= "  if (nextop == (OP *)${$_[0]}L) goto op_${$_[0]};\n";
}

sub out_jump_next {
   out_cond_jump $op_regcomp{$$op}
      if $op_regcomp{$$op};

   assert "nextop == (OP *)${$op->next}";
   $source .= "  goto op_${$op->next};\n";
}

sub out_next {
   $source .= "  nextop = (OP *)${$op->next}L;\n";

   out_jump_next;
}

sub out_linear {
   out_callop;
   out_jump_next;
}

sub op_entersub {
   out_callop;
   $source .= "  RUNOPS_TILL ((OP *)${$op->next}L);\n";
   out_jump_next;
}

*op_require = \&op_entersub;

sub op_nextstate {
   $source .= "  PL_curcop = (COP *)nextop;\n";
   $source .= "  PL_stack_sp = PL_stack_base + cxstack[cxstack_ix].blk_oldsp;\n";
   $source .= "  FREETMPS;\n";

   out_next;
}

sub op_pushmark {
   $source .= "  faster_PUSHMARK (PL_stack_sp);\n";

   out_next;
}

if ($Config{useithreads} ne "define") {
   # disable optimisations on ithreads

   *op_const = sub {
      $source .= "  { dSP; PUSHs ((SV *)${$op->sv}L); PUTBACK; }\n";

      $ops[0]{follows_const}++ if @ops;#d#

      out_next;
   };

   *op_gv = \&op_const;

   *op_aelemfast = sub {
      my $targ = $op->targ;
      my $private = $op->private;

      $source .= "  {\n";

      if ($op->flags & B::OPf_SPECIAL) {
         $source .= "    AV *av = (AV*)PAD_SV((PADOFFSET)$targ);\n";
      } else {
         $source .= "    AV *av = GvAV ((GV *)${$op->sv}L);\n";
      }

      if ($op->flags & B::OPf_MOD) {
         $source .= "    SV *sv = *av_fetch (av, $private, 1);\n";
      } else {
         $source .= "    SV **svp = av_fetch (av, $private, 0); SV *sv = svp ? *svp : &PL_sv_undef;\n";
      }

      if (!($op->flags & B::OPf_MOD)) {
         $source .= "    if (SvGMAGICAL (sv)) sv = sv_mortalcopy (sv);\n";
      }

      $source .= "    dSP;\n";
      $source .= "    PUSHs (sv);\n";
      $source .= "    PUTBACK;\n";
      $source .= "  }\n";

      out_next;
   };

   *op_gvsv = sub {
      $source .= "  {\n";
      $source .= "    dSP;\n";

      if ($op->private & B::OPpLVAL_INTRO) {
        $source .= "    PUSHs (save_scalar ((GV *)${$op->sv}L));\n";
      } else {
        $source .= "    PUSHs (GvSV ((GV *)${$op->sv}L));\n";
      }

      $source .= "    PUTBACK;\n";
      $source .= "  }\n";

      out_next;
   };
}

# does kill Crossfire/res2pm
sub op_stringify {
   my $targ = $op->targ;

   $source .= <<EOF;
  {
    dSP;
    SV *targ = PAD_SV ((PADOFFSET)$targ);
    sv_copypv (TARG, TOPs);
    SETTARG;
    PUTBACK;
  }
EOF

   out_next;
}

sub op_and {
   $source .= <<EOF;
  {
    dSP;

    if (SvTRUE (TOPs))
      {
        --SP;
        PUTBACK;
        nextop = (OP *)${$op->other}L;
        goto op_${$op->other};
      }
  }
EOF

   out_next;
}

sub op_or {
   $source .= <<EOF;
  {
    dSP;

    if (!SvTRUE (TOPs))
      {
        --SP;
        PUTBACK;
        nextop = (OP *)${$op->other}L;
        goto op_${$op->other};
      }
  }
EOF

   out_next;
}

sub op_padsv {
   my $flags = $op->flags;
   my $padofs = "(PADOFFSET)" . $op->targ;

   $source .= <<EOF;
  {
    dSP;
    SV *sv = PAD_SVl ($padofs);
EOF

   if (($flags & B::OPf_MOD) && ($op->private & B::OPpLVAL_INTRO)) {
      $source .= "    SAVECLEARSV (PAD_SVl ($padofs));\n";
      $ops[0]{follows_padsv_lval_intro}++ if @ops;#d#
   }
         
   $source .= <<EOF;
    PUSHs (sv);
    PUTBACK;
EOF

   if (($flags & B::OPf_MOD) && ($op->private & B::OPpDEREF)) {
      $source .= "    if (!SvROK (sv)) vivify_ref (sv, " . $op->private . " & OPpDEREF);\n";
   }
   $source .= "  }\n";

   out_next;
}

sub op_sassign {
  $source .= <<EOF;
  {
    dSP;
    dPOPTOPssrl;
EOF
   $source .= "    SV *temp = left; left = right; right = temp;\n"
      if $op->private & B::OPpASSIGN_BACKWARDS;

   if ($insn->{follows_padsv_lval_intro} && !($op->private & B::OPpASSIGN_BACKWARDS)) {
      # simple assignment - the target exists, but is basically undef
      $source .= "    SvSetSV (right, left);\n";
   } else {
      $source .= "    SvSetMagicSV (right, left);\n";
   }

   $source .= <<EOF;
    SETs (right);
    PUTBACK;
  }
EOF

  out_next;
}

# pattern const+ (or general push1)
# pattern pushmark gv rv2av pushmark padsv+o.ä. aassign

sub op_method_named {
   if ($insn->{follows_const}) {
      $source .= <<EOF;
  {
    dSP;
    static SV *last_cv;
    static U32 last_sub_generation;

    /* simple "polymorphic" inline cache */
    if (PL_sub_generation == last_sub_generation)
      {
        PUSHs (last_cv);
        PUTBACK;
      }
    else
      {
        PL_op = nextop; nextop = Perl_pp_method_named (aTHX);

        SPAGAIN;
        last_sub_generation = PL_sub_generation;
        last_cv             = TOPs;
      }
  }
EOF
   } else {
      $source .= <<EOF;
  {
    static HV *last_stash;
    static SV *last_cv;
    static U32 last_sub_generation;

    SV *obj = *(PL_stack_base + TOPMARK + 1);

    if (!SvGMAGICAL (obj) && SvROK (obj) && SvOBJECT (SvRV (obj)))
      {
        dSP;
        HV *stash = SvSTASH (SvRV (obj));

        /* simple "polymorphic" inline cache */
        if (stash == last_stash
            && PL_sub_generation == last_sub_generation)
          {
            PUSHs (last_cv);
            PUTBACK;
          }
        else
          {
            PL_op = nextop; nextop = Perl_pp_method_named (aTHX);

            SPAGAIN;
            last_sub_generation = PL_sub_generation;
            last_stash          = stash;
            last_cv             = TOPs;
          }
      }
    else
      {
        /* error case usually */
        PL_op = nextop; nextop = Perl_pp_method_named (aTHX);
      }
  }
EOF
   }

   out_next;
}

sub op_grepstart {
   out_callop;
   $op = $op->next;
   out_cond_jump $op->other;
   out_jump_next;
}

*op_mapstart = \&op_grepstart;

sub op_substcont {
   out_callop;
   out_cond_jump $op->other->pmreplstart;
   assert "nextop == (OP *)${$op->other->next}L";
   $source .= "  goto op_${$op->other->next};\n";
}

sub out_break_op {
   my ($idx) = @_;

   if ($op->flags & B::OPf_SPECIAL && $insn->{loop}) {
      # common case: no label, innermost loop only
      my $next = $insn->{loop}{loop_targ}[$idx];
      out_callop;
      out_jump $next;
   } elsif (my $loop = $insn->{loop}) {
      # less common case: maybe break to some outer loop
      $source .= "  return nextop;\n";
      # todo: walk stack up
   } else {
      # fuck yourself for writing such hacks
      $source .= "  return nextop;\n";
   }
}

sub op_next {
   out_break_op 0;
}

sub op_last {
   out_break_op 1;
}

# TODO: does not seem to work
#sub op_redo {
#   out_break_op 2;
#}

sub cv2c {
   my ($cv) = @_;

   local @ops;
   local %op_regcomp;

   my $curloop;
   my @todo = $cv->START;
   my %op_target;
   my $numpushmark;
   my $scope;

   my %op_seen;
   while (my $op = shift @todo) {
      my $next;
      for (; $$op; $op = $next) {
         last if $op_seen{$$op}++;

         $next = $op->next;

         my $name = $op->name;
         my $class = B::class $op;

         my $insn = { op => $op };

         # end of loop reached?
         $curloop = $curloop->{loop} if $curloop && $$op == ${$curloop->{loop_targ}[1]};

         # remember enclosing loop
         $insn->{loop} = $curloop if $curloop;

         push @ops, $insn;

         if (exists $extend{$name}) {
            my $extend = $extend{$name};
            $extend = $extend->($op) if ref $extend;
            $insn->{extend} = $extend if defined $extend;
         }

         # TODO: mark scopes similar to loops, make them comparable
         # static cxstack(?)
         if ($class eq "LOGOP") {
            push @todo, $op->other;
            $op_target{${$op->other}}++;

            # regcomp/o patches ops at runtime, lets expect that
            if ($name eq "regcomp" && $op->other->pmflags & B::PMf_KEEP) {
               $op_target{${$op->first}}++;
               $op_regcomp{${$op->first}} = $op->next;
            }

         } elsif ($class eq "PMOP") {
            if (${$op->pmreplstart}) {
               unshift @todo, $op->pmreplstart;
               $op_target{${$op->pmreplstart}}++;
            }

         } elsif ($class eq "LOOP") {
            my @targ = ($op->nextop, $op->lastop->next, $op->redoop);

            unshift @todo, $next, $op->redoop, $op->nextop, $op->lastop;
            $next = $op->redoop;

            $op_target{$$_}++ for @targ;

            $insn->{loop_targ} = \@targ;
            $curloop = $insn;

         } elsif ($class eq "COP") {
            if (defined $op->label) {
               $insn->{bblock}++;
               $curloop->{contains_label}{$op->label}++ if $curloop; #TODO: should be within loop
            }

         } else {
            if ($name eq "pushmark") {
               $numpushmark++;
            }
         }
      }
   }

   $_->{bblock}++ for grep $op_target{${$_->{op}}}, @ops;

   local $source = <<EOF;
OP *%%%FUNC%%% (pTHX)
{
  register OP *nextop = (OP *)${$ops[0]->{op}}L;
EOF

   $source .= "  faster_PUSHMARK_PREALLOC ($numpushmark);\n"
      if $numpushmark;

   while (@ops) {
      $insn = shift @ops;

      $op = $insn->{op};
      $op_name = $op->name;

      my $class = B::class $op;

      $source .= "\n/* start basic block */\n" if exists $insn->{bblock};#d#
      $source .= "op_$$op: /* $op_name */\n";
      #$source .= "fprintf (stderr, \"$$op in op $op_name\\n\");\n";#d#
      #$source .= "{ dSP; sv_dump (TOPs); }\n";#d#

      $source .= "  PERL_ASYNC_CHECK ();\n"
         unless exists $f_noasync{$op_name};

      if (my $can = __PACKAGE__->can ("op_$op_name")) {
         # handcrafted replacement

         if ($insn->{extend} > 0) {
            # coalesce EXTENDs
            # TODO: properly take negative preceeding and following EXTENDs into account
            for my $i (@ops) {
               last if exists $i->{bblock};
               last unless exists $i->{extend};
               my $extend = delete $i->{extend};
               $insn->{extend} += $extend if $extend > 0;
            }

            $source .= "  { dSP; EXTEND (SP, $insn->{extend}); PUTBACK; }\n"
               if $insn->{extend} > 0;
         }

         $can->($op);

      } elsif (exists $f_unsafe{$op_name}) {
         # unsafe, return to interpreter
         assert "nextop == (OP *)$$op";
         $source .= "  return nextop;\n";

      } elsif ("LOGOP" eq $class) {
         # logical operation with optional branch
         out_callop;
         out_cond_jump $op->other;
         out_jump_next;

      } elsif ("PMOP" eq $class) {
         # regex-thingy
         out_callop;
         out_cond_jump $op->pmreplroot if $op_name ne "pushre" && ${$op->pmreplroot};
         out_jump_next;

      } else {
         # normal operator, linear execution
         out_linear;
      }
   }

   $op_name = "func exit"; assert (0);

   $source .= <<EOF;
op_0:
  return 0;
}
EOF
   #warn $source;

   $source
}

my $uid = "aaaaaaa0";
my %so;

sub func2ptr {
   my (@func) = @_;

   #LOCK
   mkdir $CACHEDIR, 0777;
   sysopen my $meta_fh, "$CACHEDIR/meta", &Fcntl::O_RDWR | &Fcntl::O_CREAT, 0666
      or die "$$CACHEDIR/meta: $!";
   binmode $meta_fh, ":raw:perlio";
   fcntl_lock fileno $meta_fh
      or die "$CACHEDIR/meta: $!";

   my $meta = eval { Storable::fd_retrieve $meta_fh } || { version => 1 };

   for my $f (@func) {
      $f->{func} = "F" . Digest::MD5::md5_hex ($f->{source});
      $f->{so}   = $meta->{$f->{func}};
   }

   if (grep !$_->{so}, @func) {
      my $stem;
      
      do {
         $stem = "$CACHEDIR/$$-" . $uid++;
      } while -e "$stem$_so";

      open my $fh, ">:raw", "$stem.c";
      print $fh <<EOF;
#define PERL_NO_GET_CONTEXT
#define PERL_CORE

#include <assert.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if 1
# define faster_PUSHMARK_PREALLOC(count) while (PL_markstack_ptr + (count) >= PL_markstack_max) markstack_grow ()
# define faster_PUSHMARK(p) *++PL_markstack_ptr = (p) - PL_stack_base
#else
# define faster_PUSHMARK_PREALLOC(count) 1
# define faster_PUSHMARK(p) PUSHMARK(p)
#endif

#define RUNOPS_TILL(op)						\\
  while (nextop != (op))					\\
    {								\\
      PERL_ASYNC_CHECK ();					\\
      PL_op = nextop; nextop = (PL_op->op_ppaddr)(aTHX);	\\
    }

EOF
      for my $f (grep !$_->{so}, @func) {
         next if $f->{so} = $meta->{$f->{func}}; # some cv's alias others

         warn "compiling $f->{name} to $stem$_so:$f->{func}\n" if $verbose > 1;
         my $source = $f->{source};
         $source =~ s/%%%FUNC%%%/$f->{func}/g;
         print $fh $source;
         $meta->{$f->{func}} = $f->{so} = $stem;
      }

      close $fh;
      system "$COMPILE -o $stem$_o $stem.c";
      unlink "$stem.c" unless $ENV{FASTER_DEBUG} & 1;
      system "$LINK -o $stem$_so $stem$_o $LIBS";
      unlink "$stem$_o";
   }

   for my $f (@func) {
      my $stem = $f->{so};

      my $so = ($so{$stem} ||= DynaLoader::dl_load_file "$stem$_so")
         or die "$stem$_so: $!";

      #unlink "$stem$_so";

      $f->{ptr} = DynaLoader::dl_find_symbol $so, $f->{func}
         or die "$f->{func} not found in $stem$_so: $!";
   }

   seek $meta_fh, 0,  0 or die "$CACHEDIR/meta: $!";
   Storable::nstore_fd $meta, $meta_fh;
   truncate $meta_fh, tell $meta_fh;

   # UNLOCK (by closing $meta_fh)
}

my %ignore;

sub entersub {
   my ($cv) = @_;

   my $pkg = $cv->STASH->NAME;

   return if $ignore{$pkg};

   warn "optimising ", $cv->STASH->NAME, "\n"
      if $verbose;

   eval {
      my @func;

      push @func, {
         cv     => $cv,
         name   => "<>",
         source => cv2c $cv,
      };

      # always compile the whole stash
      my %stash = $cv->STASH->ARRAY;
      while (my ($k, $v) = each %stash) {
         $v->isa (B::GV::)
            or next;

         my $cv = $v->CV;

         if ($cv->isa (B::CV::)
             && ${$cv->START}
             && $cv->START->name ne "null") {

            push @func, {
               cv     => $cv,
               name   => $k,
               source => cv2c $cv,
            };
         }
      }

      func2ptr @func;

      for my $f (@func) {
         patch_cv $f->{cv}, $f->{ptr};
      }
   };

   if ($@) {
      $ignore{$pkg}++;
      warn $@;
   }
}

hook_entersub;

1;

=back

=head1 ENVIRONMENT VARIABLES

The following environment variables influence the behaviour of Faster:

=over 4

=item FASTER_VERBOSE

Faster will output more informational messages when set to values higher
than C<0>. Currently, C<1> outputs which packages are being compiled, C<3>
outputs the cache directory and C<10> outputs information on which perl
function is compiled into which shared object.

=item FASTER_DEBUG

Add debugging code when set to values higher than C<0>. Currently, this
adds 1-3 C<assert>'s per perl op (FASTER_DEBUG > 1), to ensure that opcode
order and C execution order are compatible.

=item FASTER_CACHE

Set a persistent cache directory that caches compiled code fragments. The
default is C<$HOME/.perl-faster-cache> if C<HOME> is set and a temporary
directory otherwise.

This directory will always grow in size, so you might need to erase it
from time to time.

=back

=head1 BUGS/LIMITATIONS

Perl will check much less often for asynchronous signals in
Faster-compiled code. It tries to check on every function call, loop
iteration and every I/O operator, though.

The following things will disable Faster. If you manage to enable them at
runtime, bad things will happen. Enabling them at startup will be fine,
though.

 enabled tainting
 enabled debugging

Thread-enabled builds of perl will dramatically reduce Faster's
performance, but you don't care about speed if you enable threads anyway.

These constructs will force the use of the interpreter for the currently
executed function as soon as they are being encountered during execution.

 goto
 next, redo (but not well-behaved last's)
 labels, if used
 eval
 require
 any use of formats
 .., ... (flipflop operators)

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

