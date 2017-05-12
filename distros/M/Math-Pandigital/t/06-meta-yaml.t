## no critic(RCS,VERSION,explicit,Module,eval)
use strict;
use warnings;

use Test::More;

if( ! $ENV{RELEASE_TESTING} ) {
  plan skip_all =>
    'Author only test: META.yml tests run only if RELEASE_TESTING set.';
}
elsif ( ! eval 'use Test::CPAN::Meta::YAML; 1;' ) {
  plan skip_all =>
    'Author META.yml test requires Test::CPAN::Meta::YAML.'
}
else {
  note 'Testing META.yml';
}
  
meta_yaml_ok();
