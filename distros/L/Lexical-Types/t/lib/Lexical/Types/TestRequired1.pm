package Lexical::Types::TestRequired1;

my Int $x;
Test::More::is($x, undef, 'pragma not in use in require');

eval q{
 my Int $y;
 Test::More::is($y, undef, 'pragma not in use in eval in require');
};

1;
