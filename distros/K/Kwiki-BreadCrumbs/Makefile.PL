use inc::Module::Install;

name('Kwiki-BreadCrumbs');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki BreadCrumbs Plugin');
license('perl');
version_from('lib/Kwiki/BreadCrumbs.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.37
));

check_nmake();

&WriteAll();
