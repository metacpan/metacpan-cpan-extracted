package Finance::BitPay::API;

use 5.014002;
use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Finance::BitPay::DefaultPackage);

use constant DEBUG => 0;

# you can use a lower version, but then you are responsible for SSL cert verification code...
use LWP::UserAgent 6;
use URI;
use JSON;
use Data::Dumper;

# Account...
use Finance::BitPay::API::Request::InvoiceCreate;
use Finance::BitPay::API::Request::InvoiceGet;
use Finance::BitPay::API::Request::Rates;
use Finance::BitPay::API::Request::Ledger;

use constant COMPANY          => 'BitPay';
use constant ATTRIBUTES       => qw(key);
use constant ERROR_NO_REQUEST => 'No request object to send';
use constant ERROR_NOT_READY  => 'Not enough information to send a %s request';
use constant ERROR_READY      => 'The request IS%s READY to send';
use constant ERROR_BITPAY     => COMPANY . ' error: "%s"';
use constant ERROR_UNKNOWN    => COMPANY . ' returned an unknown status';

use constant CLASS_ACTION_MAP => {
    invoice_create => 'Finance::BitPay::API::Request::InvoiceCreate',
    invoice_get    => 'Finance::BitPay::API::Request::InvoiceGet',
    rates          => 'Finance::BitPay::API::Request::Rates',
    ledger         => 'Finance::BitPay::API::Request::Ledger',
};

