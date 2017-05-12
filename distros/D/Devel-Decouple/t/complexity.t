use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Perl::Metrics::Simple; };

if ( $@ ) {
    my $msg = 'Test::Perl::Metrics::Simple required to analyze code complexity.';
    plan( skip_all => $msg );
}

Test::Perl::Metrics::Simple->import( -complexity => 10 );
my $complexity = all_metrics_ok();
diag ( "The average cyclomatic complexity of this distribution is $complexity." );
