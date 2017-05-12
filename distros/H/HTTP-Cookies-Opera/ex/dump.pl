#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use HTTP::Cookies::Opera;

my $file = shift or die "Usage: $0 cookies_file";

my $jar = HTTP::Cookies::Opera->new(file => $file);

local $Data::Dumper::Indent = 1;
local $Data::Dumper::Terse  = 1;
print Dumper($jar);