sub is_ready {
    my $self = shift;
    my $ready = 0;
    # here we are checking whether or not to default to '0' (not ready to send) based on this objects settings.
    # the secret is required if the request is private to BitPay.
    if (not $self->request->is_private or defined $self->key) {
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
        unless ($self->is_ready) {
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
            my $uri = URI->new;
            $uri->query_form($self->request->request_content);
            if ($self->request->request_type eq 'POST') {
                $request->content($uri->query);
                $request->content_type($self->request->content_type);
            }
            elsif ($self->request->request_type eq 'GET' and $uri->query) {
                $request->uri($request->uri . '?' . $uri->query);
            }
            $request->header('Accept'   => 'application/json');
            $request->authorization_basic($self->key => undef) if $self->request->is_private;
            #$self->user_agent->default_header(Basic => $self->key) if $self->request->is_private;

            # create a new user_agent each time...
            $self->user_agent(LWP::UserAgent->new);
            $self->user_agent->agent('Perl Finance::BitPay::API');
            $self->user_agent->ssl_opts(verify_hostname => 1);

            warn Data::Dumper->Dump([$self->user_agent, $request],[qw(UserAgent Request)]) if DEBUG;

# if the request has authentication errors... like bad SSL cert, would this die?
# should we encase this in an eval???
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

# We should really check for network errors here...

# This logic does not look so nice, its probably simpler...
    my $content;
    my $error_msg;
    eval {
        warn Data::Dumper->Dump([$self->http_response],['Response'])  if DEBUG;
        $content = $self->json->decode($self->http_response->content);
        1;
    } or do {
        $self->error("Network Request (REST/JSON) error: $@");
        warn $self->error . "\n";
        warn sprintf "Content was: %s\n", $self->http_response->content;
    };

    unless ($self->error) {
        if (ref $content eq 'HASH' and exists $content->{error}) {
            warn sprintf(ERROR_BITPAY, $content->{error}) . "\n";
            $self->error($content->{error});
        }
        else {
            $self->response($content);
        }
    }
# end bad logic...

    return $self->is_success;
}

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

sub invoice_create { _class_action(@_) }
sub invoice_get    { _class_action(@_) }
sub rates          { _class_action(@_) }
sub ledger         { _class_action(@_) }

sub key           { my $self = shift; $self->get_set(@_) }
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

Finance::BitPay::API - Perl extension for handling the BitPay API and IPN calls.

=head1 SYNOPSIS

  use Finance::BitPay::API;

  # all the standard BitPay API calls...

  my $bitpay  = Finance::BitPay::API->new(key => 'abc123');
  my $invoice = $bitpay->invoice_create(currency => 'EUR', price => '9.99');
  my $invoice = $bitpay->invoice_get(id => $id);
  my $rates   = $bitpay->rates;
  my $ledger  = $bitpay->ledger(c => 'USD', startDate => '2014-01-01, endDate => '2014-01-10');

  # The bitpay object contains all the request data from the last request...

  my $user_agent = $bitpay->user_agent;

  if ($bitpay->success) {
      print 'SUCESS';
  }
  else {
      print 'FAIL';
      my $error = $bitpay->error;
  }


  # A more useful example...

  my $bitpay  = Finance::BitPay::API->new(key => 'YOUR API KEY GOES HERE');
  my $invoice = $bitpay->invoice_create(currency => 'EUR', price => '9.99');

  if ($invoice) {
      printf "The BitPay invoice ID is %s. You can see it here: %s\n", @{$invoice}{qw(id url)};
  }
  else {
      printf "An error occurred: %s\n", $bitpay->error;
  }

=head1 DESCRIPTION

This API module provides a quick way to access the BitPay API from perl without worrying about
the connection, authenticatino and an errors in between.

You call these on the API object created like this:

  my $bitpay = Finance::BitPay::API->new(key => 'YOUR_KEY';

...Where 'YOUR_KEY' is the text key provided to you by BitPay through their merchant interface

The primary methods are:

  invoice_create(), invoice_get(), rates() and ledger()

The return value is a hash representing the BitPay response.

  my $response_as_a_hash = $bitpay->invoice_create(currency => $cur, price => $price);

The return value will be undefined when an error occurs...

  if ($bitpay->is_success) {
      # the last primary method call worked!
  }
  else {
      print "There was an error: " . $bitpay->error;
      # more detail can be found in the bitpay object using...
      my $ua           = $bitpay->user_agent;
      my $raw_request  = $bitpay->http_request;
      my $raw_response = $bitpay->http_response;
      # further inspection could go here (like dumping the content of the useragent)
  }
  

=head1 METHODS

=head2 new()

Create a new Finance::BitPay::API object.

=head2 invoice_create()

Request a new invoice from BitPay. 
The input is a hash with keys: 

    price and currency.

Additionally optional input settings:

IPN fields:

    posData, notificationURL, transactionSpeed, fullNotifications, notificationEmail

Order handling:

    redirectURL

Buyer information:

    orderID, itemDesc, itemCode, physical, buyerName, buyerAddress1, buyerAddress2, buyerCity, buyerState, buyerZip, buyerCountry, buyerEmail, buyerPhone

The invoice is generated like this:

    my $invoice = $bitpay->invoice_create(currency => 'CAD', price => '5.99', buyerName => 'Prime Minister');

=head2 invoice_get()

Get the current state of an invoice, given its invoice Id.

    my $invoice = $bitpay->invoice_get(id => 'YOUR_INVOICE_ID');

=head2 rates()

Get the current rates by currency...

    my $rates = $bitpay->rates;

=head2 ledger()

I cannot explain what this does...

    my $ledger = $bitpay->ledger(c => $currency, startDate => $start_date, endDate => $end_date);

=head1 NOTES

This module does not do accessive error checking on the request or the response.
It will only check for "required" parameters prior to sending a request to BitPay.
This means that you provide a word for a 'amount' parameter, and this module will happily send that off to BitPay for you.
In these cases we are allowing BitPay to decide what is and is not valid input.
If the input values are invalid, we expect BitPay to provide an appropriate response and that is the message we will return to the caller (through $bitpay->error).

This module does not validate the response from BitPay.
In general it will return success when any json response is provided by Bitpay without the 'error' key.
The SSL certificate is verified automatically by LWP, so the response you will get is very likely from BitPay itself.
If there is an 'error' key in the json response, then that error is put into the $bitpay->error attribute.
If there is an 'error' parsing the response from BitPay, then the decoding error from json is in the $bitpay->error attribute.
If there is a network error (not 200), then the error code and $response->error will contain the HTTP Response status_line() (a string response of what went wrong).

=head1 SEE ALSO

The BitPay API documentation: https://bitpay.com/downloads/bitpayApi.pdf

=head1 AUTHOR

Jeff Anderson, E<lt>peawormsworth@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jeff Anderson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
