use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    'module_name' => 'HTML::Links::Localize',
    'build_requires' =>
    {
        'Test::More' => 0,
    },
    'requires' =>
    {
        'strict' => 0,
        'warnings' => 0,
        'HTML::Parser' => 0,
        'perl' => '5.008',
    },
    configure_requires =>
    {
        'Module::Build' => 0,
    },
    'script_files' => "html-to-hd",
    'license' => "mit",
    'create_makefile_pl' => "traditional",
    'meta_merge' =>
    {
        resources =>
        {
            repository => 'http://bitbucket.org/shlomif/perl-html-links-localize',
        },
        keywords =>
        [
            'hard-disk',
            'html',
            'index',
            'links',
            'local',
            'localise',
            'localize',
            'view',
        ],
    },
);
$build->create_build_script;
