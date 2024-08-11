use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'List::Gen',
    license            => 'perl',
    dist_author        => q{Eric Strom <asg@cpan.org>},
    dist_version_from  => 'lib/List/Gen.pm',
    requires           => {
        'perl'           => '5.10.0',
        'Scalar::Util'   => 0,
        'Filter::Simple' => 0,
        'Benchmark'      => 0,
        'Symbol'         => 0,
        'List::Util'     => 0,
        'Tie::File'      => 0,
    },
    configure_requires => {
        'Module::Build' => '0.30',
    },
    build_requires     => {
        'Test::More' => 0,
        'FindBin'    => 0,
        'Cwd'        => 0,
    },
    recommends         => {
        'Math::Prime::Util' => 0,
    },
    add_to_cleanup     => ['List-Gen-*'],
    create_makefile_pl => 'traditional',
    meta_merge         => {
        repository => {
            type => 'git',
            url => 'git://github.com/jo-37/list-gen.git',
            web => 'https://github.com/jo-37/list-gen.git',
        }
    },
);

$builder->create_build_script();
