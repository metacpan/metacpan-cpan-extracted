package Drogo::Server::Test;
use URI::Escape;
use base 'Drogo::Server';

use strict;

my %SERVER_VARIABLES;

=head1 NAME

Drogo::Server::Test - Bare implementation of a server's methods, for testing.

=head1 METHODS

=head3 new 

Create a new server instance.

=cut

sub new
{
    my ($class, %params) = @_;
    %SERVER_VARIABLES = ( );
    my $self = { %params, output => '' };

    bless($self);

    return $self;
}

=head3 variable(key => $value)

Returns a persistant server variable.

Key without value returns variable.

These include variables set by the server configuration, as "user variables" in nginx.

=cut

sub variable
{
    my ($self, $key, $value) = @_;

    if ($value)
    {
        $SERVER_VARIABLES{$key} = $value;
    }
    else
    {
        return $SERVER_VARIABLES{$key};
    }
}

=head3 uri

Returns the uri.

=cut

sub uri { shift->{uri} }

=head3 args

Returns string of arguments.

=cut

sub args { shift->{args} }

=head3 request_body

Returns the request body (used for posts)

=cut

sub request_body { '' }

=head3 input

Returns input stream.

=cut

sub input { }

=head3 request_method

Returns the request method (GET or POST)

=cut

sub request_method   { shift->{request_method} || 'GET' }

=head3 remote_addr

Returns remote address.

=cut

sub remote_addr
{
    my $self = shift;

    return $self->{remote_addr} || '127.0.0.1';
}

=head3 has_request_body

Used by nginx for request body processing.

This function is only called when the request method is a post,
in an effort to reduce processing time.

=cut

sub has_request_body { }

=head3 header_in

Returns a request header.

=cut

sub header_in
{
    my ($self, $what) = @_;

    return $self->{headers_in}{$what};
}

=head3 header_out

Sets a header out.

=cut

sub header_out
{
    my ($self, $header, $value) = @_;

    return $self->{headers_out}{$header} = $value;
}

=head3 send_http_header

Send the http header.

=cut

sub send_http_header
{
    my ($self, $header) = @_;

    $self->{http_header} = $header;
}

=head3 $self->status(...)

Set output status... (200, 404, etc...)
If no argument given, returns status.

=cut

sub status 
{
    my ($self, $status) = @_;

    if ($status)
    {
        $self->{status} = $status;
    }
    else
    {
        return $self->{status};
    }
}

=head3 print

Print stuff to the http stream.

=cut

sub print {
    my ($self, $line) = @_;

    $self->{output} .= $line;
}

sub rflush { }

=head3  sleep

Sleeps (used by nginx), not needed for other server implementations.

=cut

sub sleep
{
    my $self = shift;
    sleep(shift);
}

=head3 header_only

Returns true of only the header was requested.

=cut

sub header_only { 0 }

sub server_returns_object { 1 }

=head3 unescape

Unescape an encoded uri.

=cut

sub unescape
{
    my ($self, $string) = @_;

    return uri_unescape($string);
}

=head3 server_return

This function defines what is returned to the server at the end of a dispatch.
For nginx, this will be a status code, but in this test implementation we're
returning the actual server object itself, so we can evaluate it while testing

=cut

sub server_return
{
    my ($self, $what) = @_;

    return $self;
}

sub close_connection { 1 }

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
