#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl IO-Epoll.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test;
use Socket;
use strict;
BEGIN { plan tests => 9 };
use IO::Epoll;
ok(1); # If we made it this far, we're ok.


my $fail;
foreach my $constname (qw(
	EPOLLERR EPOLLET EPOLLHUP EPOLLIN EPOLLMSG EPOLLOUT EPOLLPRI
	EPOLLRDBAND EPOLLRDNORM EPOLLWRBAND EPOLLWRNORM EPOLL_CTL_ADD
	EPOLL_CTL_DEL EPOLL_CTL_MOD)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined IO::Epoll macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }
}
if ($fail) {
  print "not ok 2\n";
} else {
  print "ok 2\n";
}

#########################

my $epoll = epoll_create(10);
if ($epoll < 0) {
    print "# fail: epoll_create: $!\n";
    print "not ok 3\n";
    exit;
} else {
    print "ok 3\n";
}

unless (socketpair(S1, S2, AF_UNIX, SOCK_STREAM, PF_UNSPEC)) {
    print "not ok 4\n";
    exit;
}
print "ok 4\n";

my $ret = epoll_ctl($epoll, EPOLL_CTL_ADD, fileno S1, EPOLLIN);
if ($ret < 0) {
    print "not ok 5\n";
    exit;
}
print "ok 5\n";

$ret = epoll_ctl($epoll, EPOLL_CTL_ADD, fileno S2, EPOLLIN);
if ($ret < 0) {
    print "not ok 6\n";
    exit;
}
print "ok 6\n";

$ret = epoll_ctl($epoll, EPOLL_CTL_ADD, 500, EPOLLIN);
if ($ret >= 0) {
    print "not ok 7\n";
    exit;
}
print "ok 7\n";

syswrite S1, "Hello\n";

my $events = epoll_wait($epoll, 10, 1000);

if (ref $events eq 'ARRAY' && @$events == 1) {
    print "ok 8\n";
} else {
    print "not ok 8\n";
}

if ($events->[0][0] == fileno S2 && $events->[0][1] & EPOLLIN) {
    print "ok 9\n";
} else {
    print "not ok 9\n";
}
