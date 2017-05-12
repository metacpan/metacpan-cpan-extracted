use inc::Module::Install;
name 'Email-Send-Test-DataDumper';
all_from 'lib/Email/Send/Test/DataDumper.pm';

# requires '';
requires 'Tie::DataDumper';
requires 'Email::Send';
requires 'Email::Simple';
test_requires 'File::Spec::Functions';
test_requires 'File::Temp';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
