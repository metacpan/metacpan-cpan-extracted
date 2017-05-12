use inc::Module::Install;

name('Kwiki-PageTemperature');
abstract('Provide a visual cue indicating the age of a page');
author('Chris Dent <cdent@burningchrome.com>');
version_from('lib/Kwiki/PageTemperature.pm');
license('perl');

requires('Kwiki' => 0.37);

check_nmake();

&WriteAll();
