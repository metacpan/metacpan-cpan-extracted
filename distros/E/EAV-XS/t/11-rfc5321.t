use strict;
use warnings;
use EAV::XS;
use Test::More;


my $testnum = 0;

my $eav = EAV::XS->new('rfc' => EAV::XS::RFC5321);

ok (defined $eav);

my @email_pass = (
    '!#$%&\'*+-/=?^_`{}|~@ok.com',
    # original: "()<>[]:,;@\\\"!#$%&'-/=?^_`{}| ~.a"@ok.com
    # perl thinks that it's smarte than a man :)
    '"()<>[]:,;@\\\\\"!#$%&\'-/=?^_`{}| ~.a"@ok.com',
);

my @email_fail = (
    '"next char is tab:	"@bad.com',
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
