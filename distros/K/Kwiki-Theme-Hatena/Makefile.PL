use inc::Module::Install;
 
name('Kwiki-Theme-Hatena');
author('Kazuhiro Osawa <ko@yappo.ne.jp>');
license('perl');
all_from('lib/Kwiki/Theme/Hatena.pm');

build_requires(Test::More => 0.42);

auto_include;
auto_install;
WriteAll;


