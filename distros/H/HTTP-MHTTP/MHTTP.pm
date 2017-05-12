package HTTP::MHTTP;
use strict;
require 5.005;
use Carp;
require DynaLoader;
require Exporter;
use MIME::Base64 qw(encode_base64);
use vars qw(@ISA $VERSION @EXPORT_OK);
$VERSION = '0.15';
@ISA = qw(DynaLoader Exporter);


sub dl_load_flags { 0x01 }
HTTP::MHTTP->bootstrap($VERSION);


#  the supported request headers
  my $headers = {
                   'Accept-Encoding' => '0',
                   'Accept-Language' => '1',
                   'Connection'      => '2',
                   'Cookie'          => '3',
                   'Host'            => '4',
                   'User-Agent'      => '5',
                   'Authorization'   => '6',
                   'Accept'          => '7',
                   'SOAPAction'      => '8',
                   'Content-Type'    => '9',
                   'Cache-control'   => '10',
                   'Cache-Control'   => '10',
                   'Accept-Charset'  => '11',
                   'Pragma'          => '12',
                   'Referrer'        => '13',
                   'Referer'         => '13',
                   'Keep-Alive'      => '14',
                   'If-Modified-Since' => '15',
                   'Content-type'    => '16',
		 };



=head1 NAME

HTTP::MHTTP - this library provides reasonably low level access to the HTTP protocol, for perl.  This does not replace LWP (what possibly could :-) but is a cut for speed.
It also supports all of HTTP 1.0, so you have GET, POST, PUT, HEAD, and DELETE.
Some support of HTTP 1.1 is available - sepcifically Transfer-Encoding = chunked and the Keep-Alive extensions.

Additionally - rudimentary SSL support can be compiled in.  This effectively enables negotiation of TLS, but does not validate the certificates.


=head1 SYNOPSIS

 use HTTP::MHTTP;
 
 http_init();
 
 http_add_headers(
               'User-Agent' => 'DVSGHTTP1/1',
               'Accept-Language' => 'en-gb',
               'Connection' => 'Keep-Alive',
                   );
 if (http_call("GET", "http://localhost")){
   if (http_status() == 200 ){
     print http_response();
   } else {
     print "MSG: ".http_reason();
   }
 } else {
   print "call failed \n";
 }


=head1 DESCRIPTION

A way faster http access library that uses C extension based on mhttp
to do the calls.

=head2 http_init()

initialise the mhttp library - must be called once to reset all internals,
use http_reset() if you don't need to reset your headers before the next call.


=head2 http_set_protocol()

  http_set_protocol(1);  # now operating in HTTP 1.1 mode

Set the protocol level to use - either HTTP 1.0 or 1.1 by passing 0 or 1 - 
the default is 0 (HTTP 1.0).


=head2 http_reset()

reset the library internals for everything except the headers specified 
previously, and the debug switch.  Call http_init() if you need to reset
everything.


=head2 switch_debug()

  switch_debug(<0 || 1>)

Toggle the internal debugging on and off by passing either > 1 or 0.


=head2 http_add_headers()

  http_add_headers(
                 'User-Agent' => 'HTTP-MHTTP1/0',
                 'Host' => 'localhost',
                 'Accept-Language' => 'en-gb',
                );

pass in header/value pairs that will be set on the next http_call().


=head2 http_body()

  http_body("this is the body");

Set the body of the next request via http_call().


=head2 http_call()

  my $rc = http_call("GET", "http://localhost");

Do an http request.  Returns either < 0 or 1 depending on whether the call was 
successful - remember to still check the http_status() code though.

Value < 0 are:
        -1 : an invalid action (HTTP verb) was supplied
        -2 : must supply an action (HTTP verb)
        -3 : must supply a url
        -4 : url must start with http:// or https://
        -5 : write of headers to socket failed
        -6 : write of data to socket was short
        -7 : failed to write last line to socket
        -8 : something wrong with the Conent-Length header
       -11 : SSL_CTX_new failed - abort everything
       -12 : SSL_new failed - abort everything
       -13 : SSL_connect failed - abort everything
       -14 : SSL_get_peer_certificate failed - abort everything
       -15 : X509_get_subject_name failed - abort everything
       -16 : X509_get_issuer_name failed - abort everything
       -17 : cant find the next chunk for Transfer-encoding
       -18 : cant find end headers
       -19 : You must supply a Host header for HTTP/1.1


=head2 http_status()

Returns the last status code.


=head2 http_reason()

Returns the last reason code.


=head2 http_headers()

Returns the headers of the last call, as a single string.


=head2 http_split_headers()

Returns the split out array ref of array ref header value pairs of the last call. 
[ [ hdr, val], [hdr, val] ... ]


=head2 http_response_length()

Returns the length of the body of the last call.


=head2 http_response()

Returns the body of the last call.


=head2 basic_authorization()

  my $pass = basic_authorization($user, $password);

Construct the basic authorization value to be passed in an "Authorization"
header.


=head1 COPYRIGHT

Copyright (c) 2003, Piers Harding. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 AUTHOR

Piers Harding, piers@ompa.net.


=head1 SEE ALSO

perl(1)

=cut


# export the open command, and initialise http::mhttp
my @export_ok = ("http_reset", "http_init", "http_add_headers", "http_status", "http_reason", "http_call", "http_headers", "http_split_headers", "http_body", "http_response", "basic_authorization", "switch_debug", "http_response_length", "http_set_protocol" );
sub import {

  my ( $caller ) = caller;

  my ($me, $debug) = @_;

  no strict 'refs';
  foreach my $sub ( @export_ok ){
    *{"${caller}::${sub}"} = \&{$sub};
  }

}


sub http_add_headers {
  my $hdrs = { @_ };
  foreach my $header ( keys %$hdrs ){
    if ( exists $headers->{$header} ){
      add_header($header.": ".$hdrs->{$header});
    } else {
      warn "Invalid header specified: $header - $hdrs->{$header} \n";
    }
  }
}


sub http_split_headers {

  my $headers = [];
  foreach my $h (split(/\n/,http_headers())){
    next unless $h =~ /:/;
    my ($hdr,$val) = $h =~ /^(.*?):\s(.*?)$/;
    $val =~ s/[\n\r]//g;
    push (@$headers, [$hdr, $val]);
    #$headers->{$hdr} = $val;
  }
  return $headers;

}


sub basic_authorization{
  my ( $user, $passwd ) = @_;
  return "Basic ".encode_base64( $user.':'.$passwd, "" );
}

1;
