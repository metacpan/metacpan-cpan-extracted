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
use CompTestUtils;

BEGIN {
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 7 + $extra ;

    use_ok('IO::Compress::Lzf', qw(:all)) ;
    use_ok('IO::Uncompress::UnLzf', qw(:all)) ;

}

{
    title "Check that MultiStream isn't allowed";

    my $UncompressClass = 'IO::Uncompress::UnLzf' ;

    my $a ;
    my $b ;
    eval qq[\$a = new $UncompressClass("anc", MultiStream => 1) ;] ;
    like $@, mkEvalErr("^$UncompressClass: MultiStream not supported by Lzf"), 
      "$UncompressClass with Multstream caught";
    ok ! $a, "lzf failed";

    eval {$a = unlzf(\"anc" => \$b , MultiStream => 1) };
    like $UnLzfError, "/^${UncompressClass}::unlzf: MultiStream not supported by Lzf/",
      "unlzf with Multstream caught";
    ok ! $a, "unlzf failed";
}
