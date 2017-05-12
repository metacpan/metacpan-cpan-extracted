use inc::Module::Install;
name 'Encode-JP-Mobile-UnicodeEmoji';
all_from 'lib/Encode/JP/Mobile/UnicodeEmoji.pm';

requires 'Encode::JP::Mobile';
requires 'Encode::JP::Emoji';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
