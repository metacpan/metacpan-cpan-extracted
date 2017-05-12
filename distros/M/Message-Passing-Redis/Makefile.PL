use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::Authority;

license 'perl';
all_from 'lib/Message/Passing/Redis.pm';
authority('GHENRY');
resources(
    repository => "git://github.com/suretec/Message-Passing-Redis.git",
);

requires 'Message::Passing' => '0.106';
requires 'Redis';
requires 'AnyEvent';
requires 'Moo' => '1.000003';
requires 'MooX::Types::MooseLike' => '0.12';
requires 'namespace::clean';

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
    system("pod2text lib/Message/Passing/Redis.pm > README")
        and die $!;
}

WriteAll;

