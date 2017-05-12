use Test::More tests => 12;

BEGIN { use_ok('Mac::Tie::PList') };

my $plist = Mac::Tie::PList->new_from_file("t/test-xml.plist");
ok($plist);
ok(ref $plist eq "HASH");
ok($plist->{'String'} eq 'Gavin');
ok($plist->{'Number'} == 42);
ok($plist->{'Bool'} == (1==1));
ok($plist->{'Date'} == 1139144800);
ok($plist->{'Data'}); #TODO
ok($plist->{'SubDict'}->{'Another String'} eq 'Brock');
ok($plist->{'Array'}->[0] eq 'a');
ok($plist->{'Array'}->[1] eq 'b');
ok($plist->{'Array'}->[2] eq 'c');

#`use Data::Dumper;
#print Data::Dumper->Dump([$plist]);
