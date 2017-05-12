# We need at least Perl 5.8.2 for proper Unicode support
use 5.008002;

use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

# recommends	'Graph::Easy::As_svg'	=> 0.23;
use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    'module_name' => "Graph::Easy",
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    build_requires =>
    {
        'Test::More' => '0.62',
    },
    'requires' =>
    {
        'Scalar::Util' => '1.13',
        'perl' => '5.8.2',
        'strict' => 0,
        'warnings' => 0,
        'vars' => 0,
    },
    'recommends' =>
    {
        'Graph::Easy::As_svg' => 0.23
    },
    'license' => "gpl",
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/perl-graph-easy",
        },
        keywords =>
        [
            'generation',
            'graph',
            'graphviz',
            'text generation',
            'text',
        ],
    },
    create_makefile_pl => 'traditional',
    'scripts' =>
    [
        'bin/graph-easy',
    ],
);

$build->create_build_script;
