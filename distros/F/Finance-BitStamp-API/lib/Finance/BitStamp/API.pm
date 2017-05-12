package Finance::BitStamp::API;

use 5.014002;
use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Finance::BitStamp::API::DefaultPackage);

use constant DEBUG => 0;

# you can use a lower version, but then you are responsible for SSL cert verification code...
use LWP::UserAgent 6;
use URI;
use CGI;
use JSON;
use MIME::Base64;
use Time::HiRes qw(gettimeofday);
use Digest::SHA qw(hmac_sha256_hex);
use Math::BigFloat;
use Data::Dumper;

use Finance::BitStamp::API::Request::Ticker;
use Finance::BitStamp::API::Request::OrderBook;
use Finance::BitStamp::API::Request::PublicTransactions;
use Finance::BitStamp::API::Request::ConversionRate;

use Finance::BitStamp::API::Request::Balance;
use Finance::BitStamp::API::Request::Transactions;
use Finance::BitStamp::API::Request::Withdrawals;
use Finance::BitStamp::API::Request::RippleAddress;
use Finance::BitStamp::API::Request::BitcoinAddress;
use Finance::BitStamp::API::Request::Orders;
use Finance::BitStamp::API::Request::PendingDeposits;

use Finance::BitStamp::API::Request::Buy;
use Finance::BitStamp::API::Request::Sell;
use Finance::BitStamp::API::Request::Cancel;
use Finance::BitStamp::API::Request::BitcoinWithdrawal;
use Finance::BitStamp::API::Request::RippleWithdrawal;

use constant ATTRIBUTES       => qw(key secret client_id);
use constant COMPANY          => 'BitStamp';
use constant ERROR_NO_REQUEST => 'No request object to send';
use constant ERROR_NOT_READY  => 'Not enough information to send a %s request';
use constant ERROR_READY      => 'The request IS%s READY to send';
use constant ERROR_BITSTAMP   => COMPANY . 'error: "%s"';
use constant ERROR_UNKNOWN    => COMPANY . 'returned an unknown status';

use constant CLASS_ACTION_MAP => {
    # Public requests:
    ticker               => 'Finance::BitStamp::API::Request::Ticker',
    orderbook            => 'Finance::BitStamp::API::Request::OrderBook',
    public_transactions  => 'Finance::BitStamp::API::Request::PublicTransactions',
    conversion_rate      => 'Finance::BitStamp::API::Request::ConversionRate',
    # Info requests
    balance              => 'Finance::BitStamp::API::Request::Balance',
    transactions         => 'Finance::BitStamp::API::Request::Transactions',
    withdrawals          => 'Finance::BitStamp::API::Request::Withdrawals',
    ripple_address       => 'Finance::BitStamp::API::Request::RippleAddress',
    bitcoin_address      => 'Finance::BitStamp::API::Request::BitcoinAddress',
    orders               => 'Finance::BitStamp::API::Request::Orders',
    pending_deposits     => 'Finance::BitStamp::API::Request::PendingDeposits',
    # Action requests:
    cancel               => 'Finance::BitStamp::API::Request::Cancel',
    buy                  => 'Finance::BitStamp::API::Request::Buy',
    sell                 => 'Finance::BitStamp::API::Request::Sell',
    bitcoin_withdrawal   => 'Finance::BitStamp::API::Request::BitcoinWithdrawal',
    ripple_withdrawal    => 'Finance::BitStamp::API::Request::RippleWithdrawal',
};

sub is_ready {
    my $self = shift;
    my $ready = 0;
    # here we are checking whether or not to default to '0' (not ready to send) based on this objects settings.
    # the settings in here are the token and the secret provided to you by BitStamp.
    # if we dont have to add a nonce, then also set to '1'
    if (not $self->request->is_private or (defined $self->secret and defined $self->key)) {
       $ready = $self->request->is_ready;
    }
    warn sprintf(ERROR_READY, $ready ? '' : ' NOT') . "\n" if DEBUG;

    return $ready;
}

