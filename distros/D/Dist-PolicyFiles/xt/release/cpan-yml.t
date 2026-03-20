use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
  plan( skip_all => "Release tests not required for installation" );
}

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing META.yml" if $@;

meta_yaml_ok();

