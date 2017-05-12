use inc::Module::Install;

name('Kwiki-Theme-Bluepole');
author('Jon Åslund <aslund.org>');
abstract('A nice, blue Kwiki Theme');
license('perl');
version_from('lib/Kwiki/Theme/Bluepole.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
));

check_nmake();

&WriteAll();
