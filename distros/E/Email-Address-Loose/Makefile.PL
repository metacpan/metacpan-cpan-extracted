use inc::Module::Install;
name 'Email-Address-Loose';
all_from 'lib/Email/Address/Loose.pm';
readme_from;

requires 'Email::Address' => 1.889;

build_requires 'Email::Address';
auto_include;

tests_recursive;

repository 'http://github.com/tomi-ru/Email-Address-Loose';
bugtracker 'http://github.com/tomi-ru/Email-Address-Loose/issues';

WriteAll;
