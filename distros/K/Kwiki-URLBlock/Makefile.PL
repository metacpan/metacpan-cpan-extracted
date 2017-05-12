use inc::Module::Install;

name('Kwiki-URLBlock');
author('Jon Aslund <aslund.org>');
abstract('Blocks edit based on added URLs');
license('perl');
version_from('lib/Kwiki/URLBlock.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.37
    URI::Find 0
));

check_nmake();

&WriteAll();
