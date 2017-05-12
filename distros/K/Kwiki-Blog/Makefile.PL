use inc::Module::Install;

name('Kwiki-Blog');
author('Chris Dent <cdent@burningchrome.com>');
abstract('Sort of Blogging for Kwiki');
license('perl');
version_from('lib/Kwiki/Blog.pm');

requires(
    Kwiki => 0.38,
    Kwiki::Keywords => 0,
);

check_nmake();

&WriteAll();
