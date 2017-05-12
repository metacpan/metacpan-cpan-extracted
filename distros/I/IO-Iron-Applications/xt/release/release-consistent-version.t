use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ( not $ENV{RELEASE_TESTING} ) {
	my $msg = 'Author test. Set $ENV{RELEASE_TESTING} to a true value to run.';
	plan( skip_all => $msg );
}

eval "use Test::ConsistentVersion";
if ( $EVAL_ERROR ) {
	my $msg = 'Test::ConsistentVersion required for checking versions!';
	plan( skip_all => $msg );
}
Test::ConsistentVersion::check_consistent_versions();
