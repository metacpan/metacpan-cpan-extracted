use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME' => 'Math::ConvexHull',
  'VERSION_FROM' => 'lib/Math/ConvexHull.pm', # finds $VERSION
  'LICENSE' => 'perl',
  'PREREQ_PM' => {
    'Test::More'   => '0',
    'List::Util'   => '0',
    'Data::Dumper' => '0',
  }, # e.g., Module::Name => 1.1
  ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM => 'lib/Math/ConvexHull.pm', # retrieve abstract from module
     AUTHOR => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
