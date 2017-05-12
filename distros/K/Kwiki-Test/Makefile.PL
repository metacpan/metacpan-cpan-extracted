use inc::Module::Install;

name('Kwiki-Test');
abstract('An alpha sort of test harness for Kwiki Plugins');
author('Chris Dent <cdent@burningchrome.com>');
version_from('lib/Kwiki/Test.pm');
license('perl');

requires('Kwiki' => 0.37);

check_nmake();

&WriteAll();
