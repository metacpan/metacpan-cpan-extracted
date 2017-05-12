use inc::Module::Install;

name     'Hash-Diff';
all_from 'lib/Hash/Diff.pm';
author   'Bjorn-Olav Strand <bo@startsiden.no>';
license  'perl';

build_requires 'Test::More';

requires 'Hash::Merge';
requires 'ok';

repository 'https://github.com/bolav/hash-diff';

auto_install;

WriteAll;

