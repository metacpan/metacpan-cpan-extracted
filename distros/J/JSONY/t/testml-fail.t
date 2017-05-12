use lib (-e 't' ? 't' : 'test'), 'inc';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/fail.tml',
    bridge => 'TestMLBridge',
)->run;
