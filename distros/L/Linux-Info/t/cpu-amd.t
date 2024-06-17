use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::SysInfo::CPU::AMD';

require_ok($class);
can_ok( $class, qw(get_cores get_threads get_bugs get_frequency) );

my $source_file = 't/samples/cpu/info8';

my $instance = $class->new($source_file);
isa_ok( $instance, $class );

my @fixtures = (
    [ 'get_model',       'AMD EPYC 7763 64-Core Processor' ],
    [ 'get_arch',        64 ],
    [ 'get_bogomips',    4890.86 ],
    [ 'get_source_file', $source_file ],
    [ 'get_vendor',      'AuthenticAMD' ],
    [ 'get_frequency',   '3243.595 MHz' ],
    [ 'get_cache',       '512 KB' ],
);

foreach my $fixture_ref (@fixtures) {
    my $method = $fixture_ref->[0];
    is( $instance->$method, $fixture_ref->[1], "$method works" );
}

is( $instance->has_multithread, 1, 'processor is multithreaded' );

my $bugs = $instance->get_bugs;

is( ref $bugs,          'ARRAY', 'get_bugs returns an array reference' );
is( scalar( @{$bugs} ), 6,       'there are no bugs for the CPU' );

my $flags = $instance->get_flags;
is( ref $flags, 'ARRAY', 'get_flags returns an array reference' );
my @expected =
  sort
  qw(fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl tsc_reliable nonstop_tsc cpuid extd_apicid aperfmperf pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm cmp_legacy svm cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw topoext invpcid_single vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves clzero xsaveerptr rdpru arat npt nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold v_vmsave_vmload umip vaes vpclmulqdq rdpid fsrm);
is_deeply( $flags, \@expected, 'get_flags works as expected' );

done_testing;
