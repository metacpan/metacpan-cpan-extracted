# $Id: /mirror/gungho/lib/Gungho/Provider.pm 31310 2007-11-29T13:19:42.807767Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Provider;
use strict;
use warnings;
use base qw(Gungho::Base);
use Gungho::Request;

__PACKAGE__->mk_accessors($_) for qw(has_requests);
__PACKAGE__->mk_virtual_methods($_) for qw(dispatch pushback_request);

sub stop { }

# XXX - Hmm, yank this method out?
sub dispatch_request
{
    my ($self, $c, $req) = @_;
    $c->log->debug("[PROVIDER]: Dispatch " . $req->uri);
    $c->send_request($req);
}

1;

__END__

=head1 NAME

Gungho::Provider - Base Class For Gungho Prividers

=head1 METHODS

=head2 has_requests

Returns true if there are still more requests to be processed.

=head2 dispatch($c)

Dispatch requests to be fetched to the Gungho framework

=head2 dispatch_request($c, $req)

Dispatch a single request

=head2 pushback_request($c, $req)

Push back a request which couldn't be sent to the engine, for example
because the request was throttled.

=head2 stop($reason)

Stop the Provider. Place code that needs to be executed to shutdown the
provider here.

=cut
