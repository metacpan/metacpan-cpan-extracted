use inc::Module::Install;
name 'Git-Release';
all_from 'lib/Git/Release.pm';

requires 'Git';
requires 'Moose';
requires 'File::Path';
requires 'File::Spec';
requires 'File::Basename';
requires 'Net::Redmine';
requires 'Getopt::Long';
requires 'Term::ANSIColor';

tests 't/*.t';
# author_tests 'xt';
# test_requires 'Test::More';
auto_set_repository;

install_script $_ for <bin/*>;

auto_include;
WriteAll;
