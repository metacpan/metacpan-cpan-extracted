#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

#plan tests => 1;

BEGIN {
    use_ok( 'File::PCAP::Writer' ) || print "Bail out!\n";
}

my ($args, $fname, $fpw, @gh);

$fname = 'fpw.pcap';
$args  = {
	fname => $fname,
};

diag( "Testing File::PCAP::Writer $File::PCAP::Writer::VERSION, Perl $], $^X" );

# Test default DLT (Ethernet)
$fpw = File::PCAP::Writer->new($args);
@gh  = get_global_header($fname);
ok($gh[6] eq 1, "DLT: Ethernet");

# Test DLT Raw (101)
$args->{dlt} = 101;
$fpw = File::PCAP::Writer->new($args);
@gh  = get_global_header($fname);
ok($gh[6] eq 101, "DLT: Raw");

unlink $fname;

done_testing;

# just functions

sub get_global_header {
	my ($fname) = @_;
	my $buf;
	my @fld;
	if (open(my $fh, '<', $fname)) {
		binmode $fh;
		read($fh,$buf,24);
		@fld = unpack("LSSlLLL",$buf);
	}
	return @fld;
}
