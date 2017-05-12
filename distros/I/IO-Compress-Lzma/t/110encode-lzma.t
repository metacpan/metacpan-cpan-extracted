BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;

use IO::Compress::Lzma     qw($LzmaError) ;
use IO::Uncompress::UnLzma qw($UnLzmaError) ;

sub identify
{
    'IO::Compress::Lzma';
}

require "encode.pl" ;
run();
