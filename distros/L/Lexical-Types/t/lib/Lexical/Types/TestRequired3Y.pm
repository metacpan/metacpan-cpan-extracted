package Lexical::Types::TestRequired3Y;

my Int3Y $y;
Test::More::is($y, undef, 'pragma not in use in require after double setup');

1;
