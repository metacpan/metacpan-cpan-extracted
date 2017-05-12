use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    module_name         => 'Devel::Backtrace',
    license             => 'perl',
    dist_author         => 'Christoph Bussenius <pepe@cpan.org>',
    dist_version_from   => 'lib/Devel/Backtrace.pm',
    no_index           => {
        directory => 'example',
    },
    requires            => {
        'String::Escape'  => 0,
        'Class::Accessor' => 0,
        'Carp'            => 0,
        'perl'            => '5.006_000',
    },
    build_requires => {
        'Test::More' => 0,
    },
#    add_to_cleanup      => [ 'Devel-Backtrace-*' ],
);

$builder->create_build_script();
