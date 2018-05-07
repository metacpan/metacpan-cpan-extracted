#!perl -T
#
# see https://rt.cpan.org/Ticket/Display.html?id=125230 for a
# description of bug #125230
# 
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok( 'File::PCAP::ACAP2PCAP' ) || print "Bail out!\n";
  use_ok( 'File::PCAP::Reader' ) || print "Bail out!\n";
}

my ($args, $fname, $fpa, @gh);

$fname = 'bug-125230-cross-midnight.pcap';

diag( "Testing File::PCAP::ACAP2PCAP $File::PCAP::ACAP2PCAP::VERSION, Perl $], $^X" );

# test cutted dump

$args  = {
	output => $fname,
  dlt    => 101,
};

$fpa = File::PCAP::ACAP2PCAP->new($args);

if (open(my $fd, '<', 't/data/bug-125230-cross-midnight.dump')) {
  $fpa->parse($fd);
  close $fd;
  my $fpr = File::PCAP::Reader->new( $fname );
  my $ts_sec = 0;
  while (my $np = $fpr->next_packet()) {
    if ($ts_sec > $np->{ts_sec}) {
      fail("bug 125230 test: time went backward");
      done_testing;
      exit
    }
    $ts_sec = $np->{ts_sec};
  }
  pass("bug 125230 test");
  unlink $fname;
}

done_testing;

# vim: set ts=2 sw=2 et ai si:
