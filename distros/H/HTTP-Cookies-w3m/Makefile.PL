use inc::Module::Install;
 
name('HTTP-Cookies-w3m');
author('Kazuhiro Osawa <ko@yappo.ne.jp>');
all_from('lib/HTTP/Cookies/w3m.pm');

build_requires(Test::More => 0.42);

auto_include;
auto_install;
WriteAll;


