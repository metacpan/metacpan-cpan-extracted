use v5.36;
use strict;
use warnings;
use Test::More;

use lib 't/lib';
use Linux::Event::XS ();

pipe(my $r, my $w) or die "pipe failed: $!";
my $fd = fileno($r);

my $reg = Linux::Event::XS::registry_new();
my $ep  = Linux::Event::XS::epoll_new();

my @seen;
my $rec = Linux::Event::XS::backend_watch_new(
  'Linux::Event::XS::BackendWatch',
  $fd,
  $r,
  sub ($loop, $fh, $fd2, $mask, $tag) {
    push @seen, [$loop, $fh, $fd2, $mask, $tag];
  },
  0x01,
  'loop-token',
  'tag-token',
);

Linux::Event::XS::registry_set($reg, $fd, $rec);
Linux::Event::XS::epoll_add($ep, $fd, 0x01);

syswrite($w, "x");
my $n = Linux::Event::XS::epoll_wait_dispatch($ep, $reg, 0.100);

ok $n >= 1, 'epoll_wait_dispatch returned at least one event';
is scalar(@seen), 1, 'callback dispatched once';
is $seen[0][0], 'loop-token', 'loop passed through';
is $seen[0][1], $r, 'fh passed through';
is $seen[0][2], $fd, 'fd passed through';
ok(($seen[0][3] & 0x01), 'readable mask passed through');
is $seen[0][4], 'tag-token', 'tag passed through';

Linux::Event::XS::epoll_modify($ep, $fd, 0x01);
ok Linux::Event::XS::epoll_delete($ep, $fd), 'delete succeeds';
Linux::Event::XS::registry_delete($reg, $fd);

done_testing;
