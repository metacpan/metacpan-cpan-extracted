package Finance::GDAX::API::Quote;
our $VERSION = '0.01';
use 5.20.0;
use warnings;
use Moose;
use JSON;
use REST::Client;
use Finance::GDAX::API::URL;
use namespace::autoclean;


=head1 NAME

Finance::GDAX::API::Quote - Get a quote from the GDAX

=head1 SYNOPSIS

  use Finanace::GDAX::API::Quote;
  my $quote = Finance::GDAX::API::Quote->new(product => 'BTC-USD')->get;
  say $$quote{price};
  say $$quote{bid};
  say $$quote{ask};

=head1 DESCRIPTION

Gets a quote from the GDAX for the specified "product". These quotes
do not require GDAX API keys, but they suggesting keeping traffic low.

More detailed information can be retrieve about products and history
using API keys with other classes like Finance::GDAX::API::Product

Currently, the supported products are:

  BTC-USD
  BTC-GBP
  BTC-EUR
  ETH-BTC
  ETH-USD
  LTC-BTC
  LTC-USD
  ETH-EUR

These are not hard-coded, but the default is BTC-USD, so if any are
added by GDAX in the future, it should work find if you can find the
product code.

Quote is returned as a hashref with the (currently) following keys:

  trade_id
  price
  size
  bid
  ask
  volume
  time

=head1 ATTRIBUTES

=head2 C<debug> (default: 1)

Bool that sets debug mode (will use sandbox). Defaults to true
(1). Debug mode does not seem to give real quotes.

=head2 C<product> (default: "BTC-USD")

The product code for which to return the quote.

=cut

has 'product' => (is  => 'rw',
		  isa => 'Str',
		  default => 'BTC-USD',
    );
has 'debug' => (is  => 'rw',
		isa => 'Bool',
		default => 1,
    );		    

=head1 METHODS

=head2 C<get>

Returns a quote for the desired product.

=cut

sub get {
    my $self = shift;
    my $url  = Finance::GDAX::API::URL->new;
    $url->debug($self->debug);
    $url->add('products');
    $url->add($self->product);
    $url->add('ticker');
    
    my $client = REST::Client->new;
    $client->GET($url->get);

    my $json = JSON->new;
    return $json->decode($client->responseContent);
}

__PACKAGE__->meta->make_immutable;
1;


=head1 AUTHOR

Mark Rushing <mark@orbislumen.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Home Grown Systems, SPC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

