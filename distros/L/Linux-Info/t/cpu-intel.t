use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::SysInfo::CPU::Intel';

require_ok($class);
can_ok( $class, qw(get_cores get_threads get_bugs get_frequency) );

my $source_file = 't/samples/cpu/info0';

my $instance = $class->new($source_file);
isa_ok( $instance, $class );

my @fixtures = (
    [ 'get_model',       'Intel Pentium 4 CPU 1.80GHz' ],
    [ 'get_arch',        32 ],
    [ 'get_bogomips',    3597.32 ],
    [ 'get_source_file', $source_file ],
    [ 'get_vendor',      'GenuineIntel' ],
    [ 'get_frequency',   '1796.992 MHz' ],
    [ 'get_cache',       '512 KB' ],
);

foreach my $fixture_ref (@fixtures) {
    my $method = $fixture_ref->[0];
    is( $instance->$method, $fixture_ref->[1], "$method works" );
}

ok( $instance->has_multithread, 'processor is multithreaded' );

my $bugs = $instance->get_bugs;

is( ref $bugs,          'ARRAY', 'get_bugs returns an array reference' );
is( scalar( @{$bugs} ), 0,       'there are no bugs for the CPU' );

my $flags = $instance->get_flags;
is( ref $flags, 'ARRAY', 'get_flags returns an array reference' );
my @expected =
  sort
  qw(fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush dts acpi mmx fxsr sse sse2 ss ht tm up);
is_deeply( $flags, \@expected, 'get_flags works as expected' );

$source_file = 't/samples/cpu/info1';
my $other = $class->new($source_file);
is(
    $other->get_model,
    'Intel Core i7 CPU 920 @ 2.67GHz',
    'get_model trims additional spaces'
);

done_testing;
