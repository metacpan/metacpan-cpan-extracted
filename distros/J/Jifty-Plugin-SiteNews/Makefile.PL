use inc::Module::Install;
name('Jifty-Plugin-SiteNews');
all_from('lib/Jifty/Plugin/SiteNews.pm');

requires('Jifty');

auto_install();
tests(qw( t/*.t ));

WriteAll;
