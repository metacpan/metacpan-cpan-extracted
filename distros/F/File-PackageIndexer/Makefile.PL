use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME              => 'File::PackageIndexer',
  VERSION_FROM      => 'lib/File/PackageIndexer.pm', # finds $VERSION
  PREREQ_PM         => {
    'PPI' => '1.203',
    'Class::XSAccessor' => '0.14',
  },
  LICENSE => 'perl',
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
   (ABSTRACT_FROM  => 'lib/File/PackageIndexer.pm', # retrieve abstract from module
    AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
