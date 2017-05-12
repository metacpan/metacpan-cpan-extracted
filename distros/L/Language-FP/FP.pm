#!/usr/bin/env perl
package Language::FP;
use Parse::RecDescent;
use Regexp::Common;

require Exporter;
@EXPORT = qw/fp_eval/;
@EXPORT_OK = qw/perl2fp fp2perl bottom BOTTOM/;
%EXPORT_TAGS = (':all' => [@EXPORT_OK, @EXPORT]);
@ISA = qw(Exporter);

$VERSION = 0.03;

sub BOTTOM () {			# the universal bad value
    if ($::FP_DEBUG =~ /b/) {
	use Carp 'confess';
	confess("Bottom!");
    }
    undef
}

sub bottom {			# check for bottom
    (@_ > 0 && !defined($_[0])) ? 1 : 0
}

sub numeric {			# check for 2 integer args
    return ($_[0] =~ /$RE{num}{real}/o) && ($_[1] =~ /$RE{num}{real}/o);
}

######################################################################
## Parser

##############################
# Debugging

sub info {			# pretty debugging output.
    my ($pack, $fn, $line, $subr) = caller 1;
    $subr =~ s/^.*:://;
    print STDERR "[$subr] ", @_, "\n";
}

sub Dparse {			# parse-time debugging output
    goto &info if $::FP_DEBUG =~ /p/;
}

sub Drun {			# run-time debugging.
    goto &info if $::FP_DEBUG =~ /r/;
}

##############################
# Utilities

# XXX: this shouldn't be needed.  It makes <X> behave the same as X
# when passed as an argument list.  Single-element lists and scalar
# values aren't the same kind of thing, but we're trying to pretend as
# if they are.  Otherwise, perl functions called from FP will all have
# to take array-refs.
sub as_array($) {
    my $a = shift;
    if (ref $a eq 'ARRAY') {
	@$a;
    } else {
	$a;
    }
}

# XXX: this is the disgusting inverse of as_array
sub to_arrayref {
    if (@_ == 1) {
	return shift;
    } else {
	return [@_];
    }
}

sub call_it {			# call a coderef, with verbosity
    my $f = shift;
    Drun "Calling $f (@_)";
    my @res = $f->(@_);
    Drun "-> (@res)";
    @res;
}

sub term {			# create a typed parse-tree node.
    my $type = shift;
    return { type => $type, val => [@_] };
}

##############################
# Symbol lookup.

# Note: we need to do a bit of magic here to look up functions and
# variables in both Language::FP and the calling package.

sub findsym {			# look up a function
    my ($sym, $type) = @_;
    if (ref $sym eq $type) {
	return $sym;
    }
    my ($where, $thing);
    foreach ('Language::FP', pkg()) {
	my $x = $_.'::'.$sym;
	if (defined($thing = *{$x}{$type})) {
	    $where = $x;
	    last;
	}
    }
    if (wantarray) {
	($thing, $where);
    } else {
	$thing;
    }
}

######################################################################
## The parser

