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
    confess "poll: $!" unless my $poll = IO::Poll->new();

    local $| = 1;
    local $/ = undef;

    my $self = shift;
    my @node = keys %$self;
    my ( %run, %result, %buffer, %busy ) = ( %RUN, @_ );
    my ( $log, $max, $timeout, $interchange ) = @run{ qw( log max timeout interchange ) };
    my %node = map { $_ => {} } qw( stdout stderr );
    my $input = defined $run{input} ? $run{input} : -t STDIN ? '' : <STDIN>;

    for ( my $time = time; @node || $poll->handles; )
    {
        if ( time - $time > $timeout ) ## timeout
        {
            for my $node ( keys %busy )
            {
                my ( $pid ) = @{ delete $busy{$node} };
                kill 9, $pid;
                waitpid $pid, WNOHANG;
                push @{ $result{error}{timeout} }, $node;
            }

            print $log "timeout!\n";
            last;
        }

        while ( @node && keys %busy < $max )
        {
            my $node = shift @node;
            my $cmd = $self->{$node};
            my @cmd = map { my $t = $_; $t =~ s/$interchange/$node/g; $t } @$cmd;

            if ( $run{noop} )
            {
                print $log join ' ', @cmd, "\n";
                next;
            }

            my @io = ( undef, undef, Symbol::gensym );
            my $pid = eval { IPC::Open3::open3( @io, @cmd ) };

            if ( $@ )
            {
                push @{ $result{error}{ "open3: $@" } }, $node;
                next;
            }

            $poll->mask( $io[0] => POLLOUT ) if $input;
            $poll->mask( $io[1] => POLLIN );
            $poll->mask( $io[2] => POLLIN );

            $node{ $io[1] } = [ stdout => $node ]; 
            $node{ $io[2] } = [ stderr => $node ]; 

            $busy{$node} = [ $pid, 2 ];
            print $log "$node started.\n" if $run{verbose};
        }

        $poll->poll( $MAX{period} );

        for my $fh ( $poll->handles( POLLIN ) ) ## stdout/stderr
        {
            sysread $fh, my $buffer, $MAX{buffer};
            $buffer{$fh} .= $buffer;
        }

        for my $fh ( $poll->handles( POLLOUT ) ) ## stdin
        {
            syswrite $fh, $input;
            $poll->remove( $fh );
            close $fh;
        }

        for my $fh ( $poll->handles( POLLHUP ) ) ## done
        {
            my ( $io, $node ) = @{ delete $node{$fh} };

            push @{ $result{$io}{ delete $buffer{$fh} } }, $node
                if defined $buffer{$fh} && length $buffer{$fh} 
                    && ( $buffer{$fh} =~ s/$node/$interchange/g || 1 );

            unless ( -- $busy{$node}[1] )
            {
                waitpid $busy{$node}[0], WNOHANG;
                my $stat = $? == -1 ? 110 : $? & 127 ? 112 : $? >> 8;
                push @{ $result{status}{$stat} }, $node;
                delete $busy{$node};
                print $log "$node done.\n" if $run{verbose};
            }

            $poll->remove( $fh );
            close $fh;
        }
    }

    push @{ $result{error}{'not run'} }, @node if @node;
    return wantarray ? %result : \%result;
}

1;
