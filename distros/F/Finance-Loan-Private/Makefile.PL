use inc::Module::Install;

name     'Finance-Loan-Private';
all_from 'lib/Finance/Loan/Private.pm';
author   q{Raphael Mankin <rapmankin@cpan.org>};
license  'perl';

requires 'Config::General';
requires 'Getopt::Long';
requires 'DateTime';
requires 'DateTime::Format::ISO8601';
build_requires 'Test::More';
install_script 'privateloan.pl';

auto_install;

WriteAll;

