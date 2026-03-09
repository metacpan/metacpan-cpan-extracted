use v5.36;
use strict;
use warnings;

use Test::More;

for my $m (qw(Linux::Epoll Linux::Event::Clock Linux::Event::Timer)) {
  eval "require $m; 1" or plan skip_all => "$m not available: $@";
}


use Linux::Event::Loop;

pipe(my $r, my $w) or die "pipe failed: $!";

my $loop = Linux::Event::Loop->new( model => 'reactor', backend => 'epoll' );

my $got = '';

my $watcher = $loop->watch(
  $r,
  read => sub ($loop, $fh, $w) {
    my $buf = '';
my $n = sysread($fh, $buf, 1024);
if (defined $n && $n > 0) {
  $got .= $buf;
  $w->cancel;      # stop watching after first read
  $loop->stop;     # exit loop
}
  },
);

# Schedule a write shortly after loop starts
$loop->after(0.020, sub ($loop) {
  syswrite($w, "hello");
});

local $SIG{ALRM} = sub { die "timeout\n" };
alarm 3;

$loop->run;

alarm 0;

is($got, 'hello', "readable event fired and data received");

done_testing;
