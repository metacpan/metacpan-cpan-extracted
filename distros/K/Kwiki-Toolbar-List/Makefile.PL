use inc::Module::Install;

name('Kwiki-Toolbar-List');
abstract('Displays the toolbar as an unordered list that can be more easily styled with CSS.');
author('Dave Mabe <dmabe@runningland.com>');
version_from('lib/Kwiki/Toolbar/List.pm');
license('perl');

requires(qw(
    perl 5.6.1
    Kwiki 0.32
));

check_nmake();

&WriteAll();
