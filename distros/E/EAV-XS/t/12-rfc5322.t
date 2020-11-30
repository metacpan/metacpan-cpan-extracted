use strict;
use warnings;
use EAV::XS;
use Test::More;


my $testnum = 0;

my $eav = EAV::XS->new('rfc' => EAV::XS::RFC5322);

ok (defined $eav);

my @email_pass = (
    '" abc"@localhost',
    '"abc "@localhost',
    '" abc "@localhost',
    # RFC 5322 disallow spaces without quote-pairs
    # they must be used like this:
    '"space\\ like.this"@accepted.com',
    '!#$%&\'*+-/=?^_`{}|~@ok.com',
);

my @email_fail = (
    '"next char is tab:	"@bad.com',
    # RFC 5322 disallow spaces without quote-pairs
    '"like this"@bad.com',
    '"tabs	not	permitted@too.com"',
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
