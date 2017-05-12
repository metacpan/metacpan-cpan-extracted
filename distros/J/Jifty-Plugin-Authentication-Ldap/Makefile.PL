use inc::Module::Install;
name('Jifty-Plugin-Authentication-Ldap');
all_from('lib/Jifty/Plugin/Authentication/Ldap.pm');

requires('Jifty');
requires('Net::LDAP');

auto_install();
tests(qw( t/*.t ));

install_share;

WriteAll;
