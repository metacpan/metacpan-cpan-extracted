#!perl -w
use strict;
use warnings;

# This is mainly a safeguard-test to check that the hardcoded
# class names XS/Inline::C generate match up with what my
# Perl code expects
use Test::More tests => 1;

my $module;

use Image::CCV;

my $param_block = Image::CCV::myccv_pack_parameters(0,0,0,0,0,0);
is ref $param_block, 'ccv_sift_param_tPtr', "Parameter block class";