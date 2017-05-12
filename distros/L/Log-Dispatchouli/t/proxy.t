use strict;
use warnings;

use Log::Dispatchouli;
use Test::More 0.88;

my $logger = Log::Dispatchouli->new_tester({
  ident => 't/proxy.t',
});

sub are_events {
  my ($comment, $want) = @_;

  my @have = map { $_->{message} } @{ $logger->events };
  $logger->clear_events;

  is_deeply(\@have, $want, $comment);
}

$logger->log("1");

is($logger->ident, 't/proxy.t', '$logger->ident is available');

are_events("we can log a simple event", [ '1' ]);

$logger->set_prefix("A: ");
$logger->log("2");

are_events("simple log with prefix", [
  'A: 2',
]);

my $proxy = $logger->proxy({
  proxy_prefix => 'B: ',
});

is($proxy->ident, 't/proxy.t', '$proxy->ident is available');

$proxy->log("3");

are_events("log with proxy with prefix", [
  'A: B: 3',
]);

$proxy->set_prefix('C: ');
$proxy->log("4");
$proxy->log({ prefix => 'D: ' }, "5");

are_events("log with proxy with prefix", [
  'A: B: C: 4',
  'A: B: C: D: 5',
]);

$logger->clear_prefix;

$proxy->log("4");
$proxy->log({ prefix => 'D: ' }, "5");

are_events("remove the logger's parent's prefix", [
  'B: C: 4',
  'B: C: D: 5',
]);

$logger->set_prefix('A: ');

my $proxprox = $proxy->proxy({
  proxy_prefix => 'E: ',
});

$proxprox->log("6");

$proxprox->set_prefix('F: ');
$proxprox->log("7");
$proxprox->log({ prefix => 'G: ' }, "8");

are_events("second-order proxy, basic logging", [
  'A: B: C: E: 6',
  'A: B: C: E: F: 7',
  'A: B: C: E: F: G: 8',
]);

$logger->log_debug("logger debug");
$proxy->log_debug("proxy debug");
$proxprox->log_debug("proxprox debug");

are_events("no debugging on at first", [ ]);

$proxy->set_debug(1);

$logger->log_debug("logger debug");
$proxy->log_debug("proxy debug");
$proxprox->log_debug("proxprox debug");

are_events("debugging in middle tier (middle set_debug)", [
  'A: B: C: proxy debug',
  'A: B: C: E: F: proxprox debug',
]);

$proxprox->set_debug(0);

$logger->log_debug("logger debug");
$proxy->log_debug("proxy debug");
$proxprox->log_debug("proxprox debug");

are_events("debugging in middle tier", [
  'A: B: C: proxy debug',
]);

sub unmute_all {
  $_->clear_muted for ($proxy, $proxprox);
  $logger->unmute;
};

unmute_all;

$proxprox->mute;
$proxprox->log("proxprox");
$proxy->log("proxy");
$logger->log("logger");

are_events("only muted proxprox", [
  'A: B: C: proxy',
  'A: logger',
]);

unmute_all;

$proxy->mute;

$proxprox->log("proxprox");
$proxy->log("proxy");
$logger->log("logger");

are_events("muted proxy", [
  'A: logger',
]);

unmute_all;

$proxprox->unmute;
$proxy->mute;

$proxprox->log("proxprox");
$proxy->log("proxy");
$logger->log("logger");

are_events("muted proxy, unmuted proxprox", [
  'A: logger',
]);

ok($logger->logger == $logger,   "logger->logger == logger");
ok($proxy->logger == $logger,    "proxy->logger == logger");
ok($proxprox->logger == $logger, "proxprox->logger == logger");

ok($logger->parent == $logger,   "logger->parent == logger");
ok($proxy->parent == $logger,    "proxy->parent == logger");
ok($proxprox->parent == $proxy, "proxprox->parent == proxy");

done_testing;
