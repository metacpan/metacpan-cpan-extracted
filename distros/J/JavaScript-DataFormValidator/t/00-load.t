#!perl -T

use Test::More qw/no_plan/;
use strict;

BEGIN {
	use_ok( 'JavaScript::DataFormValidator' );
}

diag( "Testing JavaScript::DataFormValidator $JavaScript::DataFormValidator::VERSION, Perl $], $^X" );

my $dfv_profile_in_js  = js_dfv_profile( 'profile' => { required => 'john' } );
like($dfv_profile_in_js, qr/script/, "reality check profile for script tag");
like($dfv_profile_in_js, qr/john/, "reality check profile for john");

my $onsubmit_code      = js_dfv_onsubmit('profile');
like($onsubmit_code, qr/onsubmit/i, "onsubmit contains onsubmit");
like($onsubmit_code, qr/profile/i, "onsubmit contains onsubmit");

