# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::Expression;

use strict;
use warnings;

require Exporter;

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(not3 and3 or3 xor3 eqv3 bool3 val3);
our %EXPORT_TAGS = ('all' => \@EXPORT_OK);
our $VERSION     = '0.004';

# ----- object definition -----

# Math::Logic::Ternary::Expression=ARRAY(...)

# M::L::T::Expression          ARRAY
# +----------+---------+       +----------+----------+
# | VALUEREF |    o----------->| VALUE    | anything |
# +----------+---------+       +----------+----------+
# | NEGATED  | boolean |       | DEFERRED | boolean  |
# +----------+---------+       +----------+----------+

# .......... index ..........   # .............. value ..............
use constant VALUEREF => 0;     # ref of lazily accessible value
use constant NEGATED  => 1;     # boolean

# lazily accessible value: ARRAY(...)

# .......... index ..........   # .............. value ..............
use constant VALUE    => 0;     # coderef while deferred, then value
use constant DEFERRED => 1;     # boolean

my $undef = bless [[undef, ''], ''];

# turn any value into an MLTE object
sub _object {
    my ($this) = @_;
    return $undef if !defined $this;
    return $this  if __PACKAGE__ eq ref $this;
    return bless [[$this, 'CODE' eq ref $this], ''];
}

# get the actual value from an MLTE object
sub _evaluate {
    my ($this) = @_;
    my $vr = $this->[VALUEREF];
    my $v  = $vr->[VALUE];
    my $n  = $this->[NEGATED];
    if ($vr->[DEFERRED]) {
        $vr->[DEFERRED] = '';
        $v = $vr->[VALUE] = $v->();
        if (!defined $v) {
            $n = $this->[NEGATED] = '';
        }
    }
    # die "assertion failed" unless defined($v) || !$n;
    return $n? !$v: $v;
}

# get the actual value from anything
sub val3 {
    my ($this) = @_;
    return $this if !defined($this) || __PACKAGE__ ne ref $this;
    return _evaluate($this);
}

# replace actual value by a truth value
sub bool3 {
    my ($this) = @_;
    my $val = _evaluate(_object($this));
    return $undef if !defined $val;
    return bless [[!!$val, ''], ''];
}

# negate without evaluating
sub not3 {
    my ($this) = @_;
    return $undef if !defined $this;
    if (__PACKAGE__ eq ref $this) {
        my $vr = $this->[VALUEREF];
        return $undef if !($vr->[DEFERRED] || defined $vr->[VALUE]);
        return bless [$vr, !$this->[NEGATED]];
    }
    return bless [[$this, 'CODE' eq ref $this], 1];
}

# a && b:    tt => b, tf => b, ft => a, ff => a
sub and3 {
    my ($this, $that) = @_;
    my $obj = _object($this);
    my $val = _evaluate($obj);
    return $obj if defined($val) && !$val;      # false, * => LHS
    $obj = _object($that);
    return $obj if $val;                        # true, * => RHS
    $val = _evaluate($obj);
    return $obj if defined($val) && !$val;      # undef, false => RHS
    return $undef;                              # else => undef
}

# a || b:    tt => a, tf => a, ft => b, ff => b
sub or3 {
    my ($this, $that) = @_;
    my $obj = _object($this);
    my $val = _evaluate($obj);
    return $obj if $val;                        # true, * => LHS
    $obj = _object($that);
    return $obj if defined $val;                # false, * => RHS
    $val = _evaluate($obj);
    return $obj if $val;                        # undef, true => RHS
    return $undef;                              # else => undef
}

# a? !b: b                 tt => !b, tf => !b, ft => b, ff => b
# !a && b || !b && a       tt => !b, tf => a,  ft => b, ff => a
# !b && a || !a && b       tt => !a, tf => a,  ft => b, ff => b
# !(a && b) && (a || b)    tt => !b, tf => a,  ft => b, ff => b   (implemented)

sub xor3 {
    my ($this, $that) = @_;
    my $obj1 = _object($this);
    my $val = _evaluate($obj1);
    return $undef if !defined $val;             # undef, * => undef
    my $obj2 = _object($that);
    return $obj2 if !$val;                      # false, * => RHS
    $val = _evaluate($obj2);
    return $undef if !defined $val;             # true, undef => undef
    return $obj1 if !$val;                      # true, false => LHS
    return not3($obj2);                         # true, true => not RHS
}

# !(a || b) || (a && b)         tt => b, tf => b, ft => a, ff => !b

