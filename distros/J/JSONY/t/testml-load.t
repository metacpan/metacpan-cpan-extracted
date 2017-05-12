use lib (-e 't' ? 't' : 'test'), 'inc';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/load.tml',
    bridge => 'TestMLBridge',
)->run;
