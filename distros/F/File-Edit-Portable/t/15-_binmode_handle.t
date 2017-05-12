#!perl
use 5.006;
use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'File::Edit::Portable' ) || print "Bail out!\n";
}

eval { File::Edit::Portable->new->_binmode_handle('xxx'); };

like ($@, qr/_binmode_handle\(\) can't/, "coverage for open bad file");

done_testing();
