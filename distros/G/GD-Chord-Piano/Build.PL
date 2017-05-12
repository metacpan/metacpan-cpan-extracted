use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'GD::Chord::Piano',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    dist_version_from   => 'lib/GD/Chord/Piano.pm',
    requires => {
        'perl'                  => '5.6.2',
        'Test::More'            => 0,
        'Carp'                  => 0,
        'Class::Accessor::Fast' => 0,
        'GD'                    => 2.30,
    },
    add_to_cleanup      => [ 'GD-Chord-Piano-*' ],
);

$builder->create_build_script();
