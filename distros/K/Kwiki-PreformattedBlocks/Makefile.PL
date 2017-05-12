use inc::Module::Install;

name('Kwiki-PreformattedBlocks');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Preformatted Blocks Plugin');
license('perl');
version_from('lib/Kwiki/PreformattedBlocks.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
));

check_nmake();

&WriteAll();
