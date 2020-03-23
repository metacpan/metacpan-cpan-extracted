use strict;
use warnings;
use EAV::XS;
use Test::More;


my $testnum = 0;

my $eav = EAV::XS->new(
    'allow_tld' => EAV::XS::TLD_GENERIC | EAV::XS::TLD_SPECIAL,
);

ok (defined $eav);

my @email_pass = (
    'pass@example.best',
    'pass@localhost',
    'pass@test',
);

my @email_fail = (
    'fail@example.ai',      # county-code
    'fail@example.pro',     # generic-restricted
    'fail@example.測試',    # test
    'fail@example.भारतम्',   # not assigned
);

for my $email (@email_pass) {
    ok ($eav->is_email($email), "pass: '" . $email . "'");
    $testnum++;
}

for my $email (@email_fail) {
    ok (! $eav->is_email($email), "fail: '" . $email . "'");
    $testnum++;
}

done_testing ($testnum + 1);
