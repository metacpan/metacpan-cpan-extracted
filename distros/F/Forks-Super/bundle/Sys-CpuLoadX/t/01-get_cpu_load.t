use Sys::CpuLoadX;
use Test::More tests => 1;

my $load = Sys::CpuLoadX::get_cpu_load();
ok($load > 0 || $load eq "0.00", "cpu load on $^O is $load");
