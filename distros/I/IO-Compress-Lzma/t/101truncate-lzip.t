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

    plan tests => 3700 + $extra;

};


#use Test::More skip_all => "not implemented yet";


use IO::Compress::Lzip   qw($LzipError) ;
use IO::Uncompress::UnLzip qw($UnLzipError) ;

sub identify
{
    'IO::Compress::Lzip';
}

require "truncate.pl" ;
run();
