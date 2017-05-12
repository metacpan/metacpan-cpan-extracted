use strict;
use 5.012003;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'ExtUtils::MakeMaker::BigHelper',
  VERSION_FROM      => 'lib/ExtUtils/MakeMaker/BigHelper.pm', # finds $VERSION
  PREREQ_PM         => {
    # e.g., Module::Name => 1.1
    'ExtUtils::MakeMaker' => 0,
  },
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/ExtUtils/MakeMaker/BigHelper.pm', # retrieve abstract from module
     AUTHOR         => 'Rob Janes <edgewise@cpan.org>') : ()),
);
