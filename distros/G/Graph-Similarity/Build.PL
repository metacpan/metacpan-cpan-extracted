use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Graph::Similarity',
    license             => 'perl',
    dist_author         => 'Shohei Kameda <shoheik@cpan.org>',
    dist_version_from   => 'lib/Graph/Similarity.pm',
    requires => {
        'Test::More'            => 0,
        'Test::Exception'       => 0,
        'Test::Output'          => 0,
        'Test::Perl::Critic'    => 0,
        'version'               => 0,
        'Graph'                 => 0,
        'Moose'                 => 0,
        'Moose::Role'           => 0,
        'Math::Matrix'          => 0,
        'Text::Levenshtein'     => 0,
    },
    add_to_cleanup      => [ 'Graph-Similarity-*' ],
);

$builder->create_build_script();
