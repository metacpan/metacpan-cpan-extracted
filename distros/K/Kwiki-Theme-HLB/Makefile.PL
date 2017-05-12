use inc::Module::Install;

name('Kwiki-Theme-HLB');
author('Autrijus Tang <autrijus@autrijus.org>');
abstract('The HLB Kwiki Theme Plugin');
license('perl');
version_from('lib/Kwiki/Theme/HLB.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.32
));

WriteAll( sign => 1 );
