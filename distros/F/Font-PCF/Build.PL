use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Font::PCF',
   requires => {
      'perl' => '5.026',
      'Object::Pad' => '0.64',
      'Object::Pad::ClassAttr::Struct' => 0,
      'Syntax::Keyword::Match' => 0,

      'IO::Handle::Packable' => 0,
      'List::Util' => '1.33',
      'PerlIO::gzip' => 0,
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
