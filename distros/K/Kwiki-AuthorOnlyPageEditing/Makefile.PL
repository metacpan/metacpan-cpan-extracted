use inc::Module::Install;

name            ('Kwiki-AuthorOnlyPageEditing');
abstract        ('Only the author of the page can edit it.');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/AuthorOnlyPageEditing.pm');
requires        ('Kwiki');
build_requires  ('Test::More');

&WriteAll;

