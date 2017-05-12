use inc::Module::Install;
name 'HTTP-Server-Simple-Bonjour';
all_from 'lib/HTTP/Server/Simple/Bonjour.pm';
requires 'NEXT';
requires 'HTTP::Server::Simple';
requires 'Net::Rendezvous::Publish';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
