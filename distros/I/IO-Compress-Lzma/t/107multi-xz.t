BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;

use IO::Compress::Xz     qw($XzError) ;
use IO::Uncompress::UnXz qw($UnXzError) ;

sub identify
{
    'IO::Compress::Xz';
}

require "multi.pl" ;
run();
