=head1 NAME

DynGig::CLI::Cluster::Cache - CLI for cluster cache

=cut
package DynGig::CLI::Cluster::Cache;

use warnings;
use strict;
use Carp;

use Pod::Usage;
use Getopt::Long;

use DynGig::Util::CLI;
use DynGig::Range::Cluster::Client;

$| ++;

=head1 EXAMPLE

 use DynGig::CLI::Cluster::Cache;

 DynGig::CLI::Cluster::Cache->main
 (
     timeout => 30,
     cache => '.',
     sleep => 60,
     keep => 10,
     link => 'current'
 );

=head1 SYNOPSIS

$exe B<--help>

$exe [B<--cache> dir] [B<--keep> number] [B<--link> name] [B<--sleep> seconds]
[B<--timeout> seconds] B<--server> host:port | /unix/domain/socket/path

=cut
sub main
{
    my ( $class, %option ) = @_;

    map { croak "$_ not defined" if ! defined $option{$_} }
        qw( timeout cache sleep keep link );

    my $menu = DynGig::Util::CLI->new
    (
        'h|help',"print help menu",
        'server=s','server host:port',
        'timeout=i',"[ $option{timeout} ] seconds connection timeout",
        'cache=s',"[ $option{cache} ] cached config directory",
        'sleep=i',"[ $option{sleep} ] minimum seconds between updates",
        'keep=i',"[ $option{keep} ] minimum number of cached configs",
        'link=s',"[ $option{link} ] symlink to current config",
    );

    my %pod_param = ( -input => __FILE__, -output => \*STDERR );

    Pod::Usage::pod2usage( %pod_param )
        unless Getopt::Long::GetOptions( \%option, $menu->option() )
            && ( $option{server} || $option{h} );

    if ( $option{h} )
    {
        warn join "\n", "Default value in [ ]", $menu->string(), "\n";
        return 0;
    }

    my %param = map { $_ => $option{$_} } qw( server timeout );
    my $client = DynGig::Range::Cluster::Client->new( %param );
    my %file = map { $_ => ( stat $_ )[10] }
    my @file = grep { $_ =~ /^[0-9a-f]{32}$/ } glob $option{cache};

    @file = sort { $file{$a} <=> $file{$b} } @file;
    %param = map { $_ => $option{$_} } qw( cache link );
    
    while ( 1 )
    {
        $client->cache( %param );
    
        my $current = readlink $option{link};
    
        if ( ! $file{$current} )
        {
            push @file, $current;
    
            while ( @file > $option{keep} )
            {
                my $file = shift @file;
                delete $file{$file};
                unlink $file;
            }

            $file{$current} = 1;
        }
    
        sleep( $option{sleep} + rand 30 ) while ! $client->update();
    }
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__
