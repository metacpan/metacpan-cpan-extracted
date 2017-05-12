BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;

use IO::Compress::Lzf     qw($LzfError) ;
use IO::Uncompress::UnLzf qw($UnLzfError) ;

sub identify
{
    'IO::Compress::Lzf';
}

require "newtied.pl" ;
run();
