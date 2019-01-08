BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;

use IO::Compress::Lzip     qw($LzipError) ;
use IO::Uncompress::UnLzip qw($UnLzipError) ;

sub identify
{
    'IO::Compress::Lzip';
}

require "encode.pl" ;
run();