sub send {
    my $self = shift;

    # clear any previous response values... because if you wan it, you shoulda put a variable on it.
    $self->response(undef);
    $self->error(undef);

    unless ($self->request) {
        $self->error({
            type    => __PACKAGE__,
            message => ERROR_NO_REQUEST,
        });
    }
    else {
        # validate that the minimum required request attributes are set here.
        if (not $self->is_ready) {
             $self->error({
                 type    => __PACKAGE__,
                 message => sprintf(ERROR_NOT_READY, ref $self->request),
             });
        }
        else {
            # make sure we have an request to send...
            my $request = $self->http_request(HTTP::Request->new);
            $request->method($self->request->request_type);
            $request->uri($self->request->url);
            my %query_form = $self->request->request_content;
            if ($self->request->is_private) {
                $query_form{nonce}     = $self->nonce;
                $query_form{key}       = $self->key;
                $query_form{signature} = $self->signature;
            }
            my $uri = URI->new;
            $uri->query_form(%query_form);
            if ($self->request->request_type eq 'POST') {
                $request->content($uri->query);
                $request->content_type($self->request->content_type);
            }
            elsif ($self->request->request_type eq 'GET' and $uri->query) {
                $request->uri($request->uri . '?' . $uri->query);
            }
   
            $request->header('Accept'   => 'application/json');
            #warn Data::Dumper->Dump([$request, $self->http_request]);
            #warn sprintf "Content: %s\n", $self->http_request->content;

            # create a new user_agent each time...
            $self->user_agent(LWP::UserAgent->new);
            $self->user_agent->agent('Mozilla/8.0');
            $self->user_agent->ssl_opts(verify_hostname => 1);

            warn Data::Dumper->Dump([$self->user_agent, $request],[qw(UserAgent Request)]) if DEBUG;

            $self->http_response($self->user_agent->request($request));
            $self->process_response;
        }
    }
    return $self->is_success;
}

sub process_response {
    my $self = shift;

    warn sprintf "Response CODE: %s\n", $self->http_response->code    if DEBUG;
    warn sprintf "Content: %s\n",       $self->http_response->content if DEBUG;

    my $content;
    my $error_msg;
    eval {
        warn Data::Dumper->Dump([$self->http_response],['Response'])  if DEBUG;
        # apparently, the bitcoin address request returns the new addr as a string!!! (not json compatible)
        if ($self->request->isa('Finance::BitStamp::API::Request::BitcoinAddress')) {
            $content = $self->http_response->content;
        }
        else {
            $content = $self->json->decode($self->http_response->content);
        }
        1;
    } or do {
        $self->error("Request/JSON error: $@");
        warn $self->error . "\n";
        warn sprintf "Content was: %s\n", $self->http_response->content;
    };

    unless ($self->error) {
        if (ref $content eq 'HASH' and exists $content->{error}) {
            warn sprintf(ERROR_BITSTAMP, $content->{error}) . "\n";
            $self->error($content->{error});
        }
        else {
            $self->response($content);
        }
    }

    return $self->is_success;
}

# signature : is a SHA256 HMAC encoded message using your secret key and
# input of the nonce, client ID and API key.
# It is converted to Uppercase Hex.
sub signature {
    my $self = shift;
    return uc hmac_sha256_hex($self->nonce . $self->client_id . $self->key, $self->secret);
}

# careful, this is "hot". It will return a different value with each call.
# perhaps this should be a constant class object in the Requests object.
# Since a new one is created with each processor action call.
sub nonce     { shift->request->nonce       }
sub json      { shift->{json} ||= JSON->new }
sub is_success{ defined shift->response     }
sub attributes{ ATTRIBUTES                  }

# this method makes the action call routines simpler...
sub _class_action {
    my $self = shift;
    my $class = CLASS_ACTION_MAP->{((caller(1))[3] =~ /::(\w+)$/)[0]};
    $self->request($class->new(@_));
    return $self->send ? $self->response : undef;
}

sub ticker              { _class_action(@_) }
sub orderbook           { _class_action(@_) }
sub public_transactions { _class_action(@_) }
sub conversion_rate     { _class_action(@_) }
sub balance             { _class_action(@_) }
sub transactions        { _class_action(@_) }
sub withdrawals         { _class_action(@_) }
sub ripple_address      { _class_action(@_) }
sub bitcoin_address     { _class_action(@_) }
sub orders              { _class_action(@_) }
sub cancel              { _class_action(@_) }
sub buy                 { _class_action(@_) }
sub sell                { _class_action(@_) }
sub bitcoin_withdrawal  { _class_action(@_) }
sub pending_deposits    { _class_action(@_) }
sub ripple_withdrawal   { _class_action(@_) }

