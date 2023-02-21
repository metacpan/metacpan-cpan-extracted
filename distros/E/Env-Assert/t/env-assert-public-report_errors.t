#!perl
## no critic [ValuesAndExpressions::ProhibitConstantPragma]
use strict;
use warnings;
use Test2::V0;

use Env::Assert qw( report_errors );

use constant {
    ENV_ASSERT_MISSING_FROM_ENVIRONMENT    => 1,
    ENV_ASSERT_INVALID_CONTENT_IN_VARIABLE => 2,
    ENV_ASSERT_MISSING_FROM_DEFINITION     => 3,
};

subtest 'Public Subroutine report_errors()' => sub {

    {
        my %errors = (
            variables => {
                USER => {
                    type    => ENV_ASSERT_MISSING_FROM_DEFINITION,
                    message => 'Variable USER has invalid content',
                },
            },
        );
        my $expected = <<END_OF_TEXT;
Environment Assert: ERRORS:
    variables:
        USER: Variable USER has invalid content
END_OF_TEXT
        my $out = report_errors( \%errors );
        is( $out, $expected, 'Errors output correct' );
    }

    {
        my %errors = (
            variables => {
                USER => {
                    type    => ENV_ASSERT_MISSING_FROM_ENVIRONMENT,
                    message => 'Variable USER is missing from environment',
                },
                NEEDLESS_1 => {
                    type    => ENV_ASSERT_MISSING_FROM_DEFINITION,
                    message => 'Variable NEEDLESS_1 is missing from definition',
                },
            },
        );
        my $expected = <<END_OF_TEXT;
Environment Assert: ERRORS:
    variables:
        NEEDLESS_1: Variable NEEDLESS_1 is missing from definition
        USER: Variable USER is missing from environment
END_OF_TEXT
        my $out = report_errors( \%errors );
        is( $out, $expected, 'Errors output correct' );
    }

    {
        my %errors   = ();
        my $expected = <<END_OF_TEXT;
Environment Assert: ERRORS:
END_OF_TEXT
        my $out = report_errors( \%errors );
        is( $out, $expected, 'Errors output correct' );
    }

    done_testing;
};

done_testing;
