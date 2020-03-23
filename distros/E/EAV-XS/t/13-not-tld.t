use strict;
use warnings;
use EAV::XS;
use Test::More;


my $testnum = 0;

my $eav = EAV::XS->new('tld_check' => 0);

ok (defined $eav);

my @email_pass = (
    'non-tld@bad',
);

for my $email (@email_pass) {
    ok ($eav->is_email($email), "pass: '" . $email . "'");
    $testnum++;
}

done_testing ($testnum + 1);
