use inc::Module::Install;

name('Kwiki-Yahoo');
abstract('Access Yahoo API with with WAFL');
author('Chris Dent <cdent@burningchrome.com>');
version_from('lib/Kwiki/Yahoo.pm');
license('perl');

requires('Kwiki' => 0, 'Yahoo::Search' => 0);

check_nmake();

&WriteAll();
