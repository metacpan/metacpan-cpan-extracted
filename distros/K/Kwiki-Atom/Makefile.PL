use inc::Module::Install;

name('Kwiki-Atom');
author('Autrijus Tang <autrijus@autrijus.org>');
abstract('Kwiki Atom Plugin');
license('perl');
version_from('lib/Kwiki/Atom.pm');

requires(qw(
    perl        5.6.1
    Kwiki       0.37
    XML::Atom   0.09
));

WriteAll( sign => 1 );
