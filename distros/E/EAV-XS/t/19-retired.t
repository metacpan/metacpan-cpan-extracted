use strict;
use warnings;
use EAV::XS;
use Test::More;


my $testnum = 0;

my $eav = EAV::XS->new('allow_tld' => EAV::XS::TLD_RETIRED);
ok (defined $eav);

my @email_pass = (
    'retired@example.iinet',
    'retired@example.mtpc',
);

my @email_fail = (
    'generic@metacpan.org',
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
