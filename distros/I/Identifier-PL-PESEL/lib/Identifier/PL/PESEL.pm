package Identifier::PL::PESEL;

use strict;
use warnings;

use Carp;

=head1 NAME

Identifier::PL::PESEL - Validator for polish PESEL number.

=head1 VERSION

Version 0.2

=cut

our $VERSION = '0.2';

=head1 SYNOPSIS

    use Identifier::PL::PESEL;

    my $pesel_number = '02070803628';
    my $psl = Identifier::PL::PESEL->new();
    print "OK" if $psl->validate( $pesel_number );

=head1 DESCRIPTION

More informations about PESEL L<https://en.wikipedia.org/wiki/PESEL>

=head1 METHODS

=head2 new

Create new object of C<Identifier::PL::PESEL>

=cut

sub new {
    return bless {}, $_[0];
}

=head2 validate

Validate given PESEL number.

Return 1 if number is valid.
Otherwise return undef.

C<Carp::confess> will be called if number to validate is missing.

=cut

sub validate {
    my ( $self, $pesel ) = @_;

    confess 'Missing pesel parameter' unless defined $pesel;

    return unless $pesel =~ /^\d{11}$/;

    my @p = split '', $pesel;

    my $check_sum = pop @p;

    my @weight = (1,3,7,9,1,3,7,9,1,3);

    my $new_check_sum = 0;

    $new_check_sum += $_ * shift @weight for @p;
    $new_check_sum %= 10;
    $new_check_sum = 10 - $new_check_sum;

    return 1 if $check_sum == $new_check_sum;

    return;
}

=head1 AUTHOR

Andrzej Cholewiusz

Private website: L<http://cholewiusz.com>

=head1 COPYRIGHT

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
