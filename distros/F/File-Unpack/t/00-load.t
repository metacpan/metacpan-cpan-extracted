#!perl -T

use Test::More tests => 1;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };

BEGIN {
    use_ok( 'File::Unpack' ) || print "Bail out!
";
}

diag( "Testing File::Unpack $File::Unpack::VERSION, Perl $], $^X" );
