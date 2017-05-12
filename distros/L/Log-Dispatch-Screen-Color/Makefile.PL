use inc::Module::Install;
name 'Log-Dispatch-Screen-Color';
all_from 'lib/Log/Dispatch/Screen/Color.pm';

requires 'Log::Dispatch';
requires 'Term::ANSIColor';
requires 'Params::Validate';
requires 'Win32::Console::ANSI' if $^O eq 'MSWin32';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'IO::Scalar';
use_test_base;
auto_include;
auto_set_repository;
WriteAll;
