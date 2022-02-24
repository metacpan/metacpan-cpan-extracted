use strict;
use warnings;

use Module::Build;

my %REQUIRES_PERL = (
);

my %REQUIRES_SKT = (
   'Syntax::Keyword::Try' => '0.27',
);

use feature ();
my $HAVE_FEATURE_TRY = do {
   # Core's use feature 'try' only supports 'finally' since 5.35.8
   $] >= 5.035008
};

printf "Using %s\n",
   $HAVE_FEATURE_TRY ? "core's feature 'try'" : "Syntax::Keyword::Try";

my $build = Module::Build->new(
   module_name => 'Feature::Compat::Try',
   requires => {
      'perl' => '5.014',
      $HAVE_FEATURE_TRY ? %REQUIRES_PERL : %REQUIRES_SKT,
   },
   test_requires => {
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
