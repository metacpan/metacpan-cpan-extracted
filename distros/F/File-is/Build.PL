use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'File::is',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/File/is.pm',
    configure_requires => {
        'Module::Build' => '0.3607',
    },
    requires => {
        'Carp'       => 0,
        'File::Spec' => 0,
    },
    build_requires => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
        'File::Temp'      => 0,
        'File::Path'      => 0,
    },
    add_to_cleanup      => [ 'File-is-*' ],
    create_readme       => 1,
    meta_merge => {
        resources => {
            repository => 'http://github.com/jozef/File-is',
            bugtracker => 'http://github.com/jozef/File-is/issues',
        },
        keywords => [ qw/ file stat / ],
    },
);

$builder->create_build_script();
