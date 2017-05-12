use inc::Module::Install;
 
name('Kwiki-Formatter-Hatena');
author('Kazuhiro Osawa <ko@yappo.ne.jp>');
license('perl');
all_from('lib/Kwiki/Formatter/Hatena.pm');

requires('Cache::File');
requires('Hatena::Formatter');
requires('URI::Escape');

build_requires(Test::More => 0.42);

auto_include;
auto_install;
WriteAll;


