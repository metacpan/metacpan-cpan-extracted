use inc::Module::Install;
{{ ($path = $dist->name) =~ s|-|/|g; '' }}
RTx     '{{$dist->name}}';
license 'gpl_2';
repository 'https://github.com/bestpractical/{{lc $dist->name}}';

requires_rt '4.2.0';
rt_too_new '4.6.0';

sign;
WriteAll;
