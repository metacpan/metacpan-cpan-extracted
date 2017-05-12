use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::EN::Contraction',
    license             => 'perl',
    dist_author         => 'Russ Graham <RWG@cpan.org>',
    dist_version   => '0.104',
    dist_abstract => 'Contractions for English sentances',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Lingua-EN-Contraction-*' ],
);

$builder->create_build_script();
