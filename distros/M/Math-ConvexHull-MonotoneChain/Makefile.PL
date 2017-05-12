use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $debug = grep {/^--debug$/} @ARGV;
WriteMakefile(
    NAME              => 'Math::ConvexHull::MonotoneChain',
    VERSION_FROM      => 'lib/Math/ConvexHull/MonotoneChain.pm', # finds $VERSION
    PREREQ_PM         => {
      'Data::Dumper' => '0',
      'Test::More' => '0.88',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/ConvexHull/MonotoneChain.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => ($debug ? '-O0 -Wall -Wextra' : '-O2'), # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES)', # link all the C files too
);
