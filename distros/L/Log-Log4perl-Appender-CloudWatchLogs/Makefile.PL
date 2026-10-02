use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => 'Log::Log4perl::Appender::CloudWatchLogs',
  MIN_PERL_VERSION => '5.010',
  AUTHOR           => 'Rob Lauer <rclauer@gmail.com>',
  VERSION_FROM     => 'lib/Log/Log4perl/Appender/CloudWatchLogs.pm',
  ABSTRACT         => 'Log::Log4perl::Appender::CloudWatchLogs',
  LICENSE          => 'perl',
  PL_FILES         =>     {}
,
  EXE_FILES        =>     [
      'bin/aws-logs'
    ]
,
  MAN1PODS         =>     {}
,
  PREREQ_PM        => {
      'Amazon::API::CloudWatchLogs' => '>=1.43.90',
      'CLI::Simple' => '2.0.1',
      'Class::Accessor::Fast' => '0.51',
      'Data::UUID' => '1.227',
      'Date::Format' => '2.24',
      'JSON' => '4.10',
      'Log::Log4perl::Appender' => '0',
      'Number::Bytes::Human' => '0.11',
      'Readonly' => '2.05',
      'Text::ASCIITable' => '0.22',
      'Tie::IxHash' => '1.23'
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
      'prereqs'=>{
                     'runtime'=>{
                                    'recommends'=>{
                                                      'Date::Manip'=>'6.98'
                                                    }
                                  }
                   },
      'provides'=>{
                      'Amazon::CloudWatchLogs'=>{
                                                    'file'=>'lib/Amazon/CloudWatchLogs.pm',
                                                    'version'=>'1.0.7'
                                                  },
                      'Log::Log4perl::Appender::CloudWatchLogs'=>{
                                                                     'file'=>'lib/Log/Log4perl/Appender/CloudWatchLogs.pm',
                                                                     'version'=>'1.0.7'
                                                                   }
                    },
      'resources'=>{
                       'bugtracker'=>{
                                         'mailto'=>'rclauer@gmail.com',
                                         'web'=>'http://github.com/rlauer6/Log-Log4perl-Appender-CloudWatchLogs/issues'
                                       },
                       'homepage'=>'http://github.com/rlauer6/Log-Log4perl-Appender-CloudWatchLogs.git',
                       'repository'=>{
                                         'type'=>'git',
                                         'url'=>'git://github.com/rlauer6/Log-Log4perl-Appender-CloudWatchLogs.git',
                                         'web'=>'http://github.com/rlauer6/Log-Log4perl-Appender-CloudWatchLogs.git'
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
