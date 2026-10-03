#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

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

subtest 'Script compiles' => sub {
    script_compiles('bin/envassert');

    done_testing;
};

subtest 'Script runs --version' => sub {
    script_runs(['bin/envassert', '--version', ]);
    script_runs(['bin/envassert', '--version', ], { interpreter_options => [ '-T' ], }, 'Runs with taint check enabled');

    my $stdout;
    script_runs(['bin/envassert', '--version', ], { stdout => \$stdout, }, 'Verify output');
    like( (split qr/\n/msx, $stdout)[0], qr/^ bin [\/\\] envassert (\s version \s .* |) $/msx, 'Correct stdout');
    like( (split qr/\n/msx, $stdout)[1], qr/^ [(] Getopt::Long::GetOptions [[:space:]]{1,} /msx, 'Correct stdout');

    done_testing;
};

done_testing;
