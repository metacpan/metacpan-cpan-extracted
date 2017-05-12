# $Id: Message.pm,v 1.9 2014-01-28 15:40:10 joern Exp $

#-----------------------------------------------------------------------
# Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.
# All Rights Reserved. See file COPYRIGHT for details.
# 
# This module is part of Event::RPC, which is free software; you can
# redistribute it and/or modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------

package Event::RPC::Message::Storable;

use base Event::RPC::Message;

use strict;
use utf8;

use Storable;

sub decode_message { Storable::thaw($_[1])     }
sub encode_message { Storable::nfreeze ($_[1]) }

1;

__END__

=encoding utf8

=head1 NAME

Event::RPC::Message::Storable - Storable message formatting

=head1 SYNOPSIS

  # Internal module. No documented public interface.

=head1 DESCRIPTION

This module implements the message formatting of Event::RPC
using Storable. Objects of this class are created internally by
Event::RPC::Server and Event::RPC::Client and performs message
passing over the network.

=head1 IMPORTANT NOTE

This module is shipped for client/server backward compatibility
with Event::RPC prior to 1.06. Due to security considerations it's
not recommended to use Storable in real world szenarios. Better
use one of the other alternatives (Sereal, CBOR or JSON).

=head1 AUTHORS

  Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2015 by Jörn Reder <joern AT zyn.de>.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
