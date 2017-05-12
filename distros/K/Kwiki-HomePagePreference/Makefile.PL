use inc::Module::Install;

name('Kwiki-HomePagePreference');
author('Brian Ingerson <ingy@cpan.org>');
abstract('User Selectable HomePage');
license('perl');
version_from('lib/Kwiki/HomePagePreference.pm');

requires(qw(
    perl 5.6.1
));

check_nmake();

&WriteAll();
