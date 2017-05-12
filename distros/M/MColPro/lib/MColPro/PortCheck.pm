package MColPro::PortCheck;

use Fcntl qw( F_GETFL F_SETFL O_NONBLOCK );
use Socket qw( SOCK_STREAM PF_INET inet_aton inet_ntoa sockaddr_in );
use POSIX qw( ENOTCONN ECONNREFUSED ECONNRESET EINPROGRESS EWOULDBLOCK EAGAIN WNOHANG );
use FileHandle;
use Carp;
use Time::HiRes qw( time );

sub new
{
    my ( $this, %param ) = @_;

    $param{wbits} = "";

    bless \%param, ref $this || $this;
}

sub endtime
{
    my ( $self, $time ) = @_;

    $self->{stop_time} = time + $time;
}

sub syn
{
    my ( $self, $host, $port ) = @_;
    my %result;
    my %run;
    my $wbits;

    my $ip = inet_aton($host);
    return $! unless defined $ip;
  
    my $fh = FileHandle->new();
    my $saddr = sockaddr_in( $port, $ip );
  
    # Create TCP socket
    return "tcp socket error - $!"
        unless socket( $fh, PF_INET, SOCK_STREAM, getprotobyname("tcp") );
  
    if( $flags = fcntl($fh, F_GETFL, 0) )
    {
        $flags = $flags | O_NONBLOCK;
        unless( fcntl( $fh, F_SETFL, $flags ) )
        {
            return "fcntl F_SETFL: $!";
        }
    }
    else
    {
        return "fcntl F_GETFL: $!";
    }
  
    unless( connect( $fh, $saddr ) )
    {
        unless( $! == EINPROGRESS )
        {
            my $t = $!;
            chomp $!;
            $self->{bad}{$host}{$port} = $t;
        }
    }
  
    my $entry =
    {
        host => $host,
        ip => $ip,
        fh => $fh,
        port => $port,
        start => time,
    };
    $self->{syn}{$fh->fileno} = $entry;
    vec( $self->{wbits}, $fh->fileno, 1 ) = 1;
  
    return 1;
}

sub ack
{
    my $self = shift;

    my $wbits = $self->{wbits};
    my $stop_time = $self->{stop_time} || time + 10;;

    while( $wbits !~ /^\0*\z/ )
    {
        my $timeout = $stop_time - time;
        # Force a minimum of 10 ms timeout.
        $timeout = 0.01 if $timeout <= 0.01;
        
        my $winner_fd = undef;
        my $wout = $wbits;
        my $fd = 0;

        # Do "bad" fds from $wbits first
        while( $wout !~ /^\0*\z/ )
        {
            if( vec($wout, $fd, 1) )
            {
                # Wipe it from future scanning.
                vec( $wout, $fd, 1 ) = 0;
                if( my $entry = $self->{syn}{$fd} )
                {
                    if( $self->{bad}{$entry->{host}} &&
                        $self->{bad}{$entry->{host}}{$entry->{port}} )
                    {
                        $winner_fd = $fd;
                        last;
                    }
                }
            }
            $fd++;
        }
        
        if( defined $winner_fd
            or my $nfound = mselect( undef, ( $wout=$wbits ), undef, $timeout ) )
        {
            if( defined $winner_fd )
            {
                $fd = $winner_fd;
            }
            else
            {
                # Done waiting for one of the ACKs
                $fd = 0;
                # Determine which one
                while( $wout !~ /^\0*\z/ && !vec( $wout, $fd, 1 ) )
                {
                    $fd++;
                }
            }

            if( my $entry = $self->{"syn"}->{$fd} )
            {
                # Wipe it from future scanning.
                delete $self->{syn}->{$fd};
                vec( $self->{wbits}, $fd, 1 ) = 0;
                vec( $wbits, $fd, 1 ) = 0;
                if( getpeername( $entry->{fh} ) )
                {
                    # Connection established to remote host
                    # Good, continue
                }
                else
                {
                    # TCP ACK will never come from this host
                    # because there was an error connecting.
        
                    # This should set $! to the correct error.
                    my $char;
                    sysread( $entry->{fh}, $char, 1 );
                    # Store the excuse why the connection failed.
                    my $t = $!;
                    chomp $t;
                    $self->{bad}{$entry->{host}}{$entry->{port}} = $t;
                    next;
                }

                # Everything passed okay, return the answer
                return ( $entry->{host}, $entry->{port},
                    time - $entry->{start} );
            }
            else
            {
                warn "Corrupted SYN entry: unknown fd [$fd] ready!";
                vec($wbits, $fd, 1) = 0;
                vec($self->{"wbits"}, $fd, 1) = 0;
            }
        }
        elsif( defined $nfound )
        {
            # Timed out waiting for ACK
            foreach my $fd ( keys %{ $self->{syn} } )
            {
                if( vec( $wbits, $fd, 1 ) )
                {
                    my $entry = $self->{syn}{$fd};
                    $self->{bad}{$entry->{host}}{$entry->{port}} = "TimedOut";
                    vec( $wbits, $fd, 1 ) = 0;
                    vec( $self->{wbits}, $fd, 1 ) = 0;
                    delete $self->{syn}{$fd};
                }
            }
        }
        else
        {
            # Weird error occurred with select()
            warn("select: $!");
            $self->{"syn"} = {};
            $wbits = "";
        }
    }

    return ();
}

sub mselect
{
    my $nfound = select($_[0], $_[1], $_[2], $_[3]);
    undef $nfound if $nfound == -1;
    return $nfound;
}

1;
