# vim: filetype=perl :
use Test::More tests => 757;
use lib 't/lib';
use Test::MMS::Parser;

BEGIN {
   use_ok('MMS::Parser');
}

my $parser = MMS::Parser->create();

# Test 1-octet stuff like octet or uint8
my $TID_checker = make_checker($parser, 'TID');
foreach my $index (0 .. 255) {
   my $c = chr($index);
   $TID_checker->($c, $index);
}

my %tests = (
   Reserved => [ 0, 0x81 .. 0xff ],
   Connect => 1,
   ConnectReply => 2,
   Redirect => 3,
   Reply => 4,
   Disconnect => 5,
   Push => 6,
   ConfirmedPush => 7,
   Suspend => 8,
   Resume => 9,
   Unassigned => [ 0x10 .. 0x3f ],
   Get => 0x40,
   Options_GetPDU => 0x41,
   Head_GetPDU => 0x42,
   Delete_GetPDU => 0x43,
   Trace_GetPDU => 0x44,
   Unassigned_GetPDU => [ 0x45 .. 0x4f ],
   ExtendedMethod_GetPDU => [ 0x50 .. 0x5f ],
   Post => 0x60,
   Put_PostPDU => 0x61,
   Unassigned_PostPDU => [ 0x62 .. 0x6f ],
   ExtendedMethod_PostPDU => [ 0x70 .. 0x7f ],
   DataFragmentPDU => 0x80,
);

my $PDU_type_checker = make_checker($parser, 'PDU_type');
while (my ($subname, $spec) = each %tests) {
   my $checker = make_checker($parser, $subname);
   my @list = ref($spec) ? @$spec : $spec;
   foreach my $index (@list) {
      my $c = chr($index);
      $checker->($c, $subname);
      $PDU_type_checker->($c, $subname);
   }
}
