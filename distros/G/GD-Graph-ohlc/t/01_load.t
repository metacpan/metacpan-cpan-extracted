
use Test;

plan tests => 4;

ok( eval "use GD::Graph::ohlc; 1" );
ok( grep {m/::ohlc/} @GD::Graph::mixed::ISA );

ok( eval "use GD::Graph::candlesticks; 1" );
ok( grep {m/::candlesticks/} @GD::Graph::mixed::ISA );
