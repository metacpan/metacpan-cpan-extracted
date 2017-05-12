use inc::Module::Install;

name 'Lingua-JA-Alphabet-Yomi';
all_from 'lib/Lingua/JA/Alphabet/Yomi.pm';

requires 'Unicode::Japanese';

test_requires 'Test::More';
test_requires 'Test::Exception';

auto_include;

WriteAll;
