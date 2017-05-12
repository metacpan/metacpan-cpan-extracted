use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Kwiki::RenamePage',
    license             => 'perl',
    dist_author         => 'Dr Bean <drbean@cpan.org>',
    dist_version_from   => 'lib/Kwiki/RenamePage.pm',
    requires		=> { Kwiki => 0.39 },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Kwiki::RenamePage-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
