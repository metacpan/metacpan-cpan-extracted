use inc::Module::Install;

name 'LWPx-Record-DataSection';
all_from 'lib/LWPx/Record/DataSection.pm';

requires 'Data::Section::Simple';
requires 'LWP::Protocol';
requires 'HTTP::Response';
requires 'Carp';
requires 'CGI::Simple';
requires 'CGI::Simple::Cookie';
requires 'B::Hooks::EndOfScope';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Requires';

auto_set_repository;
auto_include;

WriteAll;
