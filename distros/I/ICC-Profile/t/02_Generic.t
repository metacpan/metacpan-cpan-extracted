#!/usr/bin/perl -w

# ICC::Profile::Generic test module / 2018-03-31
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use File::Temp;
use t::lib::Boot;
use Test::More tests => 4;

# local variables
my ($profile, $tag, $temp, $ttab, $size, $raw1, $raw2);

# does module load
BEGIN { use_ok('ICC::Profile::Generic') };

# test class methods
can_ok('ICC::Profile::Generic', qw(new new_fh write_fh size data sdump));

# make empty Generic object
$tag = ICC::Profile::Generic->new;

# test object class
isa_ok($tag, 'ICC::Profile::Generic');

# read GRACoL2006_Coated1v2 profile
$profile = t::lib::Boot->new(File::Spec->catfile('t', 'data', 'GRACoL2006_Coated1v2.icc'));

# open temporary file for write-read access, binmode
$temp = File::Temp::tempfile();

# for each tag table entry
for $ttab (@{$profile->tag_table}) {
	
	# read tag as Generic type
	$tag = ICC::Profile::Generic->new_fh($profile, $profile->fh, $ttab);
	
	# write tag to temporary file
	$tag->write_fh($profile, $temp, $ttab);
	
}

# flush buffer
$temp->flush;

# compute total tag size
$size = $profile->tag_table->[-1][2] + $profile->tag_table->[-1][1] - $profile->tag_table->[0][1];

# read profile raw data
seek($profile->fh, $profile->tag_table->[0][1], 0);
read($profile->fh, $raw1, $size);

# read temporary raw data
seek($temp, $profile->tag_table->[0][1], 0);
read($temp, $raw2, $size);

# test raw data round-trip integrity
ok($raw1 eq $raw2, 'raw data round-trip');

# compare strings, if different
str_cmp($raw1, $raw2) if ($raw1 ne $raw2);

# close files
close($profile->fh);
close($temp);

# compare strings
sub str_cmp {

	# get strings
	my ($s1, $s2) = @_;

	# local variables
	my ($len1, $len2, $lenmax, $mm, $c1, $c2);

	# get string lengths
	$len1 = length($s1);
	$len2 = length($s2);

	# print string lengths
	print STDERR "\n\tlen1 $len1 : len2 $len2\n";

	# get maximum length
	$lenmax = $len1 > $len2 ? $len1 : $len2;

	# init mismatch counter
	$mm = 0;

	# for each character
	for my $i (0 .. $lenmax - 1) {
		
		# get characters
		$c1 = $i < $len1 ? sprintf('%02x', ord(substr($s1, $i, 1))) : 'undef';
		$c2 = $i < $len2 ? sprintf('%02x', ord(substr($s2, $i, 1))) : 'undef';
		
		# if strings differ
		if ($c1 ne $c2) {
			
			# print difference
			printf STDERR "\tindex %d  - %s : %s\n", $i, $c1, $c2;
			
			# increment counter
			$mm++;
			
		}
		
		# quit if number of mismatches > 10
		last if ($mm > 10);
		
	}
	
}

