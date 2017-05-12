# $Id: /mirror/gungho/lib/Gungho/Request.pm 31624 2007-12-01T04:20:00.298198Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Request;
use strict;
use warnings;
use base qw(HTTP::Request);
use Storable qw(dclone);
use UNIVERSAL::require;
use Regexp::Common qw(net);

our $DIGEST;

sub _find_digest_class
{
    $DIGEST ||= do {
        my $pkg;
        foreach my $x qw(SHA1 MD5) {
            my $candidate = "Digest::$x";
            if ($candidate->require()) {
                $pkg = $candidate;
                last;
            }
        }
        $pkg;
    };
}

sub new
{
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->id; # Forcefully make the ID here.
    $self->{_notes} = {};
    return $self;
}

sub id
{
    my $self = shift;

    local $@ = undef;
    $self->{_id} ||= do {
        my $pkg    = _find_digest_class() || die "Could not find Digest class";
        my $digest = $pkg->new;

        $digest->add(map { defined $_ ? $_ : '' } (time(), {}, rand(), $self->method, $self->uri, $self->protocol));
        $self->headers->scan(sub {
            $digest->add(join(':', $_[0], $_[1]));
        });
        $digest->hexdigest;
    };
    die $@ if $@;
    $self->{_id};
}

sub clone
{
    my $self  = shift;
    my $clone = $self->SUPER::clone;

    my $cloned_notes = dclone $self->notes;
    foreach my $note (keys %$cloned_notes) {
        $clone->notes( $note => $cloned_notes->{$note} );
    }
    return $clone;
}

sub notes
{
    my $self = shift;
    my $key  = shift;

    return $self->{_notes} unless $key;

    my $value = $self->{_notes}{$key};
    if (@_) {
        $self->{_notes}{$key} = $_[0];
    }
    return $value;
}

sub original_uri
{
    my $self = shift;
    my $uri  = $self->uri->clone;
    if (my $host = $self->notes('original_host')) {
        $uri->host($host);
    }
    return $uri;
}

sub requires_name_lookup
{
    my $self = shift;
    return ! $self->notes('resolved_ip') && 
        ($self->uri->can('host') && $self->uri->host() !~ /^$RE{net}{IPv4}$/);
}

sub format
{
    my $self   = shift;
    my $scheme = $self->uri->scheme;
    my $pkg    = "Gungho::Request::$scheme";

    require Class::Inspector;
    Class::Inspector->loaded($pkg) or $pkg->require or die;

    my $protocol = $pkg->new;
    $protocol->format($self);
}

1;

__END__

=head1 NAME

Gungho::Request - A Gungho Request Object

=head1 DESCRIPTION

Currently this class is exactly the same as HTTP::Request, but we're
creating this separately in anticipation for a possible change

=head1 METHODS

=head2 new()

Creates a new Gungho::Request instance

=head2 id()

Returns a Unique ID for this request

=head2 clone()

Clones the request.

=head2 notes($key[, $value])

Associate arbitrary notes to the request

=head2 original_uri

Returns a cloned copy of the request URI, with the host name swapped to
the original hostname before DNS substitution

=head2 requires_name_lookup

Returns true if the request object's uri host is not in an IP address format

=head2 format

Formats the request so that it's appropriate to send through a socket.

=cut