my $P = undef;
sub get_parser {
    return $P if $P;
    $P = new Parse::RecDescent <<'EOG' or die "Can't create parser!";

{
use Regexp::Common;
    BEGIN {
	no strict 'refs';
	foreach (qw|term findsym|) {
	    *{__PACKAGE__.'::'.$_} = \&{'Language::FP::'.$_};
	}
    }
}

thing:	  'val' <commit> id_undef '=' application
		{ $return = term 'val', @item{qw(id_undef application)} }
	| 'def' <commit> id_undef '=' termlist
		{ $return = term 'def', @item{qw(id_undef termlist)} }
	| application
		{ $return = $item[1];1; }
	| /\s*/
	| <error>

application: termlist ':' <commit> data
		{ $return = term 'application', @item{qw(termlist data)}; }
	| data
		{ $return = $item[1]; }

termlist: 'while' <commit> complist termlist
		{ $return = term 'while', @item{qw(complist termlist)} }
 	| complist '->' <commit> complist ';' termlist
		{ $return = term 'if', @item[1,4,6] }
	| complist 
		{ $return = $item[1];1; }
	| <error>

complist: <rightop: func '.' func>
		{ $return = term 'compose', @{$item[1]} }

func:	  'bu' <commit> func data
		{ $return = term 'bu', @item{qw(func data)} }
	| '/' func
		{ $return = term 'insert', $item{func} }
	| '@' <commit> func
		{ $return = term 'forall', $item{func} }
	| '(' <commit> termlist ')'
		{ $return = $item{termlist} }
	| '[' <commit> <rightop: termlist ',' termlist> ']'
		{ $return = term 'distribute', @{$item[3]} }
	| '`' <commit> data
		{ $return = term 'constant', $item{data} }
	| sfunc
		{ $return = $item[1];1; }
	| id
		{ $return = $item[1];1; }
	| <error>

data:	  datum
		{ $return = term 'data', $item[1] }
	| <error>

datum:	  '<' <commit> datum(s?) '>'
		{ $return = $item[3];1; }
	| /$RE{num}{real}/o
		{ $return = $item[1];1; }
 	| /$RE{num}{int}/o
		{ $return = $item[1];1; }
	| /$RE{quoted}/o
		{ $return = substr($item[1], 1, length($item[1]) - 2);1; }
	| m{[a-rt-zA-Z_][\w\d]*}
	  <error?: Undefined variable "$item[1]"> <commit> {
		no strict 'refs';
		# XXX: actually interpolate variables during parse.
		$return = findsym($item[1], 'ARRAY') || undef;
	}
	| <error>

sfunc:	  /\d+/
		{ $return = term 'sfunc', $item[1]; }

id_undef:  m{[a-zA-Z_][\w\d]*}
		{ $return = term 'id_undef', $item[1]; }

id:	  m{[a-zA-Z_][\w\d]*}
		{ $return = term 'id', $item[1];1; }
	| m{([!<>=]=) | [+*/<>-] | ([gln]e) | ([gl]t) | eq}x
		{ $return = term 'op', $item[1]; }

EOG
    $P;
}

######################################################################
## Builtin functions (for both compilers).

# FP is supposed to be "bottom-preserving".  In other words, once a
# single operaation fails, it taints all results that depend on it.
# The only way to recover from this is to explicitly recognize the
# "bottom" condition using the bottom() test.

