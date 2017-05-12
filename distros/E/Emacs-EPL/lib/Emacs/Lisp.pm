#
#  "Not all of them use vi."
#

package Emacs::Lisp;

use 5.002;  # prototypes
use Carp ();

use strict;
no strict 'refs';
use vars qw ($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD %EXPORT);
my (%special);

require Exporter;

BEGIN {
    # Set inlinable constants based on feature tests.
    local ($@);
    local $ENV{PERL_DL_NONLAZY} = "";  # Why?  I forgot.  Needed for 5.005.
    eval { require B; };
    eval ('sub HAVE_B () {'. ($@ ? 0 : 1) .'}');
}

$VERSION = '1.01';
if (! defined (&Emacs::Lisp::funcall)
    || ! defined (&Emacs::Lisp::Object::funcall))
{
    if (defined (&Emacs::boot_Emacs)) {
	Emacs::boot_Emacs ($VERSION);
    }
    else {
	require Emacs::EPL;
    }
}

# Really don't want to leave the funcall()s undefined, because they
# are called by AUTOLOAD, and infinite recursion in AUTOLOAD is a
# quick way to melt down a system.
if (! defined (&Emacs::Lisp::funcall)
    || ! defined (&Emacs::Lisp::Object::funcall))
{
    Carp::croak ("funcall not defined");
}

# Closure generator shared by Emacs::Lisp::AUTOLOAD and
# Emacs::Lisp::Object::AUTOLOAD.
# FIXME: This code tries to be very clever for best performance,
# but it should be thoroughly tested.
my $get_funcall_closure = sub {
    my ($whose_funcall, $function) = @_;
    my ($fullname);

    $function =~ s/.*:://;
    $fullname = "${whose_funcall}::$function";
    if (defined &$fullname) {
	return \&$fullname;
    }
    if (exists $special{$function}) {
	my $msg = $special{$function};
	$msg = $special{$1}
	while $msg =~ /^\*(.*)/;
	$msg = (defined ($msg) ? "; $msg" : "");
	$function =~ tr/_/-/;
	Carp::croak ("`$function' not implemented$msg");
    }
    $function = \*{"::$function"};
    $whose_funcall = \&{"$whose_funcall\::funcall"};
    *$fullname = sub {

	# Switch to package main in case Lisp compiles any Perl code.
	# FIXME: should perhaps handle this in Perlmacs, by
	# allowing the package for perl-eval to be specified.
	package main;
	return &$whose_funcall ($function, @_);
    };
    return \&$fullname;
};

my $can = sub {
    my ($symbol);
    $symbol = \*{"::$_[1]"};
    if (&fboundp ($symbol)
	and do {
	    my ($f);
	    $f = Emacs::Lisp::Object::symbol_function ($symbol);
	    # XXX should save some communication by using &Emacs::Lisp::consp
	    # and &Emacs::Lisp::car.
	    ($f->consp->is_nil) or $f->car->eq (\*::macro)->is_nil;
	}) {
	return eval { &$get_funcall_closure };
    }
    return undef;
};


package Emacs::Lisp::Object;

use vars qw ($AUTOLOAD);

sub AUTOLOAD {
    *$AUTOLOAD = &$get_funcall_closure (__PACKAGE__, $AUTOLOAD);
    goto &$AUTOLOAD;
}
sub can { &UNIVERSAL::can || &$can (__PACKAGE__, $_[1]) }

sub is_nil	($) { defined $_[0]->null->to_perl }


package Emacs::Lisp::Variable;

sub TIESCALAR	{ return bless (\$_[1], $_[0]); }
sub FETCH	{ return &Emacs::Lisp::symbol_value (${$_[0]}); }
sub STORE	{ return &Emacs::Lisp::set (${$_[0]}, $_[1]); }


package Emacs::Lisp::Plist;

# tied hash interface to Lisp property lists
# tie (%sym, 'Emacs::Lisp::Plist', \*::sym)

sub TIEHASH	{ return bless (\$_[1], $_[0]); }
sub FETCH	{ return &Emacs::Lisp::get (${$_[0]}, $_[1]); }
sub STORE	{ return &Emacs::Lisp::put (${$_[0]}, $_[1], $_[2]); }
sub CLEAR	{ &Emacs::Lisp::setplist (${$_[0]}, undef); }

# Look for $key (a Perl thing, typically a \*::globref) in all the
# even-numbered positions (zero-based) in $list (a Lisp list).
# If found, return the list's tail and the tail from one position
# up (needed for DELETE).  If not found, return an empty list.
#
# Assumes $list has an even number of elts.
# Should be called in list context.
sub memq_even ($$) {
    my ($list, $key) = @_;
    my ($prev);
    for (; not $list->is_nil; $list = ($prev = $list->cdr)->cdr)
    {
	if (&Emacs::Lisp::eq ($list->car, $key)) {
	    return ($list, $prev);
	}
    }
    return ();
}

sub EXISTS {
    #     "[T]here is no distinction between a value of `nil'
    #     and the absence of the property."
    #
    #     - *Note (elisp)Symbol Plists::. (Elisp Manual)
    #
    # Well now there is.  :-)
    #
    my ($symbol, $key) = @_;
    return (memq_even
	    (&Emacs::Lisp::Object::symbol_plist ($$symbol),
	     $key))[0] ? 1 : 0;
}

