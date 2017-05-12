use inc::Module::Install;

name            ('Log-Dispatch-Configurator-YAML');
abstract        ('Configurator implementation with YAML');
author          ('Florian Merges <fmerges@cpan.org>');
license         ('perl');
version_from    ('lib/Log/Dispatch/Configurator/YAML.pm');

requires        ('YAML');
requires        ('Log::Dispatch::Config');

build_requires  ('Test::More');

&WriteAll;
