use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'ExtUtils::Typemap',
    VERSION_FROM      => 'lib/ExtUtils/Typemap.pm', # finds $VERSION
    PREREQ_PM         => {
      'ExtUtils::Typemaps' => '1.00',
      'File::Spec' => '0',
      'Test::More' => '0.44',
      'File::Temp' => '0',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ExtUtils/Typemap.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);

