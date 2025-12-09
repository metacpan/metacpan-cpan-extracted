use v5;
use strict;
use warnings;

use Module::Build;

my %REQUIRES_PERL = (
);

my %REQUIRES_OP = (
   'Object::Pad' => '0.823',
);

# We need the :writer attribute from 5.42
my $HAVE_FEATURE_CLASS = $^V ge v5.42;

printf "Using %s\n",
   $HAVE_FEATURE_CLASS ? "core's feature 'class'" : "Object::Pad";

my $build = Module::Build->new(
   module_name => 'Feature::Compat::Class',
   requires => {
      'perl' => '5.014',
      $HAVE_FEATURE_CLASS ? %REQUIRES_PERL : %REQUIRES_OP,
   },
   test_requires => {
      'Test2::V0' => 0,
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
