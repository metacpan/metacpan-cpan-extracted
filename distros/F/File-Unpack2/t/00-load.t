#!perl -T

use Test::More tests => 1;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };

BEGIN {
    use_ok( 'File::Unpack2' ) || print "Bail out!
";
}

diag( "Testing File::Unpack2 $File::Unpack2::VERSION, Perl $], $^X" );
