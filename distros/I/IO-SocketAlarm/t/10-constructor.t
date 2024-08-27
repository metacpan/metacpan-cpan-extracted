use Test2::V0;
use Socket ':all';
use POSIX ':signal_h';
use File::Temp;
use IO::SocketAlarm;

my @tests= (
   {  spec   => [],
      result => [ [ kill => SIGALRM, $$ ] ],
      desc   => [ "kill sig=".SIGALRM." pid=$$" ],
   },
   {  spec   => undef,
      result => [ [ kill => SIGALRM, $$ ] ],
      desc   => [ "kill sig=".SIGALRM." pid=$$" ],
   },
   {  spec   => [ [ sleep => 1 ] ],
      desc   => [ 'sleep 1.000s' ],
   },
   {  spec   => [ [ run => 'echo', 'Test' ] ],
      desc   => [ "fork,fork,exec('echo','Test')" ],
   },
   {  spec   => [ [ exec => 'echo', 'Test' ] ],
      desc   => [ "exec('echo','Test')" ],
   },
   {  spec   => [ [ sig => 9 ] ],
      result => [ [ kill => 9, $$ ] ],
      desc   => [ "kill sig=9 pid=$$" ],
   },
   {  spec   => [ [ kill => 10, 19000 ] ],
      desc   => [ "kill sig=10 pid=19000" ],
   },
   {  spec   => [ [ close => 0 ] ],
      desc   => [ 'close 0' ],
   },
   {  spec   => [ [ close => 0, 1, 2 ] ],
      result => [ [ close => 0 ], [ close => 1 ], [ close => 2 ] ],
      desc   => [ 'close 0', 'close 1', 'close 2' ],
   },
   {  spec   => [ [ close => pack_sockaddr_in(42, inet_aton('127.0.0.1')) ] ],
      desc   => [ 'close peername inet 127.0.0.1:42' ],
   },
   {  spec   => [ [ shut_r => 0 ] ],
      desc   => [ 'shutdown SHUT_RD 0' ],
   },
   {  spec   => [ [ shut_r => 0, 2, 4 ] ],
      result => [ [ shut_r => 0 ], [ shut_r => 2 ], [ shut_r => 4 ] ],
      desc   => [ 'shutdown SHUT_RD 0', 'shutdown SHUT_RD 2', 'shutdown SHUT_RD 4' ],
   },
   {  spec   => [ [ shut_w => 0 ] ],
      desc   => [ 'shutdown SHUT_WR 0' ],
   },
   {  spec   => [ [ shut_rw => 0 ] ],
      desc   => [ 'shutdown SHUT_RDWR 0' ],
   },
   # 'repeat' feature is probably more trouble than it is worth
   #{  spec   => [ [ sig => 10 ], [ sleep => 1 ], [ 'repeat' ] ],
   #   result => [ "kill sig=10 pid=$$", 'sleep 1.000s', 'goto 0' ],
   #},
   #{  spec   => [ [ sleep => 1 ], [ close => 1, 2, 3, 4, 5 ], [ sleep => 1 ], [ repeat => 2 ] ],
   #   result => [ 'sleep 1.000s', 'close 1', 'close 2', 'close 3', 'close 4', 'close 5', 'sleep 1.000s', 'goto 1' ],
   #},
);

socket my $s, AF_INET, SOCK_STREAM, 0;
for my $test (@tests) {
   my $name= join ' | ', @{$test->{desc}};
   my $expected= $test->{result} || $test->{spec};
   my $expected_desc= join "\n",
      "watch fd: ".fileno($s),
      "event mask:",
      "actions:",
      (map sprintf("%4d: %s", $_, $test->{desc}[$_]), 0..$#{$test->{desc}}),
      '';
   my $sa= IO::SocketAlarm->new(socket => $s, events => 0, actions => $test->{spec});
   is( $sa, object {
      call socket => fileno($s);
      call events => 0;
      call actions => $expected;
   }, $name );
   is( $sa->stringify, $expected_desc, "$name description" );
}

done_testing;