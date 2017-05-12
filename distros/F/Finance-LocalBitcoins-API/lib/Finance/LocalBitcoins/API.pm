package Finance::LocalBitcoins::API;

use 5.014002;
use strict;
use warnings;

our $VERSION = '0.01';

use constant DEBUG   => 0;
use constant VERBOSE => 0;

# you can use a lower version, but then you are responsible for SSL cert verification code...
use LWP::UserAgent 6;
use URI;
use JSON;
use Data::Dumper;

## PUBLIC requests..
use Finance::LocalBitcoins::API::Request::Ticker;
use Finance::LocalBitcoins::API::Request::TradeBook;
use Finance::LocalBitcoins::API::Request::OrderBook;

# PRIVATE requests..
use Finance::LocalBitcoins::API::Request::User;
use Finance::LocalBitcoins::API::Request::Me;
use Finance::LocalBitcoins::API::Request::Pin;
use Finance::LocalBitcoins::API::Request::Dash;
use Finance::LocalBitcoins::API::Request::Wallet;
use Finance::LocalBitcoins::API::Request::Balance;
use Finance::LocalBitcoins::API::Request::ReleaseEscrow;
use Finance::LocalBitcoins::API::Request::Paid;
use Finance::LocalBitcoins::API::Request::Messages;
use Finance::LocalBitcoins::API::Request::Message;
use Finance::LocalBitcoins::API::Request::Dispute;
use Finance::LocalBitcoins::API::Request::Cancel;
use Finance::LocalBitcoins::API::Request::Fund;
use Finance::LocalBitcoins::API::Request::NewContact;
use Finance::LocalBitcoins::API::Request::Contact;
use Finance::LocalBitcoins::API::Request::Contacts;
use Finance::LocalBitcoins::API::Request::Send;
use Finance::LocalBitcoins::API::Request::SendPin;
use Finance::LocalBitcoins::API::Request::Address;
use Finance::LocalBitcoins::API::Request::Logout;
use Finance::LocalBitcoins::API::Request::Ads;
use Finance::LocalBitcoins::API::Request::AdGet;
use Finance::LocalBitcoins::API::Request::AdsGet;
use Finance::LocalBitcoins::API::Request::AdUpdate;
use Finance::LocalBitcoins::API::Request::Ad;
 
use constant COMPANY              => 'LocalBitcoins';
use constant ERROR_NO_REQUEST     => 'No request object to send';
use constant ERROR_NOT_READY      => 'Not enough information to send a %s request';
use constant ERROR_IS_IT_READY    => "The request is%s READY to send\n";
use constant ERROR_RESPONSE       => COMPANY . ' error';
use constant ERROR_UNKNOWN_STATUS => COMPANY . " returned an unknown status\n";

use constant ATTRIBUTES => qw(token);

use constant CLASS_ACTION_MAP => {
    user           => 'Finance::LocalBitcoins::API::Request::User',
    me             => 'Finance::LocalBitcoins::API::Request::Me',
    pin            => 'Finance::LocalBitcoins::API::Request::Pin',
    dash           => 'Finance::LocalBitcoins::API::Request::Dash',
    release_escrow => 'Finance::LocalBitcoins::API::Request::ReleaseEscrow',
    paid           => 'Finance::LocalBitcoins::API::Request::Paid',
    messages       => 'Finance::LocalBitcoins::API::Request::Messages',
    message        => 'Finance::LocalBitcoins::API::Request::Message',
    dispute        => 'Finance::LocalBitcoins::API::Request::Dispute',
    cancel         => 'Finance::LocalBitcoins::API::Request::Cancel',
    fund           => 'Finance::LocalBitcoins::API::Request::Fund',
    new_contact    => 'Finance::LocalBitcoins::API::Request::NewContact',
    contact        => 'Finance::LocalBitcoins::API::Request::Contact',
    contacts       => 'Finance::LocalBitcoins::API::Request::Contacts',
    wallet         => 'Finance::LocalBitcoins::API::Request::Wallet',
    balance        => 'Finance::LocalBitcoins::API::Request::Balance',
    'send'         => 'Finance::LocalBitcoins::API::Request::Send',
    sendpin        => 'Finance::LocalBitcoins::API::Request::SendPin',
    address        => 'Finance::LocalBitcoins::API::Request::Address',
    logout         => 'Finance::LocalBitcoins::API::Request::Logout',
    ads            => 'Finance::LocalBitcoins::API::Request::Ads',
    ad_get         => 'Finance::LocalBitcoins::API::Request::AdGet',
    ads_get        => 'Finance::LocalBitcoins::API::Request::AdsGet',
    ad_update      => 'Finance::LocalBitcoins::API::Request::AdUpdate',
    ad             => 'Finance::LocalBitcoins::API::Request::Ad',
    ticker         => 'Finance::LocalBitcoins::API::Request::Ticker',
    tradebook      => 'Finance::LocalBitcoins::API::Request::TradeBook',
    orderbook      => 'Finance::LocalBitcoins::API::Request::OrderBook',
};

