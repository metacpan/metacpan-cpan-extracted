use inc::Module::Install;

name('Kwiki-DatedAnnounce');
abstract('Date sensitive display of blocks in wiki pages');
author('Chris Dent <cdent@burningchrome.com>');
version_from('lib/Kwiki/DatedAnnounce.pm');
license('perl');

requires(Kwiki => 0.37,
         Kwiki::Test => 0,
     );

check_nmake();

&WriteAll();
