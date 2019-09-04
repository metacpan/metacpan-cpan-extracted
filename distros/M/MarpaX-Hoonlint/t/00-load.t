use 5.010001;

use warnings;
use strict;
use English qw( -no_match_vars );
use POSIX qw(setlocale LC_ALL);

POSIX::setlocale(LC_ALL, "C");

use Test::More tests => 4;

if (not eval { require MarpaX::Hoonlint; 1; }) {
    Test::More::diag($EVAL_ERROR);
    Test::More::BAIL_OUT('Could not load MarpaX::Hoonlint');
}

my $hoonlint_version_ok = defined $MarpaX::Hoonlint::VERSION;
my $hoonlint_version_desc =
    $hoonlint_version_ok
    ? 'MarpaX::Hoonlint version is ' . $MarpaX::Hoonlint::VERSION
    : 'No MarpaX::Hoonlint::VERSION';
Test::More::ok( $hoonlint_version_ok, $hoonlint_version_desc );

my $hoonlint_string_version_ok   = defined $MarpaX::Hoonlint::STRING_VERSION;
my $hoonlint_string_version_desc = "MarpaX::Hoonlint version is " . $MarpaX::Hoonlint::STRING_VERSION
    // 'No MarpaX::Hoonlint::STRING_VERSION';
Test::More::ok( $hoonlint_string_version_ok, $hoonlint_string_version_desc );

my $marpa_version_ok = defined $Marpa::R2::VERSION;
my $marpa_version_desc =
    $marpa_version_ok
    ? 'Marpa::R2 version is ' . $Marpa::R2::VERSION
    : 'No Marpa::R2::VERSION';
Test::More::ok( $marpa_version_ok, $marpa_version_desc );

my $marpa_string_version_ok   = defined $Marpa::R2::STRING_VERSION;
my $marpa_string_version_desc = "Marpa::R2 version is " . $Marpa::R2::STRING_VERSION
    // 'No Marpa::R2::STRING_VERSION';
Test::More::ok( $marpa_string_version_ok, $marpa_string_version_desc );

Test::More::diag($hoonlint_string_version_desc);
Test::More::diag($hoonlint_version_desc);
Test::More::diag($marpa_string_version_desc);
Test::More::diag($marpa_version_desc);

# vim: expandtab shiftwidth=4:
