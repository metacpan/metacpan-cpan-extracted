=head1 NAME

DynGig::Multiplex::CMD - Multiplexed Fork Client

=cut
package DynGig::Multiplex::CMD;

use warnings;
use strict;
use Carp;

use POSIX ":sys_wait_h";
use IPC::Open3;
use Errno qw( :POSIX );
use Time::HiRes qw( time sleep );
use IO::Poll 0.04 qw( POLLIN POLLERR POLLHUP POLLOUT );

use constant { MAX_BUF => 2 ** 20, MULTIPLEX => 2 ** 5 }; 

=head1 SYNOPSIS
 
 use DynGig::Multiplex::CMD;

 my @target = qw( host1 host2 ... );

 my %config =
 (
     timeout => 30,
     buffer => 'bob loblaw',
     ## {} is replaced with each of the individual 'targets'.
     ## also assuming no SSH password/pass phrase challenge.
     command => 'ssh {} wc',
 ); 

 my $client = DynGig::Multiplex::CMD->new( map { $_ => \%config } @target );

 my %option =
 (
     timeout => 300,     ## global timeout in seconds
     max_buf => 1024,    ## max number of bytes in each read buffer
     multiplex => 100,   ## max number of children processes
     verbose => *STDERR  ## report progress to STDERR
 );

 if ( $client->run( %option ) )
 {
     my $result = $client->result() || {};
     my $error = $client->error() || {};
 }
 else
 {
     print $client->error();
 }

=cut
sub new
{
    my ( $class, %config ) = @_;
    my %done;

    for my $target ( keys %config )
    {
        my $error = "$target: invalid definition"; 
        my $config = $config{$target};

        next if $done{$config};

        croak $error unless $config && ref $config eq 'HASH';

        my $buffer = $config->{buffer};
        my $timeout = $config->{timeout};
        my $command = $config->{command};
        my $ref = defined $command ? ref $command : 'UNDEF';

        croak "$error for timeout" if $timeout
            && ( ref $timeout || $timeout !~ /^\d+$/o );

        croak "$error for command" if $ref && $ref ne 'ARRAY';
        croak "$error for buffer" if $buffer && ref $buffer;

        $config->{buffer} = '' unless defined $buffer;
        $config->{length} = length $config->{buffer};
        $done{$config} = 1;
    }

    bless +{ config => \%config }, ref $class || $class;
}

=head1 DESCRIPTION

=head2 run

Launches client with the following parameter.
Returns 1 if successful. Returns 0 otherwise.

 timeout   : global timeout in seconds
 max_buf   : max number of bytes in each read buffer
 multiplex : max number of children processes
 verbose   : report progress to a file handle opened for write

