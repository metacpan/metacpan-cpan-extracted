use inc::Module::Install;

name           'Geo-DNA';
all_from       'lib/Geo/DNA.pm';

# Specific dependencies
requires       'common::sense';
requires       'POSIX';
requires       'Math::Trig';
test_requires  'Test::More'  => '0.42';

WriteAll;
