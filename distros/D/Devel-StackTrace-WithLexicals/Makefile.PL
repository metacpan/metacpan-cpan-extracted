use inc::Module::Install;

name     'Devel-StackTrace-WithLexicals';
all_from 'lib/Devel/StackTrace/WithLexicals.pm';
githubmeta;

requires 'Devel::StackTrace' => '2.00';
requires 'PadWalker' => '1.98';

WriteAll;

