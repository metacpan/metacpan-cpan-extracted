use inc::Module::Install;

name('Kwiki-PagePrivacy');
author('Brian Ingerson <ingy@ttul.org>');
abstract('Kwiki Page Level Privacy');
license('perl');
version_from('lib/Kwiki/PagePrivacy.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.37
));

check_nmake();

&WriteAll();
