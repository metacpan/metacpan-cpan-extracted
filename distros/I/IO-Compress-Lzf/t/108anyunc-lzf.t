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

use IO::Compress::Lzf     qw($LzfError) ;
use IO::Uncompress::UnLzf qw($UnLzfError) ;

sub getClass
{
    'AnyUncompress';
}


sub identify
{
    'IO::Compress::Lzf';
}

require "any.pl" ;
run();
