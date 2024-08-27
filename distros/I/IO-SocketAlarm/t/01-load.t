use Test2::V0;

plan 1;

my $err; $err= $@ unless eval 'use IO::SocketAlarm; 1';

ok(defined IO::SocketAlarm->VERSION, 'loaded' )
   or diag $err;
