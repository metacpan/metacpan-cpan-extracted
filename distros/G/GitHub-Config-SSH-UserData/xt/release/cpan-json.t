use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
  plan( skip_all => "Release tests not required for installation" );
}

eval "use Test::CPAN::Meta::JSON";
plan skip_all => "Test::CPAN::Meta::JSON required for testing META.json" if $@;

meta_json_ok();

