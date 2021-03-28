package Math::ModInt;

use 5.006;
use strict;
use warnings;
use Math::ModInt::Event
    qw(UsageError Nonexistent LoadingFailure UndefinedResult DifferentModuli);

sub _no_op {
    my ($op) = @_;
    return $op => sub { UsageError->raise('undefined operation', $op) };
}

use overload (
    'neg'      => '_NEG',
    '+'        => \&_oadd,
    '-'        => \&_osub,
    '*'        => \&_omul,
    '/'        => \&_odiv,
    '**'       => \&_opow,
    '=='       => \&_oeq,
    '!='       => \&_oneq,
    '!'        => 'is_zero',
    'bool'     => 'is_not_zero',
    '0+'       => 'residue',
    '""'       => 'as_string',
    'fallback' => undef,
    _no_op('abs'),
    _no_op('int'),
);

# ----- class data -----

BEGIN {
    require Exporter;
    our @ISA       = qw(Exporter);
    our @EXPORT_OK = qw(mod divmod qmod);
    our @CARP_NOT  = qw(Math::ModInt::ChineseRemainder);
    our $VERSION   = '0.013';
}

sub _max_modulus_perl {
    my $limit = 32767;
    foreach my $bits (16..96) {
        my $probe = $limit + $limit + 1;
        last if 0.5 != $probe / 2 - ($probe ^ 1) / 2;
        $limit = $probe;
    }
    return int sqrt $limit;
}

use constant _MAX_MODULUS_PERL => _max_modulus_perl();

my $undefined = bless [];                       # singleton
my %loaded = ();                                # collects loaded modules

# ----- private subroutines -----

sub _is_integer {
    my ($arg) = @_;
    local $@;
    return
        eval {
            use warnings FATAL => 'all';
            ref $arg?
                $arg->isa('Math::BigInt')
            :
                $arg == int($arg) && abs($arg) <= ~0
        };
}

sub _incompatible {
    my ($this, $that) = @_;
    if ($this->is_defined && $that->is_defined) {
        DifferentModuli->raise($this, $that);
    }
    return $undefined;
}

sub _best_class {
    my ($modulus) = @_;
    if (_is_integer($modulus)) {
        return 'Math::ModInt::BigInt'  if $modulus >  _MAX_MODULUS_PERL;
        return 'Math::ModInt::Perl'    if $modulus >  3;
        return 'Math::ModInt::GF3'     if $modulus == 3;
        return 'Math::ModInt::GF2'     if $modulus == 2;
        return 'Math::ModInt::Trivial' if $modulus == 1;
    }
    UsageError->raise('positive integer modulus expected');
}

sub _load {
    my ($class) = @_;
    do {
        local $@;
        $loaded{$class} ||= eval "require $class"
    }
    or LoadingFailure->raise($class);
    return $class;
}

sub _oadd {
    my ($this, $that) = @_;
    if (!ref $that || !$that->isa(__PACKAGE__)) {
        $that = $this->_NEW($that);
    }
    elsif ($this->modulus != $that->modulus) {
        return _incompatible($this, $that);
    }
    return $this->_ADD($that);
}

sub _osub {
    my ($this, $that, $reversed) = @_;
    if (!ref $that || !$that->isa(__PACKAGE__)) {
        $that = $this->_NEW($that);
    }
    elsif ($this->modulus != $that->modulus) {
        return _incompatible($this, $that);
    }
    return $reversed? $that->_SUB($this): $this->_SUB($that);
}

sub _omul {
    my ($this, $that) = @_;
    if (!ref $that || !$that->isa(__PACKAGE__)) {
        $that = $this->_NEW($that);
    }
    elsif ($this->modulus != $that->modulus) {
        return _incompatible($this, $that);
    }
    return $this->_MUL($that);
}

sub _odiv {
    my ($this, $that, $reversed) = @_;
    if (!ref $that || !$that->isa(__PACKAGE__)) {
        $that = $this->_NEW($that);
    }
    elsif ($this->modulus != $that->modulus) {
        return _incompatible($this, $that);
    }
    return $reversed? $that->_DIV($this): $this->_DIV($that);
}

sub _opow {
    my ($this, $exp, $reversed) = @_;
    # exponent should be in perl integer range or be a big int
    if ($reversed || !_is_integer($exp)) {
        UsageError->raise('integer exponent expected');
    }
    return $this->_POW($exp);
}

