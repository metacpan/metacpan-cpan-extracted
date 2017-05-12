# $Id: Message.pm,v 1.9 2014-01-28 15:40:10 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Event::RPC, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Event::RPC::Message::Sereal;

use base Event::RPC::Message;

use strict;
use utf8;

use Sereal qw(sereal_encode_with_object
              sereal_decode_with_object);

my $decoder = Sereal::Decoder->new;
my $encoder = Sereal::Encoder->new;

sub decode_message { sereal_decode_with_object($decoder, $_[1]) }
sub encode_message { sereal_encode_with_object($encoder, $_[1]) }

1;

__END__

=encoding utf8

=head1 NAME

Event::RPC::Message::Sereal - Sereal message formatting

=head1 SYNOPSIS

  # Internal module. No documented public interface.

=head1 DESCRIPTION

This module implements the message formatting of Event::RPC
using Sereal. Objects of this class are created internally by
Event::RPC::Server and Event::RPC::Client and performs message
passing over the network.

=head1 AUTHORS

  Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
