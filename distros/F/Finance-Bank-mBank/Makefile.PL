use inc::Module::Install;

name     'Finance-Bank-mBank';
all_from 'lib/Finance/Bank/mBank.pm';
author   'Bartek Jakubski <b.jakubski@gmail.com>';
license  'perl';

build_requires 'Test::More';
requires 'Crypt::SSLeay';
requires 'Web::Scraper';
requires 'WWW::Mechanize';
requires 'Exception::Base';


auto_install;

WriteAll;

