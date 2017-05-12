use strict;
use Test;
use File::Copy;

plan(tests => 15);

my $orig  = './tests/';
my $local = './t/';

foreach (qw( 01basics 02write 03nowrite 04create 05seek 06backup 07hash )) {
	ok(unlink("$local$_.t") or not -f "$local$_.t");
	ok(copy("$orig$_.t", "$local$_.t"));
}

ok(chmod 0444, "$local/03nowrite.t");
