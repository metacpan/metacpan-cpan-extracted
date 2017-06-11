use lib '.';
use inc::Module::Install;
all_from 'lib/MarpaX/Repa.pm';
readme_from 'lib/MarpaX/Repa.pm';
requires 'Marpa::R2' => 2.078;
WriteAll;