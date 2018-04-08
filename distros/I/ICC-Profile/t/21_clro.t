#!/usr/bin/perl -w

# ICC::Profile::clro test module / 2018-03-31
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use File::Temp;
use Test::More tests => 8;

# local variables
my ($temp, $fh, $clro1, $clro2, $seq, $ttab);

# test if module loads
BEGIN { use_ok('ICC::Profile::clro') };

# test class methods
can_ok('ICC::Profile::clro', qw(new new_fh write_fh size sequence sdump));

# create new clro object
$clro1 = ICC::Profile::clro->new();

# test clro object class
isa_ok($clro1, 'ICC::Profile::clro');

# set colorant sequence
$clro1->sequence([0, 1, 2, 3]);

# get colorant sequence
$seq = $clro1->sequence();

# test sequence array
is_deeply($seq, [0, 1, 2, 3], 'clro get/set sequence');

# create new clro object
$clro2 = ICC::Profile::clro->new([0, 1, 2, 3]);

# test if clro objects are identical
is_deeply($clro1, $clro2, 'clro new from array');

# test size method
ok($clro1->size == (12 + 4), 'clro size');

# open temporary file for write-read access, binmode
$temp = File::Temp::tempfile();

# make tag table entry
$ttab = ['clro', 100, 0, 0];

# write clro object to file
$clro1->write_fh(0, $temp, $ttab);

# read new clro object from file
$clro2 = ICC::Profile::clro->new_fh(0, $temp, $ttab);

# close file
close $temp;

# test object header signature
ok($clro2->[0]{'signature'} eq 'clro', 'clro object header signature');

# clear object header
$clro2->[0] = {};

# test if clro objects are identical
is_deeply($clro1, $clro2, 'clro object round-trip');

##### more tests needed #####

