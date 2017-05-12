use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    'module_name' => "Dist::Man",
    'configure_requires' =>
    {
        'Module::Build' => '0.36',
    },
    'requires' =>
    {
        'ExtUtils::Command' => 0,
        'File::Spec' => 0,
        'Getopt::Long' => 0,
        'Pod::Usage' => 0,
        'Test::More' => 0,
        'perl' => "5.8.1",
    },
    'license' => "perl",
    meta_merge =>
    {
        resources =>
        {
            # TODO : Change to the Mercurial/hg repos.
            repository => "https://bitbucket.org/shlomif/web-cpan",
            homepage => "http://web-cpan.berlios.de/modules/Dist-Man/",
        },
        keywords =>
        [
            "automate",
            "begin",
            "cpan",
            "cpan-distro",
            "cpan package",
            "cpan-package",
            "dist",
            "distribution",
            "distro",
            "generate",
            "man",
            "manager",
            "module",
            "package",
            "scaffolding",
            "starter",
        ],
    },
    create_makefile_pl => 'traditional',
    script_files => ['bin/pl-dist-man'],
);
$build->create_build_script;
