use Test::More; # -*- mode: cperl -*-

use lib qw(lib ../lib);

BEGIN {
  $ENV{'GITHUB_OUTPUT'} = '/tmp/output.env';
  $ENV{'GITHUB_ENV'} = '/tmp/env.env';
  $ENV{'GITHUB_STEP_SUMMARY'} = '/tmp/summary.md';
}

use GitHub::Actions;
use Test::File::Contents;

set_output('FOO','BAR');
file_contents_like( $github{'OUTPUT'},/FOO=BAR/, "Sets output" );

set_output('BAZ');
file_contents_like( $github{'OUTPUT'}, /BAZ/, "Sets output with empty value" );

set_env('FOO','BAR');
file_contents_like( $github{'ENV'},/FOO=BAR/, "Sets environment variable" );

set_env('BAZ');
file_contents_like( $github{'ENV'}, /BAZ/, "Sets environment variable with empty value" );

my $job_summary_msg = '#Zuux';
add_to_job_summary($job_summary_msg);
file_contents_like( $github{'STEP_SUMMARY'}, /$job_summary_msg/, "Adds to job summary" );


for $env_var (qw(OUTPUT ENV STEP_SUMMARY)) {
  # unlink $ENV{"GITHUB_".$env_var};
}

done_testing;
