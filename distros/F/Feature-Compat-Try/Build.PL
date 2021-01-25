use strict;
use warnings;

use Module::Build;

my %REQUIRES_PERL = (
);

my %REQUIRES_SKT = (
   'Syntax::Keyword::Try' => '0.21',
);

my $HAVE_FEATURE_TRY = eval {
   require feature;
   feature->import( 'try' );
   1;
};

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
