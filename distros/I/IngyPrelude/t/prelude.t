use Test::More;
use strict;
use warnings;

use IngyPrelude;

my $file = 'test.txt';
my $text = "\
Oh Hi,
I like pie.
";

ok not(-e $file),
    "'$file' does not exist";

file_write $file, $text;

ok -e $file,
    "'$file' exists";

my $read = file_read $file;

is $read, $text,
    "file_read text matches file_write text";

unlink $file;

ok not(-e $file),
    "'$file' does not exist";

done_testing;
