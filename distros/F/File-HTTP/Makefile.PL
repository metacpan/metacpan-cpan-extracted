use inc::Module::Install;

name            'File-HTTP';
all_from        'lib/File/HTTP.pm';

build_requires  'Test::More'    => '0.42';

requires 'constant'     => '1.03';

recommends 'IO::Socket::SSL'    => 0;
recommends 'Time::y2038'        => 0;

WriteAll;

