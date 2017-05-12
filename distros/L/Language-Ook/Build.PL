#!perl
#
# This file is part of Language::Ook.
# Copyright (c) 2002-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new (
    module_name         => 'Language::Ook',
    dist_author         => 'Jerome Quelin <jquelin@cpan.org>',
    license             => 'perl',
    dist_version_from   => 'lib/Language/Ook.pm',
    add_to_cleanup => [
                'Language-Ook-*',
                map { ( '*/' x $_ ) . '*~' } 0..3 ],
    build_requires => {
        'Test::More'    => 0,
        'perl'          => '5.006',
    },
    requires       => {
        'perl'          => '5.006',
    },
    recommends     => {
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
    },
);

$builder->create_build_script();
