use strict;
use warnings;

use Digest::SHA qw(hmac_sha256);
use FindBin qw($Bin);
use lib "$Bin/fixtures/problem48-spvm/lib";
use Test::More;

my $spvm_available = eval {
    require SPVM;
    require SPVM::Digest::SHA;
    1;
};
plan skip_all => 'SPVM and SPVM::Digest::SHA are optional benchmark dependencies'
  if !$spvm_available;

SPVM->import('DeveloperDashboard::Bench::HmacChain');

my $data  = 'salt';
my $key   = 'password';
my $count = 32;
my $expected = $data;
$expected = hmac_sha256( $expected, $key ) for 1 .. $count;

my $actual_object = SPVM::DeveloperDashboard::Bench::HmacChain->chain( $data, $key, $count );
isa_ok( $actual_object, 'SPVM::BlessedObject::String', 'compiled SPVM HMAC loop returns an SPVM string' );
is( $actual_object->to_bin, $expected, 'compiled SPVM loop matches Digest::SHA byte-for-byte' );

my $zero_iterations = SPVM::DeveloperDashboard::Bench::HmacChain->chain( $data, $key, 0 );
is( $zero_iterations->to_bin, $data, 'zero iterations return the original input unchanged' );

my $spvm_pbkdf2_one = SPVM::DeveloperDashboard::Bench::HmacChain->pbkdf2_sha256( 'password', 'salt', 1 );
is(
    unpack( 'H*', $spvm_pbkdf2_one->to_bin ),
    '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    'SPVM PBKDF2-SHA256 matches the one-iteration known vector',
);

require Developer::Dashboard::Auth;
my $spvm_pbkdf2_many = SPVM::DeveloperDashboard::Bench::HmacChain->pbkdf2_sha256( 'password', 'salt', 32 );
is(
    unpack( 'H*', $spvm_pbkdf2_many->to_bin ),
    Developer::Dashboard::Auth::_pbkdf2_hmac_sha256_hex( 'password', 'salt', 32 ),
    'SPVM PBKDF2-SHA256 matches the Dashboard reference implementation',
);

done_testing;

__END__

=pod

=head1 NAME

t/655-spvm-hmac-loop.t - SPVM HMAC loop parity test for Problem 48

=head1 PURPOSE

This optional test verifies that the experimental SPVM-compiled HMAC loop
preserves the chained HMAC-SHA256 bytes produced by C<Digest::SHA> and handles
the zero-iteration boundary. It also checks a PBKDF2 known-answer vector and
parity with the Dashboard's Perl PBKDF2 reference.

=head1 WHY IT EXISTS

Problem 48 evaluates SPVM as a possible way to accelerate the password-hash
hot path. Calling into SPVM once per HMAC iteration adds an expensive language
boundary, so this test exercises one compiled SPVM method for the whole loop
instead. It is a benchmark fixture, not an authentication backend.

=head1 WHEN TO USE

Run this test when changing the experimental SPVM fixture or reevaluating the
SPVM approach. It skips only when the optional SPVM distribution is absent;
SPVM compile failures and output mismatches remain test failures.

=head1 HOW TO USE

  prove -lv t/655-spvm-hmac-loop.t

The Problem 48 Docker benchmark image supplies the optional SPVM modules. The
test performs five assertions: SPVM return type, 32-iteration chain byte
parity, zero-iteration behavior, the one-round PBKDF2 known-answer vector, and
32-round parity with the Dashboard reference. It exercises the benchmark-only
compiled loop in F<t/fixtures/problem48-spvm>.

=head1 WHAT USES IT

The Problem 48 SPVM benchmark script and Docker test gate use this test to
guard the experimental HMAC and PBKDF2 output contracts. The application does
not load this fixture.

=head1 EXAMPLES

Run the targeted test from the repository root:

  prove -lv t/655-spvm-hmac-loop.t

Run it with coverage after changing the fixture:

  prove -lv -MDevel::Cover t/655-spvm-hmac-loop.t

Run the targeted test in the scoped Docker bench, which has the optional SPVM
dependencies installed:

  d2 docker compose -p dd-problem48-bench -f /tmp/d2-problem48-bench.yml -f /tmp/d2-problem48-init.yml run --rm bench prove -lv t/655-spvm-hmac-loop.t

=cut
