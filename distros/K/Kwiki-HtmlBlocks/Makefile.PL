use inc::Module::Install;

name('Kwiki-HtmlBlocks');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki HTML Blocks Plugin');
license('perl');
version_from('lib/Kwiki/HtmlBlocks.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
));

check_nmake();

&WriteAll();