sub _oeq {
    my ($this, $that) = @_;
    # note that comparing with $undefined is illegal
    if (!ref $that || !$that->isa(__PACKAGE__)) {
        return $this->residue == $that % $this->modulus;
    }
    return
        $this->residue == $that->residue &&
        $this->modulus == $that->modulus;
}

sub _oneq {
    my ($this, $that) = @_;
    # note that comparing with $undefined is illegal
    if (!ref $that || !$that->isa(__PACKAGE__)) {
        return $this->residue != $that % $this->modulus;
    }
    return
        $this->residue != $that->residue ||
        $this->modulus != $that->modulus;
}

# ----- fallback for implementation interface method -----

sub _NEW2 {
    my ($this, $int, $modulus) = @_;
    my $that;
    if (ref $this) {
        $that = $this->_NEW($int);
        $modulus = $this->modulus;
    }
    else {
        $that = $this->_NEW($int, $modulus);
    }
    my $quot = ($int - $that->residue) / $modulus;
    return ($quot, $that);
}

# ----- public methods -----

# constructors

sub mod {
    my ($int, $modulus) = @_;
    my $class = _load(_best_class($modulus));
    return $class->_NEW($int, $modulus);
}

sub divmod {
    my ($int, $modulus) = @_;
    my $class = _load(_best_class($modulus));
    return $class->_NEW2($int, $modulus);
}

sub qmod {
    my ($rat, $modulus) = @_;
    my $class = _load(_best_class($modulus));
    my $num   = $class->_NEW($rat->numerator, $modulus);
    my $den   = $num->_NEW($rat->denominator);
    return $num / $den;
}

sub new {
    my ($this, $int, $modulus) = @_;
    return $this->_NEW($int) if ref $this;
    return mod($int, $modulus);
}

sub new2 {
    my ($this, $int, $modulus) = @_;
    return $this->_NEW2($int) if ref $this;
    return divmod($int, $modulus);
}

sub undefined {
    UndefinedResult->raise;
    return $undefined;
}

# accessors

sub residue {
    Nonexistent->raise('undefined residue');
}

sub modulus {
    return 0 if __PACKAGE__ eq (caller)[0];     # special case for _oadd etc.
    Nonexistent->raise('undefined modulus');
}

sub signed_residue {
    my ($this) = @_;
    my $r = $this->residue;
    my $m = $this->modulus;
    my $n = $m - $r;
    return $n <= $r? -$n: $r;
}

sub centered_residue {
    my ($this) = @_;
    my $r = $this->residue;
    my $m = $this->modulus;
    my $n = $m - $r;
    return $n < $r? -$n: $r;
}

sub is_defined {
    my ($this) = @_;
    return ref $undefined ne ref $this;
}

sub is_undefined {
    my ($this) = @_;
    return ref $undefined eq ref $this;
}

sub is_zero {
    my ($this) = @_;
    return 0 == $this->residue;
}

sub is_not_zero {
    my ($this) = @_;
    return 0 != $this->residue;
}

sub as_string {
    my ($this) = @_;
    my ($r, $mod) =
        $this->is_defined? ($this->residue, $this->modulus): qw(? ?);
    return "mod($r, $mod)";
}

# operators

sub inverse  { $_[0]->_INV }

BEGIN {
    foreach my $method (qw(
        _NEW _NEG _INV _ADD _SUB _MUL _DIV _POW
    )) {
        no strict 'refs';
        *{$method} = sub { $undefined };
    }
}

# miscellaneous

sub optimize_time    { $_[0] }
sub optimize_space   { $_[0] }
sub optimize_default { $_[0] }

1;

__END__

=head1 NAME

Math::ModInt - modular integer arithmetic

=head1 VERSION

This documentation refers to version 0.013 of Math::ModInt.

=head1 SYNOPSIS

  use Math::ModInt qw(mod divmod qmod);

  $a = mod(32, 127);            #  32 (mod 127)
  $b = $a->new(99);             #  99 (mod 127)
  $c = $a + $b;                 #   4 (mod 127)
  $d = $a**2 - $b/$a;           # 120 (mod 127)
  ($i, $e) = divmod(32, 5);     #  6, mod(2, 5)

  $m = $d->modulus;             # 127
  $r = $d->residue;             # 120
  $s = $d->signed_residue;      #  -7
  $t = "$a";                    # 'mod(32, 127)'

  use Math::BigRat;

  $q = Math::BigRat->new('2/3');
  $f = qmod($q, 5);             #   4 (mod 5)

