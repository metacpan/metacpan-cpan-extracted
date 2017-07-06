package Finance::GDAX::API::Withdrawl;
our $VERSION = '0.02';
use 5.20.0;
use warnings;
use Moose;
use Finance::GDAX::API::TypeConstraints;
use Finance::GDAX::API;
use namespace::autoclean;

extends 'Finance::GDAX::API';

has 'payment_method_id' => (is  => 'rw',
			    isa => 'Str',
    );
has 'coinbase_account_id' => (is  => 'rw',
			      isa => 'Str',
    );
has 'crypto_address' => (is  => 'rw',
			 isa => 'Str',
    );
has 'amount' => (is  => 'rw',
		 isa => 'PositiveNum',
    );
has 'currency' => (is  => 'rw',
		   isa => 'Str',
    );

sub to_payment {
    my $self = shift;
    unless ($self->payment_method_id &&
	    $self->amount &&
	    $self->currency) {
	die 'payments need amount and currency set';
    }
    $self->path('/withdrawls/payment-method');
    $self->method('POST');
    $self->body({ amount            => $self->amount,
		  currency          => $self->currency,
		  payment_method_id => $self->payment_method_id,
		});
    return $self->send;
}

sub to_coinbase {
    my $self = shift;
    unless ($self->coinbase_account_id &&
	    $self->amount &&
	    $self->currency) {
	die 'coinbase needs an amount and currency set';
    }
    $self->path('/withdrawls/coinbase-account');
    $self->method('POST');
    $self->body({ amount              => $self->amount,
		  currency            => $self->currency,
		  coinbase_account_id => $self->coinbase_account_id,
		});
    return $self->send;
}

sub to_crypto {
    my $self = shift;
    unless ($self->crypto_address &&
	    $self->amount &&
	    $self->currency) {
	die 'crypto_address needs an amount and currency set';
    }
    $self->path('/withdrawls/crypto');
    $self->method('POST');
    $self->body({ amount         => $self->amount,
		  currency       => $self->currency,
		  crypto_address => $self->crypto_address,
		});
    return $self->send;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Finance::GDAX::API::Withdrawl - Withdraw funds to a Payment Method or
Coinbase

=head1 SYNOPSIS

  use Finance::GDAX::API::Withdraw;

  $withdraw = Finance::GDAX::API::Withdraw->new(
              currency => 'USD',
              amount   => '250.00');

  $withdraw->payment_method_id('kwji-wefwe-ewrgeurg-wef');

  $response = $withdraw->to_payment;

  # Or, to a Coinbase account
  $withdraw->coinbase_account_id('woifhe-i234h-fwikn-wfihwe');

  $response = $withdraw->to_coinbase;

  # Or, to a Crypto address
  $withdraw->crypto_address('1PtbhinXWpKZjD7CXfFR7kG8RF8vJTMCxA');

=head2 DESCRIPTION

Used to transfer funds out of your GDAX account, either to a
predefined Payment Method or your Coinbase account.

Both methods require the same two attributes: "amount" and "currency"
to be set, along with their corresponding payment or coinbase account
id's.

=head1 ATTRIBUTES

=head2 C<payment_method_id> $string

ID of the payment method.

=head2 C<coinbase_account_id> $string

ID of the coinbase account.

=head2 C<crypto_address> $string

Withdraw funds to a crypto address.

=head2 C<amount> $number

The amount to be withdrawn.

=head2 C<currency> $currency_string

The currency of the amount -- for example "USD".

=head1 METHODS

=head2 C<to_payment>

All attributes must be set before calling this method. The return
value is a hash that will describe the result of the payment.

From the current GDAX API documentation, this is how that returned hash is
keyed:

  {
    "id":"593533d2-ff31-46e0-b22e-ca754147a96a",
    "amount": "10.00",
    "currency": "USD",
    "payout_at": "2016-08-20T00:31:09Z"
  }

=head2 C<to_coinbase>

All attributes must be set before calling this method. The return
value is a hash that will describe the result of the funds move.

From the current GDAX API documentation, this is how that returned hash is
keyed:

  {
    "id":"593533d2-ff31-46e0-b22e-ca754147a96a",
    "amount":"10.00",
    "currency": "BTC",
  }

=head2 C<to_crypto>

All attributes must be set before calling this method. The return
value is a hash that will describe the result of the funds move.

From the current GDAX API documentation, this is how that returned hash is
keyed:

  {
    "id":"593533d2-ff31-46e0-b22e-ca754147a96a",
    "amount":"10.00",
    "currency": "BTC",
  }

=cut


=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

