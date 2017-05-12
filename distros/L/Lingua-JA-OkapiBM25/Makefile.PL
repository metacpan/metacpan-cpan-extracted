use inc::Module::Install;
name 'Lingua-JA-OkapiBM25';
all_from 'lib/Lingua/JA/OkapiBM25.pm';
requires 'Lingua::JA::TFIDF';
build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
