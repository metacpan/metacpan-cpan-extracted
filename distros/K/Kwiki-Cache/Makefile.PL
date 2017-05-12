use inc::Module::Install;

name('Kwiki-Cache');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Cache Plugin');
license('perl');
version_from('lib/Kwiki/Cache.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
    Digest::MD5 0
));

check_nmake();

&WriteAll();