sub DELETE {
    my ($symbol, $key) = @_;
    my ($plist, $list, $prev);

    $plist = &Emacs::Lisp::Object::symbol_plist ($$symbol);
    if ($plist->is_nil) {
	return undef;
    }
    ($list, $prev) = memq_even ($plist, $key);
    if ($list) {
	if ($prev) {
	    $prev->setcdr ($list->cdr->cdr);
	} else {
	    &Emacs::Lisp::setplist ($$symbol, $list->cdr->cdr);
	}
    }
    return undef;
}

sub FIRSTKEY {
    my ($symbol) = @_;
    my ($plist);
    $plist = &Emacs::Lisp::Object::symbol_plist ($$symbol);
    return $plist->is_nil ? undef : $plist->car->to_perl;
}

sub NEXTKEY {
    my ($symbol, $lastkey) = @_;
    my ($plist, $list);
    $plist = &Emacs::Lisp::Object::symbol_plist ($$symbol);
    ($list) = memq_even ($plist, $lastkey);
    if ($list) {
	$list = $list->cdr->cdr;
	if (not $list->is_nil) {
	    # bad if nil is a key, I guess
	    return $list->car->to_perl;
	}
    }
    return undef;
}


package Emacs::Lisp;

sub import {
    my @newlist = ();
    for my $i (1..$#_) {
	if ($_[$i] =~ m/^\d/) {
	    # Exporter will try to call Emacs::Lisp->require_version if
	    # we let it handle numeric arguments.  Rather than provide
	    # a require_version sub (which would shadow a Lisp
	    # require-version function), we emulate Exporter.
	    if ($VERSION < $_[$i]) {
		Carp::croak ("Emacs::Lisp $_[$i] required--this is only"
			     . " version $VERSION (" . __FILE__ . ")");
	    }
	    next;
	}
	next if $_[$i] !~ /([\$\%])(.*)/;
	my ($type, $name) = ($1, $2);
	if ($type eq '%') {
	    next if tied %$name;
	    tie %$name, 'Emacs::Lisp::Plist', \*{"::$name"};
	} else {
	    next if tied $$name;
	    tie $$name, 'Emacs::Lisp::Variable', \*{"::$name"};
	}
	push @newlist, $_[$i];
    }
    # XXX  Accommodating some undocumented Exporter.pm behavior here...
    if (%EXPORT) {
	@EXPORT{@newlist} = (1) x @newlist;
    } else {
	push @EXPORT_OK, @newlist;
    }
    goto &Exporter::import;
}

# Normally, one does not export an AUTOLOAD sub by default.
# But presumably, if you're using this module, you are running Emacs
# and want easy access to Lisp functions.
# Say `use Emacs::Lisp ();' to avoid importing AUTOLOAD.
#
# XXX Regardless, this should probably be fixed to insert AUTOLOAD
# as a closure/hook if there already is one.  Maybe the place to fix
# it is in Exporter.pm. (?)

%EXPORT_TAGS =
    (
     funcs	=> [qw(
		       funcall
		       AUTOLOAD
		       cons
		       consp
		       car
		       cdr
		       setcar
		       setcdr
		       )],
     special	=> [qw(
		       catch
		       defun
		       interactive
		       save_current_buffer
		       save_excursion
		       save_restriction
		       setq
		       track_mouse
		       unwind_protect
		       )],
     extra	=> [qw(
		       lisp
		       t
		       nil
		       )],
     );

@EXPORT = map { @$_ } values %EXPORT_TAGS;

sub t () { return \*::t; }
sub nil () { return undef; }

sub AUTOLOAD {
    *$AUTOLOAD = &$get_funcall_closure (__PACKAGE__, $AUTOLOAD);
    goto &$AUTOLOAD;
}
sub can { return &UNIVERSAL::can || &$can (__PACKAGE__, $_[1]); }

%special =
    (
     'setq_default'	=> "use `&set_default(\\*::symbol, \$value)' instead",
     'or'		=> "use Perl's `or' or `||' operator instead",
     'and'		=> "use Perl's `and' or `&&' operator instead",
     'if'		=> "use Perl's `if' or `?...:' operator instead",
     'cond'		=> "use Perl's `if', `elsif' and `else' instead",
     'progn'		=> "use a code block instead",
     'prog1'		=> "use a temporary variable instead",
     'prog2'		=> '*prog1',
     'quote'		=> "use `\\*::symbol' to quote a symbol, and "
			     . "`[\@items]' to make a list",
     'function'		=> '*quote',
     'defmacro'		=> "functionality to be added",
     'defvar'		=> "functionality to be added",
     'defconst'		=> '*defvar',
     'let*'		=> '*let',
     'let'		=> "use `local' instead",
     'while'		=> "use Perl's `for', `while' or `until' instead",
     'condition_case'	=> "use Perl's `eval' instead",
     'ml_if'		=> undef,
     'eval_when_compile'=> "use a `BEGIN' block or Perl's `use' instead",
  );

sub setq (&) {
    if (! HAVE_B()) {
	warn ("This version of Perl can't do setq.  Import explicitly");
	# But try anyway.
	return (&{$_[0]}());
    }

    my $coderef = shift;
    my $callpkg = caller;
    my @vars = _assignees($coderef);
    local $Exporter::ExportLevel = 1;
    import Emacs::Lisp @vars;
    return (&$coderef);
}

my (@_assignees);

