use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More 'tests' => 15;

use_ok('Linux::Proc::Cpuinfo');

my $info = Linux::Proc::Cpuinfo->new;
isa_ok( $info, 'Linux::Proc::Cpuinfo' );

can_ok( $info, 'architecture' );
can_ok( $info, 'hardware_platform' );
can_ok( $info, 'frequency' );
can_ok( $info, 'bogomips' );
can_ok( $info, 'cache' );
can_ok( $info, 'cpus' );

my $filename = File::Spec->catfile( $FindBin::RealBin, 'cpuinfo' );
$info = Linux::Proc::Cpuinfo->new($filename);
isa_ok( $info, 'Linux::Proc::Cpuinfo' );

is( $info->architecture, 'Intel(R) Core(TM) i5 CPU       M 480  @ 2.67GHz',
    'architecture' );
is( $info->hardware_platform, 'GenuineIntel', 'hardware_platform' );
is( $info->frequency,         1197,           'frequency' );
is( $info->bogomips,          5319.63,        'bogomips' );
is( $info->cache,             3072,           'cache' );
is( $info->cpus,              4,              'cpus' );
