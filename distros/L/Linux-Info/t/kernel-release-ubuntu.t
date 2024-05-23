use strict;
use warnings;
use Test::Most 0.38;

use Linux::Info::KernelSource;

use constant CLASS => 'Linux::Info::KernelRelease::Ubuntu';

plan tests => 15;

require_ok(CLASS);
can_ok( CLASS, ( 'get_abi_bump', 'get_flavour', 'get_upload', 'get_sig_raw' ) );

my $source_dir = 't/samples/kernel/ubuntu';
my $source     = Linux::Info::KernelSource->new(
    {
        sys_osrelease     => "$source_dir/sys_osrelease",
        version           => "$source_dir/version",
        version_signature => "$source_dir/signature",
    }
);

my $instance = CLASS->new( undef, $source );
isa_ok( $instance, CLASS );

my @fixtures = (
    [ 'get_abi_bump',       35 ],
    [ 'get_flavour',        'generic' ],
    [ 'get_upload',         35 ],
    [ 'get_raw',            $source->get_version ],
    [ 'get_sig_raw',        'Ubuntu 6.5.0-35.35~22.04.1-generic 6.5.13' ],
    [ 'get_major',          6 ],
    [ 'get_minor',          5 ],
    [ 'get_patch',          13 ],
    [ 'get_compiled_by',    'buildd@lcy02-amd64-079' ],
    [ 'get_gcc_version',    '12.3.0' ],
    [ 'get_type',           'SMP PREEMPT_DYNAMIC' ],
    [ 'get_build_datetime', 'Tue May  7 09:00:52 UTC 2' ],
);

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" );
}
