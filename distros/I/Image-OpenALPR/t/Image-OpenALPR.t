#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('Image::OpenALPR') };

my $alpr = Image::OpenALPR->new('us');
my $version = $alpr->getVersion;
note "OpenALPR version is $version, this module was designed for 2.2.4" unless $version =~ /^2\.2/;
$alpr->setCountry('eu');
$alpr->set_top_n(3);
my @plates = $alpr->recognise('t/ex.jpg');
is @plates, 1, 'Found only one plate';
is $plates[0]->plate, 'ZP36709', 'plate number';
cmp_ok $plates[0]->confidence, '>=', 80, 'high confidence';
my @cands = $plates[0]->candidates;
is @cands, 3, 'number of candidates matches top_n';

# These two methods should not die (nor do anything useful)
$cands[0]->coordinates;
$cands[0]->candidates;

my $data;

{
	open my $fh, '<t/ex.jpg';
	local $/ = undef;
	$data = <$fh>;
	close $fh;
}

my $plate = $alpr->recognise(\$data);
is $plate, 'ZP36709', 'recogniseArray + string conversion';
my @coords = $plate->coordinates;
is $coords[0][0], 306, 'coordinates';
is $plate->coordinates->[0][1], 351, 'coordinates in scalar context';
is $plate->candidates->[0], $plate, 'candidates in scalar context';
