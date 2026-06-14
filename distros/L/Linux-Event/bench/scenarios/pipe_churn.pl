#!/usr/bin/env perl
use v5.36;
use FindBin;
use lib "$FindBin::Bin/../../blib/lib", "$FindBin::Bin/../../blib/arch", "$FindBin::Bin/../lib", "$FindBin::Bin/../../lib";
use Linux::Event::Bench;
my $res = Linux::Event::Bench::run_scenario('pipe_churn', { backend => $ENV{LE_BENCH_BACKEND} // 'pp', phase => $ENV{LE_BENCH_PHASE} // 'manual', events => $ENV{LE_BENCH_EVENTS} // 1000000 });
Linux::Event::Bench::write_json($ENV{LE_BENCH_JSON}, $res) if $ENV{LE_BENCH_JSON};
print "pipe_churn events_per_second=$res->{events_per_second}\n";
