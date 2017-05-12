use inc::Module::Install;

name('FreePAN');
author('Brian Ingerson <ingy@cpan.org>');
abstract('FreePAN Framework');
license('perl');
version_from('lib/FreePAN.pm');

requires(qw(
    perl 5.8.3
    Spoon 0.21
    Storable 0
));

install_script('freepan');

check_nmake();

&WriteAll();
