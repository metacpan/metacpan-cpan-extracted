#!perl
# no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use strict;
use warnings;

use Carp;
use Cwd;
use English qw( -no_match_vars ); # Avoids regex performance penalty in perl 5.18 and earlier
use FindBin qw( $RealBin );
use File::Spec ();
my $lib_path;
BEGIN {
    $lib_path = File::Spec->catdir(($RealBin =~ /(.+)/msx)[0], q{..}, 'lib');
}
use lib "$lib_path";

use Test2::V0;
use Test::Script 1.28;

use Test2::Deny::Platform::OS::DOSOrDerivative;
# use Test2::Deny::Platform::CI::GitHubCI;

my $path1 = File::Spec->rel2abs(File::Spec->catfile(File::Spec->curdir(), 't', 'three'));

# FIXME: Why does GitHub CI not manage to run test! The file .envdesc is not in its place!
# subtest 'Script fails with missing env variables' => sub {
#     chdir($path1) || croak "Cannot chdir($path1): $OS_ERROR";
#
#     my $stderr;
#     my $stderr_result = <<'EOF';
# Environment Assert: ERRORS:
#     variables:
#         A_DIGIT: Variable A_DIGIT is missing from environment
#         A_MISSING_VAR: Variable A_MISSING_VAR is missing from environment
# Errors in environment detected. at bin/using-script.pl line 9.
# BEGIN failed--compilation aborted at bin/using-script.pl line 9.
# EOF
#     script_fails(['bin/using-script.pl', ], { stderr => \$stderr, exit => 255, }, 'Verify errors in output');
#     is( $stderr, $stderr_result, 'Correct stderr' );
#
#     done_testing;
# };
#
# subtest 'Script succeeds' => sub {
#     chdir($path1) || croak "Cannot chdir($path1): $OS_ERROR";
#
#     ## no critic (Variables::RequireLocalizedPunctuationVars)
#     local %ENV = map { $_ => $ENV{$_} } keys %ENV;
#     $ENV{A_DIGIT} = '123';
#     $ENV{A_MISSING_VAR} = 'is_no_longer_missing';
#     my $stdout = 'Control should not reach this point!';
#     script_runs(['bin/using-script.pl', ], { stdout => \$stdout, }, 'Verify no errors in output');
#
#     done_testing;
# };

subtest 'Script fails with other envdesc file with missing env variables' => sub {
    chdir($path1) || croak "Cannot chdir($path1): $OS_ERROR";

    my ($stdout, $stderr);
    script_fails(['bin/using-another.pl', ], { stdout => \$stdout, stderr => \$stderr, exit => 255, }, 'Verify errors in output');
    ## no critic (RegularExpressions::RequireDotMatchAnything,RegularExpressions::RequireLineBoundaryMatching,RegularExpressions::ProhibitComplexRegexes,RegularExpressions::RequireExtendedFormatting)
    is( $stdout, q{}, 'Correct stdout' );
    is( $stderr, match qr/ANOTHER_MISSING_VAR: Variable ANOTHER_MISSING_VAR is missing from environment/, 'Correct stderr' );
    is( $stderr, match qr/A_DIGIT: Variable A_DIGIT is missing from environment/, 'Correct stderr' );
    is( $stderr, match qr/A_MISSING_VAR: Variable A_MISSING_VAR is missing from environment/, 'Correct stderr' );

    done_testing;
};

subtest 'Script succeeds with other envdesc file because env requirements are fullfilled' => sub {
    chdir($path1) || croak "Cannot chdir($path1): $OS_ERROR";

    local %ENV = (
        (map { $_ => $ENV{$_} } keys %ENV),
        A_DIGIT => '123',
        A_MISSING_VAR => 'is_no_longer_missing',
        ANOTHER_MISSING_VAR => 'is_no_longer_missing',
    );

    my ($stdout, $stderr);
    script_runs(['bin/using-another.pl', ], { stdout => \$stdout, stderr => \$stderr, }, 'Verify no errors in output');
    is( $stdout, qq{Control will reach this point if env requirements are fulfilled!\n}, 'Correct stdout' );
    is( $stderr, q{}, 'Correct stderr' );

    done_testing;
};

done_testing;
