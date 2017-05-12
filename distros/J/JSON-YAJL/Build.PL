#!perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    build_requires => { 'ExtUtils::CBuilder' => 0 },
    c_source       => 'yajl',
    create_license => 1,
    create_readme  => 1,
    dist_abstract =>
        'An interface to the YAJL JSON parsing and generation library',
    dist_author => 'Leon Brocard <acme@astray.com>',
    license     => 'perl',
    meta_merge  => {
        resources => {
#            bugtracker => {
#                mailto => 'bug-JSON-YAJL@rt.cpan.org',
#                web => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=JSON-YAJL',
#            },
            homepage   => 'http://search.cpan.org/dist/JSON-YAJL/',
#            repository => {
#                type => 'git',
#                web  => 'git@github.com:acme/JSON--YAJL.git',
#                url  => 'https://github.com/acme/JSON--YAJL',
#            },
        },
    },
    'meta-spec' => {
        version => '2',
        url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    module_name    => 'JSON::YAJL',
    needs_compiler => 1,
    requires       => { 'Test::Exception' => 0, 'Test::More' => 0 },
    sign           => 1,
);
$build->create_build_script;
