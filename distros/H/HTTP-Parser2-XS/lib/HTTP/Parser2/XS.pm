package HTTP::Parser2::XS;

use strict;
use warnings;

require Exporter;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(
    parse_http_request
    parse_http_response
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('HTTP::Parser2::XS', $VERSION);


1;
__END__

=head1 NAME

HTTP::Parser2::XS - yet another http parser 

=head1 SYNOPSIS

    use HTTP::Parser2::XS;


    my $buf = "GET /foo%20bar/ HTTP/1.0\x0d\x0a".
              "Host: localhost\x0d\x0a".
              "\x0d\x0a";


    my $r = {}; 

    my $rv = parse_http_request($buf, $r);
    if ($rv == -1) {
        # bad request or internal error
    } elsif ($rv == -2 && length($buf) > 4096) {
        # incomplete request and too long already,
        # no point allowing something like this
    } elsif ($rv == -2) {
        # incomplete request, call again when there is more data
        # in the buffer
    } else {
        # $rv contains the length of the request header on success
    }


    if (exists $r->{'host'} && $r->{'host'}->[0] eq 'localhost') {
        # ...
    }


    if ($r->{'_uri'} eq '/foo bar') {
        # ...
    }




    my $buf = "HTTP/1.0 200 OK\x0d\x0a".
              "Content-type: text/html\x0d\x0a".
              "\x0d\x0a".
              "foo bar";

    my $r = {}; 

    my $rv = parse_http_response($buf, $r);
    if ($rv == -1) {
        # bad reponse or internal error
    } elsif ($rv == -2 && length($buf) > 4096) {
        # incomplete response header and too long already,
        # no point allowing something like this
    } elsif ($rv == -2) {
        # incomplete response, call again when there is more data
        # in the buffer
    } else {
        # $rv contains the length of the response header on success
    }


    if (exists $r->{'content-type'} && 
        $r->{'content-type'}->[0] eq 'text/html') 
    {
        # ...
    }


    if ($r->{'_status'} eq '200') {
        # ...
    }


=head1 DESCRIPTION

HTTP::Parser2::XS parses data into a bit different form making perl code 
more clear and consistent. 

=head1 EXPORT

    parse_http_request
    parse_http_response

=head1 FUNCTIONS

=over 4

=item $rv = parse_http_request($buf, $r)

Parses HTTP request in C<$buf> into the hashref C<$r>. Returns length
of the header on success, C<-1> on error and C<-2> if request isn't complete
yet, i.e. doesn't have an entire header.
Converts each header name to lower-case and stores each value as an arrayref.
For example C<< $r->{'host'}->[0] >> returns a C<Host> header and 
C<< @{$r->{'cookie'}} >> returns all the cookie headers.

Additionally adds the following elements:

=over 

=item $r->{'_method'} 

Request method, usually "GET", "HEAD", "POST" or "PUT".

=item $r->{'_request_uri'}

Unchanged undecoded raw request uri. 

=item $r->{'_uri'}

Decoded request uri without query string. A lot like C<$uri> in nginx.

=item $r->{'_query_string'}

Query string. Everything after question mark.

=item $r->{'_protocol'}

Protocol and version. Either "HTTP/1.0" or "HTTP/1.1". 

=item $r->{'_keepalive'}

Either C<1> or C<0>. Examines connection header and protocol version to 
decide whether or not keep-alive connection is desired. And if it is 
sets C<< $r->{'_keepalive'} >> to C<1>. 

=item $r->{'_content_length'}

Parses content-length header. Stores length as a numeric value 
(SvNV to be precise) or undef if there is no content-length header.

=back

=item $rv = parse_http_response($buf, $r)

Parses HTTP response in C<$buf> into the hashref C<$r>. Returns length
of the header on success, C<-1> on error and C<-2> if response isn't complete
yet, i.e. doesn't have an entire header.
Converts each header name to lower-case and stores each value as an arrayref.

Additionally adds the following elements:

=over

=item $r->{'_protocol'}

Protocol and version. Either "HTTP/1.0" or "HTTP/1.1". 

=item $r->{'_status'}

Response status. For example "200" for "HTTP/1.0 200 OK" response.

=item $r->{'_message'}

Status message. For example "OK" for "HTTP/1.0 200 OK" response.

=item $r->{'_keepalive'}

Either C<1> or C<0>. Examines connection header and protocol version to 
decide whether or not keep-alive connection is desired. And if it is 
sets C<< $r->{'_keepalive'} >> to C<1>. 

=item $r->{'_content_length'}

Parses content-length header. Stores length as a numeric value 
(SvNV to be precise) or undef if there is no content-length header.

=back

=back

=head1 SEE ALSO

L<HTTP::Parser::XS>

=head1 AUTHOR

Alexandr Gomoliako <zzz@zzz.org.ua>

=head1 LICENSE

This module uses Kazuho Oku's code from L<HTTP::Parser::XS>.

Copyright 2011 Alexandr Gomoliako, Kazuho Oku. All rights reserved.

This module is free software. It may be used, redistributed and/or modified 
under the same terms as Perl itself.

=cut

