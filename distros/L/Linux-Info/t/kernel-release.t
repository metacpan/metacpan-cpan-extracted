use strict;
use warnings;
use Test::Most 0.38;

use constant CLASS => 'Linux::Info::KernelRelease';

require_ok(CLASS);
can_ok(
    CLASS,
    (
        'new',             'get_raw',
        'get_major',       'get_minor',
        'get_patch',       'get_compiled_by',
        'get_gcc_version', 'get_type',
        'get_build_datetime',
    )
);

dies_ok { CLASS->new('xyz') } 'must die with a invalid parameter';
like $@, qr/string\sfor\srelease/, 'got the expected error message';

my $instance = CLASS->new('6.5.0-28-generic');
isa_ok( $instance, CLASS );

my @fixtures = (
    [ 'get_compiled_by',    undef ],
    [ 'get_gcc_version',    undef ],
    [ 'get_type',           undef ],
    [ 'get_build_datetime', undef ],
    [ 'get_major',          6 ],
    [ 'get_minor',          5 ],
    [ 'get_patch',          0 ],
);

foreach my $fixture (@fixtures) {
    my $method = $fixture->[0];
    is( $instance->$method, $fixture->[1], "$method works" );
}

@fixtures = (
    [ '6.5.0-28-generic',  '>=', ' is higher or equal ' ],
    [ '6.4.14-29-generic', '>',  ' is higher than ' ],
    [ '6.6.0-28-generic',  '<',  ' is less than ' ],
);

foreach my $fixture (@fixtures) {
    my $other = CLASS->new( $fixture->[0] );

    cmp_ok( $instance, $fixture->[1], $other,
        $instance->get_raw . $fixture->[2] . $other->get_raw );
}

done_testing;
