#!/usr/bin/perl -w

# ICC::Profile::cvst test module / 2018-02-06
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use File::Spec;
use Test::More tests => 3;

# local variables
my ($tag);

# does module load
BEGIN { use_ok('ICC::Profile::cvst') };

# test class methods
can_ok('ICC::Profile::cvst', qw(new header array new_fh write_fh size cin cout transform inverse jacobian parajac roots pars curv apogee fuji_xmf device_link harlequin indigo iso_18620 photoshop prinergy rampage trueflow xitron text graph sdump));

# make empty Curve object
$tag = ICC::Profile::cvst->new;

# test object class
isa_ok($tag, 'ICC::Profile::cvst');

##### more tests needed ######