sub _assignees ($) {
    return unless HAVE_B();
    my ($coderef) = @_;

    # What an irony that the B module is not conducive to thread-safety!
    # (or am I missing something?)
    # Well, you're toast if you are defunning from multiple threads anyway.
    @_assignees = ();

    B::walkoptree (B::svref_2object ($coderef)->ROOT,
		   'Emacs__Lisp_push_op_assignees');
    return @_assignees;
}

# Perl 5.005 $op->ppaddr returns stuff like 'pp_sassign'.
# With 5.6.0 you're supposed to use $op->name, which would return 'sassign'.
# 5.6.0's $op->ppaddr gives 'PL_ppaddr[OP_SASSIGN]'.  Oh well.
sub match_op_name {
    return unless HAVE_B();
    my ($op, $name) = @_;
    return $op->ppaddr =~ /p_$name\b/i;
}

#   Try to ferret out the variables that get assigned to in a coderef.
#   Currently, we're only looking for scalars and hash elements.

# Recklessly avoid type checking unless/until we have problems.
sub B::OBJECT::Emacs__Lisp_push_op_assignees { }
sub B::BINOP::Emacs__Lisp_push_op_assignees {
    return unless HAVE_B();
    my ($op) = @_;

    return unless match_op_name ($op, 'sassign');
    $op = $op->first->sibling;
    if (match_op_name ($op, 'null')) {
	$op = $op->first;
    }
    if (match_op_name ($op, 'gvsv')) {
	push @_assignees, "\$".$op->gv->NAME;

    } elsif (match_op_name ($op, 'helem')
	     && match_op_name (($op = $op->first), 'rv2hv')
	     # 5.005 had it as B::GVOP, 5.6.0 calls it B::SVOP
	     && ref ($op = $op->first) =~ /^B::[GS]VOP$/) {
	push @_assignees, "%".$op->gv->NAME;
    }
}

sub interactive (;$) {
    my $what = shift;
    return bless \$what, 'Emacs::InteractiveSpec';
}

# See if the first thing the sub does is assign @_ to a list.
# For use in finding reasonable function parameter names for defun.
sub _param_names {
    return undef unless HAVE_B();
    my ($code) = @_;
    my ($top, $aa, $op, @names, @pad_name, $name);

    # Make all sorts of assumptions to provoke errors and learn how Perl
    # *really* works.  :-)

    # FIXME: Could maybe replace some of the ppaddr with ref($op) eq 'B::BLAH'.
    $top = B::svref_2object ($code);
    $aa = $top->ROOT->first->first->sibling;
    return undef unless match_op_name ($aa, 'aassign');

    # The following probably needs to be revised for threaded Perl,
    # since @_ is a different sort of beast there.

    $aa = $aa->first;
    $op = $aa->first->sibling;
    return undef unless (match_op_name ($op, 'rv2av')
			 && match_op_name (($op = $op->first), 'gv')
			 # If you use @pkg::_ you get what you deserve.
			 && $op->gv->NAME eq '_');

    # We are assigning @_ to something.
    # Get the names of the variables assigned to.
    # For now, only worry about lexicals.
    # (Globals will probably be easier.  Dunno about local().)

    # Here I shy away from making assumptions.
    return undef unless match_op_name (($op = $aa->sibling), 'null');
    return undef unless B::ppname ($op->targ) eq 'pp_list';
    return undef unless match_op_name (($op = $op->first), 'pushmark');
    $op = $op->sibling;
    return undef unless (match_op_name ($op, 'padsv')
			 or match_op_name ($op, 'padav'));

    @pad_name = ($top->PADLIST->ARRAY)[0]->ARRAY;

    for (; $$op; $op = $op->sibling) {

	$name = $pad_name[$op->targ]->PV;
	return undef if $name =~ /^.arg[\ds]/;
	push @names, $name;
    }
    return \@names;
}

# Build the Lisp parameter list - names, and &optional &rest as needed.
# This makes the online help information more intelligible.
sub _make_arglist {
    my ($code) = @_;
    my ($proto, @arglist, @applylist, $ends_in_list);
    my ($num_req, $num_opt, $num_all);
    my ($counter, $arg_num, @names, $name, $pushed_and_opt);

    $proto = prototype ($code);
    if (not defined $proto or $proto =~ /[^\$\@;]/) {
	$proto = '@';  # Give up on doing anything intelligent with $proto.
    }
    @names = @{_param_names ($code) || []};

    $ends_in_list = $proto =~ s/\@.*//;
    $proto =~ s/^(\$*)//;
    $num_req = length ($1);
    $num_opt = ($ends_in_list ? 0 : $proto =~ tr/$/$/);
    $num_all = $num_req + $num_opt;

    for ($arg_num = 0; $arg_num < $num_all;) {

	if ($arg_num == $num_req && $num_opt > 0) {
	    push @arglist, '&optional';
	    $pushed_and_opt = 1;
	}
	$arg_num++;

	if (defined ($name = shift @names)) {
	    $name =~ s|^(.)||;
	    if ($1 ne "\$") {
		undef $name;
		@names = ();
	    }
	}
	$name = "arg$arg_num" unless defined $name;
	push @applylist, $name;
	push @arglist, $name;
    }

    if ($ends_in_list) {

	while (defined ($name = shift @names)) {
	    $name =~ s|^(.)||;
	    last if $1 ne "\$";

	    if (not $pushed_and_opt) {
		push @arglist, '&optional';
		$pushed_and_opt = 1;
	    }
	    push @applylist, $name;
	    push @arglist, $name;
	}
	$name = 'args' unless defined $name;
	push @applylist, $name;
	push @arglist, '&rest', $name;
    }
    package main;  # for globs
    return ([map {\*$_} @arglist], [map {\*$_} @applylist], $ends_in_list);
}

