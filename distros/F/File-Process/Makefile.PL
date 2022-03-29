
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
  BUILD_REQUIRES => {
    'ExtUtils::MakeMaker'     => 0,
    'File::ShareDir::Install' => 0,
    },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker'     => 0,
    'File::ShareDir::Install' => 0,
    },
  TEST_REQUIRES => {
      'Data::Dumper' => '2.145',
      'JSON::PP' => '4.07',
      'ReadonlyX' => '1.04',
      'Test::More' => '1.001014',
      'Text::CSV_XS' => '1.00',
      'strict' => '1.07',
      'warnings' => '1.13'
    }
,
  META_MERGE =>    {
      'meta-spec'=>{
                       'version'=>2
                     },
      'provides'=>{
                      'File::Process'=>{
                                           'file'=>'lib/File/Process.pm',
                                           'version'=>'0.05'
                                         }
                    }
    }

);

package MY;

use File::ShareDir::Install qw( postamble );

