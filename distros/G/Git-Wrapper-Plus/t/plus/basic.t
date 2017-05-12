use strict;
use warnings;

use Test::More;
use Git::Wrapper::Plus::Tester;
use Test::Fatal qw(exception);
use Git::Wrapper::Plus::Versions;
use Git::Wrapper::Plus;

my $t = Git::Wrapper::Plus::Tester->new();
my $v = Git::Wrapper::Plus::Versions->new( git => $t->git );

$t->run_env(
  sub {

    my $plus;
    is(
      exception {

        $plus = Git::Wrapper::Plus->new( $t->repo_dir );

      },
      undef,
      'No exceptions from ->new( path )'
    );

    is(
      exception {

        $plus = Git::Wrapper::Plus->new( $t->git );

      },
      undef,
      'No exceptions from ->new( wrapper )'
    );

    is(
      exception {
        $plus->tags;
      },
      undef,
      'No exceptions from ->tags'
    );

    is(
      exception {
        $plus->branches;
      },
      undef,
      'No exceptions from ->branches'
    );

    is(
      exception {
        $plus->refs;
      },
      undef,
      'No exceptions from ->refs'
    );

    is(
      exception {
        $plus->versions;
      },
      undef,
      'No exceptions from ->versions'
    );
    is(
      exception {
        $plus->support;
      },
      undef,
      'No exceptions from ->support'
    );
  }
);

done_testing;
