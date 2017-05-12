use strict;
use warnings;
use Module::Build;

use 5.010;

my $builder = Module::Build->new(
    module_name         => 'IO::Any',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/IO/Any.pm',
    configure_requires => {
        'Module::Build' => 0.36,
    },
    requires => {
        'Carp'       => 0,
        'File::Spec' => 0,
        'IO::String' => 0,
        'IO::File'   => 0,
        'Scalar::Util'   => 0,
        'IO::AtomicFile' => 0,
        'Fcntl'          => 0,
        'List::MoreUtils' => 0,
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Differences' => 0,
        'File::Slurp'       => 0,
        'File::Temp'        => 0,
        'Test::Exception'   => 0,
    },
    add_to_cleanup      => [ 'IO-Any-*' ],
    create_readme       => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/IO-Any.git',
            bugtracker => 'http://github.com/jozef/IO-Any/issues',
        },
        keywords => [ qw/ io portable slurp spew / ],
    },
);

$builder->create_build_script();
