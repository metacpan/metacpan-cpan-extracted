#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

#plan tests => 1;

BEGIN {
    use_ok( 'File::PCAP::Reader' ) || print "Bail out!\n";
}

my ($fname, $fpr, $gh, $llht, $pkg, $pkg_count);

$fname = 't/data/03-raw-ip.pcap';

diag( "Testing File::PCAP::Reader $File::PCAP::Reader::VERSION, Perl $], $^X" );

$fpr = File::PCAP::Reader->new($fname);

$gh = $fpr->global_header();

ok(0xa1b2c3d4 == $gh->{magic_number},"global header: magic number");
ok(2 == $gh->{version_major},"global header: major version = $gh->{version_major}, should be 2");
ok(4 == $gh->{version_minor},"global header: minor version = $gh->{version_minor}, should be 4");
ok(0 == $gh->{thiszone},"global header: time zone correction = $gh->{thiszone}, should be 0");
ok(0 == $gh->{sigfigs},"global header: accuracy of timestamps = $gh->{sigfigs}, should be 0");
ok(0xffff == $gh->{snaplen},"global header: max length of captured packets = $gh->{snaplen}, should be 65535");
ok(101 == $gh->{network},"global header: data link type = $gh->{network}, should be 101");

$llht = $fpr->link_layer_header_type();
ok(0 == ("LINKTYPE_RAW" cmp $llht),"name of link layer type is '$llht' should be 'LINKTYPE_RAW'");

$pkg_count = 0;
$pkg = $fpr->next_packet();
while (not $pkg->{eof}) {
    $pkg_count++;
    last if $pkg_count > 2;
    $pkg = $fpr->next_packet();
}

ok(2 == $pkg_count, "pkg_count = $pkg_count, should be 2");

done_testing;

# just functions

# eof
