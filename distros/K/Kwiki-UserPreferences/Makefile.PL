use inc::Module::Install;

name('Kwiki-UserPreferences');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki User Preferences Plugin');
license('perl');
version_from('lib/Kwiki/UserPreferences.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.37
));

check_nmake();

&WriteAll();
