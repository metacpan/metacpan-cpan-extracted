=head1 NAME

DynGig::Range::Cluster::Client - Cluster client

=cut
package DynGig::Range::Cluster::Client;

use warnings;
use strict;
use Carp;

use DynGig::Util::Sysrw;
use DynGig::Multiplex::TCP;
use DynGig::Range::Cluster::Config;

=head1 SYNOPSIS

 ## a network client
 my $client1 = DynGig::Range::Cluster::Client->new
 ( 
     server => 'localhost:12345',
     timeout => 10
 );

 ## a Unix domain socket client
 my $client2 = DynGig::Range::Cluster::Client->new
 (
     server => '/unix/domain/socket'
     timeout => 20
 );

 ...

 ## write cache
 $client1->cache( cache => '/cache/dir' );

 ## refresh data
 $client2->update();
 
 ## get the value of node 'foo' for cluster 'c1'
 my $value = $client2->node( cluster => 'c1', key => 'foo' );

 ## get the nodes for cluster 'c1' where the value is 'DOWN'
 my $keys = $client2->node( cluster => 'c1', value => 'DOWN' );

 ## get all cluster names where the attr key is 'foo' and value is 'bar'
 my $clusters = $client2->attr( key => 'foo', value => 'bar' );

=cut
sub new
{
    my ( $class, %param ) = @_;
    my $server = $param{server};

    croak "server not defined" unless defined $server;

    $param{buffer} = '00000000000000000000000000000000'; 
    delete $param{server};

    my $this = bless +{ server => $server, param => \%param },
        ref $class || $class;

    croak "unable to get config from server/cache" unless $this->update();
    return $this;
}

=head1 METHODS

=head2 update()

Returns I<true> if successful, I<false> otherwise.

=cut
sub update
{
    my $this = shift;
    my $param = $this->{param};
    my $client = DynGig::Multiplex::TCP->new( $this->{server} => $param );

    return 0 unless $client->run( index => 'forward' );
    return 0 unless my $result = $client->result();
    return 0 unless $result = ( values %$result )[0];
    return 0 unless
        my $config = DynGig::Range::Cluster::Config::unzip( $result );

    $this->{config} = $config;
    $this->{md5} = $param->{buffer} = $config->md5();
    $this->{zip} = $result;

    return 1;
}

=head2 cache( cache => dir )

Writes config to the cache directory.
Sets current symlink to the latest cache file. Returns the object.

=cut
sub cache
{
    my ( $this, %param ) = @_;
    my $cache = $param{cache};

    if ( ! defined $cache )
    {
        $this->{cache} = '.';
    }
    elsif ( ! defined $this->{cache} )
    {
        my $path = eval { readlink $cache };
        $path = $cache unless defined $path;

        if ( -d $path )
        {
            croak "inaccessible directory $cache" unless -w $path && -x $path;
        }
        else
        {
            croak "invalid cache $cache" if -e $path;
            croak "mkdir $cache: $!" unless mkdir $path;
        }

        chdir( $this->{cache} = $cache );
    }

    my $md5 = $this->{md5};

    unless ( -f $md5 )
    {
        croak "open $md5: $!" unless open my $handle, '+>', $md5;

        DynGig::Util::Sysrw->write( $handle, $this->{zip} );
        close $handle;
    }

    my $link = defined $param{link} ? $param{link} : 'current';

    croak "unlink $link: $!" if -l $link && ! unlink $link;
    croak "symlink $md5 $link: $!" unless symlink $md5, $link;

    return $this;
}

=head2 Autoloaded Methods $attribute( %query )

See DynGig::Range::Cluster::Config

=cut
sub AUTOLOAD
{
    my $this = shift;
    my $config = $this->{config};

    return our $AUTOLOAD =~ /::(\w+)$/ ? $config->$1( @_ ) : undef;
}

sub DESTROY
{
    my $this = shift;
    map { delete $this->{$_} } keys %$this;
}

=head1 NOTE

See DynGig::Range::Cluster

=cut

1;

__END__
