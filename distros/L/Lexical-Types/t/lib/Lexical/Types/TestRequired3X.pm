package Lexical::Types::TestRequired3X;

use Lexical::Types as => \&main::cb3;

my Int3X $x;
Test::More::is($x, __FILE__.':'.(__LINE__-1),
                                            'pragma in use after double setup');

1;
