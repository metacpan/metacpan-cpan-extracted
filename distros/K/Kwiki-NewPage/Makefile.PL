use inc::Module::Install;

name('Kwiki-NewPage');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki New Page Plugin');
license('perl');
version_from('lib/Kwiki/NewPage.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
));

check_nmake();

&WriteAll();
