use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::Authority;

all_from 'lib/Message/Passing/Syslog.pm';

license 'perl';
authority('cpan:GHENRY');
resources(
    repository => "git://github.com/suretec/Message-Passing-Syslog.git",
);

requires 'Moo';
requires 'namespace::clean';
requires 'AnyEvent';
requires 'JSON';
requires 'Try::Tiny';
requires 'Task::Weaken';
requires 'Message::Passing' => '0.104';
requires 'Sys::Hostname::Long';
requires 'Time::ParseDate';
requires 'Parse::Syslog::Line' => 1.2;
requires 'Socket' => 2.008;

test_requires 'Test::More' => '0.88';

author_requires(
    'Test::Pod' => '1.14',
    'Test::NoTabs' => '0',
    'Test::Pod::Coverage' => '1.04',
    'Pod::Coverage' => '0.19',
    'Pod::Coverage::TrustPod' => '0',
    'Test::Spelling' => '0',
    'Net::Syslog' => '0',
);

author_tests 't/author';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Message/Passing/Syslog.pm > README")
        and die $!;
}

WriteAll;

