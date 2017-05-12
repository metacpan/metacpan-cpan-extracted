use strict;
use warnings;

use lib 'inc';

use Module::Build;
use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'Lingua::Abbreviate::Hierarchy',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/Lingua/Abbreviate/Hierarchy.pm',
  requires          => {
    'Test::More'        => 0,
    'Test::Differences' => 0,
  },
  add_to_cleanup => ['Lingua-Abbreviate-Hierarchy-*'],
);

$builder->create_build_script();
