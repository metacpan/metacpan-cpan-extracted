# use lib "./lib";
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => "Devel::PreProcessor",
  DISTNAME => "Devel-PreProcessor",
  VERSION_FROM => "PreProcessor.pm",
  PREREQ_PM => {},
  'dist' => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);

# print "Created makefile. To build, test, and install, run:\n";
# print "\tmake\n";
# print "\tmake test\n";
# print "\tmake install\n";
