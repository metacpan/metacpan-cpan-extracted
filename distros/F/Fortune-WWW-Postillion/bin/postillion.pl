#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use Fortune::WWW::Postillion;
say Fortune::WWW::Postillion::cookie($ARGV[0]);


