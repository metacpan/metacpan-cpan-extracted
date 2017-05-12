#!perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_license => 1,
    create_readme  => 1,
    dist_abstract  => 'Data::Page for JavaScript',
    dist_author    => 'Leon Brocard <acme@astray.com>',
    license        => 'perl',
    meta_merge     => {
        resources => {

#            bugtracker => {
#                mailto => 'bug-JSON-YAJL@rt.cpan.org',
#                web => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPAN-Mirror-Finder',
#            },
            homepage => 'http://search.cpan.org/dist/JS-Data-Page/',

       #            repository => {
       #                type => 'git',
       #                web  => 'git@github.com:acme/CPAN-Mirror--Finder.git',
       #                url  => 'https://github.com/acme/CPAN-Mirror-Finder',
       #            },
        },
    },
    'meta-spec' => {
        version => '2',
        url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    module_name => 'JS::Data::Page',
    requires =>
        { 'JS' => 0 },
    share_dir => 'share',
    sign => 1,
);
$build->create_build_script;
