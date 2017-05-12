use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/JavaScript/Writer.pm';

build_requires
    'JE' => '0.021',
    'Test::More' => '0.42',
    'Test::Class' => '0';

requires
    'self'       => '0.32',
    'JSON::Syck' => '0',
    'Class::Accessor::Fast' => '0';

repository 'http://github.com/gugod/javascript-writer';

tests 't/*.t';
author_tests 'xt';

WriteAll;

