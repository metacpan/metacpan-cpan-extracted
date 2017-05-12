use inc::Module::Install;

name 'JavaScript-Sprockets';
all_from 'lib/JavaScript/Sprockets.pm';
requires 'File::Which' => 0;
requires 'Any::Moose' => 0;
requires 'IPC::Open3' => 0;
requires 'List::MoreUtils' => 0;

test_requires 'Test::More' => 0;

requires_external_bin 'sprocketize';

WriteAll;
