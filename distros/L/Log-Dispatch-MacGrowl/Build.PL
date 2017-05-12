#

use strict;
use warnings;
use Module::Build;

$^O eq 'darwin'
    or warn "*** Log::Dispatch::MacGrowl requires Darwin (e.g. MacOSX) !! ***";

my $builder = Module::Build->new(
    module_name         => 'Log::Dispatch::MacGrowl',
    license             => 'perl',
    dist_author         => 'Ryo Okamoto <ryo at aquahill dot net>',
    dist_version_from   => 'lib/Log/Dispatch/MacGrowl.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
	'Log::Dispatch' => 0,
	'Cocoa::Growl' => 0.03,
    },
    recommends => {
	'Growl::Tiny' => '0.0.2',
#	'Mac::Growl' => 0,
    },
    add_to_cleanup => [ 'Log-Dispatch-MacGrowl-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
