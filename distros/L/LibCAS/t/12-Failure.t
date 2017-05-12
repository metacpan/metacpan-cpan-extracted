#!perl -T

use lib qw(. ..);

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok( 'LibCAS::Client::Response::Failure' ) || BAIL_OUT("Failed to load LibCAS::Client::Response::Failure");
}

diag("Testing LibCAS::Client::Response::Failure $LibCAS::Client::Response::Failure::VERSION, Perl $], $^X");

my $r = new_ok(LibCAS::Client::Response::Failure);
isa_ok($r, LibCAS::Client::Response);
can_ok($r, qw(is_error is_failure is_success response code message));
ok(!$r->is_error(), "not is_error()");
ok($r->is_failure(), "is_failure()");
ok(! $r->is_success(), "not is_success()");

done_testing();