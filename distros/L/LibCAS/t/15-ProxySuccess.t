#!perl -T

use lib qw(. ..);

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok( 'LibCAS::Client::Response::ProxySuccess' ) || BAIL_OUT("Failed to load LibCAS::Client::Response::ProxySuccess");
}

diag("Testing LibCAS::Client::Response::ProxySuccess $LibCAS::Client::Response::ProxySuccess::VERSION, Perl $], $^X");

my $r = new_ok(LibCAS::Client::Response::ProxySuccess);
isa_ok($r, LibCAS::Client::Response::Success);
isa_ok($r, LibCAS::Client::Response);
can_ok($r, qw(is_error is_failure is_success response proxy_ticket));
ok(! $r->is_error(), "not is_error()");
ok(! $r->is_failure(), "not is_failure()");
ok($r->is_success(), "is_success()");

done_testing();