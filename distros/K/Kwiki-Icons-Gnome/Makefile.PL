use inc::Module::Install;

name('Kwiki-Icons-Gnome');
author('Ian Langworth <ian@cpan.org>');
abstract('Kwiki Gnome Icons Plugin');
license('gpl');
version_from('lib/Kwiki/Icons/Gnome.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.30
    Kwiki::Icons 0
));

check_nmake();

&WriteAll();
