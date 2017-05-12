use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::Authority;

all_from 'lib/Message/Passing/ZeroMQ.pm';

license 'AGPL_3';
authority('cpan:GHENRY');
resources(
    repository => "git://github.com/suretec/Message-Passing-ZeroMQ.git",
);

requires 'Moo' => '0.091011';
requires 'namespace::clean';
requires 'AnyEvent';
requires 'ZMQ::FFI';
requires 'Try::Tiny';
requires 'Task::Weaken';
requires 'Message::Passing' => '0.011';
requires 'POSIX::AtFork' => '0.02';
requires 'Sub::Name';
requires 'File::pushd';
requires 'MooX::Types::MooseLike';

test_requires 'Test::More' => '0.88';

author_requires(
    'Test::Pod' => '1.14',
    'Test::NoTabs' => '0',
    'Test::Pod::Coverage' => '1.04',
    'Pod::Coverage' => '0.19',
    'Pod::Coverage::Moose' => '0',
    'Test::Spelling' => '0',
);

author_tests 't/author';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Message/Passing/ZeroMQ.pm > README")
        and die $!;
}

WriteAll;

