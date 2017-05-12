use inc::Module::Install;

name('Kwiki-RecentChanges');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Plugin to Display Recent Changes');
license('perl');
version_from('lib/Kwiki/RecentChanges.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.37
));

check_nmake();

&WriteAll();
