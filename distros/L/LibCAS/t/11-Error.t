#!perl -T

use lib qw(. ..);

use Data::Dumper;
use Test::More;

BEGIN {
    use_ok( 'LibCAS::Client::Response::Error' ) || BAIL_OUT("Failed to load LibCAS::Client::Response::Error");
}

diag("Testing LibCAS::Client::Response::Error $LibCAS::Client::Response::Error::VERSION, Perl $], $^X");

my $r = new_ok(LibCAS::Client::Response::Error);
isa_ok($r, LibCAS::Client::Response);
can_ok($r, qw(is_error is_failure is_success response error));
ok($r->is_error(), "is_error()");
ok(! $r->is_failure(), "not is_failure()");
ok(! $r->is_success(), "not is_success()");

done_testing();