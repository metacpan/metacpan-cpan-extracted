BEGIN { push @INC, '.' }
use inc::Module::Install;

name ('MasonX-Profiler');
all_from ('lib/MasonX/Profiler.pm');
readme_from ('lib/MasonX/Profiler.pm');
requires ('HTML::Mason', 0);
requires ('Time::HiRes', 0);
license ('perl');

sign;
WriteAll();
