package Linux::MCELog;

use strict;
use warnings;

our @EXPORT_OK = qw(ping dump_all);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );
use base qw(Exporter);

our $VERSION = '0.02';

use IO::Socket::UNIX;

sub ping {
    my $mcelog_client = defined($_[0]) ? $_[0] : '/var/run/mcelog-client';
    my $sock;
    my $ping_result = 0;
    my $line = '';

    eval {
        $sock = IO::Socket::UNIX->new(
            Peer => $mcelog_client,
            Type => SOCK_STREAM,
        ) or die "socket_error";
    };

    if ($@ =~ /socket_error/) {
        $ping_result = 'socket_error';
    } else {
        $sock->autoflush(1);
 
        # send ping command
        print $sock "ping\n";

        # set up 30 seconds timeout
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm(30);
            chomp($line = <$sock>);
        };

        alarm(0);

        if ($@ =~ /timeout/) {
            $ping_result = 'timeout';
        } else {
            $ping_result = 1 if ($line =~ /pong/);
        }

        $sock->close();
    }

    return $ping_result;
}

sub dump_all {
    my $mcelog_client = defined($_[0]) ? $_[0] : '/var/run/mcelog-client';
    my %dump_all;
    my $dump_all = \%dump_all;
    my $sock;

    eval {
        $sock = IO::Socket::UNIX->new(
            Peer => $mcelog_client,
            Type => SOCK_STREAM,
        ) or die "socket_error";
    };

    if ($@ =~ /socket_error/) {
        $dump_all->{'error'} = 'socket_error';
    } else {
        $sock->autoflush(1);
    
        # send "dump all" command
        print $sock "dump all\n";
    
        # set up 30 seconds timeout
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm(30);
    
            my ($corr_marker, $uncorr_marker);
            my ($socket, $channel, $dimm);
    
            while (chomp(my $line = <$sock>)) {
                if ($line =~ /done/) {
                    last;
                }
    
                # record socket / channel / dimm information
                if ($line =~ /SOCKET (\d+) CHANNEL (\w+) DIMM (\w+)/) {
                    ($socket, $channel, $dimm) = ($1, $2, $3);
                    $dump_all->{'socket'}->{$socket}->{'channel'}->{$channel}->{'dimm'}->{$dimm}->{'corrected_errors'}->{'total'} = 0;
                    $dump_all->{'socket'}->{$socket}->{'channel'}->{$channel}->{'dimm'}->{$dimm}->{'corrected_errors'}->{'24h'} = 0;
                    $dump_all->{'socket'}->{$socket}->{'channel'}->{$channel}->{'dimm'}->{$dimm}->{'uncorrected_errors'}->{'total'} = 0;
                    $dump_all->{'socket'}->{$socket}->{'channel'}->{$channel}->{'dimm'}->{$dimm}->{'uncorrected_errors'}->{'24h'} = 0;
                }
    
                if ($line =~ /^corrected memory errors/) {
                    $corr_marker = 1;
                }
    
                # if corr_marker is defined but uncorr_marker is not, that means we meet corrected errors part only
                if (defined($corr_marker) && !defined($uncorr_marker)) {
                    if ($line =~ /(\d+) total/) {
                        $dump_all->{'socket'}->{$socket}->{'channel'}->{$channel}->{'dimm'}->{$dimm}->{'corrected_errors'}->{'total'} = $1;
                    }
    
                    if ($line =~ /(\d+) in 24h/) {
                        $dump_all->{'socket'}->{$socket}->{'channel'}->{$channel}->{'dimm'}->{$dimm}->{'corrected_errors'}->{'24h'} = $1;
                    }
                }
    
                if ($line =~ /^uncorrected memory errors/) {
                    $uncorr_marker = 1;
                }
    
                # if both corr_marker and uncorr_marker are defined, that means we processed corrected errors part already and meet uncorrected errors part now
                if (defined($corr_marker) && defined($uncorr_marker)) {
                    if ($line =~ /(\d+) total/) {
                        $dump_all->{'socket'}->{$socket}->{'channel'}->{$channel}->{'dimm'}->{$dimm}->{'uncorrected_errors'}->{'total'} = $1;
                    }
    
                    if ($line =~ /(\d+) in 24h/) {
                        $dump_all->{'socket'}->{$socket}->{'channel'}->{$channel}->{'dimm'}->{$dimm}->{'uncorrected_errors'}->{'24h'} = $1;
                    }
                }
    
                # a new line indicates another information block, reset all variables
                if ($line =~ /^$/) {
                    ($corr_marker, $uncorr_marker) = (undef, undef);
                    ($socket, $channel, $dimm) = (undef, undef, undef);
                    next;
                }
            }
        };
    
        alarm(0);
    
        if ($@ =~ /timeout/) {
            $dump_all->{'error'} = 'timeout';
        }
    }

    return $dump_all;
}

1;

__END__

=head1 NAME

Linux::MCELog - Perl extensions to extract memory failure information from MCELog UNIX domain socket on Linux.

=head1 SYNOPSIS

  use Data::Dumper;
  use Linux::MCELog qw(ping dump_all);

  # test if MCELog UNIX domain socket is pingable
  print "OK\n" if (ping() == 1);

  # print memory failures
  print Dumper(dump_all());

=head1 DESCRIPTION

Linux::MCELog is a module to extract memory failure information from MCELog (Machine Check Exception) UNIX domain socket on Linux.

=head1 EXPORT

Nothing is exported by default. You can ask for specific subroutines (described below) or ask for all subroutines at once:

    use Linux::MCELog qw(ping dump_all);
    # or
    use Linux::MCELog qw(:all);

=head1 SUBROUTINES

=head2 ping

Return a scalar to indicate if the MCELog UNIX domain socket is pingable (answerable). This function uses C</var/run/mcelog-client> as the default MCELog UNIX domain socket path. However, user can still pass different UNIX domain socket path in the function like C<ping('/diff/socket/path')>.

There are 3 possible return values in function.

C<1>: MCELog UNIX domain socket is pingable. If the C<ping()> function does not return 1, user needs to check if the MCELog is functional before running any other functions.

C<socket_error>: Cannot access the MCELog UNIX domain socket.

C<timeout>: Cannot read the ping response message after 30 seconds.

=head2 dump_all

Return a hash reference about the memory failures. This reference would have the corrected and uncorrected figures by C<SOCKET> / C<CHANNEL> / C<DIMM>.  This function uses C</var/run/mcelog-client> as the default MCELog UNIX domain socket path. However, user can still pass different UNIX domain socket path in the function like C<ping('/diff/socket/path')>. 

It is possible the returned hash reference is empty. MCELog data will be available only when there's an event triggered.

There are 2 possible return values in the C<{'error'}> key if error occurs.

C<socket_error>: Cannot access the MCELog UNIX domain socket.

C<timeout>: Cannot read the C<dump all> response message after 30 seconds.

=head1 SEE ALSO

You can find documentation for this module with the perldoc command.

    perldoc Linux::MCELog

Source Code: L<https://github.com/meow-watermelon/Linux-MCELog>

MCELog Official Website: L<https://mcelog.org>

=head1 AUTHOR

Hui Li, E<lt>herdingcat@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
