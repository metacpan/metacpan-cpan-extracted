#!/usr/bin/perl

use strict;
use warnings;

use File::fgets;
use File::Temp qw(tempfile);
use Test::More;

my($wfh, $file) = tempfile();
print $wfh <<END;
0
01
0123456789
012
0123
01234
012345

The above and below lines left blank

END
close $wfh;

ok open(my($fh), $file), "open temp file";

is fgets($fh, 5), "0\n", "basic fgets";
is fgets($fh, 0), "",    "fgets 0 length";

my @lines;
while( my $line = fgets($fh, 5) ) { push @lines, $line }

is_deeply(\@lines, [
    "01\n",
    "01234",
    "56789",
    "\n",
    "012\n",
    "0123\n",
    "01234",
    "\n",
    "01234",
    "5\n",
    "\n",
    "The a",
    "bove ",
    "and b",
    "elow ",
    "lines",
    " left",
    " blan",
    "k\n",
    "\n",
]);


ok !eval { fgets();    1; } and note $@;
ok !eval { fgets($fh); 1; } and note $@;
ok !eval {
    open $fh, "<", "dalfjalkjflkjd";
    local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /\Qtell() on closed filehandle/ };
    fgets($fh, 0);
    1;
} and note $@;

done_testing;
