use inc::Module::Install;

name('Kwiki-PrinterFriendly');
author('Henry Laxen <nadine.and.henry@pobox.com>');
abstract('Kwiki Printer Friendly Plugin');
license('perl');
version_from('lib/Kwiki/PrinterFriendly.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.38
));

check_nmake();

&WriteAll();