sub key           { my $self = shift; $self->get_set(@_) }
sub secret        { my $self = shift; $self->get_set(@_) }
sub client_id     { my $self = shift; $self->get_set(@_) }
sub error         { my $self = shift; $self->get_set(@_) }
sub http_response { my $self = shift; $self->get_set(@_) }
sub request       { my $self = shift; $self->get_set(@_) }
sub response      { my $self = shift; $self->get_set(@_) }
sub http_request  { my $self = shift; $self->get_set(@_) }
sub user_agent    { my $self = shift; $self->get_set(@_) }
sub status        { my $self = shift; $self->get_set(@_) }

1;

__END__


=head1 NAME

Finance::BitStamp::API - Perl extension for handling the BitStamp API and IPN calls.

=head1 SYNOPSIS

  use Finance::BitStamp::API;

  # all the standard BitStamp API calls...

  my $bitstamp       = Finance::BitStamp::API->new(key => 'abc123');
  my $ticker         = $bitstamp->ticker;
  my $btc_address    = $bitstamp->bitcoin_address;
  my $btc_withdrawal = $bitstamp->bitcoin_withdrawal(amount => '1.0', address => $address);

  # The bitstamp object contains all the request data from the last request...

  my $user_agent = $bitstamp->user_agent;

  if ($bitstamp->success) {
      print 'SUCESS';
  }
  else {
      print 'FAIL';
      my $error = $bitstamp->error;
  }


  # A more useful example...
  my $bitstamp  = Finance::BitStamp::API->new(key => $key, secret => $secret, client_id => $client_id);
  my $buy = $bitstamp->buy(amount => '10.00');

  if ($buy) {
      printf "The BitStamp invoice ID is %s. You can see it here: %s\n", @{$buy}{qw(id url)};
  }
  else {
      printf "An error occurred: %s\n", $bitstamp->error;
  }

=head1 DESCRIPTION

This API module provides a quick way to access the BitStamp API from perl without worrying about
the connection, authenticatino and an errors in between.

You call these on the API object created like this:

  my $bitstamp = Finance::BitStamp::API->new(key => $key, secret => $secret, client_id => $client_id);

...Where those variable are provided to you by BitStamp through their merchant interface.

The primary PUBLIC methods are:

    ticker(), orderbook(), public_transactions(), conversion_rate()

The primary PRIVATE Information methods are:

    balance(), transactions(), withdrawals(), ripple_address(), bitcoin_address(), orders(), pending_deposits()

The primary PRIVATE Actions methods are:

    cancel(), buy(), sell(), bitcoin_withdrawal(), ripple_withdrawal()

The return value is a hash representing the BitStamp response.

  my $response_as_a_hash = $bitstamp->bitcoin_withdrawal(amount => $amount, address => $address);

The return value will be undefined when an error occurs...

  if ($bitstamp->is_success) {
      # the last primary method call worked!
  }
  else {
      print "There was an error: " . $bitstamp->error;
      # more detail can be found in the bitstamp object using...
      my $ua           = $bitstamp->user_agent;
      my $raw_request  = $bitstamp->http_request;
      my $raw_response = $bitstamp->http_response;
      # further inspection could go here (like dumping the content of the useragent)
  }
  

=head1 METHODS

=head2 new()

    my $bitstamp = Finance::BitStamp::API->new(key => $key, secret => $secret, client_id => $client_id);

Create a new Finance::BitStamp::API object.
key, secret and client_id are required.
These values are provided by Bitstamp through their online administration interface.


=head2 ticker()

    my $ticker = $bitstamp->ticker;

Send a TICKER request to BitStamp.

Returns a hash reference of the ticker like this:

    $OrederBook = {
        asks => [
            [
                '645.71',
                '0.22100000'
            ],
            [
                '645.88',
                '20.00000000'
            ],
        ],
        bids => [
            [
                '2.00',
                '598.30000000'
            ],
            [
                '1.45',
                '500.00000000'
            ],
        ],
        timestamp => '1402308355'
    };

