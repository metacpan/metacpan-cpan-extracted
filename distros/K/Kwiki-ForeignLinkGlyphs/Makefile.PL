use inc::Module::Install;

name('Kwiki-ForeignLinkGlyphs');
abstract("display an image after links that aren't local");
author('Ian Langworth <ian@cpan.org>');
version_from('lib/Kwiki/ForeignLinkGlyphs.pm');
license('perl');

requires(qw(
    perl 5.6.1
    Spiffy 0.22
    Kwiki 0.32
    Kwiki::Formatter
));

check_nmake();

&WriteAll();
