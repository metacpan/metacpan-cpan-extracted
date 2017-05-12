# $Id: /mirror/gungho/lib/Gungho/Request/http.pm 2473 2007-09-04T07:08:58.221716Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rightsreserved.

package Gungho::Request::http;
use strict;
use warnings;
use base qw(Gungho::Base);

__PACKAGE__->mk_accessors($_) for qw(peer_http_version send_te keep_alive);

my $CRLF = "\015\012";

sub new
{
    my $class = shift;
    $class->next::method(peer_http_version => "1.0", send_te => 0, @_);
}

sub prepare_request{}

sub format
{
    my $self    = shift;
    my $request = shift;

    $self->prepare_request($request);

    my $method  = $request->method || 'GET';
    my $uri     = $request->uri->path || '/';

    my $content = (@_ % 2) ? pop : "";

    for ($method, $uri) {
        require Carp;
        Carp::croak("Bad method or uri") if /\s/ || !length;
    }
    
    my $protocol = $request->protocol || 'HTTP/1.1';
    my ($ver)    = ($protocol =~ /(\d+\.\d+)\s*$/);
    my $peer_ver = $self->peer_http_version || "1.0";
    
    my @h;
    my @connection;
    my %given = (host => $request->header('Host') || 0, "content-length" => 0, "te" => 0);
    while (@_) {
        my($k, $v) = splice(@_, 0, 2);
        my $lc_k = lc($k);
        if ($lc_k eq "connection") {
            $v =~ s/^\s+//;
            $v =~ s/\s+$//;
            push(@connection, split(/\s*,\s*/, $v));
            next;
        }

        if (exists $given{$lc_k}) {
            $given{$lc_k}++;
        }
        push(@h, "$k: $v");
    }
    
    if (length($content) && !$given{'content-length'}) {
        push(@h, "Content-Length: " . length($content));
    }
    
    my @h2;
    if ($given{te}) {
        push(@connection, "TE") unless grep lc($_) eq "te", @connection;
    } elsif ($self->send_te && zlib_ok()) {
        # gzip is less wanted since the Compress::Zlib interface for
        # it does not really allow chunked decoding to take place easily.
        push(@h2, "TE: deflate,gzip;q=0.3");
        push(@connection, "TE");
    }

    unless (grep lc($_) eq "close", @connection) {
        if ($self->keep_alive) {
            if ($peer_ver eq "1.0") {
                # from looking at Netscape's headers
                push(@h2, "Keep-Alive: 300");
                unshift(@connection, "Keep-Alive");
            }
        } else {
            push(@connection, "close") if $ver ge "1.1";
        }
    }
    push(@h2, "Connection: " . join(", ", @connection)) if @connection;
    unless ($given{host}) {
        my $h = $request->uri->host;
        push(@h2, "Host: $h") if $h;
    }

    return join($CRLF, "$method $uri HTTP/$ver", @h2, @h, "", $content);
}

1;

__END__

=head1 NAME

Gungho::Request::http - HTTP specific utilities

=head1 METHODS

=head2 new

=head2 prepare_request

=head2 format

=cut
