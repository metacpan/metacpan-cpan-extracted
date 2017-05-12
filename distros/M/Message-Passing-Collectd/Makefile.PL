use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::Authority;

all_from 'lib/Message/Passing/Collectd.pm';

license 'perl';
authority 'GHENRY';

requires 'Message::Passing';
requires 'JSON';
requires 'Try::Tiny';
requires 'String::RewritePrefix';
requires 'Module::Runtime';
requires 'namespace::clean';
test_requires 'Test::More' => '0.88';

author_requires 'Test::Pod' => '1.14';
author_requires 'Test::NoTabs';
author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Pod::Coverage' => '0.19';
author_requires 'Pod::Coverage::TrustPod';
author_requires 'Test::Spelling';

author_tests 't/author';

resources(
    repository => 'git://github.com/suretec/Message-Passing-Collectd.git',
);

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Message/Passing/Collectd.pm > README")
        and die $!;
}

WriteAll;

