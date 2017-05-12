BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;

use IO::Uncompress::AnyUncompress qw($AnyUncompressError) ;

use IO::Compress::Xz     qw($XzError) ;
use IO::Uncompress::UnXz qw($UnXzError) ;

sub getClass
{
    'AnyUncompress';
}


sub identify
{
    'IO::Compress::Xz';
}

require "any.pl" ;
run();
