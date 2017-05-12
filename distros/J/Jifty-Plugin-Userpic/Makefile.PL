use inc::Module::Install;
name('Jifty-Plugin-Userpic');
all_from('lib/Jifty/Plugin/Userpic.pm');

requires('Jifty');

auto_install();
tests(qw( t/*.t ));

WriteAll;
