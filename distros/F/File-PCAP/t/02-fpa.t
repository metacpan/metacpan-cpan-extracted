#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'File::PCAP::ACAP2PCAP' ) || print "Bail out!\n";
}

my ($args, $fname, $fpa, @gh);

$fname = 'fpa.pcap';

diag( "Testing File::PCAP::ACAP2PCAP $File::PCAP::ACAP2PCAP::VERSION, Perl $], $^X" );

# test cutted dump

$args  = {
	output => $fname,
        dlt    => 101,
};

$fpa = File::PCAP::ACAP2PCAP->new($args);

if (open(my $fd, '<', 't/data/02-asa-clipped.dump')) {
  $fpa->parse($fd);
  close $fd;
  ok(136 == -s $fname,"clipped dump");
  unlink $fname;
}

done_testing;

# vim: set tw=2 sw=2 et ai si:
