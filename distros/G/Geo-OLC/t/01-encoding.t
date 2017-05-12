#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Geo::OLC qw(encode decode _code_digits);

my @tests;
open(IN,'t/encodingTests.csv') or die "t/encodingTests.csv: $!\n";
while (<IN>) {
	chomp;
	next if /^\s*#/;
	push(@tests,$_);
}
close(IN);

# several codes in the file are range tests that will
# *not* decode to the exact same lat/lon they were
# encoded with. This is not an error.
#
my %decode_fix = (
	'90,1' => '89.5,1.5',
	'92,1' => '89.5,1.5',
	'1,180' => '1.5,-179.5',
	'1,181' => '1.5,-178.5',
);

plan tests => @tests * 2 + 1;

foreach (@tests) {
	my ($code,$lat,$lon,$latLO,$lonLO,$latHI,$lonHI) = split(/,/);
	my $code2 = encode($lat,$lon,_code_digits($code));
	ok ($code eq $code2, "encode($lat,$lon): $code == $code2");
	my $result = decode($code);
	my ($lat2,$lon2) = @{$result->{center}};

	# floating-point can add spurious digits to decoded lat/lon;
	# in this test file, it's the '7FG49QCJ+2VXGJ' test. That's
	# why we're comparing as string and truncating to match the
	# known length of the input.
	#
	if ($decode_fix{"$lat,$lon"}) {
		my $tmp = $decode_fix{"$lat,$lon"};
		ok ($tmp eq "$lat2,$lon2",
			"decode($code): $tmp == $lat2,$lon2");
	}else{
		ok ($lat eq substr($lat2,0,length($lat))
			&& $lon eq substr($lon2,0,length($lon)),
			"decode($code): $lat,$lon == $lat2,$lon2");
	}
}

# an additional test taken from the Ruby API;
# encode-only, since it's got range and floating-point issues
#
my ($code,$lat,$lon) = ('CFX3X2X2+X2RRRRJ',90,1);
my $code2 = encode($lat,$lon,_code_digits($code));
ok ($code eq $code2, "encode($lat,$lon): $code == $code2");