=head1 DESCRIPTION

Math::ModInt provides overloaded operators for modular integer
arithmetic.  Math::ModInt objects represent integer residue classes.
These objects can be used in arithmetic expressions just like Perl
numbers.  Math::ModInt objects are immutable.  Mutators like C<+=>
will replace an object rather than change its state.

In mixed expressions with Math::ModInt objects and ordinary numbers
the numbers are interpreted as their residue class modulo the modulus
of the rest of the expression.  Different moduli must not be mixed,
though.

There are different implementations, optimized for moduli of a
particular size or using a particular math library.  The base module
will transparently choose a suitable back-end whenever a constructor
is called.

=head2 Application Interface

=head3 Constructors

=over 4

=item I<new>

Called as a class method, C<Math::ModInt-E<gt>new($int, $modulus)>
creates a new object of a subclass appropriate for the given modulus
and current platform.  The modulus must be a positive integer value.

Called as an object method, C<$x-E<gt>new($int)> creates a new
object sharing both its type and modulus with the invocant object
C<$x>.

=item I<new2>

The constructor method C<new2> is called exactly like C<new> but
it returns two values: an integer division result and a modular
integer object.

=item I<mod>

For convenience, C<mod> can be imported as an abbreviation for the
class method constructor; C<mod($int, $modulus)> is equivalent
to C<Math::ModInt-E<gt>new($int, $modulus)>.  Note that C<mod>
has to be called as a plain function, not like a method.

=item I<divmod>

The C<divmod> function can be imported, too.  It takes two integers
like C<mod> but it returns two values: an integer division result
and a modular integer object.  Thus C<divmod($int, $modulus)> is
equivalent to C<Math::ModInt-E<gt>new2($int, $modulus)>.

=item I<qmod>

Another importable constructor function is C<qmod>.  It can convert
rational numbers to modular integers of a given modulus if the
denominator is coprime to that modulus.
The expression C<qmod($rat, $modulus)> is equivalent to
C<mod($rat-E<gt>numerator, $modulus) / mod($rat-E<gt>denominator, $modulus)>.
Note that C<$rat> must be an object with C<numerator> and C<denominator>
methods, like e.g. an instance of Math::BigRat.

Note also that mixed expressions with modular integers and rational
numbers are not permitted.  Always convert rational numbers explicitly
with C<qmod>.

=item I<undefined>

This method returns the C<undefined> placeholder object representing
undefined results in the domain of modular integer arithmetic, such
as from division by an operand not coprime to the modulus.  See
L<Math::ModInt::Event> for how to control whether this object or
other ways to report arithmetic faults should be employed.

=back

=head3 Operators

=over 4

=item C<+ - * / ** == !=>

Addition, negation, subtraction, multiplication, division,
exponentiation with integer exponents, and equivalence operators
are provided through overloaded perl operators.  Division or
exponentiation with negative exponents may trigger an C<UndefinedResult>
event and yield an C<undefined> result.

Operands must either have the same modulus or be plain integers,
except for equality/inequality checks.  Operands with different
moduli may be compared and are considered unequal.

For other exceptions to the requirement of identical moduli, see
L<Math::ModInt::ChineseRemainder>.

Note that neither the modulo operator C<%> nor bit-operations
C<E<amp> | ^ E<lt>E<lt> E<gt>E<gt>> nor order relations
C<E<lt> E<lt>= E<gt> E<gt>= E<lt>=E<gt>> are defined.

=item I<inverse>

The object method C<$x-E<gt>inverse> returns the multiplicative
modular inverse of C<$x>, if it exists, otherwise the C<undefined>
placeholder.  (I<y> is the modular inverse of I<x> modulo I<m> if
I<x * y> is equivalent to I<1> modulo I<m>.)

=back

=head3 Accessors

=over 4

=item I<is_defined>

=item I<is_undefined>

