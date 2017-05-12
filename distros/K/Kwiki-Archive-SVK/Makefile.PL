use inc::Module::Install;

name        ('Kwiki-Archive-SVK');
author      ('Autrijus Tang <autrijus@autrijus.org>');
abstract    ('Kwiki Page Archival Using SVK');
license     ('perl');
version_from('lib/Kwiki/Archive/SVK.pm');

requires    (qw(
    SVK     0.23
    Kwiki   0.35
    IO::All 0.31
));

&WriteAll;
