=head1 NAME

DynGig::CLI::Sequence::CTRL - CLI for sequence control.

=cut
package DynGig::CLI::Sequence::CTRL;

use warnings;
use strict;
use Carp;

use YAML::XS;
use Pod::Usage;
use Getopt::Long qw( :config bundling no_ignore_case );

use DynGig::Util::CLI;
use DynGig::Util::Time;
use DynGig::Util::LockFile::PID;
use DynGig::Util::LockFile::Time;
use DynGig::Automata::EZDB::Alert;
use DynGig::Automata::Sequence;
use DynGig::Range::String;

use constant { TAIL_PAUSE => 5, LINE_WIDTH => 76 };

$| ++;

=head1 EXAMPLE

 use DynGig::CLI::Sequence::CTRL;

 DynGig::CLI::Sequence::CTRL->main
 (
     root => '/sequence/root/path',
 );

=head1 SYNOPSIS

$exe B<--help>

$exe [names..] [B<--root> dir] B<--tail> number

$exe [names..] [B<--root> dir] [B<--status>]

$exe [names..] [B<--root> dir] B<--resume> range

$exe [names..] [B<--root> dir] B<--Resume>

$exe [names..] [B<--root> dir] B<--lock> [hh:mm:ss+]hh:mm::ss

$exe [names..] [B<--root> dir] B<--unlock>

$exe [names..] [B<--root> dir] B<--pause>

$exe [names..] [B<--root> dir] B<--kill>

=cut
sub main
{
    my ( $class, %option ) = @_;

    croak 'root not defined' unless my $root = $option{root};
##  CLI: usage/getopt
    my $menu = DynGig::Util::CLI->new
    (
        'h|help','help menu',
        't|tail=i','tail log',
        's|status','report status',
        'r|resume=s','resume specific targets from alert',
        'R|Resume','resume sequence from pause or alert',
        'l|lock=s','lock sequence for a period of time',
        'u|unlock','unlock sequence',
        'p|pause','pause sequence',
        'k|kill','kill sequence',
        'root=s',"[ $root ]",
    );

    Pod::Usage::pod2usage( -input => __FILE__, -output => \*STDERR )
        unless Getopt::Long::GetOptions( \%option, $menu->option() );

    if ( $option{h} )
    {
        warn join "\n", "Default value in [ ]", $menu->string(), "\n";
        return 0;
    }
##  load sequences
    croak "chdir $root: $!\n" unless chdir( $root = $option{root} );
    croak "opendir conf: $!\n" unless opendir my ( $handle ), 'conf';

    my %name = map { $_ => 1 } grep { ! /^\./ } readdir $handle;
    my ( @file, %file ) = qw( pid log lock alert pause );

    close $handle;

    for my $name ( @ARGV ? grep { $name{$_} } @ARGV : keys %name )
    {
        next unless
            my $sequence = eval { DynGig::Automata::Sequence->new( $name ) };

        $file{$name} = +{ map { $_ => $sequence->file( $_ ) } @file };
    }

    my $this = bless \%file, $class;
    my @name = sort keys %file;
##  tail
    while ( $option{t} )
    {
        system( 'clear' );
        map { $this->_tail( $_, $option{t} ) } @name;
        sleep TAIL_PAUSE;
    }

    $option{p} += DynGig::Automata::Serial::KILL
        if $option{p} = $option{k} ? 1200 : $option{p} ? -1200 : 0;

    $option{r} = DynGig::Range::String->new( $option{r} )->list() if $option{r};
    $option{s} = ! grep { $option{$_} } qw( t r R l u p k ) if ! $option{s};

    if ( defined $option{l} )
    {
        my $hms = qr/\d+(?::\d+){0,2}/;

        if ( $option{l} =~ /^($hms)(?:\+($hms))?$/ )
        {
            $option{l} = $2 
            ? +
            { 
                duration => DynGig::Util::Time->hms2sec( $2 ),
                epoch => DynGig::Util::Time->hms2sec( $1 )
            }
            : +
            {
                duration => DynGig::Util::Time->hms2sec( $1 )
            };
        }
        else
        {
            $option{l} = undef;
            warn "invalid lock duration\n";
        }
    }

    for my $name ( @name )
    {
##  load alert database
        my $file = $file{$name};
        my $alert = DynGig::Automata::EZDB::Alert->new( $file->{alert} );
##  resume
        if ( $option{R} )
        {
            map { $alert->truncate( $_ ) } $alert->table();
            _unlink( $file->{pause} );
        }
        elsif ( $option{r} )
        {
            map { $alert->delete( $_ ) } @{ $option{r} };
        }
##  unlock
        _unlink( $file->{lock} ) if $option{u};
##  kill/pause
        DynGig::Util::LockFile::Time
            ->lock( $file->{pause}, duration => $option{p} ) if $option{p}
                && DynGig::Util::LockFile::PID->check( $file->{pid} );
##  lock
        DynGig::Util::LockFile::Time->lock( $file->{lock}, %{ $option{l} } )
            if $option{l};
##  status
        YAML::XS::DumpFile \*STDOUT, $this->_status( $name, $alert )
            if $option{s};
    }

    return 0;
}
    
sub _tail
{
    my ( $this, $name, $count ) = @_;
    my $file = $this->{$name};

    return unless DynGig::Util::LockFile::PID->check( $file->{pid} );

    my $log = $file->{log};

    printf STDERR "$log\t%s\n",
        DynGig::Util::Time->sec2hms( time - ( stat $log )[9] );

    for my $line ( `tail -n $count $log` )
    {
        substr( $line, LINE_WIDTH ) = " ..\n" if length $line > LINE_WIDTH;
        print STDERR $line;
    }

    print STDERR "\n";
}

sub _status
{
    my ( $this, $name, $alert ) = @_;
    my $file = $this->{$name};
    my @status;

    if ( my $sec = DynGig::Util::LockFile::Time->check( $file->{lock} ) )
    {
        @status = sprintf 'lock expires in %s',
            DynGig::Util::Time->sec2hms( $sec );
    }

    if ( ! DynGig::Util::LockFile::PID->check( $file->{pid} ) )
    {
        push @status, 'not running';
    }
    elsif ( my $sec = DynGig::Util::LockFile::Time->check( $file->{pause} ) )
    {
        push @status, $sec < DynGig::Automata::Serial::KILL
            ? 'paused' : 'killed';
    }
    else
    {
        my %alert;

        for my $table ( $alert->table() )
        {
            my $alert = $alert->dump( $table );
            map { $alert{$_} = $alert->{$_} } keys %$alert;
        }

        push @status, %alert ? \%alert : 'running';
    }

    return +{ $name => @status > 1 ? \@status : @status };
}

sub _unlink
{
    my $file = shift @_;
    warn "unlink $file: $!\n" if -f $file && ! unlink $file; 
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__
