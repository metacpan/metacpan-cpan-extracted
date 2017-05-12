use inc::Module::Install;

name('Kwiki-Theme-JustContent');
author('Kang-min Liu <gugod@gugod.org>');
abstract('The Kwiki theme that renders only conent pane');
license('perl');
version_from('lib/Kwiki/Theme/JustContent.pm');

requires(qw(
    perl 5.6.1
    Kwiki 0.38
));

check_nmake();

&WriteAll();

