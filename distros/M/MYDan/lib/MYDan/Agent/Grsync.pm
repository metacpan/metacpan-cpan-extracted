package MYDan::Agent::Grsync;

=head1 NAME

MYDan::Util::Grsync - Replicate data via phased agent

=head1 SYNOPSIS

 use MYDan::Util::Grsync;
 my $grsync = MYDan::Util::Grsync->new
 (
     src => \@src_hosts,
     dst => \@dst_hosts,
     sp => $src_path,
     dp => $dst_path, ## defaults to sp
 );
 $grsync->run
 (
     timeout => 300, ## default 0, no timeout
     retry => 2,     ## default 0, no retry
     log => $log_handle,    ## default \*STDERR
     max => $max_in_flight, ## default 2
     opt => $rsync_options, ## default -aqz
 );

=cut

use strict;
use warnings;

use Carp;
use YAML::XS;
use FindBin qw( $RealBin );
use MYDan;
use MYDan::Agent::Proxy;
use MYDan::Agent::Mrsync;
use MYDan::Agent::Load;
use MYDan::Agent::Client;

sub new
{
    my ( $class, %self ) = @_;

    my %jobs;

    my %node = map{ $_ => 1} @{$self{src}}, @{$self{dst}};
    my $proxy =  MYDan::Agent::Proxy->new( $self{agent}{proxy} );
    %node = $proxy->search( keys %node );

    map{ 
        my $s = $_; 
	map{
	    push @{$jobs{$node{$_}||'default'}{$s}}, $_;
	}@{$self{$s}} 
    }qw( src dst );

    my ( @load, $dump, @sync, @todo ) = @{$self{src}};

    while ( my( $k, $v ) = each %jobs )
    {
	if( $v->{src} )
	{
	    push @sync, $v if $v->{dst} && @{$v->{dst}};
	}
	else
	{
	    $dump = 1;
	    push @todo, $v;
	}
    }

    my %task;
    $task{sync} = \@sync if @sync;
    $task{todo} = \@todo if @todo;

    if( $dump )
    {
        $task{dump} = $dump;
        $task{load} = \@load if @load;
    }

    bless +{ agent => $self{agent}, task => \%task }, ref $class || $class;
}

sub run
{
    my ( $this, %o ) = @_;

    my %task = %{$this->{task}};

    my %path = map { $_ => delete $o{$_} } qw( sp dp );
    $path{dp} ||= $path{sp};

    my %failed;
    if( $task{sync} )
    {
        for my $sync ( @{$task{sync}} )
        {
	    next unless @{$sync->{dst}};
            my $mrsync = MYDan::Agent::Mrsync->new( %$sync, %path);
            map{ $failed{$_} = 1 } $mrsync->run( %o )->failed();
        }
    }

    my ( $load, $loadok );
    if( $task{load} )
    {
        my $path = "$MYDan::PATH/tmp";
        unless( -d $path ){ mkdir $path;chmod 0777, $path; }
        $path .= '/grsync.data.';
        for my $f ( grep{ -f } glob "$path*" )
        {
            my $t = ( stat $f )[9];
            unlink $f if $t && $t < time - 86400;
        }

        $load  = $path. Digest::MD5->new->add( time.$$ )->hexdigest;

        for ( 0 .. $o{retry} )
        {
            my $i = int( rand time ) % @{$task{load}};
            my $host = $task{load}[$i];
            print "$host => localhost: LOAD\n";

            eval{
                MYDan::Agent::Load->new(
                    node => $host,
                    sp => $path{sp}, dp => $load,
                )->run( %{$this->{agent}}, %o );
            };

            my $stat = $@ ? "FAIL $@" : 'OK';
            print "$host <= localhost: $stat\n";
            if( $stat eq 'OK' )
            {
                $loadok = 1;
                last;
            }

        }
    }

    if( $task{dump} && ( $loadok || ! $task{load}) )
    {
        for ( 0 .. $o{retry} )
        {
            my %dump;
            my $id = -1;
            for my $todo ( @{$task{todo}} )
            {
                $id ++;
                next if $todo->{ok};

                my @dst = @{$todo->{dst}};
                my $i = int( rand time ) % @dst;
                my $dst = $dst[$i];
                $dump{$dst} = $id;
            }
            last unless keys %dump;
            my $argv = sub
            {
                my $code = File::Spec->join( $this->{agent}{argv}, shift );
                return -f $code && ( $code = do $code ) && ref $code eq 'CODE'
                    ? &$code( @_ ) : \@_;
            };

            my %query = ( 
                code => 'dump',
                argv => &$argv( 'dump',$load || $path{sp} , '-path', $path{dp} ),
                 map{ $_ => $o{$_} }qw( user sudo ) 
            );

            map{ print "localhost => $_: DUMP\n" }keys %dump;
            my %result = MYDan::Agent::Client->new(
                keys %dump
            )->run( %{$this->{agent}}, %o, query => \%query );

            map{ 
                my $stat = $result{$_} && $result{$_} eq "ok\n--- 0\n" 
                    ? 'OK' : sprintf "Fail: %s", $result{$_} || 'error';
                print "$_ <= localhost: $stat\n";
                $task{todo}[$dump{$_}]{ok} = $_ if $stat eq 'OK' 

            }keys %dump;
        }
    }

    if( $task{todo} )
    {
        for my $todo ( @{$task{todo}} )
        {
            if( $todo->{ok} )
            {
		my @dst = grep{ $_ ne $todo->{ok} }@{$todo->{dst}};
		next unless @dst;
                my $mrsync = MYDan::Agent::Mrsync->new( 
                    src => [ $todo->{ok} ], dst => \@dst, map{ $_ => $path{dp} }qw( sp dp ) );
                map{ $failed{$_} = 1 }$mrsync->run( %o )->failed();
            }
            else { map{ $failed{$_} = 1 }@{$todo->{dst}}; } 
        }
    }

    $this->{failed} = [ keys %failed ];
    return $this;
}

sub failed
{
    my $self = shift;
    my $failed = $self->{failed};
    return wantarray ? @$failed : $failed;
}

1;
