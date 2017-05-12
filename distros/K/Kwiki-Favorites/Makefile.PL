use inc::Module::Install;

name('Kwiki-Favorites');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Favorites Plugin');
license('perl');
version_from('lib/Kwiki/Favorites.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.37
));

check_nmake();

&WriteAll();
