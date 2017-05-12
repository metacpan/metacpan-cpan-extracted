=head1 NAME

DynGig::Range::Cluster::Interface - Extends DynGig::Util::TCPServer.

=cut
package DynGig::Range::Cluster::Interface;

use base DynGig::Util::TCPServer;

use warnings;
use strict;

use DynGig::Util::Sysrw;

sub _server
{
    my ( $this, $socket, @queue ) = @_;
    my $buffer = '';

    DynGig::Util::Sysrw->read( $socket, $buffer, 33 );

    if ( $buffer =~ /^([0-9a-f]{32})\b/ )
    {
        $queue[0]->enqueue( $1 );
        DynGig::Util::Sysrw->write( $socket, $buffer )
            if $buffer = $queue[1]->dequeue();
    }
}

=head1 NOTE

See DynGig::Range::Cluster

=cut

1;

__END__