my %op_guts;
BEGIN {
    %op_guts = (
## List ops #####
# first/last element of list
hd 	=> '@_ ? $_[0] : BOTTOM',
hdr 	=> '@_ ? $_[-1] : BOTTOM',
# rest of list
tl 	=> '@_ ? @_[1..$#_] : BOTTOM',
tlr 	=> '@_ ? @_[0..$#_ - 1] : BOTTOM',
len 	=> 'return BOTTOM if bottom @_; scalar @_',
'reverse' => 'reverse @_',
# append
apndl 	=> '($_[0], @{$_[1]})',
apndr 	=> '(@{$_[0]}, $_[1])',
# Rotate
rotl 	=> '@_ ? @_[1..$#_,0]  : ()',
rotr 	=> '@_ ? @_[$#_, 0..$#_ - 1] : ()',
# Catenate
cat 	=> 'map { as_array $_ } @_',
## Logical ops #####
'and' 	=> '$_[0] &&  $_[1]',
'or' 	=> '$_[0] || $_[1]',
'not' 	=> '!$_[0]',
## Other ops #####
id 	=> '@_',
out 	=> 'print STDERR perl2fp(@_), "\n"; @_',
iota 	=> '1 .. $_[0]',
atom 	=> '@_ == 1 && ref($_[0]) eq "SCALAR"',
null 	=> '@_ == 0',
## "shaping" list-ops #####
distl 	=> q{
    my ($a, $b) = @_;
    return BOTTOM unless !bottom($a) && ref $b eq 'ARRAY';
    map { [$a, $_] } @$b;
},

distr 	=> q{
    my ($a, $b) = @_;
    return BOTTOM unless !bottom($b) && ref $a eq 'ARRAY';
    map { [$_, $b] } @$a;
},

trans 	=> q{
    my @ret;
    return () unless @_;
    my $len = scalar @{$_[0]};
    foreach (@_[1..$#_]) {
	return BOTTOM unless ref $_ eq 'ARRAY' && @$_ == $len;
    }
    for (my $i = 0; $i < $len; $i++) {
	push @ret, [ map { $_->[$i] } @_ ];
    }
    @ret;
},
);
}

######################################################################
## Closure-based "Compiler"

sub defun {			# 'def' X '=' ...
    my ($name, $val) = @_;
    no strict 'refs';
    *{pkg().'::'.$name} = $val;
    Drun "Defined function $name";
    'ok';
}

sub defvar {			# 'val' X '=' ...
    my ($name, $val) = @_;
    no strict 'refs';
    @{pkg().'::'.$name} = as_array $val;
    Drun "Defined value $name";
    'ok';
}

sub do_bu {			# bu (i.e. currying)
    my ($f, $o) = @_;
    Dparse "using $f($o, ...)";
    return sub {
	no strict 'refs';
	Drun "bu $f ($o, @_)";
	call_it($f, $o, @_);
    };
}

sub compose {			# '.' operator
    my @funcs = @_;
    Dparse "using (@funcs)";
    return sub {
	no strict 'refs';
	Drun "compose (@funcs)";
	foreach my $f (reverse @funcs) {
	    @_ = call_it($f, @_);
	}
	@_;
    };
}

sub distribute {		# '[...]' list-of-functions
    my @xs = @_;
    Dparse "using (@xs)";
    return sub {
	no strict 'refs';
	Drun "distribute (@xs) : (@_)";
	map { to_arrayref call_it $_, @_ } @xs;
    }
}

sub ifelse {			# 'a -> b ; c' construct
    my ($if, $then, $else) = @_;
    Dparse "if $if then $then else $else";
    return sub {
	# XXX: having to call this in array context sucks, but is necessary.
	Drun "if $if then $then else $else";
	my ($test) = call_it $if, @_;
	if (bottom($test)) {
	    BOTTOM;
	} elsif ($test) {
	    call_it $then, @_;
	} else {
	    call_it $else, @_;
	}
    };
}

sub awhile {			# 'while x y'
    my ($while, $do) = @_;
    Dparse "while ($while) $do";
    return sub {
	Drun "while ($while) $do -> (@_)";
	my $test;
	while (!bottom($test = (call_it $while, @_)[0])) {
	    if (!$test) {
		Drun "END while ($while): (@_)";
		return @_;
	    }
	    @_ = call_it $do, @_;
	}
	# Bottom.
	BOTTOM;
    }
}

sub forall {			# '@' operator, i.e. map
    my $f = shift;
    Dparse "using $f";
    return sub {
	no strict 'refs';
	Drun "forall $f (@_)";
	map { to_arrayref call_it $f, as_array $_ } @_;
    };
}

sub insert {			# '/' operator, i.e. reduce
    my $f = shift;
    Dparse "using $f";
    return sub {
	no strict 'refs';
	Drun "insert $f (@_)";
	return () unless @_;
	my $r = $_[0];
	return BOTTOM if bottom($r);
	foreach (@_[1..$#_]) {
	    $r = (call_it $f, $r, $_)[0];
	    return BOTTOM if bottom($r);
	}
	$r;
    }
}

sub constant {			# constant '`' operator
    my $x = shift;
    Dparse $x;
    return sub {
	Drun "constant $x";
	as_array $x;
    };
}

sub apply {			# ':' operator
    my ($func, $args) = @_;
    return $func->(as_array $args);
}

my %ops = ();			# symbol table for binary operators
sub make_binary_ops {
    return if keys %ops > 0;
    # Build binary operator functions.
    foreach my $f (qw|+ - * / ** == != < > <= >=|) {
	$ops{$f} = eval qq{sub {
 			return BOTTOM unless numeric(\@_);
			\$_[0] $f \$_[1]
		}
		} || die $@;
    }
}

local $::fp_caller = 'Language::FP';
sub pkg {			# package in which to bind functions
    $::fp_caller;
}

my %compile =
(
 val => \&defvar,
 def => \&defun,
 application => \&apply,
 while => \&awhile,
 if => \&ifelse,
 compose => \&compose,
 bu => \&do_bu,
 insert => \&insert,
 forall => \&forall,
 distribute => \&distribute,
 constant => \&constant,
 sfunc => sub {
     my $x = $_[0] || die "sfunc($#_): (@_)";
     sub { $_[$x - 1] }
 },
 id => sub {
     my $ret = findsym($_[0], 'CODE');
     unless ($ret) {
	 warn "Undefined function $_[0].";
	 return \&BOTTOM;
     }
     $ret;
 },
 data => sub { @_ },
 id_undef => sub { shift },
 op => sub {
     confess "unknown operator '$_[0]'" unless exists $ops{$_[0]};
     return $ops{$_[0]};
 }
);

sub closure_compile {		# internal compiler function
    my $tree = shift;
    if (ref $tree ne 'HASH') {
	return $tree;
    }
    my $type = $tree->{type};
    if (exists $compile{$type}) {
	my @args = map { closure_compile($_) } @{$tree->{val}};
	return $compile{$type}->(@args);
    } else {
	die "Can't handle $tree (type = $type)";
    }
}

sub CLOSURE_compile {		# external compiler function
    make_binary_ops;
    closure_compile(@_);
}

######################################################################
# The "Big Heinous Eval" compiler.

=for comment

Since Perl's sub calls are slow, I decided to try compiling FP def's
down to single, heinous Perl functions.  As I suspected, this turns
out to be much faster than the other implementation, though debugging
is much more of a challenge.

Each code generating function should return an expression that will
evaluate to its result in list context, and that has enough parens
around it to avoid confusing Perl's parser.

The functions should use temporaries where necessary to avoid
evaluating any of its arguments more than once.  These temporaries
cannot be references, since the arguments generally won't be real
arrays, but expressions producing them.

=cut

sub seq($) {			# Turn a sequence into an expression
    return '(do {
'.$_[0].'
})';
}

