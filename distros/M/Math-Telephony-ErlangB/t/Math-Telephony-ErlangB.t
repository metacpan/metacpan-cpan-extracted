# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TrafficModeling-ErlangB.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 142;
#use Test::More 'no_plan';
BEGIN { use_ok('Math::Telephony::ErlangB') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Math::Telephony::ErlangB qw(:all);

#########################################################################
# gos

# Edge and beyond cases
foreach my $traffic (undef, -1) {
   my $ptraffic = defined($traffic) ? $traffic : "undef";
   foreach my $servers (undef, -1, 0, 1, 1.5, 2) {
      my $pservers = defined($servers) ? $servers : "undef";
      is(gos($traffic, $servers), undef, "gos($ptraffic, $pservers) is undef");
   }
}
foreach my $traffic (undef, -1, 0, 1, 1.5, 2) {
   my $ptraffic = defined($traffic) ? $traffic : "undef";
   foreach my $servers (undef, -1, 1.4) {
      my $pservers = defined($servers) ? $servers : "undef";
      is(gos($traffic, $servers), undef, "gos($ptraffic, $pservers) is undef");
   }
}
is(gos(0, $_), 0, "gos(0, $_) is 0") foreach (0, 1, 2, 10, 100);
is(gos($_, 0), 1, "gos($_, 0) is 1") foreach (0.001, 1, 2, 10, 100);

# Some real world calculations
my @gos = (
   [1, 1, 0.5],
   [1, 2, 0.2],
   [1, 10, 0.0],
);
cmp_ok(abs(gos($_->[0], $_->[1]) - $_->[2]), "<", 0.001,
       "|gos($_->[0], $_->[1]) - $_->[2]| < 0.001") foreach (@gos);


#########################################################################
# servers

# Edge and beyond cases
foreach my $traffic (undef, -1) {
   my $ptraffic = defined($traffic) ? $traffic : "undef";
   foreach my $gos (undef, -1, 0, 0.5, 1, 1.5) {
      my $pgos = defined($gos) ? $gos : "undef";
      is(servers($traffic, $gos), undef, "servers($ptraffic, $pgos) is undef");
   }
}
foreach my $traffic (undef, -1, 0, 1, 1.5, 2) {
   my $ptraffic = defined($traffic) ? $traffic : "undef";
   foreach my $gos (undef, -1, 1.5) {
      my $pgos = defined($gos) ? $gos : "undef";
      is(servers($traffic, $gos), undef, "servers($ptraffic, $pgos) is undef");
   }
}
is(servers(0, $_), 0, "servers(0, $_) is 0") foreach (0, 0.2, 0.5, 0.8, 1.0);
is(servers($_, 0), undef, "servers($_, 0) is undef")
  foreach (0.001, 1, 2, 10, 100);

my @servers = (
   [1, 0.5, 1],
   [1, 0.2, 2],
   [1, 0.001, 6],
);
is(servers($_->[0], $_->[1]), $_->[2], "servers($_->[0], $_->[1]) == $_->[2]")
  foreach (@servers);


#########################################################################
# traffic

# Edge and beyond cases
foreach my $servers (undef, -1, 1.4) {
   my $pservers = defined($servers) ? $servers : "undef";
   foreach my $gos (undef, -1, 0, 0.5, 1, 1.5) {
      my $pgos = defined($gos) ? $gos : "undef";
      is(traffic($servers, $gos), undef, "traffic($pservers, $pgos) is undef");
   }
}
foreach my $servers (undef, -1, 0, 1, 1.5, 2) {
   my $pservers = defined($servers) ? $servers : "undef";
   foreach my $gos (undef, -1, 1.5) {
      my $pgos = defined($gos) ? $gos : "undef";
      is(traffic($servers, $gos), undef, "traffic($pservers, $pgos) is undef");
   }
}
is(traffic(0, $_), 0, "traffic(0, $_) is 0") foreach (0, 0.2, 0.5, 0.8, 1.0);
is(traffic($_, 0), 0, "traffic($_, 0) is 0") foreach (0, 1, 2, 10, 100);
is(traffic($_, 1), undef, "traffic($_, 0) is undef")
  foreach (0.001, 1, 2, 10, 100);

is(traffic(10, 0.2, -0.1), undef, "negative traffic precision is undef");

my @traffic = (
   [1, 0.5, 1],
   [2, 0.2, 1],
   [6, 0.02, 2.2756],
);
cmp_ok(abs(traffic($_->[0], $_->[1]) - $_->[2]), "<", 0.001,
       "|traffic($_->[0], $_->[1]) - $_->[2]| < 0.001") foreach (@traffic);
