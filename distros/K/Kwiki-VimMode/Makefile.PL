use inc::Module::Install;

name('Kwiki-VimMode');
abstract('VimMode preformatted forms of text');
author('Ian Langworth <ian@cpan.org>');
version_from('lib/Kwiki/VimMode.pm');
license('perl');

requires(qw(
    perl 5.6.1
    Kwiki 0.30
    Text::VimColor 0.09
));

check_nmake();

&WriteAll();
