use ExtUtils::MakeMaker;

use strict;
require 5.008002;
WriteMakefile(
    NAME            => 'Lingua::RU::Sklon',
    VERSION_FROM    => 'lib/Lingua/RU/Sklon.pm',
    'LIBS'	=> [''],   # e.g., '-lm' 
    'INC'	=> '',     # e.g., '-I/usr/include/other',
    'NO_META'   => 1,
); 