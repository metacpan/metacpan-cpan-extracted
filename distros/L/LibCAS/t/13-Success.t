#!perl -T

use lib qw(. ..);

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok( 'LibCAS::Client::Response::Success' ) || BAIL_OUT("Failed to load LibCAS::Client::Response::Success");
}

diag("Testing LibCAS::Client::Response::Success $LibCAS::Client::Response::Success::VERSION, Perl $], $^X");

my $r = new_ok(LibCAS::Client::Response::Success);
isa_ok($r, LibCAS::Client::Response);
can_ok($r, qw(is_error is_failure is_success response));
ok(! $r->is_error(), "not is_error()");
ok(! $r->is_failure(), "not is_failure()");
ok($r->is_success(), "is_success()");

done_testing();