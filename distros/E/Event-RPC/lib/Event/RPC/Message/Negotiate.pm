# $Id: Message.pm,v 1.9 2014-01-28 15:40:10 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Event::RPC, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Event::RPC::Message::Negotiate;

use base Event::RPC::Message;

use Carp;
use strict;
use utf8;

my %MESSAGE_FORMATS = (
    "SERL"  => "Event::RPC::Message::Sereal",
    "CBOR"  => "Event::RPC::Message::CBOR",
    "JSON"  => "Event::RPC::Message::JSON",
    "STOR"  => "Event::RPC::Message::Storable",
);

my @MESSAGE_FORMAT_ORDER = qw( SERL CBOR JSON STOR );

sub known_message_formats       { \%MESSAGE_FORMATS             }
sub message_format_order        { \@MESSAGE_FORMAT_ORDER        }

my $STORABLE_FALLBACK_OK = 0;
sub get_storable_fallback_ok    { $STORABLE_FALLBACK_OK         }
sub set_storable_fallback_ok    { $STORABLE_FALLBACK_OK = $_[1] }

sub encode_message {
    my $self = shift;
    my ($decoded) = @_;

    my $ok  = $decoded->{ok}  || "";
    my $msg = $decoded->{msg} || "";
    my $cmd = $decoded->{cmd} || "";

    s,/\d/,,g for ( $ok, $msg, $cmd );

    return "/0/E:R:M:N/1/$ok/2/$msg/3/$cmd/0/";
}

sub decode_message {
    my $self = shift;
    my ($encoded) = @_;

    return { ok => $1, msg => $2, cmd => $3 }
        if $encoded =~ m,^/0/E:R:M:N/1/(.*?)/2/(.*?)/3/(.*?)/0/$,;

    #-- An old client or server may not know our message
    #-- format negotiation protocol, so we provide a Storable
    #-- fallback mechanism, if we're allowed to do so.
    if ( $self->get_storable_fallback_ok ) {
        require Event::RPC::Message::Storable;
        bless $self, "Event::RPC::Message::Storable";
        return $self->decode_message($encoded);
    }

    #-- No Storable fallback allowed. We bail out!
    die "Error on message format negotitation and no fallback to Storable allowed\n";
}

1;

__END__

=encoding utf8

=head1 NAME

Event::RPC::Message::Negotiate - Message format negotiation protocol

=head1 SYNOPSIS

  # Internal module. No documented public interface.

=head1 DESCRIPTION

This module implements the message format negotitation protocol
of Event::RPC. Objects of this class are created internally by
Event::RPC::Server and Event::RPC::Client and performs message
passing over the network.

=head1 AUTHORS

  Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
