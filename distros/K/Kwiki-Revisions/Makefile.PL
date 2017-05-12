use inc::Module::Install;

name('Kwiki-Revisions');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Revisions Plugin');
license('perl');
version_from('lib/Kwiki/Revisions.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.38
));

check_nmake();

&WriteAll();
