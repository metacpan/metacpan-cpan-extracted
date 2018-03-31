#!/usr/bin/perl -w

# ICC::Profile::mft2 test module / 2018-03-27
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use t::lib::Boot;
use ICC::Profile::matf;
use ICC::Profile::curv;
use ICC::Profile::cvst;
use ICC::Profile::clut;
use Test::More tests => 6;

# local variables
my ($profile, $tag, $temp, $raw1, $raw2);

# does module load
BEGIN { use_ok('ICC::Profile::mft2') };

# test class methods
can_ok('ICC::Profile::mft2', qw(new new_fh write_fh size cin cout header matrix input clut output mask clip transform inverse jacobian pcs wtpt sdump));

# make empty mft2 object
$tag = ICC::Profile::mft2->new;

# test object class
isa_ok($tag, 'ICC::Profile::mft2');

# read GRACoL2006_Coated1v2 profile
$profile = t::lib::Boot->new(File::Spec->catfile('t', 'data', 'GRACoL2006_Coated1v2.icc'));

# read 'A2B0' tag
$tag = ICC::Profile::mft2->new_fh($profile, $profile->fh, $profile->tag_table->[3]);

# test object class
isa_ok($tag, 'ICC::Profile::mft2');

# test size method
ok($tag->size == $profile->tag_table->[3][2], 'tag size');

# open temporary file for write-read access
open($temp, '+>' . File::Spec->catfile('t', 'data', 'temp.dat'));

# set binary mode
binmode($temp);

# write tag to temporary file
$tag->write_fh($profile, $temp, $profile->tag_table->[3]);

# read profile raw data
seek($profile->fh, $profile->tag_table->[3][1], 0);
read($profile->fh, $raw1, $tag->size);

# read temporary raw data
seek($temp, $profile->tag_table->[3][1], 0);
read($temp, $raw2, $tag->size);

# test raw data round-trip integrity
ok($raw1 eq $raw2, 'raw data round-trip');

# compare strings, if different
str_cmp($raw1, $raw2) if ($raw1 ne $raw2);

# close profile
close($profile->fh);

# close temporary file
close($temp);

##### more tests needed #####

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

