use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::EN::Conjugate',
    license             => 'perl',
    dist_author         => 'Russ Graham <RWG@cpan.org>',
    dist_version_from   => 'lib/Lingua/EN/Conjugate.pm',
    build_requires => {
        'Test::More' => 0,
	'Lingua::EN::Contraction' => 0,
	'Memoize' => 0
    },
    add_to_cleanup      => [ 'Lingua-EN-Conjugate-*' ],
);

$builder->create_build_script();
