use warnings;
use strict;
use Test::More;

my $class = 'Linux::Info::SysInfo::CPU::S390';

require_ok($class);
can_ok(
    $class,
    (
        'get_cores',       'get_threads',
        'get_frequency',   'has_multithread',
        'get_facilities',  '_parse_facilities',
        '_custom_attribs', 'get_cache',
    )
);

my $source_file = 't/samples/cpu/info7';

my $instance = $class->new($source_file);
isa_ok( $instance, 'Linux::Info::SysInfo::CPU' );
isa_ok( $instance, $class );

my @fixtures = (
    [ 'get_model',       'version FF, identification 0133E8, machine 2964' ],
    [ 'get_arch',        32 ],
    [ 'get_bogomips',    3033 ],
    [ 'get_source_file', $source_file ],
    [ 'get_vendor',      'IBM/S390' ],
    [ 'get_frequency',   '5000 MHz' ],

    # [ 'get_cache',       '512 KB' ],
);

foreach my $fixture_ref (@fixtures) {
    my $method = $fixture_ref->[0];
    is( $instance->$method, $fixture_ref->[1], "$method works" );
}

my $flags = $instance->get_flags;
is( ref $flags, 'ARRAY', 'get_flags returns an array reference' );

is( $instance->has_multithread, 0, 'processor is not multithreaded' )
  or diag( explain($instance) );

my @expected =
  sort qw(esan3 zarch stfle msa ldisp eimm dfp edat etf3eh highgprs te vx sie);
is_deeply( $flags, \@expected, 'get_flags works as expected' );

my $facilities = $instance->get_facilities;
is( ref $facilities, 'ARRAY', 'get_facilities returns an array reference' );

@expected =
  qw(0 1 2 3 4 6 7 8 9 10 12 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 30 31 32 33 34 35 36 37 40 41 42 43 44 45 46 47 48 49 50 51 52 53 55 57 73 74 75 76 77 80 81 82 128 129);

is_deeply( $facilities, \@expected, 'get_facilities returns the expected' )
  or diag( explain($facilities) );

my $caches = $instance->get_cache;
is( ref $caches,        'HASH', 'get_cache returns an hash reference' );
is( keys( %{$caches} ), 6,      'got the expected number of caches' );

my $expected = {
    'associativity' => '30',
    'level'         => '4',
    'line_size'     => '256',
    'scope'         => 'Shared',
    'size'          => '491520K',
    'type'          => 'Unified'
};

is_deeply( $caches->{cache5}, $expected,
    'get_cache returns an expected cache5' );

done_testing;
