# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Geomag-Kyoto-Dst.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
use Time::Local;
BEGIN { use_ok('Geomag::Kyoto::Dst') };

#########################

=head1 Tests for Geomag::Kyoto::Dst

We only check file reading, as it's a bit mean making people fetch
files from Kyoto that they don't need.

=cut

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# we don't test the web parts...

my $dst = Geomag::Kyoto::Dst->new(file => 't/Dstqthism.html');
isa_ok($dst, 'Geomag::Kyoto::Dst');

my $aref = $dst->get_array();
# 00:00:00 1st Oct 2005
#$sec,$min,$hour,$mday,$mon,$year
ok($aref->[0][0] == timegm(0,0,0,1,9,105));

ok($aref->[23][1] == -14);
ok($aref->[24*2 + 7][1] == 0);

# just the 2nd Oct 2005
my $bref = $dst->get_array(start => timegm(0,0,0,2,9,105), end=> timegm(23,23,23,2,9,105));
ok($bref->[0][0] == timegm(0,0,0,2,9,105));
ok($bref->[12][1] == -10);
