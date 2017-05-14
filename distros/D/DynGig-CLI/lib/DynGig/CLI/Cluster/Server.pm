=head1 NAME

DynGig::CLI::Cluster::Server - CLI for cluster server

=cut
package DynGig::CLI::Cluster::Server;

use warnings;
use strict;
use Carp;

use Pod::Usage;
use Getopt::Long;

use DynGig::Util::CLI;
use DynGig::Range::Cluster::Cache;
use DynGig::Range::Cluster::Server;

$| ++;

=head1 EXAMPLE

 use Cwd;
 use File::Spec;
 use FindBin qw( $Bin );
 use DynGig::CLI::Cluster::Server;

 DynGig::CLI::Cluster::Server->main
 (
     thread => 20,
     timeout => 30,
     mode => 'root',
     link => 'current',
     conf => Cwd::abs_path( File::Spec->join( $Bin, '..', 'conf' ) ),
 );

=head1 SYNOPSIS

$exe B<--help>

$exe [B<--conf> dir] [B<--thread> number] [B<--timeout> seconds]
[B<--mode> 'root'] B<--port> number | /unix/domain/socket/path

$exe [B<--conf> dir] [B<--thread> number] [B<--link> name]
B<--mode> 'cache' B<--port> number | /unix/domain/socket/path

=cut
sub main
{
    my ( $class, %option ) = @_;

    map { croak "$_ not defined" if ! defined $option{$_} }
        qw( thread conf mode link timeout );

    my $menu = DynGig::Util::CLI->new
    (
        'h|help',"print help menu",
        'port=s','service port or unix domain socket',
        'thread=i',"[ $option{thread} ] number of threads",
        'conf=s',"[ $option{conf} ] directory",
        'mode=s',"[ $option{mode} ] or 'cache' mode",
        'link=s',"[ $option{link} ] symlink to current cache (mode=cache)",
        'timeout=i',"[ $option{timeout} ] seconds between updates (mode=root)",
    );
    
    my %pod_param = ( -input => __FILE__, -output => \*STDERR );

    Pod::Usage::pod2usage( %pod_param )
        unless Getopt::Long::GetOptions( \%option, $menu->option() )
            && ( $option{port} || $option{h} );

    if ( $option{h} )
    {
        warn join "\n", "Default value in [ ]", $menu->string(), "\n";
        return 0;
    }

    my %param = map { $_ => $option{$_} } qw( port thread );

    if ( $option{mode} eq 'root' )
    {
        DynGig::Range::Cluster::Server->new( %param )
            ->run( map { $_ => $option{$_} } qw( conf timeout ) );
    }
    else
    {
        DynGig::Range::Cluster::Cache->new( %param )
            ->run( map { $_ => $option{$_} } qw( conf link ) );
    }
}                    

=head1 NOTE

See DynGig::Range::CLI

=cut

1;

__END__
