#!/usr/bin/perl -w
# @(#) $Id$

use strict;
use Module::Build;

Module::Build->new(
    module_name        => 'JavaScript::JSLint',
    license            => 'bsd',
    dist_author        => 'Steve Webster <cpan (at) statichtml.com>',
    script_files       => ['bin/jslint'],
    create_makefile_pl => 'passthrough',
    add_to_cleanup     => ['JavaScript-JSLint-*'],
    requires           => {
        'File::Basename' => 0,
        'Getopt::Long'   => 0,
        'JavaScript'     => 0,
        'JSON'           => 0,
    },
)->create_build_script;
