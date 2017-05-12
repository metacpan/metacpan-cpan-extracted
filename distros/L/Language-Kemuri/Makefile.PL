use inc::Module::Install;

name            'Language-Kemuri';
all_from        'lib/Language/Kemuri.pm';

author_tests 'xt';
test_requires 'Test::Base';
WriteAll;

