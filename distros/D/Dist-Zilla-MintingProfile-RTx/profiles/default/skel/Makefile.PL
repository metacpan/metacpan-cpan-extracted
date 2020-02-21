use lib '.';
use inc::Module::Install;
{{ ($path = $dist->name) =~ s|-|/|g; '' }}
RTx     '{{$dist->name}}';
license 'gpl_2';
repository 'https://github.com/bestpractical/{{lc $dist->name}}';

requires_rt '4.4.0';
rt_too_new '5.2.0';

sign;
WriteAll;
