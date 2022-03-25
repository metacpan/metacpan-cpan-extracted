
use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
    NAME           => 'File::Process',
    AUTHOR         => 'Rob Lauer <rlauer6@comcast.net>',
    VERSION_FROM   => 'lib/File/Process.pm',
    ABSTRACT       => 'File processing utiltiy',
    LICENSE        => 'perl',
    PL_FILES       => {},
    EXE_FILES      =>     []
,
    PREREQ_PM      => {
      'Carp' => '1.26',
      'Carp::Always' => '0.12',
      'English' => '1.05',
      'IO::Scalar' => '2.113',
      'ReadonlyX' => '1.04',
      'Scalar::Util' => '1.5',
      'parent' => '0.225',
      'strict' => '1.07',
      'vars' => '1.02',
      'warnings' => '1.13'
    },
    TEST_REQUIRES  =>     {}
,
    META_MERGE =>    {
      'meta-spec'=>{
                       'version'=>2
                     },
      'provides'=>{
                      'File::Process'=>{
                                           'file'=>'/usr/local/share/perl5/File/Process.pm',
                                           'version'=>'0.01'
                                         }
                    }
    }

);

package MY;

use File::ShareDir::Install qw( postamble );

