use inc::Module::Install;
 
name('HTTP-Cookies-Guess');
author('Tatsuhiko Miyagawa, Kazuhiro Osawa <ko@yappo.ne.jp>');
all_from('lib/HTTP/Cookies/Guess.pm');

build_requires(Test::More => 0.42);

auto_include;
auto_install;
WriteAll;
