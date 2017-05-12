use inc::Module::Install;

name('Kwiki-Spork');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Spork Plugin');
license('perl');
version_from('lib/Kwiki/Spork.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.37
    Spork 0.18
));

check_nmake();

&WriteAll();
