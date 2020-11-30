use strict;
use warnings;
use EAV::XS;
use Test::More;


my $testnum = 0;
my $eav = EAV::XS->new();

my @email_pass = (
    'abc.xyz@pass.com',
    '"abc."@pass.com',
    '"abc.".xyz@pass.com',
    '".xyz"@pass.com',
);

my @email_fail = (
    '.@fail.com',
    '..@fail.com',
    'abc.@fail.com',
    'abc..xyz@fail.com',
    'abc...xyz@fail.com',
    '.".xyz"@fail.com',
    'abc".xyz"@fail.com',
    'abc.."xyz"@fail.com',
);

my %rfc = (
    '822' => EAV::XS::RFC822,
    '5321' => EAV::XS::RFC5321,
    '5322' => EAV::XS::RFC5322,
    '6531' => EAV::XS::RFC6531,
);

for my $rfcnum (keys %rfc) {
    $eav->setup ('rfc' => $rfc{$rfcnum});

    for my $email (@email_pass) {
#        diag("[rfc$rfcnum]$email: " . $eav->get_error()) if !$eav->is_email($email);
        ok ($eav->is_email($email), "pass [rfc$rfcnum]: '$email'");
        $testnum++;
    }

    for my $email (@email_fail) {
        ok (! $eav->is_email($email), "fail [rfc$rfcnum]: '$email'");
        $testnum++;
    }
}

done_testing ($testnum);
