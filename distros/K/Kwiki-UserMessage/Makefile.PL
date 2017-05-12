use inc::Module::Install;

name            ('Kwiki-UserMessage');
abstract        ('Kwiki user message sub-system');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/UserMessage.pm');
requires        ("Kwiki" => 0.38,
		 "DBD::SQLite" => 0,
		 "Kwiki::DB" => 0,
		 "Class::DBI" => 0);
build_requires  ('Test::More');

&WriteAll;