The object methods C<$x-E<gt>is_defined> and C<$x-E<gt>is_undefined>
return boolean values checking whether C<$x> is a proper residue
class object or the C<undefined> placeholder.  Besides C<as_string>,
these are the only legal accessors for the C<undefined> placeholder.

=item I<modulus>

The object method C<$x-E<gt>modulus> returns the modulus of the
residue class the object represents.

=item I<residue>

The object method C<$x-E<gt>residue> returns the normalized residue
of the residue class the object represents.  Its value is chosen
as if it was a division remainder, i.e. between zero (inclusive)
and the modulus (exclusive).

=item I<signed_residue>

The object method C<$x-E<gt>signed_residue> returns a representative
of the residue class the object represents, chosen as close to zero
as possible.  In case of a tie, i.e. when the modulus is an even
number and the residue is half the modulus, the negative value is
given preference (like in many native signed integer formats).

=item I<centered_residue>

The object method C<$x-E<gt>centered_residue> is equivalent to
C<$x-E<gt>signed_residue> except that the positive value is given
preference when the residue is precisely half the modulus.

=item I<is_zero>

=item I<is_not_zero>

The object methods C<$x-E<gt>is_zero> and C<$x-E<gt>is_not_zero>
return boolean values checking whether C<$x> is the zero element
of its ring, i.e. C<0 == $x-E<gt>residue>).  Either one of these
methods can be called implicitly when a Math::ModInt object is being
used in boolean context.

=item I<as_string>

The object method C<$x-E<gt>as_string> returns a string representation
of C<$x>.  It will be in the form C<mod(residue, modulus)> (similar
to the constructor) in case of proper residue classes, or C<mod(?, ?)>
in case of the C<undefined> placeholder.

=back

=head3 Miscellaneous methods

=over 4

=item I<optimize_time>

Some implementations can employ different optimization strategies
for either time or space efficiency.  Time efficiency aims to speed
up repetitive calculations at the expense of memory space.  Space
efficiency aims to minimize the memory footprint at the expense of
cpu cycles.  Where such a distinction is available, separate choices
can be made for each modulus.

The object method C<$x-E<gt>optimize_time> gives a hint to the
implementation of C<$x> to prefer time over space efficiency for
the modulus of C<$x>.  It returns the object it was called with.

=item I<optimize_space>

The object method C<$x-E<gt>optimize_space> gives a hint to the
implementation of C<$x> to prefer space over time efficiency for
the modulus of C<$x>.  It returns the object it was called with.

=item I<optimize_default>

The object method C<$x-E<gt>optimize_default> restores the default
behaviour of the implementation of C<$x> with respect to its
optimization strategy for the modulus of C<$x>.  It returns the
object it was called with.  Defaults may depend on the modulus and
may or may not be equivalent to one of the other strategy choices.
They should, however, be reasonably secure to use on small systems,
and thus lean more to space than time efficiency.

=back

=head2 Implementation Interface

Math::ModInt offers a special interface for implementations, intended
to simplify operator overloading.  Implementations are subclasses
overriding only a couple of methods, as listed below.  The I<overload>
pragma should not explicitly be used in implementations adhering
to this interface.

Implementations handle a restricted set of moduli, sometimes only
one.  Currently, these restrictions are known in the base module
and hard-coded there.  Future revisions of Math::ModInt may offer
a registration mechanism with precedences to make platform-specific
choices possible.

=head3 Mandatory Methods

=over 4

=item I<residue>

This method should return the normalized residue as defined in the
application interface.

=item I<modulus>

This method should return the modulus as defined in the application
interface.

=item I<_NEW>

This constructor will be called either as a class method with two
parameters I<residue> and I<modulus>, or as an object method with
just one parameter I<residue>.  It should return a new object with
the given residue and modulus in the former case, or the given
residue and the modulus of the invocant object in the latter case.

Note that the constructors I<mod> and I<new> of the application
interface should not be overridden, as they need to switch
implementations, depending on parameters rather than the package
they are called from.

=item I<_NEG>

C<$x-E<gt>_NEG> should return a new object representing C<-$x>.

=item I<_INV>

C<$x-E<gt>_INV> should return a new object representing the modular
inverse of C<$x>, if it exists, otherwise C<Math::ModInt-E<gt>undefined>.

=item I<_ADD>

