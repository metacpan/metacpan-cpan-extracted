use Test::More; # -*- mode: cperl -*-

use lib qw(lib ../lib);

BEGIN {
  $ENV{'GITHUB_OUTPUT'} = '/tmp/output.env';
  $ENV{'GITHUB_ENV'} = '/tmp/env.env';
}

use GitHub::Actions;
use Test::File::Contents;

set_output('FOO','BAR');
file_contents_eq( $github{'OUTPUT'},"FOO=BAR\n", "Sets output" );

set_output('BAZ');
file_contents_like( $github{'OUTPUT'}, /BAZ/, "Sets output with empty value" );

set_env('FOO','BAR');
file_contents_eq( $github{'ENV'},"FOO=BAR\n", "Sets environment variable" );

set_env('BAZ');
file_contents_like( $github{'ENV'}, /BAZ/, "Sets environment variable with empty value" );


for $env_var (qw(OUTPUT ENV)) {
  unlink $ENV{"GITHUB_".$env_var};
}

done_testing;
