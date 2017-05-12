=head1 NAME

DynGig::Range::Cluster::Cache - Caching server.
Implements DynGig::Range::Cluster::Interface.

=cut
package DynGig::Range::Cluster::Cache;

use base DynGig::Range::Cluster::Interface;

use warnings;
use strict;
use Carp;

=head1 METHODS

=head2 run( conf => '/config/dir', link => 'current' )

Launches server with supplied parameter.

I<conf>: directory containing cluster configuration caches

I<link>: name of the symlink pointing to the latest cache

=cut
sub run 
{
    my ( $this, %param ) = @_;
    my $conf = $param{conf};
    my $link = defined $param{link} ? $param{link} : 'current';

    croak "undefined/invalid/inaccessable directory $conf"
        if defined $conf && ! ( -d $conf && chdir $conf );

    croak "readlink $link: $!" unless my $current = readlink $link;

    $this->{_run}{context} = +{ current => $current, link => $link };

    DynGig::Util::TCPServer::run( $this );
}

sub _worker
{
    my ( $this, @queue ) = @_;
    my $context = $this->{_run}{context};
    my $conf = $context->{conf};      
    my $query = $queue[0]->dequeue();
    my $current = readlink $context->{link};

    if ( $query eq $current )
    {
        $queue[1]->enqueue( '' );
        return;
    }

    if ( ! $conf || $current && $current ne $context->{current} )
    {
        if ( open my $handle, '<', $current )
        {
            DynGig::Util::Sysrw->read( $handle, $conf );
            $context->{conf} = $conf;
            close $handle;
        }
        else
        {
            my $error = "open $current: $!";
            croak $error unless $conf;
            carp $error;
        }
    }

    $queue[1]->enqueue( $conf );
}

=head1 NOTE

See DynGig::Range::Cluster

=cut

1;

__END__
