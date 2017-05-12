use inc::Module::Install;

name('Kwiki-PodBlocks');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Pod Blocks Plugin');
license('perl');
version_from('lib/Kwiki/PodBlocks.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
    Pod::Simple 0
));

check_nmake();

&WriteAll();
