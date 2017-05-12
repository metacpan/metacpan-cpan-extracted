BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;

use Test::More ;

BEGIN {
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 3336 + $extra;

};


#use Test::More skip_all => "not implemented yet";

use IO::Compress::Lzf   qw($LzfError) ;
use IO::Uncompress::UnLzf qw($UnLzfError) ;

sub identify
{
    'IO::Compress::Lzf';
}

require "truncate.pl" ;
run();
