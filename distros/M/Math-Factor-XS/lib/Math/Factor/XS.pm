package Math::Factor::XS;

use strict;
use warnings;
use base qw(Exporter);
use boolean qw(true);

use Carp qw(croak);
use List::MoreUtils qw(all);
use Params::Validate ':all';
use Scalar::Util qw(looks_like_number);

our ($VERSION, @EXPORT_OK, %EXPORT_TAGS);
$VERSION = '0.40';
@EXPORT_OK = qw(factors matches prime_factors count_prime_factors);
%EXPORT_TAGS = (all => \@EXPORT_OK);

validation_options(
    on_fail => sub
{
    my ($error) = @_;
    chomp $error;
    croak $error;
});

my $positive_nums = sub
{
    all { looks_like_number($_) && ($_ >= 0) }
      ref $_[0] ? @{$_[0]} : ($_[0]);
};

sub matches
{
    validate_pos(@_,
        { type => SCALAR,
          callbacks => {
            'is a positive number' =>
            $positive_nums,
          },
        },
        { type => ARRAYREF,
          callbacks => {
            'factors are positive numbers' => sub
            {
                my $factors = shift;
                !@$factors or $positive_nums->($factors);
            },
          },
        },
        { type => HASHREF,
          optional => true,
        },
    );
    return xs_matches(@_);
}

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=head1 NAME

Math::Factor::XS - Factorize numbers and calculate matching multiplications

=head1 SYNOPSIS

 use Math::Factor::XS ':all';
 # or
 use Math::Factor::XS qw(factors prime_factors matches);

 $number = 30107;

 @factors = factors($number);
 @primes = prime_factors($number);
 @matches = matches($number, \@factors);

 print "$factors[1]\n";
 print "$number == $matches[0][0] * $matches[0][1]\n";

=head1 DESCRIPTION

C<Math::Factor::XS> factorizes numbers by applying trial divisions.

=head1 FUNCTIONS

=head2 factors

Find all factors (ie. divisors) of a number.

 @factors = factors($number);

The number is factorized and its factors are returned as a list.  For
example,

 @factors = factors(30);
 #  @factors = (2, 3, 5, 6, 10, 15);

=head2 prime_factors

Find prime factors of a number.

 @factors = prime_factors($number);

The number is factorized and its prime factors are returned as a list.
Multiplying the list together gives C<$number>.  For example,

 @primes = prime_factors(90);
 #  @primes = (2, 3, 3, 5);

=head2 count_prime_factors

Return the count of prime factors of a number.  This is the number of values
returned by C<prime_factors()>.

 my $count = count_prime_factors($number);

=head2 matches

Calculates matching multiplications.

 @matches = matches($number, \@factors, { skip_multiples => [0|1] });

The factors will be multiplied against each other and all combinations
that equal the number itself will be returned as a two-dimensional list.
The matches are accessible through the indexes; for example, the first
two numbers that matched the number may be accessed by C<$matches[0][0]>
and C<$matches[0][1]>, the second pair by C<$matches[1][0]> and
C<$matches[1][1]>, and so on.

The hashref provided at the end is optional. If C<skip_multiples>
is set to a true value, then matching multiplications that contain
multiplicated small factors will be discarded. Example:

 11 * 2737 == 30107 # accepted
 77 * 391  == 30107 # discarded

Direct use of C<$Math::Factor::XS::Skip_multiple> does no longer
have an effect as it has been superseded by C<skip_multiples>.

=head1 EXPORT

=head2 Functions

C<factors()>, C<matches()> and C<prime_factors()> are exportable.

=head2 Tags

C<:all - *()>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
