use inc::Module::Install;

name            ('Kwiki-Simple-Server-HTTP');
abstract        ('Start a standalone http kwiki server from command line');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/Simple/Server/HTTP.pm');
requires        (Kwiki => '0.37', 'HTTP::Server::Simple::Kwiki' => 0);
build_requires  ('Test::More');

&WriteAll;

