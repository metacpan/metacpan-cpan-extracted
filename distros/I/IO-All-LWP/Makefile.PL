use inc::Module::Install;

name('IO-All-LWP');
author('Ivan Tubert-Brohman <itub@cpan.org>');
abstract('Use HTTP and FTP URLs with IO::All');
license('perl');
version_from('lib/IO/All/LWP.pm');

requires(qw(
    perl 5.8.0
    IO::All 0.30
    LWP 0
));
check_nmake();

&WriteAll();
