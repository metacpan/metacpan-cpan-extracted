use Test2::V0;
use strict;
use warnings;
use IO::SocketAlarm 'socketalarm';
use Socket ":all";
use Time::HiRes 'sleep';
use IO::Socket;

sub tcp_socketpair;
sub collect_alarms {
   my ($s1, $s2)= @_;
   my @got_alarm;
   local $SIG{ALRM}= sub { note "Got alarm early"; push @got_alarm, 'early' };
   ok( my $alarm= socketalarm($s2), 'socketalarm' );
   sleep .1;
   $SIG{ALRM}= sub { note "Got alarm"; push @got_alarm, 'ontime' };
   shutdown($s1, SHUT_WR);
   sleep .1;
   $SIG{ALRM}= sub { note "Got alarm late"; push @got_alarm, 'late' };
   close($s1);
   close($s2);
   sleep .1;
   $alarm->cancel;
   return \@got_alarm;
}

socketpair(my $s1, my $s2, AF_UNIX, SOCK_STREAM, 0);
is( collect_alarms($s1,$s2), ['ontime'], 'UNIX alarms' );

# repeat the test for TCP sockets
($s1, $s2)= tcp_socketpair;
is( collect_alarms($s1,$s2), ['ontime'], 'TCP alarms' );

# Set up a cascade of shutdowns
{
   my @got_alarm;
   local $SIG{ALRM}= sub { note "Got alarm early"; push @got_alarm, 'early' };

   ($s1, $s2)= tcp_socketpair;
   my @seq= ( $s1, $s2, socketalarm($s2) );
   for (1..9) {
      ($s1, $s2)= tcp_socketpair;
      push @seq, $s1, $s2, socketalarm($s2, [ shut_w => $seq[-3] ]);
   }

   sleep .1;
   $SIG{ALRM}= sub { note "Got alarm"; push @got_alarm, 'ontime' };
   ok( !$seq[-1]->triggered, 'not triggered yet' ) or note "cur_action = ".$seq[-1]->cur_action;
   # shutdown the final socket, triggering a chain reaction of shutdowns, and finally the signal
   shutdown($seq[-3], SHUT_WR);
   sleep 10; # sleep will get interrupted
   ok( $seq[-1]->triggered, 'triggered' );
   ok( $seq[-1]->finished, 'finished' );
   is( \@got_alarm, ['ontime'], 'cascade ending with alarm' );
}

my $tcp_listen;
sub tcp_socketpair {
   unless ($tcp_listen) {
      socket $tcp_listen, AF_INET, SOCK_STREAM, 0
         or die "socket: $!";
      $tcp_listen->blocking(0);
      listen $tcp_listen, 10
         or die "listen: $!";
   }
   socket my $sc, AF_INET, SOCK_STREAM, 0
      or die "socket: $!";
   $sc->blocking(0);
   connect $sc, getsockname $tcp_listen
      or $!{EINPROGRESS} or die "connect: $!";
   accept my $ss, $tcp_listen
      or die "accept: $!";
   setsockopt($sc, IPPROTO_TCP, TCP_NODELAY, 1);
   setsockopt($ss, IPPROTO_TCP, TCP_NODELAY, 1);
   return ($sc, $ss);
}
close $tcp_listen;

done_testing;
