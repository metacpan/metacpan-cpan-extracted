#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Deep;

use_ok('Debian::Dependencies');

my $dep_string = 'perl, libfoo-perl (>= 5.7), bar (<= 4)';
my $list = Debian::Dependencies->new($dep_string);

ok( ref($list), 'parsed dep list is a reference' );
is( ref($list), 'Debian::Dependencies', 'parsed dep list is an object' );
is( scalar(@$list), 3, 'parsed deps contain 3 elements' );
is_deeply( [ map( ref, @$list ) ], [ ( 'Debian::Dependency' ) x 3 ], 'Depencencies list contains Dependency refs' );
cmp_deeply(
    $list,
    bless(
        [
            bless( { pkg=>'perl' }, 'Debian::Dependency' ),
            bless(
                {   pkg => 'libfoo-perl',
                    rel => '>=',
                    ver => bless(
                        {   version     => '5.7',
                            epoch       => 0,
                            revision    => 0,
                            no_epoch    => 1,
                            no_revision => 1
                        },
                        'Dpkg::Version'
                    )
                },
                'Debian::Dependency'
                ),
            bless(
                {   pkg => 'bar',
                    rel => '<=',
                    ver => bless(
                        {   version     => '4',
                            epoch       => 0,
                            revision    => 0,
                            no_epoch    => 1,
                            no_revision => 1
                        },
                        'Dpkg::Version'
                    )
                },
                'Debian::Dependency'
                ),
        ],
        'Debian::Dependencies',
    ),
    'Dependencies list parsed' );
is( "$list", $dep_string, 'Dependencies stringifies' );

my $sum = $list + 'libsome-perl (>= 4.4)';
cmp_deeply(
    $sum->[3],
    bless(
        {   pkg => 'libsome-perl',
            rel => '>=',
            ver => bless(
                {   version     => '4.4',
                    epoch       => 0,
                    revision    => 0,
                    no_epoch    => 1,
                    no_revision => 1
                },
                'Dpkg::Version'
            ),
        },
        'Debian::Dependency',
    ),
    'Adding to a Dependencies',
);

$list += 'libother-perl';
cmp_deeply(
    $list->[3],
    bless( { pkg => 'libother-perl' }, 'Debian::Dependency' ),
    '+= works',
);

ok( $list eq "$dep_string, libother-perl", "eq works" );

$list = Debian::Dependencies->new('debhelper (>= 7), debhelper (>= 7.0.5)');
is( "$list", 'debhelper (>= 7.0.5)', 'versions collapsed' );

$list = Debian::Dependencies->new('debhelper (>= 7.0.5), debhelper (>= 7)');
is( "$list", 'debhelper (>= 7.0.5)', 'versions squashed' );

$list = Debian::Dependencies->new('debhelper (>= 7.0.5), debhelper (<< 8)');
is( "$list", 'debhelper (>= 7.0.5), debhelper (<< 8)', '>= and << kept' );

$list = Debian::Dependencies->new('debhelper (>= 7), libmodule-build-perl');
$list->add('debhelper (>= 7)');
$list->add('libtest-simple-perl');
is( "$list", 'debhelper (>= 7), libmodule-build-perl, libtest-simple-perl',
    'adding duplicated keeps order' );

# the example for 'remove' from POD
$list = Debian::Dependencies->new('foo (>= 1.2), bar');
$list->remove('foo, bar (>= 2.0)');
is( "$list", 'bar' );

is( "".Debian::Dependency->new("\nlibapt-pkg-perl"), "libapt-pkg-perl" );
