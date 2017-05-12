package Finance::CaVirtex::API;

use 5.014002;
use strict;
use warnings;

our $VERSION = '0.03';

use base qw(Finance::CaVirtex::API::DefaultPackage);

use constant DEBUG => 0;

# you can use a lower version, but then you are responsible for SSL cert verification code...
use LWP::UserAgent 6;
use URI;
use CGI;
use JSON;
use MIME::Base64;
use Time::HiRes qw(gettimeofday);
use Digest::SHA qw(hmac_sha256_hex);
use Data::Dumper;

use Finance::CaVirtex::API::Request::OrderBook;
use Finance::CaVirtex::API::Request::TradeBook;
use Finance::CaVirtex::API::Request::Ticker;
use Finance::CaVirtex::API::Request::Balance;
use Finance::CaVirtex::API::Request::Transactions;
use Finance::CaVirtex::API::Request::TradeHistory;
use Finance::CaVirtex::API::Request::OrderHistory;
use Finance::CaVirtex::API::Request::Order;
use Finance::CaVirtex::API::Request::OrderCancel;
use Finance::CaVirtex::API::Request::Withdraw;

use constant COMPANY              => 'CaVirtex';
use constant ERROR_NO_REQUEST     => 'No request object to send';
use constant ERROR_NOT_READY      => 'Not enough information to send a %s request';
use constant ERROR_IS_IT_READY    => "The request is%s READY to send\n";
use constant ERROR_CAVIRTEX       => COMPANY . " error: '%s'\n";
use constant ERROR_UNKNOWN_STATUS => COMPANY . " returned an unknown status\n";

use constant ATTRIBUTES => qw(token secret);

use constant CLASS_ACTION_MAP => {
   orderbook     => 'Finance::CaVirtex::API::Request::OrderBook',
   tradebook     => 'Finance::CaVirtex::API::Request::TradeBook',
   ticker        => 'Finance::CaVirtex::API::Request::Ticker',
   balance       => 'Finance::CaVirtex::API::Request::Balance',
   transactions  => 'Finance::CaVirtex::API::Request::Transactions',
   trade_history => 'Finance::CaVirtex::API::Request::TradeHistory',
   order_history => 'Finance::CaVirtex::API::Request::OrderHistory',
   order         => 'Finance::CaVirtex::API::Request::Order',
   order_cancel  => 'Finance::CaVirtex::API::Request::OrderCancel',
   withdraw      => 'Finance::CaVirtex::API::Request::Withdraw',
};

sub is_ready_to_send {
    my $self = shift;
    my $ready = 0;
    # here we are checking whether or not to default to '0' (not ready to send) based on this objects settings.
    # the settings in here are the token and the secret provided to you by CaVirtex.
    # if we dont have to add a nonce, then just check if its ready...
    if (not $self->private or defined $self->token && defined $self->secret) {
       $ready = $self->request->is_ready_to_send;
    }
    warn sprintf ERROR_IS_IT_READY, ($ready ? '' : ' NOT') if DEBUG;

    return $ready;
}

