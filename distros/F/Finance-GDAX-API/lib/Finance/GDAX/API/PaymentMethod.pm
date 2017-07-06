package Finance::GDAX::API::PaymentMethod;
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
    $self->path('/payment-methods');
    return $self->send;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Finance::GDAX::API::PaymentMethod - List Payment Methods

=head1 SYNOPSIS

  use Finance::GDAX::API::PaymentMethod;

  $pay_methods = Finance::GDAX::API::PaymentMethod->new;

  # Array of Hashes of payment methods available
  $methods = $pay_methods->get;

=head2 DESCRIPTION

Returns an array of payment methods available on the account.

=head1 METHODS

=head2 C<get>

Returns an array of payment methods available on the account.

The API documents the array of hashes as follows:

  [
    {
        "id": "bc6d7162-d984-5ffa-963c-a493b1c1370b",
        "type": "ach_bank_account",
        "name": "Bank of America - eBan... ********7134",
        "currency": "USD",
        "primary_buy": true,
        "primary_sell": true,
        "allow_buy": true,
        "allow_sell": true,
        "allow_deposit": true,
        "allow_withdraw": true,
        "limits": {
            "buy": [
                {
                    "period_in_days": 1,
                    "total": {
                        "amount": "10000.00",
                        "currency": "USD"
                    },
                    "remaining": {
                        "amount": "10000.00",
                        "currency": "USD"
                    }
                }
            ],
            "instant_buy": [
                {
                    "period_in_days": 7,
                    "total": {
                        "amount": "0.00",
                        "currency": "USD"
                    },
                    "remaining": {
                        "amount": "0.00",
                        "currency": "USD"
                    }
                }
            ],
            "sell": [
                {
                    "period_in_days": 1,
                    "total": {
                        "amount": "10000.00",
                        "currency": "USD"
                    },
                    "remaining": {
                        "amount": "10000.00",
                        "currency": "USD"
                    }
                }
            ],
            "deposit": [
                {
                    "period_in_days": 1,
                    "total": {
                        "amount": "10000.00",
                        "currency": "USD"
                    },
                    "remaining": {
                        "amount": "10000.00",
                        "currency": "USD"
                    }
                }
            ]
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

