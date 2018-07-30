use lib (-e 't' ? 't' : 'test'), 'inc';
use TestML1;
use TestMLBridge;

TestML1->new(
    testml => 'testml/load.tml',
    bridge => 'TestMLBridge',
)->run;
