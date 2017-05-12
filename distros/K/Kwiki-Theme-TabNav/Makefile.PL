use inc::Module::Install;

name('Kwiki-Theme-TabNav');
abstract('A simple, minimalistic kwiki theme');
author('Dave Mabe <dmabe@runningland.com>');
version_from('lib/Kwiki/Theme/TabNav.pm');
license('perl');

requires(qw(
    perl 5.6.1
    Kwiki 0.32
));

check_nmake();

&WriteAll();
