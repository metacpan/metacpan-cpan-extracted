use inc::Module::Install;
name 'JiftyX-Markapl';
all_from 'lib/JiftyX/Markapl.pm';

requires
    Jifty => '0.9',
    Markapl => '0.09';

tests 't/*.t t/*/t/*.t';
author_tests 'xt';

build_requires 'Test::More';

auto_include;
WriteAll;
