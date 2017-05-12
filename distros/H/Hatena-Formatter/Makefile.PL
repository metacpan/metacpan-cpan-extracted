use inc::Module::Install;
 
name('Hatena-Formatter');
author('Kazuhiro Osawa <ko@yappo.ne.jp>');
all_from('lib/Hatena/Formatter.pm');

requires('Class::Accessor::Fast');
requires('Text::Hatena');
requires('Hatena::Keyword' => 0.04);

build_requires(Test::More => 0.42);

auto_include;
auto_install;
WriteAll;


