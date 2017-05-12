use inc::Module::Install;

name('Kwiki-ParagraphBlocks');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Kwiki Paragraph Blocks Plugin');
license('perl');
version_from('lib/Kwiki/ParagraphBlocks.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.34
));

check_nmake();

&WriteAll();
