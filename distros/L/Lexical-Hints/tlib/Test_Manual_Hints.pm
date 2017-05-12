package Test_Manual_Hints;

use 5.010; use warnings;
use Lexical::Hints;

# Initialize module's hints...
sub import {
    $^H{'Test_Manual_Hints'} = 1;
}

1;
