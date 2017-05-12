use strict;
use warnings;
use inc::Module::Install;
use Module::Install::Authority;

all_from 'lib/Message/Passing/PSGI.pm';

license 'AGPL_3';
authority('GHENRY');
resources(
    repository => "git://github.com/suretec/Message-Passing-PSGI.git",
);

requires 'Plack';
requires 'Message::Passing' => '0.007';
requires 'Message::Passing::ZeroMQ' => '0.005';
requires 'AnyEvent';
requires 'Moose';
requires 'JSON' => '2.00';
requires 'Try::Tiny';
requires 'namespace::autoclean';

author_requires(
    'Test::Pod' => '1.14',
    'Test::NoTabs' => '0',
    'Test::Pod::Coverage' => '1.04',
    'Pod::Coverage' => '0.19',
    'Pod::Coverage::TrustPod' => '0',
    'Test::Spelling' => '0',
);

author_tests 't/author';

install_script 'script/message-passing_psgi_app.psgi';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Message/Passing/PSGI.pm > README")
        and die $!;
}

WriteAll;

