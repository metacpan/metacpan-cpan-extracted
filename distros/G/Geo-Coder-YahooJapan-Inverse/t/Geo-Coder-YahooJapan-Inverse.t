# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Geo-Coder-YahooJapan-Inverse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 10;
BEGIN { use_ok('Geo::Coder::YahooJapan::Inverse') };
use utf8;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Test 1: Main function
while (<DATA>) {
    my ($lat,$long,$datum,$address,$code) = split(/,/,$_);
    my $res = invlookup($lat,$long,{datum=>$datum});
    ok ($res->{address} eq $address);
    ok (join("",@{$res->{addressitem}}) eq $address);
    ok ($res->{code} eq $code);
}

# Test 2: Error case

eval {invlookup("g","h")};
ok ($@ =~ /^Format\sof\scoordinate\sis\swrong/);

eval {invlookup(35,135,{datum=>'dummy'})};
ok ($@ =~ /^Datum\sis\swrong/);

eval {invlookup(-35,-135)};
ok ($@ =~ /^API\serror\soccured/);

__END__
35.658725884775244,139.74541783332825,wgs84,東京都港区芝公園４丁目,13103012004,
35,135,tokyo,兵庫県西脇市上比延町,28213012000,
