use strict;
use warnings;
use Module::Build;

use lib 'inc';

use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'Devel::Ditto',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/Devel/Ditto.pm',
  requires          => {
    'Test::More' => 0,
    'IPC::Run'   => 0
  },
  add_to_cleanup => ['Devel-Ditto-*'],
);

$builder->create_build_script();
