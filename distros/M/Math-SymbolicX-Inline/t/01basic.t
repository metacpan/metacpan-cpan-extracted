
use strict;
use warnings;
#########################

use Test::More tests => 10;
use_ok('Math::SymbolicX::Inline');

#use lib 'lib';
#use Math::SymbolicX::Inline;
#our $Count = 0;
#sub ok {print ++$Count . ($_[0]?" okay":"  bad"); print " => $_[1]\n";}

eval {
    Math::SymbolicX::Inline->import(<<'HERE');
foo = arg0*2
HERE
};
ok( !$@, 'basic example' );
ok( foo(3) == 6, 'basic example outputs correct results' );

eval {
    Math::SymbolicX::Inline->import(<<'HERE');
bar = arg0*foo
HERE
};
ok( !$@, 'external sub example' );
ok( bar(3) == 18, 'external sub example outputs correct results' );

eval {
    Math::SymbolicX::Inline->import(<<'HERE');
baz = arg0*foo
buz = arg1*bar
HERE
};
ok( !$@, 'multiple sub, multiple args example' );
ok( baz( 5, 3 ) == 50,
    'multiple sub, mutliple args example outputs correct results (1)' );
ok( buz( 7, 3 ) == 3 * ( 7 * ( 7 * 2 ) ),
    'multiple sub, mutliple args example outputs correct results (2)' );

eval {
    Math::SymbolicX::Inline->import(<<'HERE');
fool =
foo + bar + baz + buz 
HERE
};
ok( !$@, 'single sub, whitespace, no args, fancy deps example' );
ok( fool( 8, 9 ) == 1424,
    'single sub, whitespace, no args, fancy deps example' );

