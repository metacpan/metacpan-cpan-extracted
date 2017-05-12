use Test::More;
use POSIX ();
use Linux::Smaps;

sub check_readable {
  my ($pid, $re)=@_;
  open my $fh, '<', "/proc/$pid/smaps" or return;
  local $/;
  return scalar(readline $fh)=~$re;
}

BEGIN {
  if( check_readable $$, qr/\bperl\b/ ) {
    plan tests=>10;
  } else {
    plan skip_all=>
      "Cannot read /proc/$$/smaps or didn't find 'perl' in the output";
  }
}

POSIX::setlocale( &POSIX::LC_ALL, "C" );
my ($s, $old);

$s=Linux::Smaps->new;

$old=Linux::Smaps->new;

ok $s, 'constructor';

ok scalar grep( {$_->file_name=~/perl/} $s->vmas), 'perl found';

my ($newlist, $difflist, $oldlist)=$s->diff( $s );

ok @$newlist==0 && @$difflist==0 && @$oldlist==0, 'no diff';

sub make_me_grow {
  "a" x $_[0];
}

my $dirty=$s->private_dirty;
make_me_grow 1024*1024;

$s->update;
print "# dirty grows from $dirty to ".$s->private_dirty."\n";
ok $s->private_dirty>$dirty+1024, 'dirty has grown';

($newlist, $difflist, $oldlist)=$s->diff( $old );
my ($newlist2, $difflist2, $oldlist2)=$old->diff( $s );

ok eq_set($newlist, $oldlist2), 'newlist=oldlist2';
ok eq_set($difflist, [map {[@{$_}[1,0]]} @$difflist2]), 'difflist=difflist2';
ok eq_set($oldlist, $newlist2), 'oldlist=newlist2';

my $pid; select undef, undef, undef, .2 until defined( $pid=fork );
unless( $pid ) {
  require Devel::Peek;
  sleep 10;
  exit 0;
}

SKIP: {
  my $max=50;
  select undef, undef, undef, .2
    while $max-- and !check_readable $pid, qr/\bPeek\b/;

  unless($max>=0) {
    kill 'KILL', $pid;
    skip "Cannot find /Peek/ in /proc/$pid/smaps"=>1;
  }

  $s->pid=$pid; $s->update;
  ok scalar( grep {$_->file_name=~/Peek\.so$/} $s->vmas ), 'other process';
  kill 'KILL', $pid;
}

eval {Linux::Smaps->new(0)};
ok $@ eq "Linux::Smaps: Cannot open /proc/0/smaps: No such file or directory\n",
  'error1';

$s=Linux::Smaps->new(uninitialized=>1);
$s->pid=-1; $s->update;
ok $s->lasterror eq "Cannot open /proc/-1/smaps: No such file or directory",
  'error2';

# Local Variables:
# mode: perl
# End:
