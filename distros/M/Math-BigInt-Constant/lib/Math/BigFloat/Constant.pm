# -*- mode: perl; -*-

package Math::BigFloat::Constant;

use strict;
use warnings;

our $VERSION = '1.13';

use Math::BigFloat '1.999802';
our @ISA = qw( Math::BigFloat );

use overload;                   # inherit from Math::BigFloat

##############################################################################
# We Are a True Math::BigFloat, But Thou Shallst Not Modify Us

sub modify {
    my ($self, $method) = @_;

    unless (defined $method) {
        my @callinfo = caller(0);
        for (my $i = 1 ; ; ++$i) {
            my @next = caller($i);
            last unless @next;
            @callinfo = @next;
        }
        $method = $callinfo[3];
    }

    die("Can not modify ", ref($self), " $self via $method()\n");
}

##############################################################################
# But cloning us creates a modifyable Math::BigInt, so that overload works

sub copy {
    my $x = shift;

    return Math::BigFloat->new($x) unless ref($x);
    Math::BigFloat->copy($x);
}

sub as_int {
    my $x = shift;

    die("Can not modify ", ref($x), " $x via as_int()\n");
}

1;

__END__

=pod

=head1 NAME

Math::BigFloat::Constant - arbitrary sized constant integers

=head1 SYNOPSIS

  use Math::BigFloat::Constant;

  my $class = 'Math::BigFloat::Constant';

  # Constant creation
  $x     = $class->new($str);   # defaults to 0
  $nan   = $class->bnan();      # create a NotANumber
  $zero  = $class->bzero();     # create a "0"
  $one   = $class->bone();      # create a "1"
  $m_one = $class->bone('-');   # create a "-1"

  # Testing
  $x->is_zero();                # return wether arg is zero or not
  $x->is_nan();                 # return wether arg is NaN or not
  $x->is_one();                 # return true if arg is +1
  $x->is_one('-');              # return true if arg is -1
  $x->is_odd();                 # return true if odd, false for even
  $x->is_even();                # return true if even, false for odd
  $x->is_inf($sign);            # return true if argument is +inf or -inf, give
                                # argument ('+' or '-') to match only same sign
  $x->is_pos();                 # return true if arg > 0
  $x->is_neg();                 # return true if arg < 0

  $x->bcmp($y);                 # compare numbers (undef,<0,=0,>0)
  $x->bacmp($y);                # compare absolutely (undef,<0,=0,>0)
  $x->sign();                   # return the sign, one of +,-,+inf,-inf or NaN

  # The following would modify and thus are illegal, e.g. result in a die():

  # set
  $x->bzero();                  # set $x to 0
  $x->bnan();                   # set $x to NaN

  $x->bneg();                   # negation
  $x->babs();                   # absolute value
  $x->bnorm();                  # normalize (no-op)
  $x->bnot();                   # two's complement (bit wise not)
  $x->binc();                   # increment x by 1
  $x->bdec();                   # decrement x by 1

  $x->badd($y);                 # addition (add $y to $x)
  $x->bsub($y);                 # subtraction (subtract $y from $x)
  $x->bmul($y);                 # multiplication (multiply $x by $y)
  $x->bdiv($y);                 # divide, set $x to quotient
                                # return (quo,rem) or quo if scalar

  $x->bmod($y);                 # modulus (x % y)
  $x->bpow($y);                 # power of arguments (x ** y)
  $x->blsft($y);                # left shift
  $x->brsft($y);                # right shift

  $x->band($y);                 # bit-wise and
  $x->bior($y);                 # bit-wise inclusive or
  $x->bxor($y);                 # bit-wise exclusive or
  $x->bnot();                   # bit-wise not (two's complement)

  $x->bnok($k);                 # n over k
  $x->bfac();                   # factorial $x!
  $x->bexp();                   # Euler's number e ** $x

  $x->bsqrt();                  # calculate square-root
  $x->broot($y);                # calculate $y's root
  $x->blog($base);              # calculate integer logarithm

  $x->round($A,$P,$round_mode); # round to accuracy or precision using mode $r
  $x->bround($N);               # accuracy: preserve $N digits
  $x->bfround($N);              # round to $Nth digit, no-op for Math::BigInt objects

  $x->bfloor();                 # return integer less or equal than $x
  $x->bceil();                  # return integer greater or equal than $x
  $x->as_int();                 # return a copy of the object as Math::BigInt
  $x->as_number();              # return a copy of the object as Math::BigInt

  # The following do not modify their arguments, so they are allowed:
  bgcd(@values);                # greatest common divisor
  blcm(@values);                # lowest common multiplicator

  $x->bstr();                   # return normalized string
  $x->bsstr();                  # return string in scientific notation
  $x->length();                 # return number of digits in number
  $x->digit($n);                # extract N'th digit from number

  $x->as_hex();                 # return number as hex string
  $x->as_bin();                 # return number as binary string
  $x->as_oct();                 # return number as octal string

=head1 DESCRIPTION

With this module you can define constant Math::BigFloat objects on a per-object
basis. The usual C<use Math::BigFloat ':constant'> will catch B<all> floating
point constants in the script at compile time, but will not let you create
constant values on the fly, nor work for strings and/or floating point constants
like C<1e5>.

C<Math::BigFloat::Constant> is a true subclass of L<Math::BigFloat> and can
do all the same things - except modifying any of the objects.

=head1 EXAMPLES

Opposed to compile-time checking via C<use constant>:

    use Math::BigFloat;
    use constant X => Math::BigFloat->new("12345678");

    print X," ",X+2,"\n";       # okay
    print "X\n";                # does not print value of X
    X += 2;                     # not okay, dies

these provide runtime checks and can be interpolated into strings:

    use Math::BigFloat::Constant;
    $x = Math::BigFloat::Constant->new("3141592");

    print "$x\n";               # okay
    print $x+2,"\n";            # ditto
    $x += 2;                    # not okay, dies

=head1 METHODS

A C<Math::BigFloat::Constant> object has all the same methods as a
C<Math::BigFloat> object.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-bigint-constant at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-BigInt-Constant>
(requires login).
We will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigFloat::Constant

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/pjacklam/p5-Math-BigInt-Constant>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Dist/Display.html?Name=Math-BigInt-Constant>

=item * MetaCPAN

L<https://metacpan.org/release/Math-BigInt-Constant>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-BigInt-Constant>

=item * CPAN Ratings

L<https://cpanratings.perl.org/dist/Math-BigInt-Constant>

=back

=head1 LICENSE

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Math::BigFloat>, L<Math::BigInt::Constant>.

=head1 AUTHORS

=over 4

=item *

Tels L<http://bloodgate.com/> in early 2001-2007.

=item *

Peter John Acklam E<lt>pjacklam@gmail.comE<gt>, 2016-.

=back

=cut
