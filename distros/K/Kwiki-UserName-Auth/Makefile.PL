use inc::Module::Install;

name            ('Kwiki-UserName-Auth');
abstract        ('Online user regsitration plugin for Kwiki.');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Kwiki/UserName/Auth.pm');
requires        ('Kwiki' => 0.38,
		 'Kwiki::DB' => 0,
		 'Kwiki::Session' => 0,
		);
build_requires  ('Test::More');

auto_install();
&WriteAll;

