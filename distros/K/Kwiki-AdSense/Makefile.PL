use inc::Module::Install;

name('Kwiki-AdSense');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Google AdSense Plugin For Kwiki');
license('perl');
version_from('lib/Kwiki/AdSense.pm');

requires(qw(
    perl 5.6.1
));

check_nmake();

&WriteAll();
