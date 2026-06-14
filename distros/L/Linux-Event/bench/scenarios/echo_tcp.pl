#!/usr/bin/env perl
use v5.36;
use FindBin;
use lib "$FindBin::Bin/../../blib/lib", "$FindBin::Bin/../../blib/arch", "$FindBin::Bin/../lib", "$FindBin::Bin/../../lib";
use Linux::Event::Bench;
my $res = Linux::Event::Bench::run_scenario('echo_tcp', { backend => $ENV{LE_BENCH_BACKEND} // 'pp', phase => $ENV{LE_BENCH_PHASE} // 'manual', clients => $ENV{LE_BENCH_CLIENTS} // 1, messages => $ENV{LE_BENCH_MESSAGES} // 1000, message_size => $ENV{LE_BENCH_MESSAGE_SIZE} // 64 });
Linux::Event::Bench::write_json($ENV{LE_BENCH_JSON}, $res) if $ENV{LE_BENCH_JSON};
print "echo_tcp messages_per_second=$res->{messages_per_second}\n";
