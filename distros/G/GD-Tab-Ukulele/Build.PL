use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'GD::Tab::Ukulele',
    license             => 'perl',
    dist_author         => 'Yuichi Tateno <hotchpotch@gmail.com>',
    dist_version_from   => 'lib/GD/Tab/Ukulele.pm',
    requires => {
        'Test::More' => 0,
        'Class::Accessor::Fast' => 0,
        'List::Util' => 0,
        'GD' => 2.30,
    },
    add_to_cleanup      => [ 'GD-Tab-Ukulele-*' ],
);

$builder->create_build_script();
