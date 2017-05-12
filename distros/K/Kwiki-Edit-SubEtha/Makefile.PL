use inc::Module::Install;

name        ('Kwiki-Edit-SubEtha');
author      ('Autrijus Tang <autrijus@autrijus.org>');
abstract    ('SubEthaEdit Plugin for Kwiki');
license     ('perl');
version_from('lib/Kwiki/Edit/SubEtha.pm');

requires    (qw(
    Kwiki               0.33
    Kwiki::Archive::SVK 0.01
));

&WriteAll;
