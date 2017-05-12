# ABSTRACT: Get an open file handle for reading or writing

use strict;
use warnings;
use File::Util;

my $ftl  = File::Util->new();

my $file = 'example.txt'; # in this example, this file must already exist

# open the file for writing
my $fh = $ftl->open_handle( file => $file );

print $fh 'Hello World!';

close $fh; # <-- the file won't be unlocked in this process unless we close it

# open the file for reading now
$fh = $ftl->open_handle( file => $file, mode => 'read' );

while ( <$fh> ) {

   print;
}

close $fh;

exit;
