use inc::Module::Install;

name     'FCGI-ProcManager-MaxRequests';
all_from 'lib/FCGI/ProcManager/MaxRequests.pm';
author   'Vladimir Timofeev <vovkasm@gmail.com>';
license  'perl';

build_requires 'Test::More';

requires 'FCGI::ProcManager';

WriteAll;

