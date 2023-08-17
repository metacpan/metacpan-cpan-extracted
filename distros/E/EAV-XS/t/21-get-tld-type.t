use strict;
use warnings;
use EAV::XS;
use Test::More;


my $testnum = 0;
my $eav = EAV::XS->new('allow_tld' => EAV::XS::TLD_ALL);

ok (defined $eav);
ok ($eav->get_tld_type() == EAV::XS::TLD_INVALID); # is_email() was not called
$testnum += 2;

ok ($eav->is_email('generic@example.best'));
ok ($eav->get_tld_type() == EAV::XS::TLD_GENERIC);
$testnum += 2;

ok ($eav->is_email('country-code@example.ai'));
ok ($eav->get_tld_type() == EAV::XS::TLD_COUNTRY_CODE);
$testnum += 2;

ok ($eav->is_email('infrastructure@example.arpa'));
ok ($eav->get_tld_type() == EAV::XS::TLD_INFRASTRUCTURE);
$testnum += 2;

ok ($eav->is_email('sponsored@example.gov'));
ok ($eav->get_tld_type() == EAV::XS::TLD_SPONSORED);
$testnum += 2;

#ok ($eav->is_email('test@example.測試'));
#ok ($eav->get_tld_type() == EAV::XS::TLD_TEST);
#$testnum += 2;

ok ($eav->is_email('not-assigned@example.duck'));
ok ($eav->get_tld_type() == EAV::XS::TLD_NOT_ASSIGNED);
$testnum += 2;

ok ($eav->is_email('special@localhost'));
ok ($eav->get_tld_type() == EAV::XS::TLD_SPECIAL);
$testnum += 2;

$eav = EAV::XS->new('allow_tld' => EAV::XS::TLD_SPECIAL);
ok (!$eav->is_email('sponsored@example.gov'));
ok ($eav->get_tld_type() != EAV::XS::TLD_SPONSORED);
cmp_ok ($eav->get_error(), "eq", "sponsored TLD");
$testnum += 3;

done_testing ($testnum);
