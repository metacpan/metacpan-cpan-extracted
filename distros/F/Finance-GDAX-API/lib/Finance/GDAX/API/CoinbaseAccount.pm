package Finance::GDAX::API::CoinbaseAccount;
our $VERSION = '0.01';
use 5.20.0;
use warnings;
use Moose;
use Finance::GDAX::API;
use namespace::autoclean;

extends 'Finance::GDAX::API';

sub get {
    my $self = shift;
    $self->method('GET');
    $self->path('/coinbase-accounts');
    return $self->send;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Finance::GDAX::API::CoinbaseAccount - List Coinbase Accounts

=head1 SYNOPSIS

  use Finance::GDAX::API::CoinbaseAccount;

  $coinbase_accts = Finance::GDAX::API::CoinbaseAccount->new;

  # Array of Hashes of Coinbase accounts
  $accounts = $coinbase_accts->get;

=head2 DESCRIPTION

Returns an array of Coinbase acccounts associated with the account.

=head1 METHODS

=head2 C<get>

Returns an array of Coinbase acccounts associated with the account.

The API documents the array of hashes as follows:

  [
    {
        "id": "fc3a8a57-7142-542d-8436-95a3d82e1622",
        "name": "ETH Wallet",
        "balance": "0.00000000",
        "currency": "ETH",
        "type": "wallet",
        "primary": false,
        "active": true
    },
    {
        "id": "2ae3354e-f1c3-5771-8a37-6228e9d239db",
        "name": "USD Wallet",
        "balance": "0.00",
        "currency": "USD",
        "type": "fiat",
        "primary": false,
        "active": true,
        "wire_deposit_information": {
            "account_number": "0199003122",
            "routing_number": "026013356",
            "bank_name": "Metropolitan Commercial Bank",
            "bank_address": "99 Park Ave 4th Fl New York, NY 10016",
            "bank_country": {
                "code": "US",
                "name": "United States"
            },
            "account_name": "Coinbase, Inc",
            "account_address": "548 Market Street, #23008, San Francisco, CA 94104",
            "reference": "BAOCAEUX"
        }
    },
    {
        "id": "1bfad868-5223-5d3c-8a22-b5ed371e55cb",
        "name": "BTC Wallet",
        "balance": "0.00000000",
        "currency": "BTC",
        "type": "wallet",
        "primary": true,
        "active": true
    },
    {
        "id": "2a11354e-f133-5771-8a37-622be9b239db",
        "name": "EUR Wallet",
        "balance": "0.00",
        "currency": "EUR",
        "type": "fiat",
        "primary": false,
        "active": true,
        "sepa_deposit_information": {
            "iban": "EE957700771001355096",
            "swift": "LHVBEE22",
            "bank_name": "AS LHV Pank",
            "bank_address": "Tartu mnt 2, 10145 Tallinn, Estonia",
            "bank_country_name": "Estonia",
            "account_name": "Coinbase UK, Ltd.",
            "account_address": "9th Floor, 107 Cheapside, London, EC2V 6DN, United Kingdom",
            "reference": "CBAEUXOVFXOXYX"
        }
    },
  ]

=cut


=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

