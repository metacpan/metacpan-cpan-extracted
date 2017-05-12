use inc::Module::Install;
name('Jifty-Plugin-SimpleColor');
all_from('lib/Jifty/Plugin/SimpleColor.pm');
requires('Jifty' => '0.91117');

auto_install();
install_share;
tests('t/*.t t/*/t/*.t');

WriteAll;
