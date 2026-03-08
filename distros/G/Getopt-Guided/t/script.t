use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT plan require_ok subtest ) ], tests => 5;
use Test::Script qw( script_compiles script_fails script_runs script_stderr_is script_stdout_like script_stderr_like );

use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile );

my $module;

BEGIN {
  $module = 'Getopt::Guided';
  require_ok $module or BAIL_OUT "Cannot load module '$module'!";
  no strict 'refs'; ## no critic ( ProhibitNoStrict )
  $module->import( qw( EXIT_FAILURE EXIT_USAGE ) );
}

subtest 'Utility is broken: getopts has $spec error' => sub {
  plan tests => 3;

  my $script = catfile( qw( t data script broken ) );
  script_compiles $script;
  script_fails $script, { exit => 255 }, 'Check exit status';
  script_stderr_like
    qr/\A\$spec parameter isn't a non-empty string of alphanumeric characters, stopped at \Q$script\E.*/, ## no critic ( ProhibitComplexRegexes )
    'Check standard error output'
};

subtest 'Utility is fine but called wrongly: unknown option' => sub {
  plan tests => 3;

  my $script = catfile( qw( t data script fine ) );
  script_compiles $script;
  script_fails [ $script, '-g' ], { exit => EXIT_USAGE }, 'Check exit status';
  script_stderr_is basename( $script ) . ": illegal option -- g\n", 'Check standard error output'
};

subtest 'Premature stop: ask script for its version information' => sub {
  plan tests => 3;

  my $script = catfile( qw( t data script fine ) );
  script_compiles $script;
  script_runs [ $script, '-V' ], 'Check exit status';
  script_stdout_like qr/\A ${ \( basename( $script ) ) } \  v6\.6\.6 \n perl \  v\d+\.\d+\.\d+ \n \z/x,
    'Check standard output'
};

subtest 'Normal script run but with failure exit status' => sub {
  plan tests => 2;

  my $script = catfile( qw( t data script fine ) );
  script_compiles $script;
  script_fails [ $script, '-x' ], { exit => EXIT_FAILURE }, 'Check exit status'
}
