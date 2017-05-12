#!/usr/bin/env perl
#  Copyright (C) 2012-2015 Rocky Bernstein <rocky@cpan.org>
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
require Devel::Trepan::Disassemble;

my $release_status = ($Devel::Trepan::Disassemble::VERSION =~ /_/) ?
    'testing' : 'stable';

my $builder = Module::Build->new(
    module_name         => 'Devel::Trepan::Disassemble',
    add_to_cleanup      => [ 'Devel-Trepan-*', 'tmp*', '*.got'  ],
    create_makefile_pl  => 'passthrough',
    dist_abstract       =>
    'Adds disassemble support via B::Concise to Devel::Trepan',
    dist_author         => 'Rocky Bernstein <rocky@cpan.org>',
    dist_version_from   => 'lib/Devel/Trepan/Disassemble.pm',
    license             => 'gpl',
    needs_compiler      => 0,
    release_status      => $release_status,

    meta_merge => {
	resources => {
	    bugtracker  => 'https://github.com/rocky/Perl-Devel-Trepan-Disassemble/issues',
	    repository  => 'http://github.com/rocky/Perl-Devel-Trepan-Disassemble'
	}
    },

    configure_requires  => {
	'Module::Build' => '0.32',
    },
    test_requires  => {
	'Data::Dumper'                      => 0,
        'Test::Simple'                      => '0.81',
        'rlib'                              => '0.02',
        'Syntax::Highlight::Perl::Improved' => '1.01',
    },
    recommends => {
        'Pod::Text::Color'                  => 2.06,
    },
    requires => {
	'perl'                              => '5.008008',
	'B::Concise'                        => 0,
	'Devel::Trepan'                     => '0.71',
	'Getopt::Long'                      => 0,
        'rlib'                              => '0.02',
        'Devel::Callsite'                   => 0.08,
    },
    sign                => ($ENV{PERL_MB_NOSIGN} ? 0 : 1),
    );

$builder->create_build_script();
