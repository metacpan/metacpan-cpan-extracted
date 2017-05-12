use inc::Module::Install;

name('Kwiki-ShellBlocks');
author('Autrijus Tang <autrijus@autrijus.org>');
abstract('Kwiki Shell Blocks Plugin');
license('perl');
version_from('lib/Kwiki/ShellBlocks.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.31
));

&WriteAll();