my $gen = 0;
sub gensym {			# yep.
    if (wantarray) {
	return map { $_.'_'.++$gen } @_;
    } else {
	return $_[0].'_'.++$gen;
    }
}

my %bhe_compile =
(
 val => sub {
     my ($name, $val, $rhs) = @_;
     $name = bhe_compile($name, undef);
     eval '@'.pkg()."::$name = ".bhe_compile($val, $rhs).";'ok';";
     if ($@) {
	 warn "Compilation error in $name: $@" if $@;
	 BOTTOM;
     } else {
	 q{'ok'};
     }
 },
 def => sub {
     my ($name, $val, $rhs) = @_;
     my $BODY = bhe_compile($val, $rhs);
     my $NAME = pkg().'::'.bhe_compile($name, undef);
     Dparse "\n---\n", $body, "\n---\n";
     eval "sub $NAME { $BODY }";
     if ($@) {
	 warn "Compilation error in $NAME: $@" if $@;
	 BOTTOM;
     } else {
	 q{'ok'};
     }
 },
 application => sub {
     my ($func, $args, $rhs) = @_;
     my $arg = bhe_compile($args, undef);
     return bhe_compile($func, $arg);
 },
 while => sub {
     my ($while, $do, $rhs) = @_;
     my ($test, $res) = gensym '$WHILE', '@WHILE';
     my $WHILE = bhe_compile($while, $res);
     my $DO = bhe_compile($do, $res);
     seq <<END;
my $res = $rhs;
while (my $test = ($WHILE)[0]) {
	$res = $DO;
	return BOTTOM if bottom($res);
    }
     $res;
END
 },
 if => sub {
     my ($if, $then, $else, $rhs) = @_;
     my $x = gensym '@IF';
     my ($IF, $THEN, $ELSE)
	 = map { bhe_compile($_, $x) } ($if, $then, $else);
     seq <<END;
my $x = $rhs;
if (($IF)[0]) {
    $THEN;
} else {
    $ELSE;
}
END
 },
 compose => sub {
     my $rhs = pop;
     my @funcs = @_;
     my $ret = $rhs;
     while (my $x = pop @funcs) {
	 $ret = bhe_compile($x, $ret);
     }
     $ret;
 },
 bu => sub {
     my ($f, $a, $rhs) = @_;
     my $A = bhe_compile($a, undef);
     return bhe_compile($f, "($A, $rhs)");
 },
 insert => sub {
     my ($f, $rhs) = @_;
     my ($r, $x, $xs) = gensym '$INSERT', '$INSERT', '@INSERT';
     my $DOIT = bhe_compile($f, "($r, $x)");
     return seq <<END;
my $xs = $rhs;
if ($xs) {
    my $r = shift $xs;
    foreach my $x ($xs) {
	$r = ($DOIT)[0];
	return Language::FP::BOTTOM if Language::FP::bottom($r);
    }
    $r;
} else {
    ();				# nothing to insert
}
END
},
 forall => sub {
     my ($f, $rhs) = @_;
     my $v = gensym '@FORALL';
     my $body = bhe_compile($f, $v);
     seq <<ENDS;
map {
    my $v = Language::FP::as_array(\$_);
    Language::FP::to_arrayref($body)
} $rhs
ENDS
 },
 distribute => sub {
     my $rhs = pop;
     my $args = gensym '@DISTRIBUTE';
     my $ret = "my $args = $rhs;\n(";
     $ret .= join ",\n\t", map {
	 'Language::FP::to_arrayref('.bhe_compile($_, $args).')'
     } @_;
     seq ($ret . ');');
 },
 constant => sub { return bhe_compile(shift, undef) },
 sfunc => sub {
     my ($x, $rhs) = @_;
     --$x;			# FP indices are one-based.
     "(($rhs)[$x])";
 },
 id => sub {
     my ($f, $rhs) = @_;
     my ($code, $fullname) = findsym($f, 'CODE');
     unless ($code) {
	 warn "Undefined function $f.";
	 return 'return BOTTOM';
     }
     unless ($fullname) {
	 warn "Anonymous sub not supported\n";
	 return 'return BOTTOM';
     }
     return '&{'.$fullname.'}('.$rhs.')';
 },
 data => sub {
     use Data::Dumper;
     pop;			# get rid of rhs.
     return 'Language::FP::as_array('.seq(Dumper(to_arrayref @_)).')';
 },
 id_undef => sub { shift },
 op => sub {
     my ($op, $rhs) = @_;
     my $res = gensym 'OP';
     seq "my \@$res = $rhs; \$$res\[0] $op \$$res\[1]";
 }
);

