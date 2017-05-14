use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Lingua::TreeTagger::Filter',
    license             => 'gpl',
    dist_author         => q{Benjamin Gay <Benjamin.Gay@unil.ch>},
    dist_version        => '0.01',
    build_requires => {
        'Test::More' => 0,
        'File::Spec' => 0,
    },
    requires => {
        'Moose'                => 0,
        'Lingua::TreeTagger'   => 0,
    },
);

$builder->create_build_script();
