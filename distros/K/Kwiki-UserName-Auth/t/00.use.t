#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

use_ok('Kwiki::UserName::Auth');
require_ok ('Kwiki::UserName::Auth');

use_ok('Kwiki::Users::Auth');
require_ok ('Kwiki::Users::Auth');

