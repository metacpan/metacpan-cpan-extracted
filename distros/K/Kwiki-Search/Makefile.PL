use inc::Module::Install;

name('Kwiki-Search');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Search Plugin');
license('perl');
version_from('lib/Kwiki/Search.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
));

check_nmake();

&WriteAll();
