use Forks::Super;
use Test::More tests => 1;
use strict;
use warnings;


SKIP: {
    if (!Forks::Super::Config::CONFIG_module("Sys::CpuLoadX")) {
	skip "cpu load test: requires Sys::CpuLoadX module", 1;
    }
    my $load = Forks::Super::Job::OS::get_cpu_load();
    ok($load > 0 || $load eq "0.00", "got current cpu load $load");
}
