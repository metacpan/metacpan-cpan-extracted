#!perl

use strict;
use warnings;

use Test::More tests=>30;
#use Test::More 'no_plan';
use HTTP::LoadGen::ScoreBoard;

my $name='scoreboard.sb';
unlink $name if -e $name;
die "Move $name out of the way" if -e $name;
HTTP::LoadGen::ScoreBoard::init $name, 3, 4, 5;

isa_ok HTTP::LoadGen::ScoreBoard::scoreboard, 'IPC::ScoreBoard', 'scoreboard';
ok -f $name, "$name created";

# test lvalue function
HTTP::LoadGen::ScoreBoard::scoreboard=undef;
ok !defined HTTP::LoadGen::ScoreBoard::scoreboard, 'lvalue function';

# reinit
my $sb=HTTP::LoadGen::ScoreBoard::init undef, 3, 4, 5;
isa_ok HTTP::LoadGen::ScoreBoard::scoreboard, 'IPC::ScoreBoard', '$sb';

is SB::nslots($sb), 3, 'nslots';
if( SB::have_atomics ) {
  is SB::slotsize($sb), 4, 'slotsize';
  is SB::nextra($sb), 5+HTTP::LoadGen::ScoreBoard::SC_SLOTSIZE, 'nextra';
} else {
  is SB::slotsize($sb), 4+HTTP::LoadGen::ScoreBoard::SC_SLOTSIZE, 'slotsize';
  is SB::nextra($sb), 5, 'nextra';
}

# thread accounting
HTTP::LoadGen::ScoreBoard::slot=0;
is HTTP::LoadGen::ScoreBoard::thread_start, 1, '1. thread';
HTTP::LoadGen::ScoreBoard::slot=1;
is HTTP::LoadGen::ScoreBoard::thread_start, SB::have_atomics?2:1, '2. thread';
HTTP::LoadGen::ScoreBoard::slot=2;
is HTTP::LoadGen::ScoreBoard::thread_start, SB::have_atomics?3:1, '3. thread';
HTTP::LoadGen::ScoreBoard::slot=0;
is HTTP::LoadGen::ScoreBoard::thread_start, SB::have_atomics?4:2, '4. thread';

is HTTP::LoadGen::ScoreBoard::thread_count, 4, 'thread_count';

HTTP::LoadGen::ScoreBoard::slot=0;
is HTTP::LoadGen::ScoreBoard::thread_done, SB::have_atomics?3:1, '1 done';

is HTTP::LoadGen::ScoreBoard::thread_count, 3, 'thread_count';

# req accounting
HTTP::LoadGen::ScoreBoard::slot=0;
is HTTP::LoadGen::ScoreBoard::req_start, 1, '1. req';
HTTP::LoadGen::ScoreBoard::slot=1;
is HTTP::LoadGen::ScoreBoard::req_start, SB::have_atomics?2:1, '2. req';
HTTP::LoadGen::ScoreBoard::slot=2;
is HTTP::LoadGen::ScoreBoard::req_start, SB::have_atomics?3:1, '3. req';
HTTP::LoadGen::ScoreBoard::slot=0;
is HTTP::LoadGen::ScoreBoard::req_start, SB::have_atomics?4:2, '4. req';

is HTTP::LoadGen::ScoreBoard::req_started, 4, 'req_started';
is HTTP::LoadGen::ScoreBoard::req_success, 0, 'req_success';
is HTTP::LoadGen::ScoreBoard::req_failed, 0, 'req_failed';
is HTTP::LoadGen::ScoreBoard::header_bytes, 0, 'header_bytes';
is HTTP::LoadGen::ScoreBoard::header_count, 0, 'header_count';
is HTTP::LoadGen::ScoreBoard::body_bytes, 0, 'body_bytes';

HTTP::LoadGen::ScoreBoard::slot=0;
HTTP::LoadGen::ScoreBoard::req_done 0, {a=>["a"x10], bb=>['b'x20]}, 'x'x80;
HTTP::LoadGen::ScoreBoard::slot=1;
HTTP::LoadGen::ScoreBoard::req_done 1, {a=>["a"x10], bb=>['b'x20]}, 'x'x80;
HTTP::LoadGen::ScoreBoard::slot=2;
HTTP::LoadGen::ScoreBoard::req_done 1, {a=>["a"x10], bb=>['b'x20]}, 'x'x80;

is HTTP::LoadGen::ScoreBoard::req_started, 4, 'req_started still 4';
is HTTP::LoadGen::ScoreBoard::req_success, 2, 'req_success==2';
is HTTP::LoadGen::ScoreBoard::req_failed, 1, 'req_failed==1';
is HTTP::LoadGen::ScoreBoard::header_bytes, 3*(1+10+2+20),
  'header_bytes=='.(3*(1+10+2+20));
is HTTP::LoadGen::ScoreBoard::header_count, 3*2, 'header_count=='.(3*2);
is HTTP::LoadGen::ScoreBoard::body_bytes, 3*80, 'body_bytes=='.(3*80);

