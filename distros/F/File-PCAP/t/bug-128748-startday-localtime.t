#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use POSIX qw(tzset);

BEGIN {
    use_ok( 'File::PCAP::ACAP2PCAP' ) || print "Bail out!\n";
}

my ($args, $fname, $fpa, @gh);

$fname = 'fpa.pcap';

$args  = {
	output   => $fname,
        startday => '2019-03-08',
};

$ENV{TZ} = 'Europe/Berlin';

$fpa = File::PCAP::ACAP2PCAP->new($args);

ok(1552003200 == $fpa->{sot}, "test 'sot' with TZ Europe/Berlin");

$ENV{TZ} = 'America/Los_Angeles';

$fpa = File::PCAP::ACAP2PCAP->new($args);

ok(1552003200 == $fpa->{sot}, "test 'sot' with TZ America/Los_Angeles");

unlink $fname;

done_testing;

# vim: set tw=2 sw=2 et ai si:
