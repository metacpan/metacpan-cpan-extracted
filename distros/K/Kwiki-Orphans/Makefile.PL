use inc::Module::Install;

name('Kwiki-Orphans');
author('Chris Dent <cdent@burningchrome.com>');
abstract('Kwiki Orphan Finder');
license('perl');
version_from('lib/Kwiki/Orphans.pm');

requires(
    'Kwiki::Backlinks' => 0,
);

check_nmake();

&WriteAll();
