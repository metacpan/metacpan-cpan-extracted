package HTTP::Any;

our $VERSION = '1.05';

1;

__END__

=head1 NAME

HTTP::Any - a common interface for HTTP clients (LWP, AnyEvent::HTTP, Curl)

=head1 SYNOPSIS

 use HTTP::Any::...
 use ...

 sub do_http {
 	...
 	HTTP::Any::...
 }

 my $opt = { ... };

 my $cb = sub {
 	my ($is_success, $body, $headers, $redirects) = @_;
 	...
 }

 do_http($url, $opt, $cb);

 or

 my ($is_success, $body, $headers, $redirects) = do_http($url, $opt);


=head1 MOTIVATION

LWP, AnyEvent::HTTP, Curl - each of them has its advantages, disadvantages and peculiarities. The HTTP::Any modules were created during the process of investigation of the strong and weak sides of those above-mentioned HTTP clients. They allow quick switching between them to use the best one for each definite case.

If you only need  Net::Curl then see it L<HTTP::Curl>

=head1 DESCRIPTION

=head2 IMPORT

I recommend placing using HTTP::Any in a separate module which should be used from any point of your project.

Why would not make a simple one-line connection? Because of better flexibility and an option to replace the modules used. For example, using LWP::RobotUA instead for LWP::UserAgent.

=head3 LWP

 use LWP;
 use HTTP::Any::LWP;
 sub do_http {
 	my $ua = LWP::UserAgent->new;
 	HTTP::Any::LWP::do_http($ua, @_);
 }

 or

 my ($is_success, $body, $headers, $redirects) = HTTP::Any::LWP::do_http($ua, $url, $opt);

=head3 AnyEvent

 use EV;
 use AnyEvent::HTTP;
 use HTTP::Any::AnyEvent;
 sub do_http {
 	HTTP::Any::AnyEvent::do_http(\&http_request, @_);
 }

=head3 Curl

 use Net::Curl::Easy;
 use HTTP::Any::Curl;
 sub do_http {
 	my ($url, $opt, $cb) = @_;
 	my $easy = Net::Curl::Easy->new();
 	HTTP::Any::Curl::do_http(undef, $easy, $url, $opt, $cb);
 }

 or

 my ($is_success, $body, $headers, $redirects) = HTTP::Any::Curl::do_http($easy, $url, $opt);

=head3 Curl with Multi

 use Net::Curl::Easy;
 use Net::Curl::Multi;
 use Net::Curl::Multi::EV;
 use HTTP::Any::Curl;
 my $multi = Net::Curl::Multi->new();
 my $curl_ev = Net::Curl::Multi::EV::curl_ev($multi);
 sub do_http {
 	my ($url, $opt, $cb) = @_;
 	my $easy = Net::Curl::Easy->new();
 	HTTP::Any::Curl::do_http($curl_ev, $easy, $url, $opt, $cb);
 }

=head2 CALL

 # Callback API

 my $opt = { ... };

 my $cb = sub {
 	my ($is_success, $body, $headers, $redirects) = @_;
 	...
 }

 do_http($url, $opt, $cb);


 # Return API

 my ($is_success, $body, $headers, $redirects) = do_http($url, $opt);

where:

=over

=item url

URL as string

=item opt

options and headers

=item cb

callback function to get result

=back

=head3 options

=over

=item referer

Referer url

=item agent

User agent name

=item timeout

Timeout, seconds

=item compressed

This option adds 'Accept-Encoding' header to the HTTP query and tells that the response must be decoded.
If you don't want to decode the response, please add 'Accept-Encoding' header into the 'headers' parameter.

=item headers

Ref on HASH of HTTP headers:

 {
   'Accept' => '*/*',
    ...
 }

=item cookie

It enables cookies support. The "" values enables the session cookies support without saving them.
Any other value is transferred as is: ref to a hash (LWP, AnyEvent::HTTP), the file's name (Curl).

=item persistent

1 or 0. Try to create/reuse a persistent connection.
When not specified, see the default behavior of Curl (reverse of CURLOPT_FORBID_REUSE) and AnyEvent::HTTP (persistent)

=item proxy

http and socks proxy

 proxy => "$host:$port"
 or
 proxy => "$scheme://$host:$port"
 where scheme can be one of the: http, socks (socks5), socks5, socks4.

Install LWP::Protocol::socks to use socks proxy with LWP.

Use AnyEvent::HTTP::Socks instead AnyEvent::HTTP for socks proxy.

=item max_size

The size limit for response content, bytes.

Note: when you use the accept_encoding and max_size options will be triggered, the current mode is the following:
HTTP::Any::Curl - will return the result partially, HTTP::Any::LWP - will return "", HTTP::Any::AnyEvent - will return "".

However, this state can be changed in future.

When max_size options will be triggered, 'client-aborted' header will added with 'max_size' value.

Atention, when max_size is used with compressed, then the size is calculated differently: Curl - uncompressed, AnyEvent and LWP compressed.

=item max_redirect

The limit of how many times it will obey redirection responses in a given request cycle.

By default, the value is 7.

=item body

Data for POST method.

String or CODE ref to return strings (return undef is end of body data).

N.B. CODE ref is not supported for AnyEvent::HTTP (v2.21).

=item method

When method parameter is "POST", the POST request is used with body parameter on data and 'Content-Type' header is added with 'application/x-www-form-urlencoded' value.

=back

=head3 finish callback function

 my $cb = sub {
 	my ($is_success, $body, $headers, $redirects) = @_;
 	...
 };

where:

=over

=item is_success

It is true, when HTTP code is 2XX.

=item body

HTML body. When on_header callback function is defined, then body is undef.

=item headers

Ref on HASH of HTTP headers (lowercase) and others info: Status, Reason, URL

=item redirects

Previous headers from last to first

=back

=head3 on_header callback function

When specified, this callback will be called after getting all headers.

 $opt{on_header} = sub {
 	my ($is_success, $headers, $redirects) = @_;
 	...
 };

=head3 on_body callback function

When specified, this callback will be called on each chunk.

 $opt{on_body} = sub {
 	my ($body) = @_; # body chunk
 	...
 };


=head1 NOTES

Turn off the persistent options to download pages of many sites.

Use libcurl with "Asynchronous DNS resolution via c-ares".

=head1 AUTHOR

Nick Kostyria <kni@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Nick Kostyria

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Net::Curl>
L<AnyEvent::HTTP>
L<LWP>

L<Net::Curl::Multi::EV>

L<HTTP::Curl>

=cut
