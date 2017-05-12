use inc::Module::Install;

name        ('Lingua-ZH-Wrap');
author      ('Autrijus Tang <autrijus@autrijus.org>');
abstract    ('Wrap Chinese text');
license     ('perl');
version_from('lib/Lingua/ZH/Wrap.pm');

WriteAll(sign => 1);
 
1;
