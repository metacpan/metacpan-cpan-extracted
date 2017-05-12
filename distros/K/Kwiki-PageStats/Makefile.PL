use inc::Module::Install;

name('Kwiki-PageStats');
abstract('Keep a count of page display, and display it');
author('Chris Dent <cdent@burningchrome.com>');
version_from('lib/Kwiki/PageStats.pm');
license('perl');

requires('Kwiki' => 0.37, 'Kwiki::Test' => 0.03);

check_nmake();

&WriteAll();
