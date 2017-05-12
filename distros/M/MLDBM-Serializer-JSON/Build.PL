use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
         module_name       => 'MLDBM::Serializer::JSON',
         license           => 'perl',
         dist_author       => q{Jens Rehsack <rehsack@cpan.org>},
         dist_version_from => 'lib/MLDBM/Serializer/JSON.pm',
         requires          => {
                       'MLDBM'     => '2.00',
                       'JSON::Any' => '1.25',
                     },
         recommends => {
                         'MLDBM'    => '2.05',
                         'JSON::XS' => '2.34',
                       },
         build_requires => { 'Test::More' => 0.90, },
         add_to_cleanup => ['MLDBM-Serializer-JSON-*'],
         meta_merge =>
           { resources => { repository => "https://github.com/rehsack/MLDBM-Serializer-JSON/", }, },
         test_files => join( ' ' => 't/*.t xt/*.t' ),
);

$builder->create_build_script();
