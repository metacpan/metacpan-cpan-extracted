# ABSTRACT: Easily write or append to a file in one go

use strict;
use warnings;
use File::Util;

my $ftl  = File::Util->new();

my $file = 'example.txt';

# writing content to the file, creating it if it doesn't exist
$ftl->write_file( file => $file, content => 'Hello World!' );

# you optionally specify a bitmask for a file if it doesn't exist yet.
# the bitmask is combined with the user's current umask for the creation
# mode of the file.  (You should usually omit this.)
$ftl->write_file(
   file    => 'new.txt',
   bitmask => oct 777,
   content => 'Hello World!'
);

# append to the file you just created
$ftl->write_file(
   file    => 'new.txt',
   content => 'Goodbye cruel world',
   mode    => 'append'
);

exit;
