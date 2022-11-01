use strict;
use warnings;

use Module::Build;

my %REQUIRES_PERL = (
);

my %REQUIRES_OP = (
   'Object::Pad' => '0.70',
);

use feature ();
my $HAVE_FEATURE_CLASS = do {
   # %feature::feature was only added on 5.16, but that's fine. If we're
   # running on 5.14 this definitely won't be define()ed anyway. Looking at a
   # package var is safe even under strict, we'll just get a "used once only"
   # typo warning. We can quiet it.
   no warnings 'once';
   defined $feature::feature{class};
};

printf "Using %s\n",
   $HAVE_FEATURE_CLASS ? "core's feature 'class'" : "Object::Pad";

my $build = Module::Build->new(
   module_name => 'Feature::Compat::Class',
   requires => {
      'perl' => '5.014',
      $HAVE_FEATURE_CLASS ? %REQUIRES_PERL : %REQUIRES_OP,
   },
   test_requires => {
      'Test::Fatal' => 0,
      'Test::More' => '0.88', # done_testing
   },
   configure_requires => {
      'Module::Build' => '0.4004', # test_requires
   },
   license => 'perl',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
