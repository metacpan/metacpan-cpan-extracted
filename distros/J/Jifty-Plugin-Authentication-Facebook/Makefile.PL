use inc::Module::Install;
name('Jifty-Plugin-Authentication-Facebook');
all_from('lib/Jifty/Plugin/Authentication/Facebook.pm');

requires('Jifty');
requires('WWW::Facebook::API' => '0.3.6');

auto_install();
tests(qw( t/*.t ));

WriteAll;
