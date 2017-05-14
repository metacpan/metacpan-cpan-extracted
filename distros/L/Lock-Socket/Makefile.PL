use inc::Module::Install;

name 'Lock-Socket';
author 'Mark Lawrence <nomad@null.net>';
version '0.0.6';
license 'gpl3';

homepage 'https://github.com/mlawren/p5-Lock-Socket';
bugtracker 'https://github.com/mlawren/p5-Lock-Socket/issues';
repository 'git://github.com/mlawren/p5-Lock-Socket.git';

perl_version 5.006;

requires 'Socket' => 0;
requires 'Carp'   => 0;

test_requires 'Test::Fatal' => 0;
test_requires 'Test::More'  => 0;

#devel_requires 'Module::Install' => 0;
#devel_requires 'App::githook_perltidy' => 0;
#devel_requires 'Mo' => 0;
#devel_requires 'IO::All' => 0; # for mo-inline

tests_recursive 't';

no_index package => 'Lock::Socket::Error';
no_index package => 'Lock::Socket::Mo';

WriteAll;
