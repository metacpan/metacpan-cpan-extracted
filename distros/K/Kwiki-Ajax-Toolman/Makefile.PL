use inc::Module::Install;

name('Kwiki-Ajax-Toolman');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Tool-man Javascript Libraries for Kwiki');
license('perl');
version_from('lib/Kwiki/Ajax/Toolman.pm');

requires(qw(
    perl 5.6.1
    Kwiki::Ajax 0
));

check_nmake();

&WriteAll();
