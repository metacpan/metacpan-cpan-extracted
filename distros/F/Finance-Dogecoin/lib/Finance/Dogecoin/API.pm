package Finance::Dogecoin::API;
$Finance::Dogecoin::API::VERSION = '1.20140201.1608';
use 5.010;

use Moo;
# limit the damage from Moo's use of strictures
# see: http://www.modernperlbooks.com/mt/2014/01/fatal-warnings-are-a-ticking-time-bomb.html
use warnings NONFATAL => 'all';

use Carp ();

use URI;
use JSON;
use HTTP::Headers;
use LWP::UserAgent;
use LWP::Protocol::https;
use URI::QueryParam;

has 'api_key',  is => 'ro', required => 1;
has 'endpoint', is => 'ro', default  => sub { 'https://www.dogeapi.com/wow/' };
has 'json',     is => 'ro', default  => sub {
    my $j = JSON->new; $j->allow_nonref; $j
};

has 'ua',       is => 'ro', default => sub {
    my $headers = HTTP::Headers->new;
    $headers->header( 'Content-Type' => 'application/json' );
    LWP::UserAgent->new(
        ssl_opts        => { verify_hostname => 1 },
        default_headers => $headers,
    );
};

sub request {
    my ($self, $method, %params) = @_;

    # manually setting the 'a' parameter avoids a weird behavior in LWP::UA
    # which uppercases 'a'--not what the API expects or wants
    my $uri = URI->new( $self->endpoint );
    $uri->query_param( a => $method );

    while (my ($key, $value) = each %params) {
        $uri->query_param( $key => $value );
    }

    my $response = $self->ua->get( $uri );
    my $result   = $self->json->decode( $response->decoded_content );

    Carp::croak( "Bad API call from $method() call" ) if $result eq 'Bad Query';
    Carp::croak( "Invalid API key '" . $self->api_key . "'" )
        if $result eq 'Invalid API Key';

    return $result;
}

BEGIN {
    for my $non_api (qw( get_difficulty get_current_block get_current_price )) {
        my $method = sub { $_[0]->request( $non_api ) };
        do {
            no strict 'refs';
            *{ $non_api } = $method;
        };
    }

    for my $api (qw( get_balance get_my_addresses )) {
        my $method = sub { $_[0]->request( $api, api_key => $_[0]->api_key ) };
        do {
            no strict 'refs';
            *{ $api } = $method;
        };
    }
}

sub withdraw {
    my ($self, %params) = @_;

    my @errors;

    for my $param (qw( payment_address amount )) {
        push @errors, $param unless $params{$param};
    }

    if (@errors) {
        my $error = join ', ', @errors;
        Carp::croak( "Must call withdraw() with $error params" );
    }

    Carp::croak( 'Must call withdraw() with amount of at least 5 Doge' )
        if $params{amount} < 5;

    $self->request( 'withdraw', api_key => $self->api_key, %params );
}

sub get_new_address {
    my ($self, %params) = @_;
    $self->request( 'get_new_address', api_key => $self->api_key, %params );
}

sub get_address_received {
    my ($self, %params)        = @_;
    $params{payment_address} //= $params{address_label};

    Carp::croak( 'Must call get_address_received() with payment_address param' )
        unless $params{payment_address};

    $self->request( 'get_address_received',
        api_key => $self->api_key, %params
    );
}

sub get_address_by_label {
    my ($self, %params) = @_;

    Carp::croak( 'Must call get_address_by_label() with address_label param' )
        unless $params{address_label};

    $self->request( 'get_address_by_label',
        api_key => $self->api_key, %params
    );
}

'to the moon';
__END__
=pod

=head1 NAME

Finance::Dogecoin::API - use the dogeapi.com API from Perl

=head1 SYNOPSIS

    use Finance::Dogecoin::API;

    # may throw errors
    eval {
        my $dc      = Finance::Dogecoin::API->new( api_key => $SECRET_KEY );
        my $block   = $dc->get_current_block;
        my $price   = $dc->get_current_price;

        my $balance = $dc->get_balance;
        my $result  = $dc->withdraw(
            payment_address => $ADDY, amount => $AMOUNT
        );
    };

    # tip the author
    $dc->withdraw(
        payment_address => 'DPxuFc7dhNrTvNMCE53ENGF5g7LSGrzyYs',
        amount          => 5,
    );

=head1 DESCRIPTION

C<Finance::Dogecoin::API> provides an OO interface to the Dogecoin API provided
by L<http://dogeapi.com/>. You need to sign up for an API key to use most of
the methods in this class; do so at the site. When creating the object, you
must provide the C<api_key> as a constructor argument.

=head1 METHODS

This module provides several methods. See the documentation at
L<https://www.dogeapi.com/api_documentation> for current details. These methods
may I<all> throw an exception if a network error or protocol error occurs, so
be ready to catch them:

=head2 get_current_price()

Returns the current price of Dogecoins in US dollars. This is a floating point
number.

=head2 get_current_block()

Returns the current block of Doge mining.

=head2 get_difficulty()

Returns the current difficulty of Doge mining.

=head2 get_balance()

Returns the balance of your entire account across all wallets. This is a
floating point number.

=head2 get_my_addresses()

Returns an array reference of all payment addresses associated with your
account. This array may be empty.

=head2 withdraw( payment_address => $address, amount => $amount )

Withdraws C<$amount> from your account and sends it to <$address>. The API and
the Doge network each charge a modest transaction fee. The transaction will
fail unless your account meets these criteria. In particular, you must transfer
at least 5 Doge at a time.

If you do not provide I<both> the C<payment_address> and C<amount> parameters,
this method will throw an exception.

=head2 get_new_address( address_label => $label )

Creates and returns a new payment address for your account. You may provide an
I<optional> C<address_label> parameter. The API will use this alphanumeric
value as the label if possible.

=head2 get_address_received( payment_address => $address )

Returns the current amount of Dogecoins recieved at the given address or label.
This method will throw an exception if you do not provide either the
C<payment_address> or C<address_label> parameters. This method will return the
number C<0> if you provide an invalid address or label.

=head2 get_address_by_label( address_label => $label )

Returns the payment address for the given address label. This method will throw
an exception if you do not provide the C<address_label> parameter. This method
will return the string C<No matching addresses> if there are no matching
addresses.

=head1 CAVEATS

The Dogecoin API is under development, so these methods might change and new
methods might appear.

=head1 COPYRIGHT & LICENSE

Copyright 2014 chromatic, some rights reserved.

This program is free software. You can redistribute it and/or modify it under
the same terms as Perl 5.18.

=cut
