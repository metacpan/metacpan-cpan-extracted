use inc::Module::Install;

name('Kwiki-Theme-Selectable');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Preference to Select a Theme');
license('perl');
version_from('lib/Kwiki/Theme/Selectable.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.38
));

check_nmake();

&WriteAll();
