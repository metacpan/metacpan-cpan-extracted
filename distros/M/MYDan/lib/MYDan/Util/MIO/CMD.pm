package MYDan::Util::MIO::CMD;

=head1 NAME

MYDan::Util::MIO::CMD - Run multiple commands in parallel.

=head1 SYNOPSIS
 
 use MYDan::Util::MIO::CMD;

 my @node = qw( host1 host2 ... );
 my @cmd = qw( ssh {} wc );

 my $cmd = MYDan::Util::MIO::CMD->new( map { $_ => \@cmd } @node );
 my $result = $cmd->run( max => 32, log => \*STDERR, timeout => 300 );

 my $stdout = $result->{stdout};
 my $stderr = $result->{stderr};
 my $error = $result->{error};

=cut
use strict;
use warnings;

use Carp;
use IPC::Open3;
use Time::HiRes qw( time );
use POSIX qw( :sys_wait_h );
use IO::Poll qw( POLLIN POLLHUP POLLOUT );
use Tie::File;
use FindBin qw( $Script );

use base qw( MYDan::Util::MIO );

our %RUN = ( %MYDan::Util::MIO::RUN, interchange => '{}' );
our %MAX = %MYDan::Util::MIO::MAX;

sub new
{
    my $self = shift;
    $self->cmd( @_ );
}

=head1 METHODS

=head3 run( %param )

Run commands in parallel.
The following parameters may be defined in I<%param>:

 max : ( default 128 ) number of commands in parallel.
 log : ( default STDERR ) a handle to report progress.
 timeout : ( default 300 ) number of seconds allotted for each command.
 input : ( default from STDIN ) input buffer.

Returns HASH of HASH of nodes. First level is indexed by type
( I<stdout>, I<stderr>, or I<error> ). Second level is indexed by message.

=cut
sub run
{
    local $| = 1;

    my $self = shift;
    my @node = keys %$self;
    my ( $run, $ext, %run, %result, %busy ) = ( 1, "$Script.$$", %RUN, @_ );
    my ( $max, $timeout, $interchange ) = @run{ qw( max timeout interchange ) };
    my $input = defined $run{input} ? $run{input} : -t STDIN ? '' : <STDIN>;

    $SIG{INT} = $SIG{TERM} = sub
    {
        print STDERR "killed\n";
        $run = 0;
    };

    for ( my $time = time; $run && ( @node || %busy ); )
    {
        $run = 0 if time - $time > $timeout;

        while ( @node && keys %busy < $max )
        {
            my $node = shift @node;
	    my $log = "/tmp/$node.$ext";
            my $cmd = $self->{$node};
            my @cmd = map { my $t = $_; $t =~ s/$interchange/$node/g; $t } @$cmd;

            if ( $run{noop} )
            {
                print join ' ', @cmd, "\n";
                next;
            }

            print "$node started.\n" if $run{verbose};

            if ( my $pid = fork() ) { $busy{$pid} = [ $log, $node ]; next } 

	    open STDOUT, ">>$log";
	    open STDERR, ">>$log";
	    
	    exec sprintf join ' ', @cmd;
	    exit 0;
        }

        for ( keys %busy )
        {
            my $pid = waitpid( -1, WNOHANG );
            next if $pid <= 0;

	    my $stat = $? >> 8;

            my ( $log, $node ) = @{ delete $busy{$pid} };

            print "$node done.\n" if $run{verbose};

            tie my @log, 'Tie::File', $log,recsep => "\n";

            push @{ $result{output}{ join "\n", @log, "--- $stat", '' } }, $node;
            unlink $log;
        }
    }

    kill 9, keys %busy;
    push @{ $result{output}{killed} }, map{ $busy{$_}[1]}keys %busy;
    push @{ $result{output}{norun} }, @node;
    unlink glob "/tmp/*.$ext";
    unlink $input if $input && -f $input;

    return wantarray ? %result : \%result;
}

1;
