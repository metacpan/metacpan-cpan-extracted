use inc::Module::Install;

name('HTTP-Server-Simple-Mason');
version_from('lib/HTTP/Server/Simple/Mason.pm');
author('Jesse Vincent <jesse@bestpractical.com>');
license('perl');
abstract('A simple mason server');
requires(
    'HTTP::Server::Simple' => 0.04,
    'HTML::Mason'          => 1.25,
    'Hook::LexWrap'        => 0,
);

&WriteAll;
