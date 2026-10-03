#!perl

use strict;
use warnings;

use Cwd;
use FindBin qw( $RealBin );
use File::Spec ();
my $lib_path;
BEGIN {
    $lib_path = File::Spec->catdir(($RealBin =~ /(.+)/msx)[0], q{.}, 'lib');
}
use lib "$lib_path";

use Test2::V0;
use Test::Script 1.28;

use Test2::Deny::Platform::OS::DOSOrDerivative;

subtest 'Script runs with --stdin' => sub {

    my $stdout;
    my $stdin = <<'EOF';
NUMERIC_VAR=^[[:digit:]]+$
TIME_VAR=^\d{2}:\d{2}:\d{2}$
EOF

    local %ENV = ( 'NUMERIC_VAR' => '123', 'TIME_VAR' => '01:02:03' );
    script_runs(['bin/envassert', '--stdin', ], { stdin => \$stdin, stdout => \$stdout, }, 'Verify output');

    done_testing;
};

done_testing;
