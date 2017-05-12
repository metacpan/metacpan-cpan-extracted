use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'HTML::Acid',
    license             => 'perl',
    dist_author         => 'Nicholas Bamber <nicholas@periapt.co.uk>',
    dist_version_from   => 'lib/HTML/Acid.pm',
    build_requires => {
        'Test::More' => '0.94',
        'Perl6::Slurp' => 0,
        'Test::Differences'=>0,
        'Benchmark'=>0,
        'Test::NoWarnings'=>0,
    },
    requires => {
        'version'    => 0,
        'HTML::Parser' => 3,
        'String::Dirify'=>0,
        'Readonly'=>0,
    },
    meta_merge => {
        resources => {
            repository =>
                'http://github.com/periapt/HTML-Acid/tree',
        },
        keywords => [ 'HTML', 'Clean', 'XSS', 'end tags', 'YUI rich text editor' ],
    },
    create_readme=>1,
    create_makefile_pl => 'traditional',
    add_to_cleanup      => [ 'HTML-Acid-*' ],
);

$builder->create_build_script();
