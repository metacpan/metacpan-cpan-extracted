use inc::Module::Install;
 
name 'Lingua-JA-Summarize-Extract';
all_from 'lib/Lingua/JA/Summarize/Extract.pm';

build_requires 'Test::More';

requires $_ for (qw/Class::Accessor::Fast UNIVERSAL::require/);

auto_include;
auto_install;
WriteAll;
