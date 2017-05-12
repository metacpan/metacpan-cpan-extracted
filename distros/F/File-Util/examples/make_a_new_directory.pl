# ABSTRACT: Make a new directory, even if the parent directory doesn't exist

use strict;
use warnings;
use File::Util;

my $ftl = File::Util->new();

$ftl->make_dir( '/tmp/myapp_tempfiles' );

# optionally specify a creation bitmask to be used in directory creations.
# the bitmask is combined with the user's current umask for the creation
# mode of the file.  (You should usually omit this.)
$ftl->make_dir( '/tmp/a/b/c/foo/bar', oct 755 );

exit;
