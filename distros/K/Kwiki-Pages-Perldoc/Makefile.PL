use inc::Module::Install;

name('Kwiki-Pages-Perldoc');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Pages Sublcass for Perldoc');
license('perl');
version_from('lib/Kwiki/Pages/Perldoc.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
));

check_nmake();

&WriteAll();
