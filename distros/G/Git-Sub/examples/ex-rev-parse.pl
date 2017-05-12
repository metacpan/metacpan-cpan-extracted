#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Git::Sub;

say scalar git::rev_parse 'master';
