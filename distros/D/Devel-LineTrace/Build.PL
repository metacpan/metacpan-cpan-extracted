use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    module_name => "Devel::LineTrace",
    dist_version_from => "lib/Devel/LineTrace.pm",
    license => "mit",
    create_makefile_pl => 'traditional',
    configure_requires =>
    {
        'Module::Build' => 0.36,
    },
    requires =>
    {
        'perl' => '5.006',
        'strict' => 0,
        'vars' => 0,
        'warnings' => 0,
    },
    build_requires =>
    {
        'Test::More' => 0,
        'strict' => 0,
        'warnings' => 0,
    },
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/perl-devel-linetrace",
        },
        keywords =>
        [
            "debug",
            "devel",
            "trace",
            "line",
            "callback",
        ],
    },
);

$build->create_build_script;
