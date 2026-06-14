use v5.36;
use strict;
use warnings;

use Test::More;

use Linux::Event::XS ();

{
  package Local::Loop;
  sub _watcher_update { 1 }
  sub _watcher_cancel { 1 }
}

pipe(my $r, my $w) or die "pipe: $!";
my $loop = bless {}, 'Local::Loop';
my $cb = sub {};
my $watcher = Linux::Event::XS::watcher_new(
  'Linux::Event::Watcher',
  $loop,
  $r,
  fileno($r),
  $cb,
  undef,
  undef,
  'payload',
  1,
  0,
);

isa_ok($watcher, 'Linux::Event::Watcher');
is($watcher->{loop}, $loop, 'loop stored');
is($watcher->{fd}, fileno($r), 'fd stored');
is($watcher->{read_cb}, $cb, 'read callback stored');
ok($watcher->{read_enabled}, 'read enabled by default when read cb exists');
ok(!$watcher->{write_enabled}, 'write disabled without write cb');
is($watcher->{data}, 'payload', 'data stored');
ok($watcher->{edge_triggered}, 'edge flag stored');
ok(!$watcher->{oneshot}, 'oneshot flag stored');
ok($watcher->{active}, 'active by default');

done_testing;
