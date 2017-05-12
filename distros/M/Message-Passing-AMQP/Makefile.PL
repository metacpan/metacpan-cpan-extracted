use strict;
use warnings;
use inc::Module::Install;
use Module::Install::Authority;

all_from 'lib/Message/Passing/AMQP.pm';
authority('cpan:GHENRY');
resources(
    repository => "git://github.com/suretec/Message-Passing-AMQP.git",
);

license 'LGPL_2_1';

requires 'Moose';
requires 'namespace::autoclean';
requires 'AnyEvent';
requires 'AnyEvent::RabbitMQ' => '1.15';
requires 'JSON';
requires 'JSON::XS';
requires 'Try::Tiny';
requires 'Task::Weaken';
requires 'Message::Passing' => '0.009';

test_requires 'Test::More' => '0.88';

author_requires(
    'Test::Pod' => '1.14',
    'Test::NoTabs' => '0',
    'Test::Pod::Coverage' => '1.04',
    'Pod::Coverage' => '0.19',
    'Pod::Coverage::TrustPod' => '0',
    'Test::Spelling' => '0',
);

author_tests 't/author';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Message/Passing/AMQP.pm > README")
        and die $!;
}

WriteAll;

