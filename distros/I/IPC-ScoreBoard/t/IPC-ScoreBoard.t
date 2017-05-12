#!perl

use strict;
use warnings;

use Test::More tests => 89;
#use Test::More 'no_plan';

BEGIN {
  warn "\n";
  local $/;
  my $f;
  open $f, '<', 'out1' and warn ">>> out1\n".readline($f)."<<< out1\n";
  undef $f;
  open $f, '<', 'out2' and warn ">>> out2\n".readline($f)."<<< out2\n";
  undef $f;
}

BEGIN { use_ok('IPC::ScoreBoard') };

my @param=([3,5,0], [3,5,8]);

my $named_sb=IPC::ScoreBoard->named("tmp.sb", 3, 5, 8);

my ($pidsum, @pids, $p);
for my $sb (SB::anon(3, 5), $named_sb) {
  @pids=();
  for(my $i=0; $i<3; $i++) {
    my $pid;
    select undef, undef, undef, 0.1 until defined($pid=fork);
    if( $pid ) {			# parent
      push @pids, $pid;
      SB::incr_extra $sb, 3 if $sb->nextra;
    } else {				# child
      SB::set $sb, $i, 0, $$;
      SB::incr $sb, $i, 1, $$;
      SB::decr $sb, $i, 2, $$;
      SB::incr $sb, $i, 3;
      SB::incr $sb, $i, 3;
      SB::decr $sb, $i, 4;
      SB::decr $sb, $i, 4;
      SB::incr_extra $sb, 3, $$ if $sb->nextra;
      SB::decr_extra $sb, 4, $$ if $sb->nextra;
      SB::incr_extra $sb, 5 if $sb->nextra;
      SB::decr_extra $sb, 6 if $sb->nextra;
      exit 0;
    }
  }

  {
    local $SIG{ALRM}=sub {die "Timeout while waiting for children"};
    alarm 3;
    foreach my $pid (@pids) {
      waitpid $pid, 0;
    }
    alarm 0;
  }

  $pidsum=0;
  for( my $i=0; $i<3; $i++ ) {
    is SB::get($sb, $i, 0), $pids[$i], "[$i,0]==$pids[$i]";
    is SB::get($sb, $i, 1), $pids[$i], "[$i,1]==$pids[$i]";
    is SB::get($sb, $i, 2), -$pids[$i], "[$i,2]==-$pids[$i]";
    is SB::get($sb, $i, 3), 2, "[$i,3]==2";
    is SB::get($sb, $i, 4), -2, "[$i,3]==-2";
    $pidsum+=$pids[$i];
  }

  is SB::sum($sb, 0), $pidsum, "sum [0]==$pidsum";
  is SB::sum($sb, 1), $pidsum, "sum [1]==$pidsum";
  is SB::sum($sb, 2), -$pidsum, "sum [2]==-$pidsum";
  is SB::sum($sb, 3), 6, "sum [3]==6";
  is SB::sum($sb, 4), -6, "sum [4]==-6";

  is_deeply [SB::get_all $sb, 0], [$pids[0], $pids[0], -$pids[0], 2, -2],
    "get_all(0)";
  is_deeply [SB::get_all $sb, 1], [$pids[1], $pids[1], -$pids[1], 2, -2],
    "get_all(1)";
  is_deeply [SB::get_all $sb, 2], [$pids[2], $pids[2], -$pids[2], 2, -2],
    "get_all(2)";

  is_deeply [SB::sum_all $sb], [$pidsum, $pidsum, -$pidsum, 6, -6],
    "sum_all";

  $p=shift(@param);
  is_deeply [$sb->nslots, $sb->slotsize, $sb->nextra], $p, "sb parameters";
  is_deeply [SB::nslots($sb), SB::slotsize($sb), SB::nextra($sb)],
    $p, "sb parameters";

  undef $sb;
}

my ($sb, $n, $sz, $extra)=SB::open("tmp.sb");

is_deeply [$n, $sz, $extra], $p, "open named -- params";

