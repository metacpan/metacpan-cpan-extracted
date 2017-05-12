use inc::Module::Install;

name('Kwiki-ReferrerLog');
abstract('Log Referrers to your Kwiki');
author('Benjamin Reitzammer <cpan@nur-eine-i.de>');
version_from('lib/Kwiki/ReferrerLog.pm');
license('perl');

requires(qw(
    perl 5.6.1
    Kwiki 0.30
    Storable
    POSIX
));

check_nmake();

&WriteAll();

