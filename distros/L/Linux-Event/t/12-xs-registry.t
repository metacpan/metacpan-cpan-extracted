use v5.36;
use strict;
use warnings;
use Test2::V0;

use Linux::Event::XS;

my $r = Linux::Event::XS::registry_new();

is Linux::Event::XS::registry_count($r), 0, 'new registry is empty';
is Linux::Event::XS::registry_get($r, 10), undef, 'missing fd returns undef';

my $w1 = bless { name => 'one' }, 'Local::Watcher';
Linux::Event::XS::registry_set($r, 10, $w1);

is Linux::Event::XS::registry_count($r), 1, 'set increments count';
is Linux::Event::XS::registry_get($r, 10), $w1, 'get returns stored object';

my $w2 = bless { name => 'two' }, 'Local::Watcher';
Linux::Event::XS::registry_set($r, 10, $w2);

is Linux::Event::XS::registry_count($r), 1, 'replace keeps count stable';
is Linux::Event::XS::registry_get($r, 10), $w2, 'replace updates stored object';

is Linux::Event::XS::registry_delete($r, 10), $w2, 'delete returns stored object';
is Linux::Event::XS::registry_count($r), 0, 'delete decrements count';
is Linux::Event::XS::registry_delete($r, 10), undef, 'delete missing fd returns undef';

Linux::Event::XS::registry_set($r, 4096, $w1);
is Linux::Event::XS::registry_get($r, 4096), $w1, 'registry grows for large fd';

is Linux::Event::XS::registry_count($r), 1, 'large fd counts as one entry';


open my $fh, '<', '/dev/null' or die "open /dev/null: $!";
my @called;
my $bw = Linux::Event::XS::backend_watch_new(
  'Linux::Event::XS::BackendWatch',
  fileno($fh),
  $fh,
  sub { @called = @_ },
  1,
  'loop-value',
  'tag-value',
);

is Linux::Event::XS::backend_watch_mask($bw), 1, 'backend watch stores mask';
Linux::Event::XS::backend_watch_set_mask($bw, 3);
is Linux::Event::XS::backend_watch_mask($bw), 3, 'backend watch updates mask';
is Linux::Event::XS::backend_watch_fh($bw), $fh, 'backend watch returns fh';

Linux::Event::XS::backend_watch_dispatch($bw, { in => 1, out => 1, hup => 1 });
is $called[0], 'loop-value', 'backend dispatch passes loop';
is $called[1], $fh, 'backend dispatch passes fh';
is $called[2], fileno($fh), 'backend dispatch passes fd';
is $called[3], 0x01 | 0x02 | 0x80, 'backend dispatch converts event hash to mask';
is $called[4], 'tag-value', 'backend dispatch passes tag';

done_testing;