sub defun ($$;$$) {
    my $sym = shift;
    my ($next, $docstring, $interactive, $body, @form);
    my ($arglist, $applylist, $ends_in_list);

    $sym = \*$sym
	unless ref ($sym) eq 'GLOB';
    $next = shift;
    if (! ref ($next)) {
	$docstring = $next;
	$next = shift;
    }
    if (ref ($next) eq 'Emacs::InteractiveSpec') {
	$interactive = $next;
	$next = shift;
    }

    # FIXME: can't use a sub name.
    ref ($body = $next) eq 'CODE' && $#_ == -1
	or Carp::croak ('Usage: defun ($sym, [$docstring],'
			.' [&interactive($spec)], $code)');

    ($arglist, $applylist, $ends_in_list) = _make_arglist ($body);

    @form = (\*::lambda, $arglist);

    if (defined ($docstring)) {
	push @form, $docstring;
    }
    if (defined ($interactive)) {
	$interactive = $$interactive;
	if (ref ($interactive) eq 'CODE') {
	    $interactive = [\*::perl_call,
			    wrap ($interactive),
			    \*::list_context];
	}
	if (defined ($interactive)) {
	    push @form, [\*::interactive, $interactive];
	} else {
	    push @form, [\*::interactive];
	}
    }
    if ($ends_in_list) {
	push @form, [\*::apply, $body, @$applylist];
    } else {
	push @form, [$body, @$applylist];
    }
    &fset ($sym, [@form]);
    return $sym;
}

sub catch ($&) {
    return &eval ([\*::catch, [\*::quote, $_[0]],
		   [\*::perl_call, wrap ($_[1])]]);
}

sub save_excursion (&) {
    return &eval ([\*::save_excursion, [\*::perl_call, wrap ($_[0])]]);
}

sub save_current_buffer (&) {
    return &eval ([\*::save_current_buffer, [\*::perl_call, wrap ($_[0])]]);
}

sub save_restriction (&) {
    return &eval ([\*::save_restriction, [\*::perl_call, wrap ($_[0])]]);
}

sub track_mouse (&) {
    return &eval ([\*::track_mouse, [\*::perl_call, wrap ($_[0])]]);
}

sub unwind_protect {
    my ($body, $handler) = @_;

    for ($body, $handler) {
	$_ = wrap ($_) if ref eq 'CODE';
    }
    return (&eval ([\*::unwind_protect,
		    [\*::perl_call, $body],
		    # XXX should save some possible work by adding
		    # \*::void_context.
		    [\*::perl_call, $handler]]));
}


1;
__END__


=head1 NAME

Emacs::Lisp - Support for writing Emacs extensions in Perl

=head1 SYNOPSIS

=head2 In Emacs

    M-x perl-eval-expression RET 2+2 RET
    M-x perl-eval-region RET
    M-x perl-eval-buffer RET
    ... and more ...

=head2 In Perl

    use Emacs::Lisp;

    &switch_to_buffer('*scratch*');
    &insert("Hello, world!\n");

    setq { $cperl_font_lock = t };

    &add_hook(\*find_file_hooks,
	      sub { &message("found a file!") });

    use Emacs::Lisp qw($emacs_version $epl_version);
    save_excursion {
	&set_buffer(&get_buffer_create("*test*"));
	&insert("This is ");
	&insert(&featurep(\*::xemacs) ? "XEmacs" : "Emacs");
	&insert(" version $emacs_version,\n");
	&insert("EPL version $epl_version.\n");
	&insert("Emacs::Lisp version is $Emacs::Lisp::VERSION.\n");
    };


=head1 DESCRIPTION

Emacs allows you to customize your environment using Lisp.  With
EPL, you can use Perl, too.  This module allows Perl code to call
functions and access variables of Lisp.

You still need to learn some Lisp in order to understand I<The Elisp
Manual>, which is the definitive reference for Emacs programming.
This document assumes a basic understanding of Emacs commands and Lisp
data types.  I also assume familiarity with Perl's complex data
structures (described in L<perlref>) and objects (see L<perlobj>).

=head2 Quick Start

Run B<emacs -l perl> and type:

    C-x p e &insert ("hello!\n") RET

The string C<"hello!"> should appear in your scratch buffer.  The Perl
sub C<&insert> has called the Emacs Lisp C<insert> function, which
inserts its string argument into the current buffer at point.

Paste this text into a buffer, select it, and type C<M-x
perl-eval-region RET>:

    sub doit { &message("Cool, huh?"); }
    defun (\*perltest, interactive, \&doit);

Type C<M-x perltest RET>.  The text will appear in the minibuffer.
C<defun> and C<interactive> are used to create Emacs commands.


=head1 EPL AND PERLMACS

Perlmacs was (is?) a project that embedded a Perl interpreter into the
Emacs binary so that it could run Lisp, Perl, or any combination of
the two.  It uses Perl's C interface, which requires patching and
recompiling Emacs.  As a result, each release is tied to a version of
Emacs, it takes a lot of time and disk space to build, and it is not
very portable.

EPL (Emacs Perl) accomplishes most of what Perlmacs can do, but it
does not suffer from the same drawbacks.  It uses unmodified Emacs and
Perl and lets them work together through IPC (pipes).  This may make
some tasks much slower, but it is much more convenient to install and
upgrade, and it works with XEmacs as well as Emacs 21 betas.

