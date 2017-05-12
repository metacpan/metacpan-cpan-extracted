use lib (-e 't' ? 't' : 'test'), 'inc';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/json.tml',
    bridge => 'TestMLBridge',
)->run;
