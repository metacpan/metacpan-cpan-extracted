use inc::Module::Install;

name('Kwiki-GoogleLink');
abstract('Embed Google search');
author('Michael Gray <mjg17@eng.cam.ac.uk>');
version_from('lib/Kwiki/GoogleLink.pm');
license('perl');

requires(qw(
    perl 5.6.1
    Kwiki 0.30
));

check_nmake();

&WriteAll();
