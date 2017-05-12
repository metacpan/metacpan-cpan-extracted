use inc::Module::Install;

name            ('Kwiki-PageTemplate');
abstract        ('Page Templating, generate page more easily!');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/PageTemplate.pm');
requires        ('Kwiki');
requires        ('List::Util');
requires	('YAML');
build_requires  ('Test::More');

&WriteAll;

