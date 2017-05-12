use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'ExtUtils::LibBuilder',
    license             => 'perl',
    dist_author         => q{Alberto Simoes <ambs@cpan.org>},
    dist_version_from   => 'lib/ExtUtils/LibBuilder.pm',
    requires => {
        'perl' => '5.006',
    },
    build_requires      => {
                            'ExtUtils::CBuilder' => '0.23',
                            'File::Spec'         => 0,
                            'File::Temp'         => 0,
                            'Test::More'         => 0,
    },
    add_to_cleanup      => [ 'ExtUtils-LibBuilder-*' ],
    meta_merge => {
        resources  => {
            repository => 'http://github.com/ambs/ExtUtils-LibBuilder',
        },
    },
);

$builder->create_build_script();
