use inc::Module::Install;
 
name('Kwiki-HatenaAuth');
author('Kazuhiro Osawa <ko@yappo.ne.jp>');
license('perl');
all_from('lib/Kwiki/HatenaAuth.pm');

requires('Hatena::API::Auth' => 0.03);
requires('URI::Escape');
requires('Kwiki::UserName');

build_requires(Test::More => 0.42);

auto_include;
auto_install;
WriteAll;