=cut
sub run
{
    my ( $this, %param ) = @_;
    my $config = $this->{config};

    return 1 unless my @target = keys %$config;

    map { delete $this->{$_} } qw( result error );

    for my $key ( qw( timeout max_buf multiplex ) )
    {
        my $value = $param{$key};
        croak "invalid definition for $key"
            if $value && ( ref $value || $value !~ /^\d+$/o );
    }

    my $poll = IO::Poll->new();

    unless ( $poll )
    {
        $this->{error} = "poll: $!";
        return 0;
    }

    my %mask =
    (
        in => POLLIN | POLLHUP | POLLERR,
        out => POLLOUT,
    );

    my $timeout = $param{timeout};
    my $verbose = $param{verbose};
    my $multiplex = $param{multiplex} || MULTIPLEX;
    my $max_buf = $param{max_buf} || MAX_BUF;
    my @io = qw( stdin stdout stderr );
    my ( %error, %result, %lookup, %pid );
    my $epoch = time;
    my $current = 0;

    $multiplex = @target if $multiplex > @target;
    $verbose = 0 unless $verbose && fileno $verbose;

    while ( $poll->handles || @target )
    {
        my $time = time;

        if ( $timeout && $time - $epoch > $timeout )
        {
            $this->{error} = 'timeout';
            return 0;
        }

        while ( $current < $multiplex && @target )
        {
            my $target = shift @target;
            my $config = $config->{$target};
            my $command = $config->{command};
            my @handle = ( undef, undef, Symbol::gensym );
            my @command = ref $command ? @$command : $command;

            @command = map { $_ =~ s/{}/$target/g; $_; } @command;

            my $pid = eval { IPC::Open3::open3( @handle, @command ); };

            if ( $@ )
            {
                $error{$target} = "open3: $@";
                next;
            }
            $pid{$pid} = 1;

            $lookup{target}{$target} = +
            {
                handle => \@handle,
                epoch => $time,
                pid => $pid,
            };

            my %config =
            (
                target => $target,
                stdout => '',
                stderr => '',
                stdin => \ $config->{buffer},
                length => $config->{length},
                offset => 0,
            );

            for my $i ( 0 .. $#handle )
            {
                my $handle = $handle[$i];

                if ( $i )
                {
                    $poll->mask( $handle => POLLIN );
                }
                else
                {
                    next unless $config{length};
                    $poll->mask( $handle => POLLOUT );
                }

                $lookup{handle}{$handle} = [ \%config, $io[$i] ];
            }

            $current ++;
        }

        $poll->poll( 0.1 );

        for my $handle ( $poll->handles( $mask{in} ) )
        {
            my $buffer;
            my $lookup = $lookup{handle}{$handle};
            my $read = sysread $handle, $buffer, $max_buf;
            my $io = $lookup->[1];

            if ( $read )
            {
                $lookup->[0]{$io} .= $buffer;
                next;
            }

            my $target = $lookup->[0]{target};

            if ( defined $read )
            {
                $result{$target}{$io} = $lookup->[0]{$io};
            }
            else
            {
                next if $! == EAGAIN;
                $error{$target} = "sysread: $!";
            }

            delete $lookup{handle}{$handle};

            $poll->remove( $handle );
            close $handle;
        }

        for my $handle ( $poll->handles( $mask{out} ) )
        {
            my $lookup = $lookup{handle}{$handle};
            my $length = $lookup->[0]{length};
            my $wrote = eval { syswrite $handle, ${ $lookup->[0]{stdin} },
                $length, $lookup->[0]{offset} };

            if ( defined $wrote )
            {
                next if $length != ( $lookup->[0]{offset} += $wrote );
            }
            else
            {
                next if $! == EAGAIN;
                $error{ $lookup->[0]{target} } = "syswrite: $!";
            }

            delete $lookup{handle}{$handle};

            $poll->remove( $handle );
            close $handle;
        }

        for my $target ( keys %{ $lookup{target} } )
        {
            my $timeout = $config->{$target}{timeout};
            my $lookup = $lookup{target}{$target};
            my $handle = $lookup->{handle};
            my $status = 'complete';

            goto NEXT unless grep { $lookup{handle}{$_} } @$handle;
            next if ! $timeout || $timeout > $time - $lookup->{epoch};

            $status = $error{$target} = 'timeout';
            die sprintf( "kill 9, %s", $lookup{pid} )
                unless kill 9, $lookup->{pid};

            for my $handle ( @$handle )
            {
                delete $lookup{handle}{$handle};
                $poll->remove( $handle );
                close $handle;
            }

            NEXT: $current --;
            delete $lookup{target}{$target};
            print $verbose "$target $status.\n" if $verbose;
        }
    }

    while ( keys %pid )
    {
        my $pid = waitpid( -1, WNOHANG );
        last if $! == ECHILD;
        sleep 0.1, next unless $pid > 0;
        delete $pid{$pid};
    }
  
    $this->{result} = \%result if %result;
    $this->{error} = \%error if %error;

    return 1;
}

=head2 result()

Returns undef if no result. Returns a HASH reference indexed by 'target'.

=cut
sub result
{
    my $this = shift;
    return $this->{result};
}

=head2 error()

Returns undef if no error.
Returns a string if a global error occurred, else if errors occurred with
children processes, returns a HASH reference indexed by 'target'.

=cut
sub error
{
    my $this = shift;
    return $this->{error};
}

=head1 SEE ALSO

IPC::Open3 and IO::Poll

=head1 NOTE

See DynGig::Multiplex

=cut

1;

__END__
