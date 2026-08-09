#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# the App::Cmd subcommand hooks are documented collectively per module
# rather than one =head2 apiece, as they are framework callbacks and not a
# API anyone calls... prepare is the same, overridden in the base class to
# wire --help into every subcommand
all_pod_coverage_ok(
	{
		'also_private' => [
			qr/^(?:abstract|description|usage_desc|opt_spec|validate_args|execute|command_names|prepare)$/
		]
	}
);
