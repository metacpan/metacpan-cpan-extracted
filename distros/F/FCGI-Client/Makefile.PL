use inc::Module::Install;
name 'FCGI-Client';
all_from 'lib/FCGI/Client.pm';

requires 'IO::Socket::UNIX';
requires 'Any::Moose' => 0.13;

author_requires 'FCGI';

tests 't/*.t';
recursive_author_tests 'xt';

build_requires 'Test::More';
WriteAll;
