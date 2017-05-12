use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
  module_name        => 'Lingua::EN::CommonMistakes',
  license            => 'gpl',
  dist_author        => q{Rohan McGovern <rohan@mcgovern.id.au>},
  dist_version_from  => 'lib/Lingua/EN/CommonMistakes.pm',
  release_status     => 'stable',
  configure_requires => { 'Module::Build' => 0, },
  build_requires     => {
    'Test::More' => 0,
    'Test::Warn' => 0,
  },
  requires => {},
  add_to_cleanup     => ['Lingua-EN-CommonMistakes-*'],
  create_makefile_pl => 'traditional',
  sign => 1,
);

$builder->create_build_script();
