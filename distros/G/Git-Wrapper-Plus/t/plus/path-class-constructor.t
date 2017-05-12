use strict;
use warnings;

use Test::More;
use Test::Requires { 'Path::Class::Dir' => 0, };

use Git::Wrapper::Plus::Tester;
use Test::Fatal qw(exception);
use Git::Wrapper::Plus::Versions;
use Git::Wrapper::Plus;

my $t = Git::Wrapper::Plus::Tester->new();
my $v = Git::Wrapper::Plus::Versions->new( git => $t->git );

$t->run_env(
  sub {

    my $plus;
    my $path = Path::Class::Dir->new( $t->repo_dir );
    is(
      exception {

        $plus = Git::Wrapper::Plus->new($path);

      },
      undef,
      'No exceptions from ->new( path::class::dir )'
    );
    my $git;
    is(
      exception {
        $git = $plus->git;
      },
      undef,
      '->git() does not throw'
    );

    isa_ok( $git, 'Git::Wrapper', '$git' );
  }
);

done_testing;
