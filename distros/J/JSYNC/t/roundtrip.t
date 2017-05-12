use lib (-e 't' ? 't' : 'test'), 'inc';

use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/roundtrip.tml',
    bridge => 'TestMLBridge',
)->run;
