=head1 NAME

DynGig::CLI::Watcher::Exclude - CLI for watcher exclude.

=cut
package DynGig::CLI::Watcher::Exclude;

use warnings;
use strict;
use Carp;

use POSIX;
use Cwd qw();
use YAML::XS;
use File::Spec;
use Pod::Usage;
use Getopt::Long qw( :config bundling );

use DynGig::Util::CLI;
use DynGig::Util::Time;
use DynGig::Util::Setuid;
use DynGig::Util::LockFile::PID;
use DynGig::Automata::MapReduce;
use DynGig::Range::String;

$| ++;

=head1 EXAMPLE

 use DynGig::CLI::Watcher::Exclude;

 DynGig::CLI::Watcher::Exclude->main
 (
     user => 'username',
     root => '/watcher/root/path',
 );

=head1 SYNOPSIS

$exe B<--help>

$exe [B<--root> dir] [B<--user> user] [B<--job> jobs] [B<--target> targets]
[name ..] B<--lock> period

$exe [B<--root> dir] [B<--user> user] [B<--job> jobs] [B<--target> targets]
[name ..] B<--unlock>

$exe [B<--root> dir] [B<--user> user] [B<--job> jobs] [B<--target> targets]
[name ..] [B<--status>]

=cut
sub main
{
    my ( $class, %option ) = @_;

    map { croak "$_ not defined" if ! defined $option{$_} } qw( root user );

    die "must run as non-super user\n" unless $< && $>;

    my $menu = DynGig::Util::CLI->new
    (
        'h|help','help menu',
        's|status','status',
        'u|unlock','unexclude',
        'l|lock=s','duration to exclude',
        'j|job=s','[ all ] jobs to exclude',
        't|target=s','[ all ] targets to exclude',
        'user=s',"[ $option{user} ] run as user",
        'root=s',"[ $option{root} ]",
    );
    
    my %pod_param = ( -input => __FILE__, -output => \*STDERR );
    my $who = ( getpwuid $< )[0];

    push @ARGV, $who;
    my @argv = @ARGV;

    Pod::Usage::pod2usage( %pod_param )
        unless Getopt::Long::GetOptions( \%option, $menu->option() );

    if ( $option{h} )
    {
        warn join "\n", "Default value in [ ]", $menu->string(), "\n";
        return 0;
    }

    $who = pop @ARGV;

    if ( $who ne $option{user} )
    {
        @ARGV = @argv;
        DynGig::Util::Setuid->sudo( $option{user} );
    }

    my $root = $option{root};
    my @name = @ARGV;

    croak "chdir $root: $!" unless chdir $root;

    unless ( @name )
    {
        my ( $dir, $handle ) = 'conf';

        croak "opendir $dir: $!" unless opendir $handle, $dir;

        @name = grep { -f File::Spec->join( $dir, $_ ) } readdir $handle;
    }

    $option{s} = ! grep { $option{$_} } qw( u l ) if ! $option{s};

    my ( $time, @time ) = time;

    if ( defined $option{l} )
    {
        my $hms = qr/\d+(?::\d+){0,2}/;

        if ( $option{l} =~ /^($hms)(?:\+($hms))?$/ )
        {
            @time = $2
                ? map { DynGig::Util::Time->hms2sec( $_ ) } $1, $2
                : ( $time, DynGig::Util::Time->hms2sec( $1 ) );
        }
        else
        {
            warn "invalid lock duration\n";
        }
    }

    my $global = DynGig::Automata::Serial::GLOBAL;
    my @job = DynGig::Range::String->new( $option{j} )->list() if $option{j};
    my @target = DynGig::Range::String->new( $option{t} )->list() if $option{t};

    for my $name ( @name )
    {
        my $sequence = DynGig::Automata::MapReduce->new( $name )->setup();

        unless ( eval { DynGig::Util::LockFile::PID
            ->check( $sequence->file( 'pid' ) ) } )
        {
            warn "$name: not running\n";
            next;
        }

        my %job = map { $_ => 1 } $sequence->job();
        my @job = $option{j} ? grep { $job{$_} } @job : keys %job;
        my $exclude = $sequence->exclude();
        my ( $target, $job );

        if ( @target )
        {
            $target = \@target;
            $job = \@job;
        }
        else
        {
            $target = \@job;
            $job = [ $global ];
        }

        if ( $option{u} )
        {
            for my $job ( @$job )
            {
                map { $exclude->delete( $job, key => $_ ) } @$target;
            }
        }
        elsif ( @time && $time[1] )
        {
            for my $job ( @$job )
            {
                map { $exclude->set( $job, @time, $_, $who ) } @$target;
            }
        }

        if ( $option{s} )
        {
            my ( %time, %exclude );
            my %target = map { $_ => 1 } @target;

            unshift @job, $global unless $option{j};

            for my $job ( @job )
            {
                for my $record ( $exclude->get( $job, $time ) )
                {
                    my ( $target, $who ) = splice @$record, 2;

                    next if @target && ! $target{$target};

                    my @time = map { _format( $_, \%time ) } @$record;
                    my $msg = $time[0] eq $time[2]
                        ? sprintf '%s, %s .. %s by %s', @time[0,1,3], $who,
                        : sprintf '%s, %s .. %s, %s by %s', @time, $who;

                    push @{ $exclude{$job}{$msg} }, $target;
                }
            }

            YAML::XS::DumpFile \*STDOUT, +{ $name => \%exclude } if %exclude;
        }
    }

    return 0;
}

sub _format
{
    my ( $time, $done ) = @_;
    my @time;

    $time = $done->{$time} ||=
    [
        POSIX::strftime( '%a %b %d', @time = localtime $time ),
        POSIX::strftime( '%H:%M:%S', @time ),
    ];

    return @$time;
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__
