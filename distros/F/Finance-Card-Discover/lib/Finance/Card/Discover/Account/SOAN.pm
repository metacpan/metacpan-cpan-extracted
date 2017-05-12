package Finance::Card::Discover::Account::SOAN;

use strict;
use warnings;

use DateTime::Tiny;
use Object::Tiny qw(account cid expiration number);

sub new {
    my ($class, $data, %params) = @_;

    return bless {
        account    => $params{account},
        cid        => $data->{cvv},
        expiration => DateTime::Tiny->new(
            year  => $data->{expiryyear},
            month => $data->{expirymonth}
        ),
        number => $data->{pan},
    }, $class;
}


1;

__END__

=head1 NAME

Finance::Card::Discover::Account::SOAN

=head1 DESCRIPTION

This module provides a class representing a Secure Online Access Number
(SOAN) for an account.

=head1 ACCESSORS

=over

=item * account

The associated L<Finance::Card::Discover::Account> object.

=item * account

=item * cid

=item * expiration

=item * number

=back

=cut
