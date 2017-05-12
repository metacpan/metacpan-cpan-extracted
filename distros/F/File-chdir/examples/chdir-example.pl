use strict;
use warnings;
use File::chdir;

mkdir "foo";

$CWD = "foo"; # now in foo/

mkdir "bar";

{
    local $CWD = "bar";  # now in foo/bar/
}

# back to foo
rmdir "bar";

pop @CWD; # now in original directory

rmdir "foo";

