use inc::Module::Install;

name 'Games-Worms';
all_from 'lib/Games/Worms.pm';

recommends 'Tk';

build_requires('Test::Pod' => 1.26);
build_requires('Test::Pod::Coverage' => 1.08);
build_requires('Pod::Coverage' => 0.18);

prompt_script 'worms';
auto_install;
WriteAll;
