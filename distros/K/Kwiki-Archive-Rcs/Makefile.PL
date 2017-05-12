use inc::Module::Install;

name('Kwiki-Archive-Rcs');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Page Archival Using RCS');
license('perl');
version_from('lib/Kwiki/Archive/Rcs.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.38
));

check_nmake();

&WriteAll();
