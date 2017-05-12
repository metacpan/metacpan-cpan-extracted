use inc::Module::Install;

name('Kwiki-Formatter-Pod');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Formatting Using Pod');
license('perl');
version_from('lib/Kwiki/Formatter/Pod.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
));

check_nmake();

&WriteAll();
