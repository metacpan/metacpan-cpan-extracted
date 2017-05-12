use inc::Module::Install;

name           'Method-Alias';
all_from       'lib/Method/Alias.pm';
build_requires 'Test::More' => '0.47';
build_requires 'File::Spec' => '0.82';

WriteAll;
