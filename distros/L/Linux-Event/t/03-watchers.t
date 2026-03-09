
use v5.36;
use strict;
use warnings;

use Test::More;

for my $m (qw(Linux::Epoll Linux::Event::Clock Linux::Event::Timer)) {
  eval "require $m; 1" or plan skip_all => "$m not available: $@";
}


use Linux::Event::Loop;
use Socket qw(AF_UNIX SOCK_STREAM);

local $SIG{ALRM} = sub { die "timeout\n" };
alarm 5;

sub make_loop () { return Linux::Event::Loop->new( model => 'reactor', backend => 'epoll' ) }

subtest "watch() replaces existing watcher on same fd" => sub {
  my $loop = make_loop();

  pipe(my $r, my $w) or die "pipe failed: $!";

  my $seen = '';

  # First watcher: would append 'old' if it fires.
  $loop->watch($r, read => sub ($loop, $fh, $w) { $seen .= "old"; $loop->stop });

  # Replacement watcher: should be the one that fires.
  $loop->watch($r, read => sub ($loop, $fh, $w) { $seen .= "new"; $w->cancel; $loop->stop });

  $loop->after(0.02, sub ($loop) { syswrite($w, "x") });

  $loop->run;
  is($seen, "new", "replacement watcher fired (old watcher did not)");
};

subtest "unwatch() is safe on unknown / already-unwatched" => sub {
  my $loop = make_loop();
  pipe(my $r, my $w) or die "pipe failed: $!";

  ok(!$loop->unwatch($r), "unwatch on never-watched is a no-op");

  my $wat = $loop->watch($r, read => sub ($loop, $fh, $w) { });
  ok($loop->unwatch($r), "unwatch on watched handle succeeds");
  ok(!$loop->unwatch($r), "unwatch again is a no-op");

  $wat->cancel; # should also be safe even though already removed
  pass("watcher->cancel is safe after unwatch");
};

subtest "read callback removing watcher prevents write callback" => sub {
  my $loop = make_loop();

  require Socket;
  Socket->import(qw(AF_UNIX SOCK_STREAM));

  socketpair(my $a, my $b, AF_UNIX, SOCK_STREAM, 0) or die "socketpair failed: $!";

  # Make sure $a is readable immediately before the loop starts
  syswrite($b, "hi") or die "syswrite failed: $!";

  my @order;

  $loop->watch($a,
               read  => sub ($loop, $fh, $w) {
                 push @order, "read";
                 $w->cancel;     # remove watcher immediately
                 $loop->stop;    # end loop immediately
               },
               write => sub ($loop, $fh, $w) {
                 push @order, "write";
               },
  );

  $loop->run;

  is_deeply(\@order, ["read"], "write did not run after read cancelled watcher");
};


subtest "oneshot removes watcher after first event" => sub {
  my $loop = make_loop();
  pipe(my $r, my $w) or die "pipe failed: $!";

  my $count = 0;

  $loop->watch($r,
    oneshot => 1,
    read => sub ($loop, $fh, $w) {
      $count++;
    },
  );

  # Two writes; only one read callback should be delivered because oneshot removes watcher.
  $loop->after(0.02, sub ($loop) { syswrite($w, "a") });
  $loop->after(0.04, sub ($loop) { syswrite($w, "b") });
  $loop->after(0.08, sub ($loop) { $loop->stop });

  $loop->run;

  is($count, 1, "oneshot watcher fired once");
};

subtest "closing watched fh does not dispatch and self-purges" => sub {
  my $loop = make_loop();
  pipe(my $r, my $w) or die "pipe failed: $!";

  my $called = 0;

  $loop->watch($r, read => sub ($loop, $fh, $w) { $called++ });

  # Close the read end without unwatching. This should not lead to callback firing.
  close $r;

  # Write to the pipe; since read end is closed, write may SIGPIPE or EPIPE.
  $loop->after(0.02, sub ($loop) {
    local $SIG{PIPE} = 'IGNORE';
    syswrite($w, "x");
  });

  $loop->after(0.06, sub ($loop) { $loop->stop });
  $loop->run;

  is($called, 0, "no callback fired for closed handle");
};

done_testing;
alarm 0;
