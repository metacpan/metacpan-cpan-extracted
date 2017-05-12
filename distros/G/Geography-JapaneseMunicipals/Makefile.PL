use inc::Module::Install;
name 'Geography-JapaneseMunicipals';
all_from 'lib/Geography/JapaneseMunicipals.pm';

requires 'Encode';
requires 'Geography::JapanesePrefectures';

tests 't/*.t';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
