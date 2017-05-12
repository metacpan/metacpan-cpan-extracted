use inc::Module::Install;

name     'MasonX-Resolver-Multiplex';
all_from 'lib/MasonX/Resolver/Multiplex.pm';
author   'Hans Dieter Pearcey <hdp@pobox.com>';

build_requires 'Test::More';

requires 'Moose'       => 0;
requires 'HTML::Mason' => '1.30'; # a guess, based on most recent major change

WriteAll;

