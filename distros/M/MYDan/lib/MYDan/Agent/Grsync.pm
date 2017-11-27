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
use MYDan;
use MYDan::Agent::Proxy;

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

    bless +{ agent => $self{agent}, task => \%task, proxy => \%node }, ref $class || $class;
}

sub failed
{
    my $self = shift;
    my $failed = $self->{failed};
    return wantarray ? @$failed : $failed;
}

1;
