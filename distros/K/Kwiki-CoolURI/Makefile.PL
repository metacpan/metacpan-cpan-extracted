use inc::Module::Install;

name('Kwiki-CoolURI');
author('Jon Åslund <aslund.org>');
abstract('makes the Kwiki url cleaner');
license('perl');
version_from('lib/Kwiki/CoolURI.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.36
));

check_nmake();

&WriteAll();
