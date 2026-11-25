use strict;
use warnings;

use Test::More;

use Developer::Dashboard::HtmlEscape ();
use Developer::Dashboard::GoRoutine;

ok $Developer::Dashboard::HtmlEscape::XS_LOADED,
  'the GoRoutine module shares the already-loaded Dashboard XS object';
ok defined(&go),       'go is exported by Developer::Dashboard::GoRoutine';
ok defined(&wait_all), 'wait_all is exported by Developer::Dashboard::GoRoutine';
ok defined(&share),    'share is exported by Developer::Dashboard::GoRoutine';

share my $counter = 0;
for ( 1 .. 40 ) {
    go sub {
        $counter += 1;
    };
}
wait_all();
is 0 + $counter, 40, 'routine compound updates are visible to the caller';

share my $text = 'worker';
for ( 1 .. 8 ) {
    go sub {
        $text .= '!';
    };
}
wait_all();
is "$text", 'worker!!!!!!!!', 'routine string updates are shared';

$counter = 100;
$counter -= 7;
is 0 + $counter, 93, 'subtraction is applied to a shared scalar';
$counter *= 2;
is 0 + $counter, 186, 'multiplication is applied to a shared scalar';
$counter /= 3;
is 0 + $counter, 62, 'division is applied to a shared scalar';
$counter %= 9;
is 0 + $counter, 8, 'modulus is applied to a shared scalar';
--$counter;
is 0 + $counter, 7, 'decrement is applied to a shared scalar';

share my $other = 5;
$counter += $other;
is 0 + $counter, 12, 'a shared scalar can be the right-hand operand';

my $invalid_go_ok = eval {
    &Developer::Dashboard::GoRoutine::go('not a callback');
    1;
};
ok !$invalid_go_ok, 'go rejects a non-callback argument';
like $@, qr/go\(\) expects a code reference/, 'invalid callback error is explicit';

my $division_ok = eval { $counter /= 0; 1 };
ok !$division_ok, 'division by zero is rejected';
like $@, qr/Illegal division by zero/, 'division failure is explicit';

done_testing;

__END__

=head1 NAME

231-goroutine-integration.t - verify the packaged GoRoutine XS runtime

=head1 DESCRIPTION

This integration test checks that the Developer::Dashboard distribution
provides its GoRoutine API, waits for routines, and exposes
shared scalar updates to the calling interpreter. It is a regression
contract for packaging the XS extension with the existing distribution rather
than relying on a separately installed development copy.

=head1 PURPOSE

The GoRoutine package is intended to replace direct Perl C<fork> usage for
asynchronous work. These checks cover the public API and the shared scalar
operations needed by routines. They do not by themselves prove
Windows or macOS portability, process lifecycle parity, or integration with
every existing runtime call site; those require their own tests and hosted
platform evidence.

=head1 WHY IT EXISTS

The XS library must be built and loaded from the distribution that ships it.
This test catches missing exported APIs, worker shutdown hangs, and lost writes
before collectors or runtime supervision depend on the new concurrency layer.

=head1 WHEN TO USE

Run this test in the dev Docker container after configuring and building the
distribution's XS extension, or as part of the full test suite. A missing
module, failed XS load, unfinished routine, lost scalar update, or corrupted
shared string is a test failure.

=head1 HOW TO USE

  d2 docker compose exec dev prove -lv t/231-goroutine-integration.t

The test starts forty routines that update one shared integer, waits for them,
and checks the final value. It then starts eight routines that append to a
shared string and checks the final string. It also checks the supported
compound numeric operations, decrement, a shared right-hand operand, explicit
callback validation, and division-by-zero reporting. The exact routine
completion order is intentionally unspecified.

=head1 WHAT USES IT

The test suite runs this file through C<prove> and the distribution's normal
test harness. The GoRoutine module is expected to be built and loaded from the
distribution's configured XS library path.

=head1 EXAMPLES

Run the focused contract:

  d2 docker compose exec dev prove -lv t/231-goroutine-integration.t

Run it after rebuilding the XS library and before the full suite:

  d2 docker compose exec dev bash -c 'PERL5LIB=/work/blib/lib:/work/blib/arch prove -lv t/231-goroutine-integration.t'

=cut
