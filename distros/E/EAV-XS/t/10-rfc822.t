use strict;
use warnings;
use EAV::XS;
use Test::More;


my $testnum = 0;

my $eav = EAV::XS->new('rfc' => EAV::XS::RFC822);

ok (defined $eav);

my @email_pass = (
    '!#$%&\'*+-/=?^_`{}|~@ok.com',
    # original: "()<>[]:,;@\\\"!#$%&'-/=?^_`{}| ~.a"@ok.com
    # perl thinks that it's smarte than a man :)
    '"()<>[]:,;@\\\\\"!#$%&\'-/=?^_`{}| ~.a"@ok.com',
    '"next char is CR:"@ugly.com',
);

for my $email (@email_pass) {
    ok ($eav->is_email($email), "pass: '" . $email . "'");
    $testnum++;
}

done_testing ($testnum + 1);
