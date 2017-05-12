use strict;
use warnings;
use Test::More tests => 4;
use Env::Sanctify;

$ENV{SANCTIFY_REGEX_TEST} = 'Sanctify this';
delete $ENV{SANCTIFY_NO_VAR};

my $sanctify = Env::Sanctify->sanctify(
		sanctify => [ '^SANCTIFY_REGEX_TEST' ],
		env => { SANCTIFY_REGEX_TEST => 'pigdog',
			 SANCTIFY_NO_VAR => 'nothing to see',
	        },
);

is( $ENV{SANCTIFY_NO_VAR}, 'nothing to see', 'Nothing to see' );
is( $ENV{SANCTIFY_REGEX_TEST}, 'pigdog', 'Okay, no SANCTIFY_REGEX_TEST' );

$sanctify->restore();

is( $ENV{SANCTIFY_REGEX_TEST}, 'Sanctify this', 'Yes sanctification worked' );
ok( !$ENV{SANCTIFY_NO_VAR}, 'Nothing to see there' );
