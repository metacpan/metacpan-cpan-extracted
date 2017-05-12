use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::Authority;

all_from 'lib/Message/Passing.pm';

license 'LGPL_2_1';
authority('cpan:GHENRY');
resources(
    repository => "git://github.com/suretec/Message-Passing.git",
);

requires 'Moo' => '0.091011';
requires 'Package::Variant' => '1.001001';
requires 'namespace::clean' => '0.23';
requires 'Module::Runtime' => '0.013';
requires 'AnyEvent';
requires 'AnyEvent::Handle::UDP';
requires 'Config::Any';
requires 'MooX::Types::MooseLike' => '0.08';
requires 'MooX::Options' => '3.71';
requires 'String::RewritePrefix';
requires 'JSON::MaybeXS' => '1.002002';
requires 'Try::Tiny';
requires 'Task::Weaken';
requires 'Sys::Hostname::Long';
requires 'DateTime';
requires 'IO::Handle';

recommends 'Linux::IO_Prio' => 0.03;

install_script 'script/message-pass';

author_requires(
    'Test::Pod' => '1.14',
    'Test::NoTabs' => '0',
    'Test::Pod::Coverage' => '1.04',
    'Test::CPAN::Changes' => '0.22',
    'Pod::Coverage' => '0.19',
    'Pod::Coverage::TrustPod' => '0',
    'Test::Spelling' => '0',
    'Compress::Zlib' => '0',
    'Compress::Bzip2' => '0',
    'Crypt::CBC' => '0',
    'Crypt::Blowfish' => '0',
);

author_tests 't/author';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Message/Passing.pm > README")
        and die $!;
}

WriteAll;

