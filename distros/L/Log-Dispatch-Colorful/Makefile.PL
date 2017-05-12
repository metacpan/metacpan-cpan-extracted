use inc::Module::Install;
name 'Log-Dispatch-Colorful';
all_from 'lib/Log/Dispatch/Colorful.pm';

requires 'Log::Dispatch::Output';
requires 'Params::Validate';

tests 't/*.t';

build_requires 'IO::Scalar';
build_requires 'Log::Dispatch';
build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
