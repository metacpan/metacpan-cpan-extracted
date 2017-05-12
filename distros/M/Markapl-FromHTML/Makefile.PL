use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Markapl/FromHTML.pm';

requires
    'Rubyish'          => 0.31,
    'HTML::PullParser' => 0;

build_requires
 'Test::More' => '0.42';

WriteAll;


