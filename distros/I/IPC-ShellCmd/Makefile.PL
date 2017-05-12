use inc::Module::Install 0.91;
use Module::Install::ReadmeFromPod;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::AssertOS;

assertos qw/ Unix /;

all_from 'lib/IPC/ShellCmd.pm';
readme_from 'lib/IPC/ShellCmd.pm';

requires_external_bin 'ssh';
requires_external_bin 'sudo';

requires 'IO::Pipe';
requires 'Scalar::Util';
requires 'String::ShellQuote';

test_requires 'Test::More' => '0.88';

author_requires 'Test::NoTabs';
author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';

author_tests 't/author';

resources repository => 'http://goatse.co.uk/~bobtfish/IPC-ShellCmd/.git';

WriteAll;
