#!perl
use warnings;
use strict;

use Test::More tests => 3;
use Data::Dumper;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

{
    my $p = {
        post_proc => 'file_lines_contain',
        file => 't/sample.data',
        engine => 'all',
    };
    my $des = Devel::Examine::Subs->new();
    
    my $res = $des->run($p);
   
    ok (@$res == 11, "file_lines_contain post_proc loads properly");
    ok (ref $res eq 'ARRAY', "proper return when using a post_proc"); 

}
