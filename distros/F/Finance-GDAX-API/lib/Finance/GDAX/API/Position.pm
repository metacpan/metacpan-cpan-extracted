package Finance::GDAX::API::Position;
our $VERSION = '0.01';
use 5.20.0;
use warnings;
use Moose;
use Finance::GDAX::API;
use namespace::autoclean;

extends 'Finance::GDAX::API';

has 'repay_only' => (is  => 'rw',
		     isa => 'Bool',
    );

sub get {
    my $self = shift;
    $self->method('GET');
    $self->path('/position');
    return $self->send;
}

sub close {
    my $self = shift;
    $self->method('POST');
    $self->path('/position/close');
    if (defined $self->repay_only) {
	my $r = $self->repay_only ? 'true' : 'false';
	$self->body({ repay_only => $r });
    }
    return $self->send;
}
__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Finance::GDAX::API::Position - Overview of profile

=head1 SYNOPSIS

  use Finance::GDAX::API::Position;

  $overview = Finance::GDAX::API::Position->new;

  # Hash of profile positions
  $positions = $overview->get;

=head2 DESCRIPTION

Returns an overview of profile information in hash form, including
profile status, funding (margin), accounts, margin call, etc, as
documented in the "get" method.

Also there is a "close" method which is left mostly undescribed in the
API as to what it actually does, but is included here for fun and
danger.

=head1 ATTRIBUTES

=head2 C<repay_only> $boolean

This attribute is associated with the "close" method and is
boolean. The GDAX API docs do not say what it does or means, nor if it
is required.

=head1 METHODS

=head2 C<get>

Returns a hash representing an overview of the position/account
information.

The API documents the hash structure as follows:

  {
  "status": "active",
  "funding": {
    "max_funding_value": "10000",
    "funding_value": "622.48199522418175",
    "oldest_outstanding": {
      "id": "280c0a56-f2fa-4d3b-a199-92df76fff5cd",
      "order_id": "280c0a56-f2fa-4d3b-a199-92df76fff5cd",
      "created_at": "2017-03-18T00:34:34.270484Z",
      "currency": "USD",
      "account_id": "202af5e9-1ac0-4888-bdf5-15599ae207e2",
      "amount": "545.2400000000000000"
    }
  },
  "accounts": {
    "USD": {
      "id": "202af5e9-1ac0-4888-bdf5-15599ae207e2",
      "balance": "0.0000000000000000",
      "hold": "0.0000000000000000",
      "funded_amount": "622.4819952241817500",
      "default_amount": "0"
    },
    "BTC": {
      "id": "1f690a52-d557-41b5-b834-e39eb10d7df0",
      "balance": "4.7051564815292853",
      "hold": "0.6000000000000000",
      "funded_amount": "0.0000000000000000",
      "default_amount": "0"
    }
  },
  "margin_call": {
    "active": true,
    "price": "175.96000000",
    "side": "sell",
    "size": "4.70515648",
    "funds": "624.04210048"
  },
  "user_id": "521c20b3d4ab09621f000011",
  "profile_id": "d881e5a6-58eb-47cd-b8e2-8d9f2e3ec6f6",
  "position": {
    "type": "long",
    "size": "0.59968368",
    "complement": "-641.91999958602800000000000000",
    "max_size": "1.49000000"
  },
  "product_id": "BTC-USD"
  }

The structure is explained in the API thusly:

=head3 Status

=over

The status of the profile. If active, the profile can be used for
trading. If pending, the profile is currently being created. If
locked, the profile is undergoing a rebalance. If default, you were
not able repay funding after a margin call or expired funding and now
have a default.

=back

=head3 Funding [margin]

=over

Holds details about the open/outstanding fundings taken out in the
margin profile.

funding_value is the value of all outstanding fundings in USD. This
value is updated every time you draw or repay funding.

max_funding_value is maximum value of fundings in USD that you can
have oustanding. This value can restrict you from drawing more
funding.

oldest_outstanding is the oldest funding record you have
outstanding. This is important as funding can only remain outstanding
for 27 days and 22 hours before being automatically closed and
settled. It is recommended that you manually settle or claim the
funding before it expires.

=back

=head3 Accounts

=over

The accounts in the profile indexed by their currency.

=back

=head3 Margin Call [margin]

=over

Holds details about the resting margin call. To attempt to ensure you
can repay funding we place a hidden stop like order on the book. When
the last trade price hits or goes past price the margin call will
trigger issuing a market order to rebalance your profile so each
account has enough funds to repay all outstanding funding records.

If each account's balance is large enough to repay the its
funded_amount, active will be false signifying your profile does not
have a resting margin call.

=back

=head2 C<close>

The GDAX API docs do not currently say what this method does. But it
does have an either optional or required attribute that can be set,
"repay_only".

=cut


=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

