use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'LaTeX::Decode',
    license             => 'artistic_2',
    dist_author         => q{Francois Charette <firmicus@cpan.org>},
    dist_version_from   => 'lib/LaTeX/Decode.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.008,
        'File::Slurp' => 0,
        'Unicode::Normalize' => 0,
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/fc7/LaTeX-Decode',
        },
    },
    script_files => [ glob( "bin/*" ) ],
    add_to_cleanup      => [ 'LaTeX-Decode-*' ],
#    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
