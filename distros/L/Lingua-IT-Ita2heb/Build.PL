# This file is under the MIT X11 License:
# http://www.opensource.org/licenses/mit-license.php

use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    module_name => 'Lingua::IT::Ita2heb',
    dist_author => q{Amir E. Aharoni <amir.aharoni@mail.huji.ac.il>},
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    requires => 
    {
        'base' => 0,
        'Carp' => 0,
        'charnames' => 0,
        'lib' => 0,
        'List::MoreUtils' => 0,
        'Moose' => 0,
        'open' => 0,
        'perl' => '5.010',
        'Readonly' => 0,
        'strict' => 0,
        'utf8' => 0,
        'vars' => 0,
        'warnings' => 0,
    },
    build_requires =>
    {
        'Test::More' => 0,
    },
    license => 'artistic_2',
    create_makefile_pl => 'traditional',
    meta_merge =>
    {
        resources =>
        {
            repository => 'https://github.com/amire80/ita2heb',
            homepage => 'https://github.com/amire80/ita2heb',
        },
        keywords =>
        [
            'hebrew',
            'italian',
            'languages',
            'natural',
            'nlp',
            'transliteration',
        ],
    },

);

$build->create_build_script;

