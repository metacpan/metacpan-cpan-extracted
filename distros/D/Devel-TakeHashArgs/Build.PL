use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Devel::TakeHashArgs',
    license             => 'perl',
    dist_author         => 'Zoffix Znet <zoffix@cpan.org>',
    dist_version_from   => 'lib/Devel/TakeHashArgs.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Exporter' => 5.58,
        'perl' => '5.006',
    },
    configure_requires => { 'Module::Build' => 0 },
    add_to_cleanup      => [ 'Devel-TakeHashArgs-*' ],
    create_makefile_pl => 'traditional',
);
if ( $ENV{RELEASE_TESTING} ) {
    system('pod2text lib/Devel/TakeHashArgs.pm > README');
}
$builder->create_build_script();
