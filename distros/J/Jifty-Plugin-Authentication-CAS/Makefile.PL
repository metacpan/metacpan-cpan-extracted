use inc::Module::Install;
name('Jifty-Plugin-Authentication-CAS');
all_from('lib/Jifty/Plugin/Authentication/CAS.pm');

requires('Jifty');
requires('Authen::CAS::Client');

auto_install();
tests(qw( t/*.t ));

install_share;

WriteAll;
