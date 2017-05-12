use inc::Module::Install;

name('Kwiki-PoweredBy');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Powered-By Plugin');
license('perl');
version_from('lib/Kwiki/PoweredBy.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.38
));

check_nmake();

&WriteAll();
