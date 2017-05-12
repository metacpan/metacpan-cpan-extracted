use inc::Module::Install;

name('Kwiki-ModPerl');
abstract('enable Kwiki to work under mod_perl');
author('Kang-min Liu <gugod@gugod.org>');
version_from('lib/Kwiki/ModPerl.pm');
license('perl');

requires(qw(
    perl 5.6.1
    Kwiki 0.32
    mod_perl
));

check_nmake();

&WriteAll();
