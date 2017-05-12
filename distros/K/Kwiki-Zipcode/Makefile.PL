use inc::Module::Install;

name('Kwiki-Zipcode');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Zipcode Plugin');
license('perl');
version_from('lib/Kwiki/Zipcode.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
));

check_nmake();

&WriteAll();
