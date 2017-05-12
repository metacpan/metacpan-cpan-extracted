#!perl
#
# This file is part of Inline::Befunge.
# Copyright (c) 2001-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new (
	module_name         => 'Inline::Befunge',
	license             => 'perl',
    dist_version_from   => 'lib/Inline/Befunge.pm',
    add_to_cleanup => [
                'Inline-Befunge-*', '_Inline',
                map { ( '*/' x $_ ) . '*~' } 0..3 ],
    build_requires => {
        'Inline'            => '0.43',
        'Language::Befunge' => '3.00',
    },
    requires => {
        'Inline'            => '0.43',
        'Language::Befunge' => '3.00',
    },
    recommends     => {
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
    },
);

$builder->create_build_script();
