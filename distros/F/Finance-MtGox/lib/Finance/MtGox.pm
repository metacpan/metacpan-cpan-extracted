package Finance::MtGox;

use warnings;
use strict;
use Carp qw( croak );
use JSON::Any;
use WWW::Mechanize;
use URI;
use Time::HiRes qw( gettimeofday );
use Digest::SHA qw( hmac_sha512 );
use MIME::Base64;

=head1 NAME

Finance::MtGox - trade Bitcoin with the MtGox API

=head1 VERSION

Version 0.50

=cut

our $VERSION = '0.50';


=head1 SYNOPSIS

  use Finance::MtGox;
  my $mtgox = Finance::MtGox->new({
    key     => 'api key',
    secret  => 'api secret'
  });

  # unauthenticated API calls
  my $depth = $mtgox->call('getDepth');

  # authenticated API calls
  my $funds = $mtgox->call_auth('generic/info');

  # convenience methods built on the core API
  my ( $btcs, $usds ) = $mtgox->balances;
  my $rate = $mtgox->clearing_rate( 'asks', 200, 'BTC' );
  $rate    = $mtgox->clearing_rate( 'bids',  42, 'USD' );

=head1 BASIC METHODS

=head2 new

Create a new C<Finance::MtGox> object with your MtGox credentials provided
in the C<key> and C<secret> arguments.

=cut

sub new {
    my ( $class, $args ) = @_;

    $args->{key} && $args->{secret}
      or croak "You must provide 'key' and 'secret' credentials.";

    $args->{json} = JSON::Any->new;
    $args->{mech} = WWW::Mechanize->new(stack_depth => 0);

    return bless $args, $class;
}

=head2 call( $name )

Run the API call named C<$name>.  Returns a Perl data structure
representing the JSON returned from MtGox.

=cut

sub call {
    my ( $self, $name ) = @_;
    croak "You must provide an API method" if not $name;

    my $version = $self->_version_from_name($name);
    my $req = $self->_build_api_method_request( 'GET',
                                                $version,
                                                $name,
                                                $version == 0  ? 'data': '' );
    $self->_mech->request($req);
    return $self->_decode;
}

=head2 call_auth( $name, $args )

Run the API call named C<$name> with arguments provided by the hashref
C<$args>. Returns a Perl data structure representing the JSON returned
from MtGox

=cut

sub call_auth {
    my ( $self, $name, $args ) = @_;
    croak "You must provide an API method" if not $name;

    my $version = $self->_version_from_name($name);
    $args ||= {};
    my $req = $self->_build_api_method_request( 'POST', $version, $name, '', $args );
    $self->_mech->request($req);
    return $self->_decode;
}

=head1 CONVENIENCE METHODS

=head2 balances

Returns a list with current BTC and C<$currency> account balances,
respectively. If C<$currency> is not specified it defaults to USD.

=cut

sub balances {
    my ($self, $currency) = @_;
    $currency ||= 'USD';

    my $result = $self->call_auth('info');
    return ( $result->{Wallets}{BTC}, $result->{Wallets}{$currency} );
}

=head2 clearing_rate( $side, $amount, $currency )

Traverse the current "asks" or "bids" (C<$side>) on the order book until the
given amount of currency has been consumed.
Returns the resulting market clearing rate.
This method is useful when trying to determine how much you'd have to pay
to purchase $40 worth of BTC:

  my $rate = $mtgox->clearing_rate( 'asks', 40, 'USD' );

Similar code for determining the rate to sell 40 BTC:

  my $rate = $mtgox->clearing_rate( 'bids', 40, 'BTC' );

Dark pool orders are not considered since they're not visible on the order
book.

=cut

sub clearing_rate {
    my ( $self, $side, $amount, $currency ) = @_;
    croak "You must specify a side"  if not defined $side;
    $side = lc $side;
    croak "Invalid side: $side" if not $side =~ /^(asks|bids)$/;
    croak "You must specify an amount"  if not defined $amount;
    croak "You must specify a currency" if not defined $currency;
    $currency = uc $currency;

    # make sure we traverse offers in the right order
    my @offers =
        sort { $a->[0] <=> $b->[0] }
        @{ $self->call('getDepth')->{$side} };
    @offers = reverse @offers if $side eq 'bids';

    # how much will we pay to purchase the desired quantity of BTC?
    my $bought_btc = 0;
    my $paid_usd   = 0;
    for my $offer (@offers) {
        my ( $price_usd, $volume_btc ) = @$offer;
        my $trade_btc = $currency eq 'BTC' ? $amount-$bought_btc
                      : $currency eq 'USD' ? ($amount-$paid_usd)/$price_usd
                      : croak "Invalid currency: $currency"
                      ;
        $trade_btc = $volume_btc if $volume_btc < $trade_btc;
        $paid_usd   += $trade_btc * $price_usd;
        $bought_btc += $trade_btc;
        last if $currency eq 'BTC' && $bought_btc >= $amount;
        last if $currency eq 'USD' && $paid_usd   >= $amount;
    }

    return $paid_usd / $bought_btc;
}

