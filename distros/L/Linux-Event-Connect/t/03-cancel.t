use v5.36;
use Test::More;

use Linux::Event;
use Linux::Event::Connect;

my $loop = Linux::Event->new;

my $called = 0;

my $req = Linux::Event::Connect->new(
  loop => $loop,
  host => '10.255.255.1',  # unroutable in many setups; but we cancel immediately anyway
  port => 9,
  timeout_s => 5,
  on_connect => sub ($r, $fh, $data) { $called = 1; close $fh; },
  on_error   => sub ($r, $errno, $data) { $called = 1; },
);

$req->cancel;

# Pump the loop a bit; no callbacks should fire.
for (1..5) {
  $loop->run_once(0);
}

ok(!$called, "cancel is silent (no callbacks)");
ok($req->is_done, "request is done after cancel");

done_testing;
