use inc::Module::Install;

name        'Document-Tools';
all_from    'lib/Document/Tools.pm';

requires    perl => '5.6.1';
perldoc;

WriteAll;