=head2 market_price

Returns a volume-weighted USD price per BTC based on MtGox trades within
the last 24 hours.  Returns C<undef> if there have been no trades in the
last 24 hours.

=cut

sub market_price {
    my ($self) = @_;
    my $trades    = $self->call('getTrades');
    my $threshold = time - 86400;           # last 24 hours

    my $trade_count      = 0;
    my $trade_volume_btc = 0;
    my $trade_volume_usd = 0;
    for my $trade (@$trades) {
        next if $trade->{date} < $threshold;
        $trade_count++;
        $trade_volume_btc += $trade->{amount};
        $trade_volume_usd += $trade->{price} * $trade->{amount};
    }

    return if $trade_count == 0;
    return if $trade_volume_btc == 0;
    return $trade_volume_usd / $trade_volume_btc;
}

### Private methods below here

sub _decode {
    my ($self) = @_;
    return $self->_json->decode( $self->_mech->content );
}

sub _json {
    my ($self) = @_;
    return $self->{json};
}

sub _mech {
    my ($self) = @_;
    return $self->{mech};
}

sub _key {
    my ($self) = @_;
    return $self->{key};
}

sub _secret {
    my ($self) = @_;
    return $self->{secret};
}

# build a URI object for the endpoint of an API call
sub _build_api_method_uri {
    my ( $self, $version, $name, $prefix ) = @_;
    my $version_url_token = "api/" . $version;

    $prefix = $prefix ? "$prefix/" : '';
    return URI->new($version == 0 ?
                    "https://mtgox.com/$version_url_token/$prefix$name.php"
                    : "https://data.mtgox.com/$version_url_token/$prefix$name");
}

# builds an HTTP::Request object for making an API call
sub _build_api_method_request {
    my ( $self, $method, $version, $name, $prefix, $params ) = @_;
    $method = uc $method;
    $params ||= {};

    # prepare for authentication
    if ( $method eq 'POST') {
        $params->{nonce} = $self->_generate_nonce;
    }

    my $uri = $self->_build_api_method_uri( $version, $name, $prefix );
    if ( $method eq 'GET') {
        # since March 19, 2013 no-auth requests need this hostname
        $uri->scheme('http');
        $uri->host('data.mtgox.com');
    }

    my $req = HTTP::Request->new( $method, $uri );
    if ( keys %$params ) {
        $uri->query_form($params);
        if ( $method eq 'POST' ) {

            # move params to the request body
            my $query = $uri->query;
            my $message = $version == 2 ? "$name\0$query" : $query;
            $req->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
            $req->content($query);
            $uri->query(undef);

            # include a signature
            $req->header( 'Rest-Key', $self->_key );
            $req->header( 'Rest-Sign', $self->_sign($message) );
          }
    }
    return $req;
}

# Returns an ever-increasing nonce value
# (Fails to increase when the system clock adjusts backwards)
sub _generate_nonce {
    return sprintf '%s%06s', gettimeofday()
}

# Returns a signature for the given message (using the API secret)
sub _sign {
    my ( $self, $message ) = @_;
    my $secret = decode_base64( $self->_secret );
    return encode_base64( hmac_sha512( $message, $secret ) );
}

# Returns the version of the api from the method name
sub _version_from_name {
  my ( $self, $name ) = @_;
  $name =~ /^BTC[A-Z]{3}\/(money|stream|security)/ and return 2;
  $name =~ /^(BTC[A-Z]{3}|generic)\/(\w*)/ and return 1;
  return 0;
}

=head1 AUTHOR

Michael Hendricks, C<< <michael@ndrix.org> >>

=head1 BUGS

Please report any bugs or feature requests through
the web interface at L<https://github.com/mndrix/Finance-MtGox/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::MtGox


You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-MtGox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-MtGox>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-MtGox/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Michael Hendricks.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Finance::MtGox
