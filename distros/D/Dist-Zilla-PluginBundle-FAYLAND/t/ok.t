#!perl -T

# just make CPAN Tester return OK instead of UNKNOWN
use Test::More tests => 1;

ok(1);

=pod

PERL_DL_NONLAZY=1 /home/src/perl/repoperls/installed-perls/perl/v5.13.4-219-gb24b84e/bin/perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/*.t
t/00-compile.t ............ skipped: no tests to run
t/release-pod-coverage.t .. skipped: these tests are for release candidate testing
t/release-pod-syntax.t .... skipped: these tests are for release candidate testing
Files=3, Tests=0,  0 wallclock secs ( 0.03 usr  0.00 sys +  0.08 cusr  0.00 csys =  0.11 CPU)
Result: NOTESTS

=cut
