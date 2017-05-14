=head1 NAME

DynGig::CLI::Service - CLI for daemontools service.

=cut
package DynGig::CLI::Service;

use warnings;
use strict;
use Carp;

use Cwd qw();
use File::Spec;
use File::Temp;
use Pod::Usage;
use Getopt::Long qw( :config bundling );

use DynGig::Util::CLI;
use DynGig::Util::Setuid;

our $SVC_PATH;

$| ++;

=head1 EXAMPLE

 use YAML::XS;
 use FindBin qw( $Bin );
 use DynGig::CLI::Service;

 ################################################################
 ##                   define services here                     ##
 ################################################################

 my $config =<< "END_CONF";
 ---
 cluster.server:
   command: "$Bin/cluster.server -p 34567"
   svc_root: /home/huan/service
   log_size: 100000
   log_keep: 10
   user: huan
   pause: 60
   nice: 19

 END_CONF

 ################################################################

 DynGig::CLI::Service->main( config => YAML::XS::Load $config );

=head1 SYNOPSIS

$exe B<--help>

$exe name [B<--svc-path> directory] B<--up>

$exe name [B<--svc-path> directory] B<--down>

$exe name [B<--svc-path> directory] B<--kill>

$exe name [B<--svc-path> directory] B<--restart>

$exe name [B<--svc-path> directory] [B<--status>]

=cut
sub main
{
    my ( $class, %option ) = @_;

    croak "config not defined\n" unless my $config = $option{config};
    croak "invalid config\n" if ref $config ne 'HASH';

    my $menu = DynGig::Util::CLI->new
    (
        'h|help','help menu',
        's|status','service status',
        'u|up','set up service',
        'd|down','down service, stop process gracefully',
        'k|kill','down and exit service, kill process',
        'r|restart','restart service gracefully',
        'svc-path=s','parent directory path of svc',
    );
    
    my %pod_param = ( -input => __FILE__, -output => \*STDERR );
    my @argv = @ARGV;

    Pod::Usage::pod2usage( %pod_param )
        unless Getopt::Long::GetOptions( \%option, $menu->option() );

    if ( $option{h} )
    {
        warn join "\n", "Default value in [ ]", $menu->string(), "\n";
        return 0;
    }

    Pod::Usage::pod2usage( %pod_param ) if @ARGV != 1;

    croak "service not supported\n" unless $config = $config->{ $ARGV[0] };

    map { croak "$_ not defined\n" unless $config->{$_} }
        qw( user nice pause command svc_root log_keep log_size );

    if ( $> )
    {
        @ARGV = @argv;
        DynGig::Util::Setuid->sudo();
    }

    my $root = $config->{svc_root};
    my $svc = File::Spec->join( File::Spec->rootdir(), 'service' );

    croak "chdir $root: $!" unless chdir $root;
    croak 'invalid service directory' if ! $svc || -e $svc && ! -d $svc;
    croak "mkdir $svc: $!" unless -d $svc || mkdir $svc;

    $option{s} = ! grep { $option{$_} } qw( u d k r ) if ! $option{s};

    my $name = shift @ARGV;
    my $link = File::Spec->join( $svc, $name );
    my $path = File::Spec->catdir( $root, $name );
    my $log = File::Spec->catdir( $path, 'log' );

    $SVC_PATH = $option{'svc-path'} if defined $option{'svc-path'};

    if ( $option{d} || $option{k} || $option{r} )
    {
## down
	    if ( -l $link )
	    {
            unlink $link;
            _svc( '-dx', $path ) && _svc( '-dx', $log );
	    }
## kill
        system( "rm -rf $path" ) if $option{k};
    }
## up
    _start( $name, $config, $link, $path, $log ) if $option{u} || $option{r};
## status
    system _path( 'svstat' ), $path if $option{s};

    return 0;
}

sub _path
{
    my $command = shift @_;

    return $command unless $SVC_PATH;

    my $path = Cwd::abs_path( $SVC_PATH );

    return $path && -d $path ? File::Spec->join( $path, $command ) : $command;
}

sub _svc
{
    return ! system _path( 'svc' ), @_;
}

sub _start
{
    my ( $name, $config, $link, $path, $log ) = @_;

    croak "cannot mkdir $log" if system 'mkdir', '-p', $log;

    my $setuidgid = _path( 'setuidgid' );
    my $multilog = _path( 'multilog' );
    my $user = $config->{user};
    my $main = './main';

    _run_script( $name, "exec %s %s nice -n %d %s 2>&1 || sleep %d",
        $setuidgid, map { $config->{$_} } qw( user nice command pause ) );

    _run_script( $log,
        "mkdir -p %s\nchown -R %s %s\nexec %s %s %s t I s%d n%d %s",
        $main, $user, $main, $setuidgid, $user, $multilog,
        $config->{log_size}, $config->{log_keep}, $main );

    die "$name: already running\n" if -l $link;

    croak "symlink: $!" unless symlink $path, $link;
}

sub _run_script
{
    my $path = shift @_;
    my $handle = File::Temp->new();
    my $temp = $handle->filename();

    printf $handle "#!/bin/sh\n";
    printf $handle @_;

    $path = File::Spec->join( $path, 'run' );
    $handle->unlink_on_destroy( 0 );

    croak "failed to mv $temp $path" if system 'mv', $temp, $path;
    croak "chmod $path: $!" unless chmod 0544, $path;
}

=head1 NOTE

See DynGig::CLI

=cut

1;

__END__
