use Test::More; # -*- mode: cperl -*-

use lib qw(lib ../lib);

BEGIN {
  $ENV{'GITHUB_FOO'} = 'foo';
  $ENV{'GITHUB_BAR'} = 'bar';
}

use GitHub::Actions;

for my $k (qw( foo bar ) ) {
  is( $github{uc($k)}, $k, "Key «$k» set" );
}

if ( $ENV{CI} ) { # We're in an actual Github Action
  is( $github{'ACTOR'}, $ENV{'GITHUB_ACTOR'}, 'Action run by us' );
  like( $github{'EVENT_NAME'}, qr{^(push|pull_request)$}, "Activated by push or pull_request" );
  is( $github{'REPOSITORY'}, $ENV{'GITHUB_REPOSITORY'}, 'We are in the correct repository' );
  is( $github{'REF'}, $ENV{GITHUB_REF}, 'We are in the right branch' );
  like( $github{'REF'}, qr{^refs/(heads/[\w/-]+|pull/\d+/merge|tags/v?\d+\.\d+\.\d+)$}, 'We are in the correct branch' );
  is( $github{'SERVER_URL'}, 'https://github.com', 'We are in the correct server' );
  for my $n (qw(RUN_ID RUN_NUMBER) ) {
    like( $github{$n}, qr/\d+/, 'Run-related numbers are numbers' );
  }
  like( $github{'WORKSPACE'}, qr/GitHub/, "Workspace includes repo name" );
}


done_testing;
