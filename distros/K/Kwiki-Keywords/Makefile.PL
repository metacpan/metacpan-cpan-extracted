use inc::Module::Install;

name('Kwiki-Keywords');
author('Chris Dent <cdent@cpan.org>');
abstract('Keywords for Kwiki');
license('perl');
version_from('lib/Kwiki/Keywords.pm');

requires(
    Kwiki => 0.38,
);

check_nmake();

&WriteAll();
