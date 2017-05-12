use strict;
use warnings;

use Test::More tests => 22;
use Socket;
use IO::EventMux::Socket::MsgHdr;

ok(1); # If we made it this far, we are ok.

for my $g (*recvmsg, *sendmsg) {
  ok(defined *{$g}{CODE}, "basic exports");
}

for my $m (qw|new name namelen buf buflen control controllen flags cmsghdr|) {
  ok(IO::EventMux::Socket::MsgHdr->can($m), "Socket::MsgHdr->can($m)");
}

# len/int accessors
for my $m (qw|namelen buflen controllen flags|) {
  my $val = int(rand(1024)+1);
  my $hdr = new IO::EventMux::Socket::MsgHdr ($m => $val);
  ok($val == $hdr->$m(), "$m method/ctor ok");
}

# other accessors
for my $m (qw|name buf control|) {
  my $val = "foo" x int(rand(256)+1);
  my $hdr = new IO::EventMux::Socket::MsgHdr ($m => $val);
  my $mlen = $m. "len";
  ok($val eq $hdr->$m() && length($hdr->$m)==$hdr->$mlen, "$m method/ctor ok");
}

my $hdr = IO::EventMux::Socket::MsgHdr->new();
ok(!$hdr->controllen && !defined($hdr->control),
   "empty initial cmsghdr sets control");
my @l = (5, 10, "fifteen", 20, 25, "thirty");
$hdr->cmsghdr(@l);
ok($hdr->controllen && (length($hdr->control) == $hdr->controllen),
   "cmsghdr sets control");
ok(eq_array(\@l, [$hdr->cmsghdr]), "cmsghdr fetches properly");


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

