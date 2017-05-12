use strict;
use warnings;

use lib './inc';

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    'module_name' => "HTML::Strip::Whitespace",
    'configure_requires' =>
    {
        'Module::Build' => '0.40',
    },
    'requires' =>
    {
           'HTML::TokeParser::Simple' => 0,
           'warnings' => 0,
           'strict' => 0,
           'Exporter' => 0,
           'vars' => 0,
           'perl' => '5.008',
    },
    'build_requires' =>
    {
        'Test::More' => 0,
    },
    'license' => "mit",
    create_makefile_pl => 'traditional',
    meta_merge =>
    {
        resources =>
        {
            homepage => "http://web-cpan.shlomifish.org/modules/HTML-Strip-Whitespace/",
            repository => "http://bitbucket.org/shlomif/perl-html-strip-whitespace",
        },
        keywords =>
        [
            "bandwidth",
            "compression",
            "html",
            "reduce",
            "remove",
            "size",
            "space",
            "strip",
            "tags",
            "whitespace",
        ],
    },
);

$build->create_build_script;
