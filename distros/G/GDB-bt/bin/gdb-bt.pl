#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

die("$0 /path/to/perlcore\n") unless @ARGV;

my $core_file = $ARGV[0];
my $py_script = $FindBin::Bin . '/gdb-bt.py';
my @args = (qw/gdb --silent -x/, $py_script, qw/-ex get_perl_trace -ex quit perl/, $core_file); 
exec(@args) or die("can't exec gdb :: $!\n");

