use inc::Module::Install;

name('Kwiki-Purple');
abstract('Provides purple numbers support to Kwiki');
author('Chris Dent <cdent@burningchrome.com>');
version_from('lib/Kwiki/Purple.pm');
license('perl');

requires(Kwiki         => 0.38,
         Kwiki::Test   => 0.03,
         DB_File::Lock => 0
     );

check_nmake();

&WriteAll();
