#!/usr/bin/perl -w

# ICC::Shared test module / 2015-09-02
#
# Copyright © 2004-2018 by William B. Birkett

use strict;

use Test::More tests => 3;

# does module load
BEGIN { use_ok('ICC::Shared') };

# test class methods
can_ok('ICC::Shared', qw(copy dump));
can_ok('Math::Matrix', qw(sdump dump power xyz2XYZ XYZ2xyz));

##### more tests needed #####

