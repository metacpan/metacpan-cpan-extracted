#!/usr/bin/env perl
use v5.36;
use FindBin;
use lib "$FindBin::Bin/../../blib/lib", "$FindBin::Bin/../../blib/arch", "$FindBin::Bin/../lib", "$FindBin::Bin/../../lib";
use Linux::Event::Bench;
my $res = Linux::Event::Bench::run_scenario('watcher_churn', { backend => $ENV{LE_BENCH_BACKEND} // 'pp', phase => $ENV{LE_BENCH_PHASE} // 'manual', events => $ENV{LE_BENCH_EVENTS} // 100000 });
Linux::Event::Bench::write_json($ENV{LE_BENCH_JSON}, $res) if $ENV{LE_BENCH_JSON};
print "watcher_churn watchers_per_second=$res->{watchers_per_second}\n";
