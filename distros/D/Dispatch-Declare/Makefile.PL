use inc::Module::Install;

name 'Dispatch-Declare';
all_from 'lib/Dispatch/Declare.pm';
license 'perl';
build_requires 'Test::More' => '0.42';

WriteAll;