sub BHE_compile {		# bootstrap function for BHE
    my $compiled = bhe_compile(@_, '@_');
    Dparse "---\n$compiled\n---\n";
    my @ret = eval $compiled;
    warn $@ if $@;
    @ret;
}

sub bhe_compile {		# Internal BHE compile function
    my $tree = shift;
    my $rhs = shift;
    if (ref $tree ne 'HASH') {
	# Terminals should never call bhe_compile
	die;
    }
    my $type = $tree->{type};
    if (exists $compile{$type}) {
	return $bhe_compile{$type}->(@{$tree->{val}}, $rhs);
    } else {
	die "Can't handle $tree (type = $type)";
    }
}

######################################################################
## Exportables:

sub import {
    Language::FP->export_to_level(1, @_);

    # XXX: maybe consider autoloading these?

    # Build op-functions.
    while (my ($f, $b) = each %op_guts) {
	*{$f} = eval qq{ sub { return BOTTOM if bottom(\@_); $b }};
	die "$f: $@" if $@;
    }
    1;
}

sub perl2fp {
    my @ret;
    foreach (@_) {
	if (ref eq 'ARRAY') {
	    push @ret, '<'.perl2fp(@$_).'>';
	} elsif (ref) {
	    die "Expecting ARRAY, got ".ref;
	} elsif (/$RE{num}{int}/o || /$RE{num}{real}/o) {
	    push @ret, $_;
	} elsif (defined) {
	    push @ret, qq{"$_"};
	} else {
	    push @ret, '_|_';
	}
    }
    join(' ', @ret);
}

sub fp2perl {
    my $str = shift;
    return to_arrayref($P->data($str));
}

sub fp_eval {
    local $::fp_caller = caller;
    my $p = get_parser;
    if (@_ == 1) {
	use Data::Dumper;
	my $parsed = $P->thing(shift);
	unless ($parsed) {
	    warn "Parse error";
	    return undef;
	}
 	if ($::FP_DEBUG =~ /C/) {
	    return [CLOSURE_compile($parsed)];
 	} else {
	    return [BHE_compile($parsed)];
 	}
    }

    my %o = @_;
    my $in = $o{in} || 'STDIN';
    my $out = $o{out} || 'STDOUT';
    while (<$in>) {
	chomp;
	my $res = $P->thing($_);
	unless ($res) {
	    warn;
	    next;
	}
	print $out perl2fp($res), "\n";
    }
}

1;

__END__

=head1 NAME

Language::FP -- think like Jonh Backus wants you to

