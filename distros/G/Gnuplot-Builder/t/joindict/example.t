use strict;
use warnings FATAL => "all";
use Test::More;

use Gnuplot::Builder::JoinDict;
    
my $dict = Gnuplot::Builder::JoinDict->new(
    separator => ', ',
    content => [x => 640, y => 480]
);
is "$dict", '640, 480';
    
is $dict->get("x"), 640;
is $dict->get("y"), 480;
    
my $dict2 = $dict->set(y => 16);
is "$dict", '640, 480';
is "$dict2", '640, 16';
    
my $dict3 = $dict2->set(x => 8, z => 32);
is "$dict3", '8, 16, 32';
    
my $dict4 = $dict3->delete("x", "y");
is "$dict4", '32';

done_testing;
