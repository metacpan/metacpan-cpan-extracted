use inc::Module::Install;

name     'Memory-Usage';
all_from 'lib/Memory/Usage.pm';
author   q{Dave O'Neill <dmo@roaringpenguin.com>};
license  'perl';

test_requires 'Test::More';

install_script 'script/module-size';

WriteAll;

