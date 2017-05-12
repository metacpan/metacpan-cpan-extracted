use inc::Module::Install;

all_from    'lib/MasonX/LeakGuard/Object.pm';
readme_from 'lib/MasonX/LeakGuard/Object.pm';

requires 'HTML::Mason::Plugin';
requires 'Devel::LeakGuard::Object';
requires 'Data::Dumper';

WriteAll;
