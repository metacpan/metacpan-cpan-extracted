use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'JavaScript::Beautifier',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/JavaScript/Beautifier.pm',
    build_requires => {
        'Test::More' => '0.88',
        'Getopt::Long' => 0,
        'Pod::Usage' => 0,
        'IO::File' => 0,
    },
    add_to_cleanup      => [ 'JavaScript-Beautifier-*' ],
    create_makefile_pl => 'traditional',
    script_files => [
        'bin/js_beautify.pl',
    ],
    meta_merge     => {
        resources => {
            repository => 'http://github.com/fayland/perl-javascript-beautifier/tree/master',
        }
    },
);

$builder->create_build_script();