sub eqv3 {
    my ($this, $that) = @_;
    my $obj1 = _object($this);
    my $val = _evaluate($obj1);
    return $undef if !defined $val;             # undef, * => undef
    my $obj2 = _object($that);
    return $obj2 if $val;                       # true, * => RHS
    $val = _evaluate($obj2);
    return $undef if !defined $val;             # false, undef => undef
    return $obj1 if $val;                       # false, true => LHS
    return not3($obj2);                         # false, false => not RHS
}

1;
__END__

=head1 NAME

Math::Logic::Ternary::Expression - ternary logic on native perl expressions

=head1 VERSION

This documentation refers to version 0.004 of Math::Logic::Ternary::Expression.

=head1 SYNOPSIS

  use Math::Logic::Ternary::Expression qw(:all);

  $foo = not3( $bar);
  $foo = and3( $bar, sub { $baz });
  $foo = or3(  $bar, sub { $baz });
  $foo = xor3( $bar, sub { $baz });
  $foo = eqv3( $bar, sub { $baz });
  $foo = bool3($bar);

  $val = val3($foo);

=head1 DESCRIPTION

This module provides ternary logic operations on native perl expressions.
Ternary truth values are B<1> (or anything evaluating in Perl as
true, except unblessed code references), the empty string (or anything
evaluating in Perl as false but defined), and B<undef>.

As in Perl built-in logic, result values in general represent the
value of the last operand evaluated, not just plain boolean values.
By way of some additional magic, negated terms recover their original
value when they are negated once more.  To discard any information
but the truth value, use I<bool3> rather than double negation.

To make short-cut expression evaluation possible, operands can be
wrapped in code references, which will lazily be evaluated as late
as possible (if at all).  If you do want to treat an unblessed code
reference as true, wrap it in one additional code reference before
using it as a ternary logical operand.

All subroutines except I<val3> return an expression object and
accept arbitrary Perl scalars as well as expression objects as
arguments.  The actual value for use outside of ternary logical
expressions is returned by I<val3>.

Expression objects can be stored in variables and be used more than
once, acting as common subexpressions.  Code reference wrappers
will be executed at most once, even then.

=head2 Unary Operators

=over 4

=item B<val3>

This operator recovers an ordinary Perl scalar from an expression
object returned by any of the other operators.  If the operand is
not an expression object, it is returned itself.

=item B<not3>

     A   | val3(not3(A)) | val3(not3(not3(A)))
  -------+---------------+---------------------
   true  | not A         |   A
   false | not A         |   A
   undef | undef         | undef

=item B<bool3>

     A   | val3(bool3(A))
  -------+----------------
   true  |   1
   false |   ''
   undef | undef

=back

=head2 Binary Operators

=over 4

=item B<and3>

     A   |   B   | val3(and3(A, B))
  -------+-------+------------------
   true  | true  |   B
   true  | false |   B
   true  | undef | undef
   false | true  |   A
   false | false |   A
   false | undef |   A
   undef | true  | undef
   undef | false |   B
   undef | undef | undef

=item B<or3>

     A   |   B   | val3(or3(A, B))
  -------+-------+-----------------
   true  | true  |   A
   true  | false |   A
   true  | undef |   A
   false | true  |   B
   false | false |   B
   false | undef | undef
   undef | true  |   B
   undef | false | undef
   undef | undef | undef

=item B<xor3>

Unlike perl-builtin xor, xor3 is implemented with short-cut behaviour
and value preservation.  The second operand will only be evaluated
if the first one is defined.  If one operand is true and the other
operand is false, the true operand will be the result.  Exclusive-or
is defined based on other operators like this:

A I<xor> B := !(A I<and> B) I<and> (A I<or> B)

     A   |   B   | val3(xor3(A, B))
  -------+-------+------------------
   true  | true  | not B
   true  | false |   A
   true  | undef | undef
   false | true  |   B
   false | false |   B
   false | undef | undef
   undef | true  | undef
   undef | false | undef
   undef | undef | undef

=item B<eqv3>

Ternary logical equivalence eqv3 is defined very similar to xor3,
swapping I<and> and I<or>:

A I<eqv> B := !(A I<or> B) I<or> (A I<and> B)

     A   |   B   | val3(eqv3(A, B))
  -------+-------+------------------
   true  | true  |   B
   true  | false |   B
   true  | undef | undef
   false | true  |   A
   false | false | not B
   false | undef | undef
   undef | true  | undef
   undef | false | undef
   undef | undef | undef

=back

=head2 EXPORT

By default, nothing is exported.  Subroutine names can be imported
individually or via the I<:all> tag.

=head1 SEE ALSO

L<Math::Logic::Ternary>

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mpE<64>cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2017 by Martin Becker, Blaubeuren.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
