use inc::Module::Install;

name ('HTTP-Server-Simple-Recorder');
author ('David Glasser <glasser@bestpractical.com>');
version_from ('lib/HTTP/Server/Simple/Recorder.pm');
abstract_from('lib/HTTP/Server/Simple/Recorder.pm');
license('perl');
requires('Test::More');
requires('Test::HTTP::Server::Simple' => '0.02');
requires('IO::Tee');
requires('HTTP::Server::Simple' => '0.10');

&WriteAll;
