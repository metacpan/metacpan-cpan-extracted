use inc::Module::Install;

name           'Jifty-Plugin-RecordHistory';
all_from       'lib/Jifty/Plugin/RecordHistory.pm';

requires('Jifty::DBI' => '0.66');
requires('Jifty' => '1.10214');

build_requires 'Test::More';

tests('t/*/t/*.t');

install_share;
auto_install;
WriteAll;

