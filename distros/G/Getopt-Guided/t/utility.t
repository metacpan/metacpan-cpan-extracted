use strict;
use warnings;

use Test::More import => [ qw( plan subtest ) ], tests => 2;
use Test::Script qw( script_compiles script_fails script_stderr_is script_stderr_like );

use File::Basename        qw( basename );
use File::Spec::Functions qw( catfile );

subtest 'Utility is broken: getopts has $spec error' => sub {
  plan tests => 3;

  my $utility = catfile( qw( t examples broken ) );
  script_compiles $utility;
  script_fails $utility, { exit => 255 }, 'Check exit status';
  script_stderr_like
    qr/\Aparse_spec: \$spec parameter isn't a non-empty string of alphanumeric characters, stopped at \Q$utility\E.*/, ## no critic ( ProhibitComplexRegexes )
    'Check standard error output'
};

subtest 'Utility is fine but called wrongly: unknown option' => sub {
  plan tests => 3;

  my $utility = catfile( qw( t examples fine ) );
  script_compiles $utility;
  script_fails [ $utility, '-g' ], { exit => 2 }, 'Check exit status';
  script_stderr_is basename( $utility ) . ": illegal option -- g\n", 'Check standard error output'
}