=head2 orderbook()

    my $orderbook = $bitstamp->orderbook;

=head2 public_transactions()

    my $public_transaction = $bitstamp->public_transaction;


=head2 conversion_rate()

    my $conversion_rate = $bitstamp->conversion_rate;


=head2 balance()

    my $balance = $bitstamp->balance;


=head2 transactions()

    my $transactions = $bitstamp->transactions;


=head2 withdrawals()

    my $withdrawals = $bitstamp->withdrawals;


=head2 ripple_address()

    my $ripple_address = $bitstamp->ripple_address;


=head2 bitcoin_address()

    my $bitcoin_address = $bitstamp->bitcoin_address;


=head2 orders()

    my $orders = $bitstamp->orders;


=head2 cancel()

    my $cancel = $bitstamp->cancel;


=head2 buy()

    my $buy = $bitstamp->buy;


=head2 sell()

    my $sell = $bitstamp->sell;


=head2 bitcoin_withdrawal()

    my $bitcoin_withdrawal = $bitstamp->bitcoin_withdrawal;


=head2 pending_deposits()

    my $pending_deposits = $bitstamp->pending_deposits;


=head2 ripple_withdrawal()

    my $ripple_withdrawal = $bitstamp->ripple_withdrawal;


=head1 ATTRIBUTES

=head2 key(), secret(), client()

These are usually set during object instantiation. But you can set and retrieve them through these attributes.
The last set values will always be used in the next action request. These values are obtained from BitStamp through your account.

=head2 is_ready()

Will return true if the request is set and all conditions are met.
Will return false if:
- the request object does not exist
- the request object requires authentication and no key is provided
- the request object does not have the manditory parameters set that BitStamp requires for that request.

=head2 error()

If the request did not work, error() will contain a hash representing the problem. The hash contains the keys: 'type' and 'message'. These are strings. ie:

    print "The error type was: " . $bitstamp->error->{type};
    print "The error message was: " . $bitstamp->error->{message};

=head2 user_agent()

This will contain the user agent of the last request to BitStamp.
Through this object, you may access both the HTTP Request and Response.
This will allow you to do detailed inspection of exactly what was sent and the raw BitPay response.

=head2 request()

This will contain the Request object of the last action called on the object. It is not a HTTP Request, but rather a config file for the request URL, params and other requirements for each post to bitstamp. You will find these modules using the naming Finance::BitStamp::API::Request::*

=head1 HOWTO DETECT ERRORS

The design is such that the action methods (invoice_create(), invoice_get(), rates() and ledger()) will return false (0) on error.
On success it will contain the hash of information from the BitStamp JSON response.
Your code should just check whether or not the response exists to see if it worked.
If the response does not exist, then then the module detected a problem.
The simplest way to handle this is to print out $bitstamp->error.
A coding example is provided above in the SYNOPSIS.

=head1 NOTES

This module does not do accessive error checking on the request or the response.
It will only check for "required" parameters prior to sending a request to BitStamp.
This means that you provide a word for a 'amount' parameter, and this module will happily send that off to BitStamp for you.
In these cases we are allowing BitStamp to decide what is and is not valid input.
If the input values are invalid, we expect BitStamp to provide an appropriate response and that is the message we will return to the caller (through $bitstamp->error).

This module does not validate the response from BitStamp.
In general it will return success when any json response is provided by Bitstamp without the 'error' key.
The SSL certificate is verified automatically by LWP, so the response you will get is very likely from BitStamp itself.
If there is an 'error' key in the json response, then that error is put into the $bitstamp->error attribute.
If there is an 'error' parsing the response from BitStamp, then the decoding error from json is in the $bitstamp->error attribute.
If there is a network error (not 200), then the error code and $response->error will contain the HTTP Response status_line() (a string response of what went wrong).

=head1 SEE ALSO

The BitStamp API documentation: https://www.bitstamp.net/api/
This project on Github: https://github.com/peawormsworth/Finance-BitStamp-API

=head1 AUTHOR

Jeff Anderson, E<lt>peawormsworth@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jeff Anderson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

