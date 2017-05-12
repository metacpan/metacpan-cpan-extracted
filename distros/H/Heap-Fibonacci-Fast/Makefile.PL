use strict;
use inc::Module::Install;

perl_version '5.005';
name 'Heap-Fibonacci-Fast';

abstract_from 'lib/Heap/Fibonacci/Fast.pod';
author 'Sergey Aleynikov <sergey.aleynikov@gmail.com>';
version_from 'lib/Heap/Fibonacci/Fast.pm';
license 'bsd';

test_requires 'List::Util';
test_requires 'Test::More';
test_requires 'Test::Exception';

requires 'XSLoader';

system 'pod2text lib/Heap/Fibonacci/Fast.pod > README';

makemaker_args(
#	OPTIMIZE	=> '-Winline -O2 -march=prescott -fomit-frame-pointer',
#       OPTIMIZE        => '-g -ggdb',
);

WriteAll();