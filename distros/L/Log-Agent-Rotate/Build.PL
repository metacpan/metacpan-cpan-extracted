#!./perl
###########################################################################
#
#   Build.PL
#
#   Copyright (C) 2015 Mark Rogaski (mrogaski@cpan.org);
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Log::Agent::Rotate',
    license             => 'artistic_2',
    dist_author         => q{Mark Rogaski <mrogaski@cpan.org>},
    dist_version_from   => 'lib/Log/Agent/Rotate.pm',
    license             => 'artistic_2',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
        'Test::More'        => '0',
        'File::Copy'        => '0',
		'Compress::Zlib'    => '0.4',
		'Getargs::Long'     => '0.103',
		'LockFile::Simple'  => '0.202',
		'Log::Agent'        => '0.201',
    },
    requires => {
		'Compress::Zlib'    => '0.4',
		'Getargs::Long'     => '0.103',
		'LockFile::Simple'  => '0.202',
		'Log::Agent'        => '0.201',
    },
    add_to_cleanup     => [ 'Log-Agent-Rotate-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
