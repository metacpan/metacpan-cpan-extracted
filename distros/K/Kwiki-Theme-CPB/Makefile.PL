use inc::Module::Install;

name('Kwiki-Theme-CPB');
abstract('Simple three column theme');
author('Chris Dent <cdent@burningchrome.com>');
version_from('lib/Kwiki/Theme/CPB.pm');
license('perl');

requires('Kwiki' => 0.38);

check_nmake();

&WriteAll();
