use inc::Module::Install;

name('Kwiki-Image');
abstract('More comprehensive WAFL support for images in Kwiki');
author('Dave Mabe <dmabe@runningland.com>');
version_from('lib/Kwiki/Image.pm');
license('perl');

requires(qw(
    perl 5.6.1
    Kwiki 0.30
));

check_nmake();

&WriteAll();
