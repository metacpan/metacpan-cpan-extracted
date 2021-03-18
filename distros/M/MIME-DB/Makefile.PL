use lib '.';
use inc::Module::Install;
name 'MIME-DB';
author 'Thomas Drugeon, <tdrugeon@cpan.org>';
license 'MIT';
perl_version '5.006'; # because of inc::Module::Install
all_from 'lib/MIME/DB.pm';
no_index directory => 'tools';
build_requires 'Test::More' => '0.42';
WriteAll;