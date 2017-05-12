#!/bin/env perl

use warnings;
use strict;
use Module::Build;

Module::Build->new(
    module_name       => 'GetNum',
    module_author     => 'Aaron Dallas <adallas@cpan.org>',
    dist_version_from => 'lib/GetNum.pm',
    dist_abstract     => 'Utility module to return numbers from strings',
    requires          => {
        'Inline::C' => 0,
        'Exporter'  => 0,
    },
    use_tap_harness => 1,
    test_files      => [ 't/*.t' ],
)->create_build_script;

exit 0;
