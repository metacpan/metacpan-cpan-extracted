use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    'module_name' => "HTML::Widgets::NavMenu",
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    'requires' =>
    {
        'Test::More' => 0,
        'Class::XSAccessor' => 0,
        'perl' => "5.6.1",
        'IO::Scalar' => 0,
    },
    'license' => "mit",
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/perl-html-widgets-navmenu",
            homepage => "http://web-cpan.shlomifish.org/modules/HTML-Widgets-NavMenu/",
        },
        keywords =>
        [
            "arrows",
            "bar",
            "breadcrumbs",
            "css",
            "expand",
            "hidden",
            "html",
            "menu",
            "menus",
            "nav-bar",
            "navbar",
            "navigation",
            "navigation aids",
            "nav-menu",
            "navmenu",
            "next",
            "prev",
            "previous",
            "pure-perl",
            "site-map",
            "skipped",
            "trail",
            "tree",
            "unexpand",
            "up",
            "widget",
            "widgets",
            "xhtml",
        ],
    },
    create_makefile_pl => 'traditional',
);
$build->create_build_script;
