#!/usr/bin/env perl
#  Copyright (C) 2015 Rocky Bernstein <rocky@cpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Module::Build;
use Config;

use File::Spec;
use File::Basename;
my $lib = File::Spec->catfile(dirname(__FILE__), 'lib');
unshift @INC, $lib;
require Devel::Trepan::Deparse;

my $release_status = ($Devel::Trepan::Deparse::VERSION =~ /_/) ?
    'testing' : 'stable';

my $builder = Module::Build->new(
    module_name         => 'Devel::Trepan::Deparse',
    add_to_cleanup      => [ 'Devel-Trepan-*', 'tmp*', '*.got'  ],
    create_makefile_pl  => 'passthrough',
    dist_abstract       =>
    'Adds deparse support via B::DeparseTree to Devel::Trepan',
    dist_author         => 'Rocky Bernstein <rocky@cpan.org>',
    dist_version_from   => 'lib/Devel/Trepan/Deparse.pm',
    license             => 'gpl',
    needs_compiler      => 0,
    release_status      => $release_status,

    meta_merge => {
	resources => {
	    bugtracker  => 'https://github.com/rocky/p5-Devel-Trepan-Deparse/issues',
	    repository  => 'http://github.com/rocky/p5-Devel-Trepan-Deparse'
	}
    },

    configure_requires  => {
	'Module::Build' => '0.4214',
    },
    test_requires  => {
        'Test::Simple'                      => '0.81',
        'rlib'                              => '0.02',
    },
    requires => {
	'perl'                              => '5.018000',
        'Devel::Callsite'                   => '0.08',
	'Devel::Trepan'                     => '0.73',
        'rlib'                              => '0.02',
        'B::DeparseTree'                    => '3.2.0',
        'Data::Printer'                     => '0.40',
    },
    sign                => ($ENV{PERL_MB_NOSIGN} ? 0 : 1),
    );

$builder->create_build_script();
