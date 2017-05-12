use inc::Module::Install;

name 'Games-Alak';
all_from 'lib/Games/Alak.pm';

requires('Term::ReadLine');

build_requires('Test::Pod' => 1.26);
build_requires('Test::Pod::Coverage' => 1.08);
build_requires('Pod::Coverage' => 0.18);

auto_install;
WriteAll;
