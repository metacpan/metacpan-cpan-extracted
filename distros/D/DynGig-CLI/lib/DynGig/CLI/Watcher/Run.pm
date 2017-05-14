=head1 NAME

DynGig::CLI::Watcher::Run - CLI for watcher run.

=cut
package DynGig::CLI::Watcher::Run;

use warnings;
use strict;
use Carp;

use Pod::Usage;
use Getopt::Long;

use DynGig::Util::CLI;
use DynGig::Util::Setuid;
use DynGig::Util::LockFile::PID;
use DynGig::Automata::MapReduce;

$| ++;

=head1 EXAMPLE

 use DynGig::CLI::Watcher::Run;

 DynGig::CLI::Watcher::Run->main
 (
     user => 'username',
     root => '/watcher/root/path',
 );

=head1 SYNOPSIS

$exe B<--help>

$exe name [B<--root> dir]

$exe name [B<--root> dir] B<--repeat>

=cut
sub main
{
    my ( $class, %option ) = @_;

    map { croak "$_ not defined" if ! defined $option{$_} } qw( root user );

    my $menu = DynGig::Util::CLI->new
    (
        'h|help','help menu',
        'r|repeat','run repeatedly',
        'user=s',"[ $option{user} ] run as user",
        'root=s',"[ $option{root} ]",
    );
    
    my %pod_param = ( -input => __FILE__, -output => \*STDERR );
    my $who = ( getpwuid $< )[0];
    my @argv = @ARGV;

    Pod::Usage::pod2usage( %pod_param )
        unless Getopt::Long::GetOptions( \%option, $menu->option() );

    if ( $who ne $option{user} )
    {
        @ARGV = @argv;
        DynGig::Util::Setuid->sudo( $option{user} );
    }

    if ( $option{h} )
    {
        warn join "\n", "Default value in [ ]", $menu->string(), "\n";
        return 0;
    }

    Pod::Usage::pod2usage( %pod_param ) unless @ARGV;
    
    croak "chdir $option{root}: $!" unless chdir $option{root};

    my ( $exit, %context );
    my $name = $ARGV[0];
    my $sequence = DynGig::Automata::MapReduce->new( $name )->setup();

    die "already running.\n" unless
        DynGig::Util::LockFile::PID->new( $sequence->file( 'pid' ) )->lock();

##  graceful interrupt
    $SIG{INT} = sub { $exit = 1 };
    
    while ( ! $exit )
    {
        $sequence->run( context => \%context );

        return 0 if $exit || ! $option{r};

        my $context = $sequence->context();
        my ( $nap ) = sort { $a <=> $b }
            map { $context->{$_}{due} } $sequence->job();

        sleep $nap;
    }

    return 0;
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__
