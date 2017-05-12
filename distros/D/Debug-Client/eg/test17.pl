#!/usr/bin/perl

use 5.010;
use strict;
use warnings FATAL => 'all';

# Turn on $OUTPUT_AUTOFLUSH
local $| = 1;

use FindBin qw($Bin);
use lib map "$Bin/$_", 'lib', '../lib';

#Top
use t::lib::Debugger;

start_script('t/eg/02-sub.pl');
my $debugger;
$debugger = start_debugger();
my $out = $debugger->get;
say '$out ' . $out;

# (?<![->|_])(?<ver>version)

$out =~ m/(?<=[version])\s*(?<ver>1.\d{2})/m;
my $perl5db_ver = $+{ver};
say '$perl5db_ver ' . $perl5db_ver;


1;

__END__
