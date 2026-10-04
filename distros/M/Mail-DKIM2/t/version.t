use strict; use warnings;
use Test::More;
use Mail::DKIM2;
use Mail::DKIM2::Common qw(DKIM2_DRAFT DKIM2_DATE);
is(DKIM2_DRAFT, 'ietf-dkim-dkim2-spec-06', 'draft constant is -06');
is(DKIM2_DATE, '2026-10-02', 'software date is the last DKIM2 behaviour change (installed milter name in X-DKIM2-Info sw=)');

# One distribution version, carried by every module.
ok($Mail::DKIM2::VERSION, 'Mail::DKIM2 has a version');
for my $m (qw(Common DSN HeaderParser MessageInstance MessageStore Reflector Signature
              Signer Split TagValueList Validate Verifier)) {
    my $pkg = "Mail::DKIM2::$m";
    eval "require $pkg; 1" or die $@;
    is($pkg->VERSION, $Mail::DKIM2::VERSION, "$pkg carries the distribution version");
}
done_testing;
