package Infix::Custom;

use 5.038;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Infix::Custom', $VERSION);

1;

__END__

=encoding utf8

=head1 NAME

Infix::Custom - custom infix operators

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use utf8;

    # call mode: lower to a sub call
    use Infix::Custom op => '⊕', call => \&add, prec => 'add';
    my $sum = 2 ⊕ 3;             # add(2, 3)  ==  5

    # op mode: lower to a native binary op (no call overhead)
    use Infix::Custom op => '×', binop => '*', prec => 'mul';
    my $area = $w × $h;          # native multiply

    sub add { $_[0] + $_[1] }

=head1 DESCRIPTION

C<Infix::Custom> owns core's single C<PL_infix_plugin> hook and exposes a small
declarative API for adding your own binary infix operators. A declared operator
is parsed at compile time and lowered to an ordinary optree, so there is no
residual runtime cost beyond the work the operator names.

=head2 import options

    use Infix::Custom op => GLYPH, <one lowering mode>, prec => NAME;
    use Infix::Custom GLYPH => \&code, prec => NAME;     # shorthand for call mode

=over 4

=item C<op> => I<string>

The operator glyph (the shorthand passes it as the first argument). Any
byte/UTF-8 sequence core will route to the plugin; it may not contain
whitespace.

=item C<call> => I<CODE ref or sub name>

Call mode. C<LHS op RHS> lowers to C<call(LHS, RHS)>.

=item C<method> => I<bool> (with C<call>)

Method mode. The right-hand side is read as a B<bareword> (an identifier,
captured by a parse stage I<before> C<strict subs> sees it) and passed to
C<call> as a string, so C<LHS op name> lowers to C<call(LHS, "name")>. This is
what makes a safe-navigation operator read naturally:

    sub nav { my ($o, $m) = @_; defined $o ? $o->$m : undef }
    use Infix::Custom op => '?->', call => \&nav, method => 1, prec => 'mul';

    my $n = $obj ?-> child ?-> name // 'default';   # under strict, no quotes

The bareword must be a plain method name with no argument list; for arguments,
fall back to call mode with a CODE ref (C<$obj ?-E<gt> sub { $_[0]-E<gt>m(@a) }>).

=item C<binop> => I<symbol>

Op mode. C<LHS op RHS> lowers to a native binary op, with no sub-call overhead.
One of C<+ - * / % ** . x | & ^ E<lt>E<lt> E<gt>E<gt>>.

=item C<build_op> => I<integer>

Escape hatch for XS authors (see L</"C-LEVEL build_op">).

=item C<prec> => I<name>

One of C<low>, C<logical_or_low>, C<logical_and_low>, C<assign>, C<logical_or>,
C<logical_and>, C<rel>, C<add>, C<mul>, C<pow>, C<high> (mirroring core's
C<INFIX_PREC_*> ladder). Defaults to C<low>.

B<Associativity follows the precedence tier> — core's infix-plugin API ties the
two together, so there is no separate C<assoc> option. C<add>, C<mul>,
C<logical_or>, C<logical_and> (and the C<*_low> pair) are left-associative;
C<assign> and C<pow> are right-associative; C<low>, C<rel> and C<high> are
non-associative.

=back

=head2 Lexical scope

A declared operator is active only in the lexical scope that imported it (it is
recorded in C<%^H>) and is restored on scope exit. The same glyph can be rebound
to a different meaning in a nested scope. Used outside any declaring scope, the
glyph is an ordinary unknown-operator parse error. C<no Infix::Custom GLYPH;>
removes an operator earlier; C<no Infix::Custom;> removes all of them.

=head2 C-LEVEL build_op

For operators that should lower to a custom optree rather than a sub call or a
native binop, an XS author can supply their own C<build_op> with the core
signature

    OP *build_op(pTHX_ SV **opdata, OP *lhs, OP *rhs, struct Perl_custom_infix *);

and pass its address (as an integer, e.g. via C<PTR2IV>) as C<build_op>:

    use Infix::Custom op => '×', build_op => $addr, prec => 'mul';

The pointer is called at compile time with the parsed operands and must return
the combined optree. This is a deliberately low-level hatch; the call and binop
modes cover everything reachable from pure Perl.

=head2 Perl version requirement

B<Requires perl 5.38 or newer.> The C<PL_infix_plugin> hook that makes ambient
infix operators possible was added to core in 5.38; there is no way to parse a
custom operator mid-expression before then, so the distribution does not install
on older perls.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
