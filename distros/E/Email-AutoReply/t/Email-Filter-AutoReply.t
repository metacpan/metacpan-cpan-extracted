# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Email-Filter-AutoReply.t'

use strict;
use Test::More qw(no_plan);
BEGIN { use_ok('Email::Filter::AutoReply') };

