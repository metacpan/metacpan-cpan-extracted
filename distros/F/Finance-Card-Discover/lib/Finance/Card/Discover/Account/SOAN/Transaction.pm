package Finance::Card::Discover::Account::SOAN::Transaction;

use strict;
use warnings;

use DateTime::Tiny;
use Object::Tiny qw(
    account amount authcode city date expiration merchant reference soan
    state
);

sub new {
    my ($class, $data, $num, %params) = @_;

    my $date = do {
        my ($month, $day, $year) = split '/', $data->{"date${num}"}, 3;
        $year += 2000 if 2000 > $year;
        DateTime::Tiny->new(year => $year, month => $month, day => $day);
    };
    my $expiration = do {
        my ($year, $month) = split '/', $data->{"ocodeexpires${num}"}, 2;
        $year += 2000 if 2000 > $year;
        DateTime::Tiny->new(year => $year, month => $month);
    };

    return bless {
        account    => $params{account},
        amount     => $data->{"amount${num}"},
        authcode   => $data->{"authcode${num}"},
        city       => $data->{"city${num}"},
        date       => $date,
        expiration => $expiration,
        merchant   => $data->{"merchantname${num}"},
        soan       => $data->{"ocode${num}"},
        reference  => $data->{"refnumber${num}"},
        state      => $data->{"state${num}"},
    }, $class;
}


1;

__END__

=head1 NAME

Finance::Card::Discover::Account::SOAN::Transaction

=head1 DESCRIPTION

This module provides a class representing a single transaction for a SOAN.

=head1 ACCESSORS

=over

=item * account

The associated L<Finance::Card::Discover::Account> object.

=item * amount

=item * authcode

=item * city

City or phone number or website.

=item * date

Date of the transaction, as a L<DateTime::Tiny> object.

=item * expiration

Expiration of the SOAN, as a L<DateTime::Tiny> object.

=item * merchant

Name of the merchant.

=item * soan

The number of the SOAN account.

=item * reference

Reference code.

=item * state

=back

=cut