for( my $i=0; $i<3; $i++ ) {
  is $sb->get($i, 0), $pids[$i], "[$i,0]==$pids[$i]";
  is $sb->get($i, 1), $pids[$i], "[$i,1]==$pids[$i]";
  is $sb->get($i, 2), -$pids[$i], "[$i,2]==-$pids[$i]";
  is $sb->get($i, 3), 2, "[$i,3]==2";
  is $sb->get($i, 4), -2, "[$i,3]==-2";
}

is $sb->sum(0), $pidsum, "sum [0]==$pidsum";
is $sb->sum(1), $pidsum, "sum [1]==$pidsum";
is $sb->sum(2), -$pidsum, "sum [2]==-$pidsum";
is $sb->sum(3), 6, "sum [3]==6";
is $sb->sum(4), -6, "sum [4]==-6";

is_deeply [SB::get_all $sb, 0], [$pids[0], $pids[0], -$pids[0], 2, -2],
  "get_all(0)";
is_deeply [SB::get_all $sb, 1], [$pids[1], $pids[1], -$pids[1], 2, -2],
  "get_all(1)";
is_deeply [SB::get_all $sb, 2], [$pids[2], $pids[2], -$pids[2], 2, -2],
  "get_all(2)";

is_deeply [SB::sum_all $sb], [$pidsum, $pidsum, -$pidsum, 6, -6],
  "sum_all";

is_deeply [SB::get_all_extra $sb], [0,0,0,$pidsum+3,-$pidsum,3,-3,0],
  "get_all_extra";

is SB::get_extra($sb,3), $pidsum+3, "get_extra";

is SB::set_extra($sb,3,42), 42, "set_extra";
is SB::get_extra($sb,3), 42, "get_extra";

SKIP: {
  skip "environment variable STRESSTEST not set or incr ops are not atomic", 1
    unless SB::have_atomics && $ENV{STRESSTEST};

  @pids=();
  for(my $i=0; $i<10; $i++) {
    my $pid;
    select undef, undef, undef, 0.1 until defined($pid=fork);
    if( $pid ) {			# parent
      push @pids, $pid;
    } else {				# child
      1 until SB::get_extra $sb, 0; # busy wait

      for( my $i=0; $i<1000000; $i++ ) {
	SB::incr_extra $sb, 1;
      }

      exit 0;
    }
  }
  SB::incr_extra $sb, 0;	# start children

  {
    local $SIG{ALRM}=sub {die "Timeout while waiting for children"};
    alarm 30;
    foreach my $pid (@pids) {
      waitpid $pid, 0;
    }
    alarm 0;
  }

  is SB::get_extra($sb,1), 1000000*@pids, "stresstest";
}

my $ivlen=length pack "j", 0;
is SB::offset_of($sb, 0, 0), 4*$ivlen, "offset_of(0,0)";
is SB::offset_of($sb, 2, 0), (4+2*$p->[1])*$ivlen, "offset_of(2,0)";
is SB::offset_of($sb, 2, 2), (4+2*$p->[1]+2)*$ivlen, "offset_of(2,2)";
is $sb->offset_of(2), (6+$p->[0]*$p->[1])*$ivlen, "offset_of(2)";

{
  my $pid;
  select undef, undef, undef, 0.1 until defined($pid=fork);
  if( $pid ) {			# parent
    {
      local $SIG{ALRM}=sub {die "Timeout while waiting for children"};
      alarm 30;
      waitpid $pid, 0;
      alarm 0;
    }
  } else {				# child
    substr( $$sb, $sb->offset_of(2), 2*$ivlen,
	    pack( "Z".(2*$ivlen), "abc") );
    exit 0;
  }
}
is_deeply [SB::get_extra($sb, 2), SB::get_extra($sb, 3)],
  [unpack("j", pack("Z".$ivlen, "abc")), 0], "string stored";

is +(unpack "x".($sb->offset_of(2))."Z*", $$sb)[0],
  "abc", "string retrieved";

undef $sb;
