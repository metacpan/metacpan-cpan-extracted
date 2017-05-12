use strict;
use warnings;
use Test::More;
use Test::DZil;
use Test::Script 1.12;
use Test::NoTabs ();
use Test::EOL    ();
use File::chdir;
use Path::Tiny;

my $tzil = Builder->from_config(
  {
    dist_root    => 'corpus/a',
  },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        {},
        ['GatherDir'],
        ['FileFinder::ByName / MyFinder' => {
          dir => 'lib/X1',
        }],
        ['Test::Version' => {
          finder => 'MyFinder',
        }]
      ),
      'source/lib/X1/Foo.pm' => "package X1::Foo;\nour \$VERSION = 1.00;\n1;\n",
      'source/lib/X2/Bar.pm' => "package X2::Bar;\n1;\n",
    }
  },
);

$tzil->build;

is $tzil->prereqs->as_string_hash->{develop}->{requires}->{'Test::Version'}, '1', 'needs Test::Version 1';

my $fn = path($tzil->tempdir)->child('build', 'xt', 'author', 'test-version.t');

ok ( -e $fn, 'test file exists');

note $fn->slurp;

do {
  local $CWD = path($tzil->tempdir)->child('build')->stringify;
  #note "CWD = $CWD";
  Test::NoTabs::notabs_ok      ( path(qw( xt author test-version.t ))->stringify, 'test has no tabs');
  Test::EOL::eol_unix_ok       ( path(qw( xt author test-version.t ))->stringify, 'test has good EOL',   { trailing_whitespace => 1 });
  script_compiles( path(qw( xt author test-version.t ))->stringify, 'check test compiles' );
  script_runs    ( path(qw( xt author test-version.t ))->stringify, 'check test runs'     );
};

done_testing;
