use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'IPC-Lock-RabbitMQ';
all_from 'lib/IPC/Lock/RabbitMQ.pm';

requires 'Devel::GlobalDestruction';
requires 'Net::RabbitFoot';
requires 'Moose';
requires 'namespace::autoclean';

build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'git://somewhere.com/myproject.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/IPC/Lock/RabbitMQ.pm > README")
        and die $!;
}

WriteAll();
