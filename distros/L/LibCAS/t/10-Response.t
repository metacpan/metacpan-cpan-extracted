#!perl -T

use lib qw(. ..);

use Data::Dumper;
use Test::More;

BEGIN {
	use_ok( 'LibCAS::Client::Response' ) || BAIL_OUT("Failed to load LibCAS::Client::Response");
}

diag("Testing LibCAS::Client::Response $LibCAS::Client::Response::VERSION, Perl $], $^X");

my $r = new_ok(LibCAS::Client::Response);
can_ok($r, qw(is_error is_failure is_success response));

done_testing();