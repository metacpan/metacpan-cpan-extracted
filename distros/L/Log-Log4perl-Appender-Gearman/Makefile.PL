sub readme_from {}; sub auto_include_deps {}; sub author_tests {}; sub auto_set_repository {};
use inc::Module::Install;
name 'Log-Log4perl-Appender-Gearman';
all_from 'lib/Log/Log4perl/Appender/Gearman.pm',
readme_from 'lib/Log/Log4perl/Appender/Gearman.pm',
build_requires 'Test::More';
requires 'Gearman::Client';
requires 'Log::Log4perl';
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
