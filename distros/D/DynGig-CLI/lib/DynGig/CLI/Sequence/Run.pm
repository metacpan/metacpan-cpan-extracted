=head1 NAME

DynGig::CLI::Sequence::Run - CLI for sequence run.

=cut
package DynGig::CLI::Sequence::Run;

use warnings;
use strict;
use Carp;

use Pod::Usage;
use Getopt::Long;

use DynGig::Util::CLI;
use DynGig::Util::LockFile::PID;
use DynGig::Util::LockFile::Time;
use DynGig::Automata::Sequence;

$| ++;

=head1 EXAMPLE

 use DynGig::CLI::Sequence::Run;

 DynGig::CLI::Sequence::Run->main
 (
     thread => 0,
     root => '/sequence/root/path',
 );

=head1 SYNOPSIS

$exe B<--help>

$exe name [B<--root> dir] [B<--time> timestamp] [B<--thread> 0]

$exe name [B<--root> dir] [B<--time> timestamp] [B<--thread> 0] --noexec

$exe name [B<--root> dir] [B<--time> timestamp] B<--thread> number

$exe name [B<--root> dir] [B<--time> timestamp] B<--thread> number --noexec

=cut
sub main
{
    my ( $class, %option ) = @_;

    map { croak "$_ not defined" if ! defined $option{$_} } qw( root thread );

    my $menu = DynGig::Util::CLI->new
    (
        'h|help','help menu',
        'n|noexec','do not really run',
        'thread=i',"[ $option{thread} ] or thread count for threaded mode",
        'time=s',"[ none ] or 'raw', 'utc', 'local' for log timestamp",
        'root=s',"[ $option{root} ]",
    );
    
    my %pod_param = ( -input => __FILE__, -output => \*STDERR );

    Pod::Usage::pod2usage( %pod_param )
        unless Getopt::Long::GetOptions( \%option, $menu->option() );

    if ( $option{h} )
    {
        warn join "\n", "Default value in [ ]", $menu->string(), "\n";
        return 0;
    }

    Pod::Usage::pod2usage( %pod_param ) unless @ARGV;
    
    croak "chdir $option{root}: $!" unless chdir $option{root};
    
    $DynGig::Automata::Sequence::THREAD = $option{thread};

    my $name = $ARGV[0];
    my $sequence = DynGig::Automata::Sequence->new( $name )->setup();
    
    die "already running.\n" unless
        DynGig::Util::LockFile::PID->new( $sequence->file( 'pid' ) )->lock();
    
    die "active time lock in place.\n"
        if DynGig::Util::LockFile::Time->check( $sequence->file( 'lock' ) );
    
    my $log = Cwd::abs_path( 'log' );
    
    if ( -e $log )
    {
        croak "not a directory: $log" unless -d $log;
    }
    else
    {
        croak "mkdir $log: $!" unless mkdir $log, 0755;
    }
    
    my $time = POSIX::strftime( '%Y%m%d-%H%M%S-%a-%Z', localtime );
    
    $log = File::Spec->join( $log, "$time.$name" );
    
    $sequence->run
    ( 
        log => $log, context => {},
        map { $_ => $option{$_} } qw( time thread ),
    )
    unless $option{n};

    return 0;
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__
