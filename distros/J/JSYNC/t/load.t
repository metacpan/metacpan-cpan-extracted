use lib (-e 't' ? 't' : 'test'), 'inc';

{
    use Test::More;
    eval "use YAML::XS; 1" or plan skip_all => 'YAML::XS required';
}

use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/load.tml',
    bridge => 'TestMLBridge',
)->run;
