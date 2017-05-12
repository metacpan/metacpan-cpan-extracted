use strict;
use warnings;

use Test::More;

# ABSTRACT: test basic normalisation
use Test::Fatal;
use Git::Wrapper::Plus::Tester;
use Git::Wrapper::Plus::Support;
use Test::DZil qw( dist_ini );
use Dist::Zilla::Util::Test::KENTNL 1.003001 qw( dztest );

my $test = dztest();
$test->add_file(
  'dist.ini',
  dist_ini(
    {
      name             => 'DZT-Sample',
      abstract         => 'Sample DZ Dist',
      author           => 'E. Xavier Ample <example@example.org>',
      license          => 'Perl_5',
      copyright_holder => 'E. Xavier Ample',
    },
    'Git::NextVersion::Sanitized'
  )
);
my $t = Git::Wrapper::Plus::Tester->new( repo_dir => $test->tempdir );
my $s = Git::Wrapper::Plus::Support->new( git => $t->git );
$ENV{V} = '0.04';
$t->run_env(
  sub {
    my $git = $t->git;
    if ( not $s->supports_command('init-db') ) {
      plan skip_all => 'This version of Git cannot init-db';
      return;
    }
    my $excp = exception {
      $git->init_db();
      $git->add('dist.ini');
      local $ENV{'GIT_COMMITTER_DATE'} = '1388534400 +1300';
      $git->commit('-m First Commit');
      $git->tag('v0.01');
    };
    is( $excp, undef, 'Git::Wrapper test preparation did not fail' )
      or diag $excp;

    $test->build_ok;

    is( $test->builder->version, '0.040000', 'Version normalises from env as expected' );
    note explain $test->builder->log_messages;
  }
);

done_testing;

