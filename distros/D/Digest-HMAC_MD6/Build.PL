require 5.008;

use strict;
use warnings;

use lib 'inc';

use Module::Build;
use MyBuilder;

my $builder = MyBuilder->new(
  module_name       => 'Digest::HMAC_MD6',
  license           => 'perl',
  dist_author       => 'Andy Armstrong <andy@hexten.net>',
  dist_version_from => 'lib/Digest/HMAC_MD6.pm',
  requires          => {
    'Test::More'   => 0,
    'Digest::HMAC' => '1.01',
    'Digest::MD6'  => '0.08',
  },
  add_to_cleanup => ['Digest-HMAC_MD6-*'],
);

$builder->create_build_script();