sub send {
    my $self = shift;

    # clear any previous response values... because if you wan it, you shoulda put a variable on it.
    $self->response(undef);
    $self->error(undef);
    $self->new_nonce;

    unless ($self->request) {
        $self->error({
            type    => __PACKAGE__,
            message => ERROR_NO_REQUEST,
        });
    }
    else {
        # validate that the minimum required request attributes are set here.
        if (not $self->is_ready_to_send) {
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
            my %query_form = %{$self->request_content};
#
# This block will be removed once we have basic testing completed.
# ...because printing these variables on a live system is not a good idea...
#
#if ($self->private) {
#    print Data::Dumper->Dump([\%query_form],['Query Form']);
#    printf "sorted request values: %s\n", join(', ', $self->sorted_request_values);
#    printf "Nonce: %s\n", $self->nonce;
#    printf "Token: %s\n", $self->token;
#    printf "Path: %s\n", $self->path;
#}
#
            if ($self->private) {
                $query_form{nonce    } = $self->nonce;
                $query_form{token    } = $self->token;
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
   
            $request->header(Accept => 'application/json');

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

    warn sprintf "Content: %s\n", $self->http_response->content if DEBUG;

    my $content;
    eval {
        warn Data::Dumper->Dump([$self->http_response],['Response']) if DEBUG;
        $content = $self->json->decode($self->http_response->content);
        1;
    } or do {
        $content = {};
        warn "error: $@\n";
    };
    if (exists $content->{status}) {
        if (lc $content->{status} eq 'ok') {
            $self->apirate($content->{apirate}) if exists $content->{apirate};
            if ($self->request->data_key) {
                # crutch: there is a call to tradebook that returns the json data keyed on either
                # 'orders' or 'trades'. As a result we have to allow this to be a hash or potential
                # keys to search.
                # once this is standardized on Cavirtex, we will remove these conditions...
                #
                # TODO: watch for such a change and then reduce the code below and change Request/TrasdeBook.pm
                if (ref $self->request->data_key) {
                    foreach my $key (@{$self->request->data_key}) {
                        if (exists $content->{$key}) {
                            $self->response($content->{$key});
                            last;
                        }
                    }
                }
                # end crutch, but also, remove the 'else' below...
                else {
                    $self->response($content->{$self->request->data_key});
                }
            }
            else {
                $self->response($content);
            }
        }
        elsif ($content->{status} eq 'error') {
            warn sprintf ERROR_CAVIRTEX, Dumper $content->{message} if DEBUG;
            $self->error($content->{message});
        }
        else {
            # we got a response but the result was not 'success' and did not contain an 'error' key...
            # note: your code should never get here, so I am forcing a warning and Dump of the content...
            warn ERROR_UNKNOWN_STATUS;
            warn Data::Dumper->Dump([$content],[sprintf 'Invalid %s Response Content', COMPANY]);
            $self->error('unknown status');
        }
    }
    else {
        # we did not get valid content from their server. Assume an unknown HTTP error occurred...
        $self->error({
            type    => __PACKAGE__,
            message => 'no status',
        });
    }
    return $self->is_success;
}


# the code below is only here to explain the code above
sub sorted_request_values { @{$_[0]->request_content}{sort {lc($a) cmp lc($b)} keys $_[0]->request_content} }
#sub sorted_request_values {
    #my $self = shift;
    #my %content = %{$self->request_content};
    #return @content{sort {lc($a) cmp lc($b)} keys %content};
#}

# signature : is a HMAC-SHA256 Hex encoded hash containing the string data input:
# nonce, API token, relative API, request path and alphabetically sorted post parameters. 
# The message must be generated using the Secret Key that was created with your API token.
#sub signature { hmac_sha256_hex(map($_[0]->$_, qw(nonce token path sorted_request_values secret))) }
sub signature {
    my $self = shift;
    return hmac_sha256_hex($self->nonce, $self->token, $self->path, $self->sorted_request_values, $self->secret);
}

sub new_nonce       { shift->nonce(sprintf '%d%06d' => gettimeofday) }
sub path            { URI->new(shift->http_request->uri)->path       }
sub request_content { shift->request->request_content                }
sub json            { shift->{json} ||= JSON->new                    }
sub private         { shift->request->is_private                     }
sub is_success      { defined shift->response                        }
sub public          { not shift->private                             }
sub attributes      { ATTRIBUTES                                     }

# this method makes the action call routines simpler...
sub class_action {
    my $self = shift;
    my $class = CLASS_ACTION_MAP->{((caller(1))[3] =~ /::(\w+)$/)[0]};
    $self->request($class->new(@_));
    return $self->send ? $self->response : undef;
}

sub orderbook     { class_action(@_) }
sub tradebook     { class_action(@_) }
sub ticker        { class_action(@_) }
sub balance       { class_action(@_) }
sub transactions  { class_action(@_) }
sub trade_history { class_action(@_) }
sub order_history { class_action(@_) }
sub order         { class_action(@_) }
sub order_cancel  { class_action(@_) }
sub withdraw      { class_action(@_) }

sub token         { my $self = shift; $self->get_set(@_) }
sub secret        { my $self = shift; $self->get_set(@_) }
sub nonce         { my $self = shift; $self->get_set(@_) }
sub error         { my $self = shift; $self->get_set(@_) }
sub http_response { my $self = shift; $self->get_set(@_) }
sub request       { my $self = shift; $self->get_set(@_) }
sub response      { my $self = shift; $self->get_set(@_) }
sub http_request  { my $self = shift; $self->get_set(@_) }
sub user_agent    { my $self = shift; $self->get_set(@_) }
sub apirate       { my $self = shift; $self->get_set(@_) }

1;

__END__


=head1 NAME

Finance::CaVirtex::API - Perl extension for handling the CaVirtex API and IPN calls.

=head1 SYNOPSIS

  use Finance::CaVirtex::API;

  # all the standard CaVirtex API calls...

  my $cavirtex = Finance::CaVirtex::API->new(token => $token, secret => $secret);

  # access public requests...
  my $ticker = $cavirtex->ticker; 

  # make private requests...
  my $wallet = $cavirtex->wallet;

  # private request with parameters...
  my $withdrawal = $cavirtex->withdrawal(amount => $amount, currency => $currency, address => $address, 

  # access the user agent of the last request...
  my $user_agent = $cavirtex->user_agent;

  # the is_success() and error() methods are also useful...
  if ($cavirtex->is_success) {
      print 'SUCESS';
  }
  else {
      print 'FAIL';
      my $error = $cavirtex->error;
  }


  # A more useful example...
  my $cavirtex  = Finance::CaVirtex::API->new(key => $key, secret => $secret, client_id => $client_id);
  my $order = $cavirtex->order(currencypair => 'USDCAD', mode => 'bid', amount => '4.5', price => '1000.00');

  if ($order) {
      printf "The CaVirtex invoice ID is %s. You can see it here: %s\n", @{$order}{qw(id url)};
  }
  else {
      printf "An error occurred: %s\n", $cavirtex->error;
  }

=head1 DESCRIPTION

This API module provides a quick way to access the CaVirtex API from perl without worrying about
the connection, authenticatino and an errors in between.

You create an object like this:

    my $caviertex = Finance::CaVirtex::API->new(%params);
    # required param keys: token, secret

The methods you call that match the API spec are:

    $cavirtex-> orderbook(%params);
    # required: currencypair

    $cavirtex-> tradebook(%params);
    # required: currencypair
    # optional: days, startdate, enddate

    $cavirtex-> ticker(%params);
    # required: currencypair 

    $cavirtex-> balance(%params);

    $cavirtex-> transactions(%params);
    # required: currencypair
    # optional: days, startdate, enddate

    $cavirtex-> trade_history(%params);
    # required: currencypair
    # optional: days, startdate, enddate

    $cavirtex-> order_history(%params);
    # required: currencypair
    # optional: days, startdate, enddate

    $cavirtex-> order(%params);
    # required: currencypair, mode, amount, price

    $cavirtex-> order_cancel(%params);
    # required: id

    $cavirtex-> withdraw(%params);
    # required: amount, currency, address


=head1 REQUEST PARAMETERS:

    currencypair - a string. "BTCCAD", "LTCCAD", "BTCLTC"

    days - an integer

    startdate, enddate - a date in the format 'YYYY-MM-DD'

    mode -  a string. "buy", "sell"

    amount - a quantity of BTC or LTC as a floating point string (up to 8 decimals)

    price - a string dollar value. (up to 5 decimals)

    id - an order ID.

    currency - a string. "BTC", "LTC"

    address - a BTC or LTC wallet address

=head1 METHODS

=head2 new()

    my $cavirtex = Finance::CaVirtex::API->new(key => $key, secret => $secret, client_id => $client_id);

Create a new Finance::CaVirtex::API object.
key, secret and client_id are required.
These values are provided by Bitstamp through their online administration interface.


=head2 Other Methods

The methods you will use are discussed in the DESCRIPTION. For details on valid parameter values, please consult the offical CaVirtex API documentation.

=head1 ATTRIBUTES

=head2 token(), secret()

These are usually set during object instantiation. But you can set and retrieve them through these attributes.
The last set values will always be used in the next action request. These values are obtained from CaVirtex through your account.

=head2 is_ready()

Will return true if the request is set and all conditions are met.
Will return false if:
- the request object does not exist
- the request object requires authentication and no key is provided
- the request object does not have the manditory parameters set that CaVirtex requires for that request.

=head2 error()

If the request did not work, error() will contain a hash representing the problem. The hash contains the keys: 'type' and 'message'. These are strings. ie:

    print "The error type was: " . $cavirtex->error->{type};
    print "The error message was: " . $cavirtex->error->{message};

=head2 user_agent()

This will contain the user agent of the last request to CaVirtex.
Through this object, you may access both the HTTP Request and Response.
This will allow you to do detailed inspection of exactly what was sent and the raw CaVirtex response.

=head2 request()

This will contain the Request object of the last action called on the object. It is not a HTTP Request, but rather a config file for the request URL, params and other requirements for each post to cavirtex. You will find these modules using the naming Finance::CaVirtex::API::Request::*

=head1 HOWTO DETECT ERRORS

The design is such that the action methods (invoice_create(), invoice_get(), rates() and ledger()) will return false (0) on error.
On success it will contain the hash of information from the CaVirtex JSON response.
Your code should just check whether or not the response exists to see if it worked.
If the response does not exist, then then the module detected a problem.
The simplest way to handle this is to print out $cavirtex->error.
A coding example is provided above in the SYNOPSIS.

=head1 NOTES

This module does not do accessive error checking on the request or the response.
It will only check for "required" parameters prior to sending a request to CaVirtex.
This means that you provide a word for a 'amount' parameter, and this module will happily send that off to CaVirtex for you.
In these cases we are allowing CaVirtex to decide what is and is not valid input.
If the input values are invalid, we expect CaVirtex to provide an appropriate response and that is the message we will return to the caller (through $cavirtex->error).

This module does not validate the response from CaVirtex.
In general it will return success when any json response is provided by Bitstamp without the 'error' key.
The SSL certificate is verified automatically by LWP, so the response you will get is very likely from CaVirtex itself.
If there is an 'error' key in the json response, then that error is put into the $cavirtex->error attribute.
If there is an 'error' parsing the response from CaVirtex, then the decoding error from json is in the $cavirtex->error attribute.
If there is a network error (not 200), then the error code and $response->error will contain the HTTP Response status_line() (a string response of what went wrong).

=head1 SEE ALSO

The CaVirtex API documentation: unknown (2014-06-11). contact Cavirtex.
This project on Github: https://github.com/peawormsworth/Finance-CaVirtex-API

=head1 AUTHOR

Jeff Anderson, E<lt>peawormsworth@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jeff Anderson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

