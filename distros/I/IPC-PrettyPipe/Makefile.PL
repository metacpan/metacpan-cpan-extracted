use inc::Module::Install;

name 'IPC-PrettyPipe';

license 'gpl3';
author 'Diab Jerius';

repository 'http://bitbucket.org/djerius/ipc-prettypipe';
bugtracker 'https://rt.cpan.org/Public/Dist/Display.html?Name=IPC-PrettyPipe';

all_from 'lib/IPC/PrettyPipe.pm';

tests_recursive;

cpanfile;

WriteAll;
