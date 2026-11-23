use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => 'File::DistDir',
  MIN_PERL_VERSION => '5.010',
  AUTHOR           => 'Rob Lauer <rclauer@gmail.com>',
  VERSION_FROM     => 'lib/File/DistDir.pm',
  ABSTRACT         => 'File::DistDir - locate and copy installed Perl distribution resources',
  LICENSE          => 'perl',
  PL_FILES         =>     {}
,
  EXE_FILES        =>     [
      'bin/dist-dir'
    ]
,
  MAN1PODS         =>     {}
,
  PREREQ_PM        => {
      'CLI::Simple' => '2.4.0',
      'File::ShareDir' => '1.118'
    },
  BUILD_REQUIRES   => {
      'ExtUtils::MakeMaker' => '6.64',
      'File::ShareDir::Install' => 0
    },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => 0,
    },
  TEST_REQUIRES => {},
  META_MERGE =>    {
      'meta-spec'=>{
                       'version'=>2
                     },
      'provides'=>{
                      'File::DistDir'=>{
                                           'file'=>'lib/File/DistDir.pm',
                                           'version'=>'1.0.0'
                                         },
                      'File::DistDir::CLI'=>{
                                                'file'=>'lib/File/DistDir/CLI.pm',
                                                'version'=>'1.0.0'
                                              }
                    },
      'resources'=>{
                       'bugtracker'=>{
                                         'mailto'=>'rclauer@gmail.com',
                                         'web'=>'https://github.com/rlauer6/File-DistDir/issues'
                                       },
                       'homepage'=>'https://github.com/rlauer6/File-DistDir',
                       'repository'=>{
                                         'type'=>'git',
                                         'url'=>'git@github.com:rlauer6/File-DistDir.git',
                                         'web'=>'https://github.com/rlauer6/File-DistDir'
                                       }
                     }
    }

);
package MY;

use File::ShareDir::Install;
use English qw(-no_match_vars);

sub postamble {
  my $self = shift;

  my @ret = File::ShareDir::Install::postamble($self);

  my $postamble = join "\n", @ret;

  if ( -e 'postamble' ) {

    local $RS = undef;

    open my $fh, '<', 'postamble'
      or die "could not open postamble\n";

    $postamble .= <$fh>;

    close $fh;
  }

  return $postamble;
}

1;