C<$x-E<gt>_ADD($y)> should return a new object representing C<$x+$y>.
The parameter C<$y> will always be an object of the same class and
have the same modulus as C<$x>.

=item I<_SUB>

C<$x-E<gt>_SUB($y)> should return a new object representing C<$x-$y>.
The parameter C<$y> will always be an object of the same class and
have the same modulus as C<$x>.

=item I<_MUL>

C<$x-E<gt>_MUL($y)> should return a new object representing C<$x*$y>.
The parameter C<$y> will always be an object of the same class and
have the same modulus as C<$x>.

=item I<_DIV>

C<$x-E<gt>_DIV($y)> should return a new object representing C<$x/$y>
if it exists, otherwise C<Math::ModInt-E<gt>undefined>.  The parameter
C<$y> will always be an object of the same class and have the same
modulus as C<$x>.

=item I<_POW>

C<$x-E<gt>_POW($y)> should return a new object representing C<$x ** $y>
if it exists, otherwise C<Math::ModInt-E<gt>undefined>.  The exponent
C<$y> will always be an integer number.  An undefined result means
that the exponent was negative while C<$x> had no modular inverse.

=back

=head3 Optional Methods

=over 4

=item I<_NEW2>

This constructor method will be called like C<_NEW> but it must
return two values: an integer division result and the newly created
modular integer object.  It should be implemented if the underlying
library offers an efficient way to calculate a quotient and remainder
simultaneously.

=item I<optimize_time>

=item I<optimize_space>

=item I<optimize_default>

These methods give hints for the optimization strategy for a
particular modulus, as described in the application interface above.
They do not need to be implemented.

=back

=head1 DIAGNOSTICS

Some operations are not defined for all operands.  For instance,
division only makes sense if the denominator residue is coprime
to the modulus.  Operands with different moduli generally can not
be combined in binary operations.

By default, operations with incompatible operands or undefined
results consistently yield the Math::ModInt->undefined object, which
will raise an exception upon modulus/residue inspection, but can
be recognized by the boolean result of the is_defined/is_undefined
methods.  See L<Math::ModInt::Event> for ways to alter this behaviour.

=head1 DEPENDENCIES

This module uses Math::BigInt for arbitrary-precision calculations.
If you want control over which Math::BigInt backend is to be used,
import Math::BigInt before Math::ModInt, like this:

  use Math::BigInt try => 'GMP,Pari';
  use Math::ModInt qw(mod);

The minimal required perl version is 5.6.

=head1 BUGS AND LIMITATIONS

Math::BigInt version 1.99 can not be used together with this module,
as the former has a severe bug with modular integer arithmetic which
is detected in our test suite.  Math::BigInt version 1.991 has this
issue resolved.

A little bit of effort has been put into making this module suite
reasonably efficient even in the absence of convenient big integer
libraries.  For best performance, though, we recommend installing
a fast integer library such as Math::BigInt::GMP together with
Math::ModInt.

Currently, the choice of Math::ModInt backend is hard-wired into
the main module, for the sake of simplicity.  Please contact the
maintainer if you intend to use a backend not from this distribution,
so that something clever can be done about it.

Math::ModInt has settled down a bit after a decade of beta testing.
The interface may now be considered stable and new features will
not intentionally break or remove existing ones from this point.

Bug reports and suggestions are always welcome.
Please submit them through the github issue tracker,
L<https://github.com/mhasch/perl-Math-ModInt/issues> .

More information for potential contributors can be found in the file
named F<CONTRIBUTING> in this distribution.

=head1 SEE ALSO

=over 4

=item *

L<Math::ModInt::Event>

=item *

L<Math::ModInt::ChineseRemainder>

=item *

L<Math::BigInt>

=item *

L<perlnumber>

=item *

L<overload>

=item *

L<perlop>

=item *

The subject "modular arithmetic" on Wikipedia.
L<http://en.wikipedia.org/wiki/Modular_arithmetic>

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 ACKNOWLEDGEMENTS

Thanks go to Ilya Zakharevich for the I<overload> package, and for
mentioning this package ages before it was actually written, in
perlnumber.pod.  I also appreciate the role of cpantesters.org in
quality assurance for CPAN.

If you find something cool you can do with Math::ModInt you like
to share with others, you are welcome to submit your code for the
examples section, as well as your name or chosen identity for the
hall of fame.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2021 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
