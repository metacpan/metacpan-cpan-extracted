use inc::Module::Install;

name('Kwiki-TimeZone');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Time Zone Plugin');
license('perl');
version_from('lib/Kwiki/TimeZone.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
));

check_nmake();

&WriteAll();