sub is_ready_to_send {
    my $self = shift;
    my $ready = 0;
    # here we are checking whether or not to default to '0' (not ready to send) based on this objects settings.
    # the setting in here is the token provided to you by LocalBitcoins.
    # if we dont have to add a token, then just check if its ready...
    if (not $self->private or defined $self->token) {
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
#    printf "Token: %s\n", $self->token;
#    printf "Path: %s\n", $self->path;
#}
#
            if ($self->private) {
                $query_form{access_token} = $self->token;
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

    eval {
        my $content;
        warn Data::Dumper->Dump([$self->http_response],['Response']) if DEBUG;
        $content = $self->json->decode($self->http_response->content);
        if (ref $content eq 'ARRAY') {
            $self->response($content);
        }
        elsif (exists $content->{error}) {
            $self->error({
                type    => ERROR_RESPONSE,
                %{$content->{error}},
            });
        }
        elsif ($self->http_response->code != 200) {
            warn sprintf "Invalid Server Response Code: %s\n", $self->http_response->code if VERBOSE;
            $self->error({
                type    => 'Server Response Error',
                message => sprintf('%s Server Response: %s', COMPANY, $self->http_response->code),
            });
        }
        else {
            $self->response($content);
        }
        1;
    } or do {
        warn "eval error: $@\n";
        $self->error({
            type    => 'eval/json error',
            message => $@,
        });
    };

    return $self->is_success;
}

sub new             { (bless {} => shift)->init(@_)                  }
sub path            { URI->new(shift->http_request->uri)->path       }
sub request_content { shift->request->request_content                }
sub json            { shift->{json} ||= JSON->new                    }
sub is_success      { defined shift->response                        }
sub private         { shift->request->is_private                     }
sub public          { not shift->private                             }
sub attributes      { ATTRIBUTES                                     }

sub user            { class_action(@_) }
sub me              { class_action(@_) }
sub pin             { class_action(@_) }
sub dash            { class_action(@_) }
sub release_escrow  { class_action(@_) }
sub paid            { class_action(@_) }
sub messages        { class_action(@_) }
sub message         { class_action(@_) }
sub dispute         { class_action(@_) }
sub cancel          { class_action(@_) }
sub fund            { class_action(@_) }
sub new_contact     { class_action(@_) }
sub contact         { class_action(@_) }
sub contacts        { class_action(@_) }
sub wallet          { class_action(@_) }
sub balance         { class_action(@_) }
sub send_coin       { class_action(@_) }
sub send_pin        { class_action(@_) }
sub address         { class_action(@_) }
sub logout          { class_action(@_) }
sub ads             { class_action(@_) }
sub ad_get          { class_action(@_) }
sub ads_get         { class_action(@_) }
sub ad_update       { class_action(@_) }
sub ad              { class_action(@_) }
sub ticker          { class_action(@_) }
sub tradebook       { class_action(@_) }
sub orderbook       { class_action(@_) }

sub token           { get_set(@_) }
sub error           { get_set(@_) }
sub http_response   { get_set(@_) }
sub request         { get_set(@_) }
sub response        { get_set(@_) }
sub http_request    { get_set(@_) }
sub user_agent      { get_set(@_) }

sub init {
    my $self = shift;
    my %args = @_;
    foreach my $attribute ($self->attributes) {
        $self->$attribute($args{$attribute}) if exists $args{$attribute};
    }
    return $self;
}

# this method simply makes all the get/setter attribute methods below very tidy...
sub get_set {
   my $self      = shift;
   my $attribute = ((caller(1))[3] =~ /::(\w+)$/)[0];
   $self->{$attribute} = shift if scalar @_;
   return $self->{$attribute};
}

sub class_action {
    my $self = shift;
    my $class = CLASS_ACTION_MAP->{((caller(1))[3] =~ /::(\w+)$/)[0]};
    $self->request($class->new(@_));
    return $self->send ? $self->response : undef;
}

# These additional routines will allow you to easily encrypt your API secret using a similar but random text string as a key.
# Generate and store a random string of 40 hex chars in your script.
#   perl -e 'use Finance::CaVirtex::API qw(string_encrypt); print "Encrypted: %s\n", string_encrypt('put your token here', $random_key);
# to output the cyphertext of the real secret encrypted using your key.
# Your script should then load the cyphertext from an external file and call this:
#   my $api_secret = string_decrypt($cyphertext, $random_key);
# Since both the random_key and the cyphertext are in separate files, a breach would require both files to be compromised.
# If you also put the token into a database table that is accessed during runtime... then you are further protected.
# This setup would require 3 distinct components which would all need to be compromised to gain unwanted access to your API keys and functions.
#
# From the command line, you can generate a set of semi-random strings that should be good enough for this using:
#  perl -e 'print join("",("a".."z",0..9)[map rand$_,(36) x 22])."\n"for 1..20;'
#
# select one of those as your random_key.
#

# encryption works by assigning an ordinal value to each character '0' = 0 ... 'Z' = 35
# these values are then added for each character in the cypher and the random key.
# the modulus of the sum is then taken to remain within the 36 available characters.
# this number is then converted back to character.
# once each character of the string is calculated, the complete cyphertext is generated.
#
# the end result is that we are adding the secret string to the random key string to obtain the cyphertext:
#    Cypher = Secret + Key
#
# decryption is exactly like encryption except we take the difference of each character
# instead of the sum. 
#
# the end result is thatIn this way we are subtracting the random key from the cyphertext to get back the secret string.
#    Secret = Cypher - Key
#
# I believe this method is equivalent to XOR encryption, which is very strong as long as the key is random and kept secret.
#
sub alphanum_to_digit { ord($_[0]) > 57 ? ord($_[0]) - 87 : ord($_[0]) - 48  }
sub digit_to_alphanum { chr($_[0]  >  9 ?     $_[0]  + 87 :     $_[0]  + 48) }
sub string_encrypt    { join '', map(digit_to_alphanum((alphanum_to_digit(substr $_[0], $_, 1) + alphanum_to_digit(substr $_[1], $_, 1)) % 36), 0 .. length($_[0]) - 1) }
sub string_decrypt    { join '', map(digit_to_alphanum((alphanum_to_digit(substr $_[0], $_, 1) - alphanum_to_digit(substr $_[1], $_, 1)) % 36), 0 .. length($_[0]) - 1) }
sub gen_random_key    { join("",("a".."f",0..9)[map rand$_,(16) x 40]) }


1;

__END__


=head1 NAME

Finance::LocalBitcoins::API - Perl extension for handling the LocalBitcoins API and IPN calls.

=head1 SYNOPSIS

  use Finance::LocalBitcoins::API;

  # all the standard LocalBitcoins API calls...

  my $api = Finance::LocalBitcoins::API->new(token => $token);

  # access public requests...
  my $ticker = $api->ticker; 

  # make private requests...
  my $wallet = $api->wallet;

  # private request with parameters...
  my $withdrawal = $api->withdrawal(amount => $amount, currency => $currency, address => $address, 

  # access the user agent of the last request...
  my $user_agent = $api->user_agent;

  # the is_success() and error() methods are also useful...
  if ($api->is_success) {
      print 'SUCESS';
  }
  else {
      print 'FAIL';
      my $error = $api->error;
  }


  # A more useful example...
  my $api  = Finance::LocalBitcoins::API->new(token => $token);
  my $contacts = $api->get_contacts();

  if ($contacts) {
      printf "You have %d contacts\n", scalar @$contacts;
  }
  else {
      printf "An error occurred: %s\n", $api->error;
  }

=head1 DESCRIPTION

This API module provides a quick way to access the LocalBitcoins API from perl without worrying about
the connection, authenticatino and an errors in between.

You create an object like this:

    my $api = Finance::LocalBitcoins::API->new(%params);
    # required param keys: token

The methods you call that match the API spec are:

    $api->orderbook(%params);
    # required: currency

    $api->tradebook(%params);
    # required: currency
    # optional: since

    $api->ticker();
    # a ticker for all currencies

    ...etc...

=head1 REQUEST PARAMETERS:

    currency - a string. "CAD", "USD", "GBP", "EUR", etc.

    since - a date in the format 'YYYY-MM-DD'

    ...etc...

=head1 METHODS

=head2 new()

    my $api = Finance::LocalBitcoins::API->new(token => $token);

Create a new Finance::LocalBitcoins::API object.
token is required.
These values are provided by LocalBitcoins through their online administration interface.


=head2 Other Methods

The methods you will use are discussed in the DESCRIPTION. For details on valid parameter values, please consult the offical LocalBitcoins API documentation.

=head1 ATTRIBUTES

=head2 token()

These are usually set during object instantiation. But you can set and retrieve them through these attributes.
The last set values will always be used in the next action request. These values are obtained from LocalLocalBitcoinsBitcoins through your account.

=head2 is_ready()

Will return true if the request is set and all conditions are met.
Will return false if:
- the request object does not exist
- the request object requires authentication and no key is provided
- the request object does not have the manditory parameters set that LocalBitcoins requires for that request.

=head2 error()

If the request did not work, error() will contain a hash representing the problem. The hash contains the keys: 'type' and 'message'. These are strings. ie:

    print "The error type was: " . $api->error->{type};
    print "The error message was: " . $api->error->{message};

=head2 user_agent()

This will contain the user agent of the last request to LocalBitcoins.
Through this object, you may access both the HTTP Request and Response.
This will allow you to do detailed inspection of exactly what was sent and the raw LocalBitcoins response.

=head2 request()

This will contain the Request object of the last action called on the object. It is not a HTTP Request, but rather a config file for the request URL, params and other requirements for each post to localbitcoins. You will find these modules using the naming Finance::LocalBitcoins::API::Request::*

=head1 HOWTO DETECT ERRORS

The design is such that the action methods (invoice_create(), invoice_get(), rates() and ledger()) will return false (0) on error.
On success it will contain the hash of information from the LocalBitcoins JSON response.
Your code should just check whether or not the response exists to see if it worked.
If the response does not exist, then then the module detected a problem.
The simplest way to handle this is to print out $api->error.
A coding example is provided above in the SYNOPSIS.

=head1 NOTES

This module does not do accessive error checking on the request or the response.
It will only check for "required" parameters prior to sending a request to LocalBitcoins.
This means that you provide a word for a 'amount' parameter, and this module will happily send that off to LocalBitcoins for you.
In these cases we are allowing LocalBitcoins to decide what is and is not valid input.
If the input values are invalid, we expect LocalBitcoins to provide an appropriate response and that is the message we will return to the caller (through $api->error).

This module does not validate the response from LocalBitcoins.
In general it will return success when any json response is provided by LocalBitcoins without the 'error' key.
The SSL certificate is verified automatically by LWP, so the response you will get is very likely from LocalBitcoins itself.
If there is an 'error' key in the json response, then that error is put into the $api->error attribute.
If there is an 'error' parsing the response from LocalBitcoins, then the decoding error from json is in the $api->error attribute.
If there is a network error (not 200), then the error code and $response->error will contain the HTTP Response status_line() (a string response of what went wrong).

=head1 SEE ALSO

The LocalBitcoins API documentation: unknown (2014-06-11). contact Cavirtex.
This project on Github: https://github.com/peawormsworth/Finance-LocalBitcoins-API

=head1 AUTHOR

Jeff Anderson, E<lt>peawormsworth@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jeff Anderson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

