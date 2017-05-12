use inc::Module::Install;
use Module::Install::AuthorTests;

name 'IO-Prompt-Simple';
all_from 'lib/IO/Prompt/Simple.pm';

requires 'Encode';
requires 'Scalar::Util';

test_requires 'Test::More', 0.98;
test_requires 'Test::Requires', 0.06;

tests join q{ }, map { sprintf 't%s.t', '/*' x $_ } 1..3;
author_tests 'xt';

repository 'http://github.com/xaicron/p5-IO-Prompt-Simple/';
bugtracker 'http://github.com/xaicron/p5-IO-Prompt-Simple/issues';

WriteAll;
