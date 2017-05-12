use inc::Module::Install;

name('Kwiki-GDGraphGenerator');
abstract('put pretty graphs into your Kwiki pages');
author('Ian Langworth <ian@cpan.org>');
version_from('lib/Kwiki/GDGraphGenerator.pm');
license('perl');

requires(qw(
    perl 5.6.1
    Kwiki 0.32
    GD::Graph 1.40
));

check_nmake();

&WriteAll();
