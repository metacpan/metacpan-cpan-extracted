use inc::Module::Install;
name('Jifty-Plugin-GoogleMap');
all_from('lib/Jifty/Plugin/GoogleMap.pm');

requires('Jifty');

auto_install();
tests(qw( t/*.t ));

install_share;

WriteAll;
