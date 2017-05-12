use inc::Module::Install;

name('Kwiki-Raw');
abstract('Action to retrieve the wiki text of a page');
author('Chris Dent <cdent@burningchrome.com>');
version_from('lib/Kwiki/Raw.pm');
license('perl');

requires('Kwiki' => 0.37);

check_nmake();

&WriteAll();
