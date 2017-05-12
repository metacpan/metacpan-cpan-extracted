use inc::Module::Install;

name('Kwiki-Theme-Klassik');
author('Brian Ingerson <ingy@cpan.org>');
abstract('The Classic Kwiki Theme Plugin');
license('perl');
version_from('lib/Kwiki/Theme/Klassik.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
));

check_nmake();

&WriteAll();