For the time being, this module attempts to support both Perlmacs and
EPL.  The user-visible APIs are almost identical, except for EPL's
lack of C<Emacs::main()>.


=head1 LISP SUPPORT FOR PERL

Lisp code can check for Perl support using C<(require 'perl)>.  In
Perlmacs, some of the Perl functions are built in, and others are
defined in F<perl.el>.  When you use EPL, F<epl.el> substitutes for
the built-in support, but the same F<perl.el> is used.

=head2 Functions

The following Lisp functions do not rely on the Emacs::Lisp module.
Use C<C-h f E<lt>function-nameE<gt> RET> within Emacs to see their doc
strings.

    perl-eval-expression  EXPRESSION
    perl-eval-region      START END
    perl-eval-buffer
    perl-load-file        NAME
    perl-eval             STRING &optional CONTEXT
    perl-call             SUB &optional CONTEXT &rest ARGS
    perl-eval-and-call    STRING &optional CONTEXT &rest ARGS
    perl-to-lisp          OBJECT
    perl-wrap             OBJECT
    perl-value-p          OBJECT
    perl-eval-raw         STRING &optional CONTEXT
    perl-call-raw         SUB &optional CONTEXT &rest ARGS
    make-perl-interpreter &rest ARGV
    perl-destruct         &optional INTERPRETER
    perl-gc               &optional PURGE
    perl-free-refs        &rest REFS

The following Lisp variables affect the Perl interpreter and have doc
strings accessible via C<C-h f E<lt>variable-nameE<gt> RET>.  They
are:

    perl-interpreter-program
    perl-interpreter-args
    perl-interpreter

=head2 Data Conversions

When Perl calls a Lisp function, its arguments are converted to Lisp
objects, and the returned object is converted to a Perl value.
Likewise, when Lisp calls Perl, the arguments are converted from Lisp
to Perl and the return values are converted to Lisp.

=over 4

=item * Lisp has three scalar types.

Lisp integers, floats, and strings all become Perl scalars.  A simple
Perl scalar becomes either an integer, a float, or a string.

Interesting character encodings such as UTF-8 are not currently
supported.  I don't even know what happens to 8-bit characters during
string conversion.

=item * Lisp symbols correspond to globrefs.

Glob references become symbols in Lisp.  Underscores are swapped with
hyphens in the name, since Perl prefers underscores and Lisp prefers
hyphens.  See L</Symbols> for more information.

=item * Lisp's `nil' is equivalent to Perl's `undef' or `()'.

As an exception to the rule for symbols, C<nil> in Lisp corresponds to
C<undef> in Perl.

In Lisp, C<nil> is really a symbol.  However, it is typically used as
the boolean value I<false>.  Glob references evaluate to I<true> in
boolean context.  It is much more natural to convert C<nil> to
C<undef>.

=item * Arrayrefs correspond to lists.

Lists are a central data structure in Lisp.  To make it as easy as
possible to pass lists to Lisp functions that require them, Perl array
references are converted Lisp lists.  For example, the Perl expression
such as

    ["x", ["y", 1]]

is converted to

    '("x" ("y" 1))

in Lisp.

=item * Arrayref refs correspond to vectors.

Adding C<\> to an arrayref makea it an arrayref ref, which becomes a
vector in Lisp.  For example, C<\[1, 2, undef]> becomes C<[1 2 nil]>.

=item * Conses that are not lists become Emacs::Lisp::Cons objects.

Compatibility note:  Perlmacs does not have this feature.

    $x = &cons("left", "right");
    print ref($x);                # "Emacs::Lisp::Cons"
    print $x->car;                # "left"
    print $x->cdr;                # "right"

But:

    $x = &cons ("top", undef);    # a Lisp list
    print ref($x);                # "ARRAY"
    print $x->[0];                # "top"

=item * Conversion uses "deep" copying by default.

Conversion of lists and vectors to arrayrefs and arrayref refs is
recursive by default.  Changes made by Lisp to a list will not affect
the Perl array of which it is a copy, nor will changes to a Perl array
affect a Lisp list.  See L</BUGS> about converting cyclic structures.

=item * There are ways to make "shallow" copies.

A shallow copy simply wraps a Perl scalar in a Lisp object or vice
versa.  Wrapped Perl values appear as a Lisp objects of type
C<perl-value>.  Wrapped Lisp values appear in Perl as objects of class
C<Emacs::Lisp::Object>.  See L</CAVEATS> for issues relating to
wrapped data.

Where a data type has no natural equivalent in the other language,
shallow copying is the default.  Examples include Perl hashrefs and
Lisp buffer objects.

In Perl, the C<lisp> function wraps its argument in a Lisp object.
This allows Perl arrays to be passed by reference to Lisp functions.
(Of course, the value returned by C<lisp> is really a Perl value
wrapped in a Lisp object wrapped in a Perl object.)

An Emacs::Lisp::Object's C<to_perl> method performs a deep copy (if
the argument is Lisp data) or unwraps its argument (if it is Perl
data).

Lisp functions called through package Emacs::Lisp convert their return
values using deep copying.  The same functions are accessible through
Emacs::Lisp::Object, which does shallow conversion and always returns
an Emacs::Lisp::Object object.

These examples show how the data wrapping functions work:

    $x = lisp [1, 2, 3];
    print ref($x);           # "Emacs::Lisp::Object"
    print ref($x->to_perl);  # "ARRAY"
    print @{&list(2, 3)};    # "23"

    $x = Emacs::Lisp::Object::list(2, 3);
    print ref($x);           # "Emacs::Lisp::Object"
    print @{$x->to_perl};    # "23"

=back

=head2 Scripts

Perlmacs can run Perl programs.  By default, Perlmacs is installed
under two names, B<pmacs> and B<perlmacs>.  Which name is used to
invoke the program determines how it parses its command line.

If B<perlmacs> is used (or, more precisely, any name containing
"B<perl>"), it behaves like Perl.  For example,

    $ perlmacs script.pl

runs the Perl program script.pl.

When invoked as B<pmacs>, it behaves like Emacs.  Example:

    $ pmacs file.txt

This begins an editing session with F<file.txt> in the current buffer.

The I<first> command line argument can override the invocation name.
If it is B<--emacs>, Emacs takes control.  If it is B<--perl>, the
program runs in Perl mode.

The I<Emacs> module (that is, the Perl module named "Emacs") includes
support for starting an editing session from within a Perlmacs script.
See L<Emacs>.


=head1 PERL SUPPORT FOR LISP

The Emacs::Lisp module allows Perl programs to invoke Lisp functions
and handle Lisp variables as if they were Perl subs and variables.

The directive C<use Emacs::Lisp;> causes any use of a function not
defined in Perl to invoke the Lisp function of the same name (with
hyphens in place of underscores).  For example, this writes a message
to the standard error stream (in Perl mode) or displays it in the
minibuffer:

    &message ("this is a test");

=head2 Functions

This code calls the hypothetical Lisp function C<foo-bar> with
arguments C<4> and C<t>.

    &foo_bar(4, t);

The Lisp syntax for the same call would be

    (foo-bar 4 t)

The ampersand (C<&>) in the Perl example is not required, but it is
needed for functions, such as C<read>, C<eval>, and C<print>, which
are Perl keywords.  Using it with Emacs::Lisp is a good habit, so the
examples in this document include it.

If you don't want an C<AUTOLOAD> sub to affect your namespace, you may
either put parentheses after "C<use Emacs::Lisp>" or import to a
different package, and use qualified function names.  For example:

    use Emacs::Lisp ();
    Emacs::Lisp::message("hello\n");

    {package L; use Emacs::Lisp;}
    L::message("goodbye\n");

=head2 Symbols

Many Lisp functions take arguments that may be, or are required to be,
I<symbols>.  In Lisp, a symbol is a kind of name, but does not have
the same type as a string.  Lisp programs typically use the C<quote>
operator to specify a symbol.  For example, this Lisp code refers to
the C<beep> symbol:

    (run-at-time nil 1 'beep)

EPL uses glob references to specify symbols.  A literal globref begins
with a backslash followed by an asterisk, so the last example would be
written as

    &run_at_time(undef, 1, \*beep);

in Perl.  (You may want to do C<&cancel_function_timers(\*beep)> soon
after trying this example.)

When comparing the returned values of Lisp functions to each other and
to symbols, it is best to use the Lisp C<eq> function instead of
Perl's equality operators.

    ### PREFERRED
    if (&eq(&type_of($x), \*::cons)) { ... }

    ### PROBABLY OK
    if (&type_of($x) eq \*cons) { ... }
    if (&type_of($x) == \*cons) { ... }

=head2 Variables

In Lisp, variables play a role akin to that of Perl I<scalar>
variables.  A variable may hold a number, a string, or a reference to
any type of complex Lisp data structure.  (They are not called
references in Lisp, but rather "objects".)

You can create a Perl alias for any reasonably named Lisp variable by
saying C<use Emacs::Lisp qw($varname);>.  Thereafter, assignment to
C<$varname> will update the Lisp value.  Changes made to the variable
in Lisp will be reflected in Perl when C<$varname> is used in
expressions.

This example saves and replaces the value of the Lisp variable
C<inhibit-eol-conversion>:

    use Emacs::Lisp qw($inhibit_eol_conversion);
    $old_val = $inhibit_eol_conversion;
    $inhibit_eol_conversion = 1;

This sort of thing could be accomplished in Lisp as follows:

    (setq old-val inhibit-eol-conversion)
    (setq inhibit-eol-conversion 1)

(but you would probably rather use C<let> instead, for which there is
still no convenient Emacs::Lisp equivalent).  See also the C<setq>
function below.

=head2 Property Lists

Lisp symbols all have an associated object called a I<plist>, for
"property list".  The plist is an object just like any other, but it
is typically used in a way vaguely resembling Perl's hashes.

Plists are not used nearly as often as Lisp functions and variables.
If you are new to Lisp, you can probably skip this section.

A plist is different from a Perl hash.  Lookups are not based on
string equality as with Perl, but rather on Lisp object equality of
the C<eq> variety.  For this reason, it is best to stick to the Lisp
convention of using only symbols as keys.  (See L</Symbols>.)

Emacs::Lisp provides a shorthand notation for getting and setting
plist elements.  If you say "C<use Emacs::Lisp qw(%any_name)>", then
subsequent access to the elements of C<%any_name> will get or set the
corresponding properties of the Lisp symbol C<any-name>.

For example, the following Perl and Lisp fragments are more or less
equivalent:

    # Perl fragment
    use Emacs::Lisp qw(%booboo %upcase_region);
    $booboo{\*error_conditions} = [\*booboo, \*error];
    $can_upcase = ! $upcase_region{\*disabled};

    ; Lisp fragment
    (put 'booboo 'error-conditions '(booboo error))
    (setq can-upcase (not (get 'upcase-region 'disabled)))

See also the C<setq> function below.

=head2 Macros

Lisp I<macros>, such as C<setq> and C<defun>, do not work the same way
functions do, although they are invoked using the function syntax.
(Here you see the vast philosophical chasm separating Perl from Lisp.
While Perl might have five syntaxes to mean the same thing, Lisp has
one syntax with two meanings!)

Some macros are equivalent to Perl operators, such as C<if> and
C<while>.  Others have meanings peculiar to Lisp.  A few macros are
implemented in Emacs::Lisp.  They are described below.  If you try to
call a macro that has not been implemented, you will get an error
message which may propose an alternative.

=over 8

=item catch SYMBOL,CODE

Evaluate CODE in a Lisp C<catch> construct.  At any point during
CODE's execution, the C<throw> function may be used to return control
to the end of the C<catch> block.  For example:

    $x = catch \*::out, sub {
	$y = 1;
	&throw(\*::out, 16);
	$y = 2;
    };
    print $x;  # prints 16
    print $y;  # prints 1

Some Perl constructs have functionality similar to C<throw>; for
example, C<return> and C<last>.  However, they do not work with
catches in Lisp code.

=item defun SYMBOL,DOCSTRING,SPEC,CODE

=item defun SYMBOL,DOCSTRING,CODE

=item defun SYMBOL,SPEC,CODE

=item defun SYMBOL,CODE

Make CODE callable as the Lisp function SYMBOL.  This is Lisp's
version of Perl's C<sub> keyword.  A function defined in this way
becomes visible to Lisp code.

C<defun> is useful for defining Emacs I<commands>.  Commands are
functions that the user can invoke by typing C<M-x
E<lt>function-nameE<gt>>.  A command may be bound to a key or sequence
of keystrokes.  See the Emacs documentation for specifics.

When defining a command, you must specify the interactive nature of
the command.  There are various codes to indicate that the command
acts on the current region, a file name to be read from the
minibuffer, etc.  Please see I<The Elisp Manual> for details.

Emacs::Lisp's C<defun> uses a SPEC returned by the C<interactive>
function to specify a command's interactivity.  If no SPEC is given,
the function will still be callable by Lisp, but it will not be
available to the user via C<M-x E<lt>function-nameE<gt> RET> and
cannot be bound to a sequence of keystrokes.  Even commands that do
not request information from the user need an interactive spec.  See
L</interactive>.

This example creates a command, C<reverse-region-words>, that replaces
a region of text with the same text after reversing the order of
words.  To be user-friendly, we'll provide a documentation string,
which will be accessible through the Emacs help system (C<C-h f
reverse-region-words RET>).

    use Emacs::Lisp;
    defun (\*reverse_region_words,
	   "Reverse the order of the words in the region.",
	   interactive("r"),
	   sub {
	       my ($start, $end) = @_;
	       my $text = &buffer_substring($start, $end);
	       $text = join('', reverse split (/(\s+)/, $text));
	       &delete_region($start, $end);
	       &insert($text);
	   });

If you try this example and invoke the help system, you may notice
something not quite right in the message.  It reads as follows:

    reverse-region-words is an interactive Lisp function.
    (reverse-region-words &optional START END &rest ARGS)

    Reverse the order of the words in the region.

Notice the part about "&optional" and "&rest".  This means that Lisp
thinks the function accepts any number of arguments.  It knows the
names of the first two because of the assignment "C<my ($start, $end)
= @_>".

But our function only works if it receives two args.  Specifying a
prototype documents this:

    sub ($$) {
	my ($start, $end) = @_;
	...
    }

    reverse-region-words is an interactive Lisp function.
    (reverse-region-words START END)

=item interactive SPEC

=item interactive

Used to generate the third (or, in the absence of a doc string, the
second) argument to C<defun>.  This determines how a command's
arguments are obtained.

What distinguishes a "command" from an ordinary function in Emacs is
the presence of an C<interactive> specifier in the C<defun>
expression.

SPEC may be a string, as described in I<The Elisp Manual>, or a
reference to code which returns the argument list.  If no spec is
given, the command runs without user input.

=item save_excursion BLOCK

Execute BLOCK within a Lisp C<save-excursion> construct.  This
restores the current buffer and other settings to their original
values after the code has completed.  See I<The Elisp Manual> for
details.

=item setq BLOCK

BLOCK is searched for assignments of either of these forms:

    $var = EXPR;
    $hash{$key} = EXPR;

Every such C<$var> and C<%hash> is imported from the Emacs::Lisp
module as if you had said, "C<use Emacs::Lisp qw($var %hash)>".
Afterwards, BLOCK is executed.  This is a convenient way to assign to
variables, for example in customization code.

This code

    use Emacs::Lisp;
    setq {
	$A = 2*$foo[5];
	$B{\*foo} = "more than $A";
    };

would have exactly the same effect as this:

    use Emacs::Lisp qw(:DEFAULT $A %B);
    $A = 2*$foo[5];
    $B{\*foo} = "more than $A";

The following, which does not tie or import any variables, has the
same effect on Lisp as the above:

    use Emacs::Lisp ();
    Emacs::Lisp::set( \*A, 2*$foo[5] );
    Emacs::Lisp::put( \*B, \*foo, "more than "
      . &Emacs::Lisp::symbol_value( \*A ));

=item unwind_protect (BODY, HANDLER)

Execute coderef BODY, returning its result.  Execute coderef HANDLER
after BODY finishes, even if BODY exits nonlocally through C<die> or
the like.

=back


=head1 BUGS

These are some of the known bugs in EPL and Emacs::Lisp.  If you find
other bugs, please check that you have the latest version, and email
me.

=over 4

=item * Emacs::Lisp doesn't work outside of XEmacs.

If a Perl program not under the control of an Emacs process uses
Emacs::Lisp functions, Emacs::Lisp tries to run Emacs in batch mode.
This only works with GNU Emacs 21 beta, not Emacs 20 or XEmacs.  This
can probably be fixed, but I don't know what the problem is yet.

A real solution would involve talking to Emacs on a channel other than
its standard input and output.  This might allow one to run in
interactive mode with arbitrary command line options.  I don't know if
Emacs can use arbitrary file descriptors or named pipes.  I suspect
not.  If not, I guess I'll try inet sockets.  Other possibilities
would be ptys (Emacs loves them, I'm not overly fond) and an
intermediary perl process that talks to the original process over a
named pipe.

=item * Non-robust with respect to subprocess Perl dying.

Perl dies because of (e.g.) version mismatch between epl.el and
EPL.pm.  Then you can't exit Emacs, because it tries to tell Perl to
exit and gives you an error "Process perl not running".  Very
unfriendly.

=item * Within Lisp code, everything defaults to package `main'.

It would perhaps be best to give the Lisp evaluation environment the
notion of a "current package" such as Perl has.

=item * Symbols whose names contain :: or '

How can we convert them to and from Perl?

=item * High IPC overhead

Strings are copied more than they absolutely need to be.  Even if they
weren't, it's bound to be a lot slower than Perlmacs.

=item * Lisp hash tables are not deep-copied.

What to do?  Produce tied hashes whose keys can be any Lisp object?
Wrap hashes that contain non-string keys?

=item * XEmacs package autoloads commands but not key bindings.

I need to figure out how to do this.

=back


=head1 CAVEATS

=over 4

=item * Conversion of scalar types is uncertain.

A defined, non-reference Perl scalar converted to Lisp becomes either
an integer, a float, or a string.  The method of choice is unclear.
This could be considered a bug, but it is somewhat inherent in the
languages' semantics, as Perl has no really good way to distinguish a
number from an equivalent string or an integer from a float.

=item * Conversion is not always reversible.

Information may be lost through the default (``deep'') data conversion
process.  For example, the glob reference C<\*::nil> and an empty
arrayref both become C<undef> when converted to Lisp and back.  Perl
and Emacs support different ranges for integer values.  Integers that
don't fit are upgraded to floats, so the distinction is lost.

=item * Circular data structures are troublesome.

See L<perlobj/"Two-Phased Garbage Collection">.  Lisp data structures
may be recursive (contain references to themselves) without the danger
of a memory leak, because Lisp uses a periodic-mark-and-sweep garbage
collector.

However, if a recursive structure involves I<any> Perl references, it
may I<never> be destroyable.

For best results, Perl code should handle mainly Perl data, and Lisp
code should handle mainly Lisp data.

=item * Cross-language references incur overhead.

For the benefit of Lisp's garbage collection, all Perl data that is
referenced by Lisp participates in mark-and-sweep.  For the benefit of
Perl's garbage collection, all Lisp objects that are referenced by
Perl maintain a (kind of) reference count.

A chain of Perl -> Lisp -> ... -> Perl references may take several
garbage collection cycles to be freed.  It is therefore probably best
to keep the number and complexity of such references to a minimum.

To make matters worse, if Emacs does not support weak hash tables,
Lisp must explicitly free its references to Perl data.  GNU Emacs 20
does not support weak hash tables, but Perlmacs solves this problem by
adding necessary support.  XEmacs 21 has weak hash tables, but EPL
does not yet know how to use them.

=back


=head1 TO DO

=over 4

=item * Finish texinfo doc

=item * Delete/revise obsolete portions of POD

=item * Figure out how to handle hash tables

=item * Garbage collection for XEmacs

=item * Debian package target

=item * Overload Emacs::Lisp::Object in various ways

=item * Formal rules for scalar type conversion

=item * Regression-test multiple Emacses under Perl

=item * Regression-test any Perls under Emacs

=item * Steal from IPC::Open2

=item * Optimized regex find and replace functions

=item * Multibyte characters

Emacs has had them for some time.  Now Perl's UTF-8 support is
stabilizing.  It's time the two met.

=item * Special forms: let, defmacro, defvar.

=item * Make a way to get a tied filehandle that reads a buffer.

=item * Improve perl-eval-buffer, perl-eval-and-call, et al.

=back


=head1 COPYRIGHT

Copyright (C) 1998-2001 by John Tobey,
jtobey@john-edwin-tobey.org.  All rights reserved.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; see the file COPYING.  If not, write to the
  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
  MA 02111-1307  USA


=head1 SEE ALSO

L<perl>, L<perlref>, L<perlobj>, L<Emacs>, B<emacs>, and I<The Elisp
Manual> (available where you got the Emacs source, or from
ftp://ftp.gnu.org/pub/gnu/emacs/).

=cut
