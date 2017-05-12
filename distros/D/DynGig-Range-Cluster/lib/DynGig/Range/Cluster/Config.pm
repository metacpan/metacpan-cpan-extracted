=head1 NAME

DynGig::Range::Cluster::Config - Cluster configuration methods

=cut
package DynGig::Range::Cluster::Config;

use warnings;
use strict;
use Carp;

use YAML::XS;
use File::Spec;
use Digest::MD5;
use Compress::Zlib;
use File::Spec;

use DynGig::Range::Cluster::EZDB;

my %_CONF;

=head1 SYNOPSIS

 my $config = DynGig::Range::Cluster::Config->new( '/config/dir' );

 if ( my %update = $config->load() )
 {
     $config->update( %update );
 }

 my $compressed = $config->zip();
 my $md5 = $config->md5();

=cut
sub new
{
    my ( $class, $conf ) = @_;
    my ( $file, $handle );

    croak 'conf directory not defined' unless defined $conf;
    croak "$conf: $!" unless opendir $handle, $conf;

    while ( defined ( my $name = readdir $handle ) )
    {
        $_CONF{$name} = [ DynGig::Range::Cluster::EZDB->new( $file ) ]
            if $name !~ /^\./o
                && -f ( $file = File::Spec->join( $conf, $name ) );
    }

    close $handle;
    bless { cluster => {}, key => {}, value =>{} }, ref $class || $class;
}

=head1 METHODS

=head2 unzip()

Returns decompressed config.

=cut
sub unzip
{
    return undef unless my $buffer = Compress::Zlib::uncompress( $_[0] );
    return undef unless my $this = eval { YAML::XS::Load $buffer };
    return ref $this eq __PACKAGE__ ? $this : undef;
}

=head2 unzip()

Returns compressed config.

=cut
sub zip
{
    my $serial = YAML::XS::Dump shift @_;

    return Compress::Zlib::compress( $serial ) unless @_;
    return Compress::Zlib::compress( $serial, @_ );
}

=head2 unzip()

Returns MD5 digest of serialized config.

=cut
sub md5
{
    Digest::MD5->new()->add( YAML::XS::Dump $_[0] )->hexdigest();
}

=head2 load()

Delta loads ( no change == no-op ) configs into a HASH.
Returns HASH reference in scalar context.
Returns flattened HASH in list context.

=cut
sub load
{
    my $this = shift @_;
    my %conf;

    for my $name ( keys %_CONF )
    {
        my $conf = $_CONF{$name};
        my $mtime  = ( $conf->[0]->stat() )[9];

        next if $conf->[1] && $mtime <= $conf->[1];

        $conf{$name} = $conf->[0]->reload()->get();
        $conf->[1] = $mtime;
    }

    return wantarray ? %conf : \%conf;
}

=head2 update( cluster1 => config1, cluster2 => config2 .. )

Updates object.

=cut
sub update
{
    my ( $this, %conf ) = @_;
    my $K = $this->{key};
    my $V = $this->{value};
    my $C = $this->{cluster};

    for my $name ( keys %conf )
    {
        for my $table ( keys %$K )
        {
            for my $table ( $K->{$table}, $V->{$table} )
            {
                for my $key ( keys %$table )
                {
                    delete $table->{$key}{$name};
                    delete $table->{$key} unless %{ $table->{$key} };
                }
            }
        }

        while ( my ( $table, $conf ) = each %{ $C->{$name} = $conf{$name} } )
        {
            while ( my ( $key, $value ) = each %$conf )
            {
                $K->{$table}{$key}{$name} = $value;
                push @{ $V->{$table}{$value}{$name} }, $key;
            }
        }
    }
}

sub AUTOLOAD 
{
    my $this = shift;
    my $K = $this->{key};
    my $V = $this->{value};

    if ( our $AUTOLOAD =~ /::DB_(\w+)$/ ) ## 'DB' methods
    {
        my $key = $1;

        if ( $key =~ /^(cluster|table)s$/ )
        {
            my @list = keys %{ $this->{$1} || $K };
            return wantarray ? @list : \@list;
        }
        elsif ( $this->{$key} )
        {
            my $table = shift;
            return defined $table ? $this->{$key}{$table} : $table;
        }
    }
    elsif ( $AUTOLOAD =~ /::(\w+)$/ && $K->{$1} ) ## 'table' methods
    {
        my $table = $1;
        my %param = @_;
        my $key = $param{key};
        my $value = $param{value};
        my $cluster = $param{cluster};

        if ( defined $key && defined $value ) ## find clusters by key:value
        {
            my @list = grep { $K->{$table}{$key}{$_} eq $value }
                keys %{ $K->{$table}{$key} };

            return wantarray ? @list : \@list;
        }
        elsif ( defined $cluster )
        {
            if ( defined $value ) ## find keys by cluster:value
            {
                my $list = $V->{$table}{$value}{$cluster};

                if ( $list && @$list == 1 && $list->[0] =~ /^##(.+)/ )
                {
                        my $newlist = [];
                        my @param = split '_', $1;
                        if( @param >= 1 )
                        {
                            my $plugin = shift @param;
                            my $pfile = File::Spec->join(
                                "/devops/tools/var/range/plugin", $plugin );
                            if ( -f $pfile )
                            {
                                eval
                                {
                                    no warnings;
                                    no strict 'vars';
                                    local $PARAM = \@param;
                                    $newlist = do $pfile;
                                };
                            }
                        }
                        $list = $newlist; 
                }
                return wantarray ? @$list : $list if $list;
            }
            elsif ( defined $key ) ## find value by cluster:key
            {
                return $K->{$table}{$key}{$cluster};
            }
        }
    }

    return undef;
}

sub DESTROY
{
    my $this = shift @_;
    map { delete $this->{$_} } keys %$this;
}

## a node may belong to more than one cluster.
## hence it may have different status in different clusters

=head1 NOTE

See DynGig::Range::Cluster

=cut

1;

__END__
