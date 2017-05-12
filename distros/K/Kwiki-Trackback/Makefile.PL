use inc::Module::Install;

name('Kwiki-Trackback');
abstract('Trackback server and tracker for Kwiki pages');
author('Chris Dent <cdent@burningchrome.com>');
version_from('lib/Kwiki/Trackback.pm');
license('perl');

requires('Kwiki' => 0.37,
         'Spoon' => 0.22,
         'Net::Trackback' => 0,
         );

check_nmake();

&WriteAll();