=head1 SYNOPSIS

  use Language::FP qw/perl2fp/;

  # Sum of the first 12 integers:
  my $sum = fp_eval '/+ . iota:12'
  print perl2fp($result);
  # prints '<78>'

  # Matrix-vector product:
  fp_eval 'def Ax = @(+ . @* . trans) . distr';
  my @mv = ([[1, 2], [3, 4]], [5, 6]);
  print perl2fp(fp_eval('Ax:' . perl2fp(@mv)));
  # prints '<17 39>'

  # Cross-language calls:
  print join ', ', Ax(@mv);
  # prints '17, 39'

  sub cubes { map { $_ ** 3 } @_ }
  print perl2fp(fp_eval 'cubes:<1 2 3>');
  # prints '<1 8 27>'

  fp_eval in => \*INPUT, out => \*OUTPUT;

=head1 DESCRIPTION

C<Language::FP> is an implementation of John Backus' FP language, a
purely functional language remarkable for its lack of named variables
-- only functions have names.  Note that this is B<not> a deliberately
obfuscated language -- it was designed for actual users (probably
mathematicians).  Since Perl's $calars, @rrays and %ashes advertise
themselves so boldly, I thought programming in a language whose author
thought that named variables led only to confusion and error would be
eye-opening.  I now know why every language since has had named
variables.

While at some point I should probably include a brief FP tutorial, for
the moment please see http://www.cse.sc.edu/~bays/FPlink for more
information on the language's history and basic functions.  There are
a number of subtle syntactic variants of FP described and implemented
on the web.  This unfortunate state of affairs is due at least in part
to the original language's use of non-ASCII characters.  This package
uses a hybrid chosen to be somewhat: (1) legible, (2) faithful to the
original, and (3) predictable to those familiar with Perl.

=head2 Functions

The following functions are useful in evaluating FP expressions and
handling FP data.

=over

=item C<$str = perl2fp @array>

Convert a Perl list-of-lists (LoL) to a string represeting it in FP.

=item C<@array = fp2perl $str>

Convert an FP value to a Perl LoL.

=item C<fp_eval in =E<gt> \*IFH, out =E<gt> \*OFH>

Evaluate the contents of C<IFH> (C<STDIN> by default), writing the
results to C<OFH> (C<STDOUT> by default).

=item C<$result = fp_eval $string>

Evaluate the FP expression C<$string>, returning the result as a Perl
scalar or reference to a LoL.

=back

In addition, all FP builtin functions (B<not> combining forms) may be
called as Perl functions in list context.  For example, to use
C<distl> in Perl, one could write

  my @result = Language::FP::distl $x, @ys

=head2 Debugging

You will experience unexpected behavior when programming in FP.  Some
of it may even be your fault.  When this occurs, setting the global
variable C<$::FP_DEBUG> to a string containing one or more of the
following characters can help:

=over

=item 'p' -- Trace parsing

=item 'r' -- Trace execution

=item 'b' -- Make FP errors ("bottom") fatal

=item 'C' -- Use the slower, closure-based evaluator.

=back

=head1 EXPORTS

C<Language::FP> exports the C<fp_eval> function by default, for
command-line convenience.

=head1 TODO

Documentation -- a lot more needs to be explained a lot better.

Testing -- getting better, but still needs work.

Maybe make it more "OO" -- not that important.

=head1 BUGS

While calling user-defined Perl functions from FP works as expected,
it is currently not possible to call Perl builtins.

Argument context is a mess in places.

=head1 AUTHOR

Sean O'Rourke, E<lt>seano@cpan.orgE<gt>

Bug reports welcome, patches even more welcome.

=head1 COPYRIGHT

Copyright (C) 2002 Sean O'Rourke.  All rights reserved, some wrongs
reversed.  This module is distributed under the same terms as Perl
itself.  Let me know if you actually find it useful.

=head1 APPENDIX

For further study, here is an implementation of Euler's totient
function, which computes the number of co-primes less than its
argument.  This may be the longest FP program ever written.

  def totient = /+ . @((== . [1, `1] -> `1 ; `0) .
 	(while (> . [2, `0]) (< -> reverse ; id) . [2, -]))
 	. distl . [id, iota]

=cut

# one-liner version of the above, for cut-and-paste:
# def totient = /+ . @((== . [1, `1] -> `1 ; `0) . (while > . [2, `0] (< -> reverse ; id) . [2, -])) . distl . [id, iota]
