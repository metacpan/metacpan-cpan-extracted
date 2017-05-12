
use inc::Module::Install;

name            ('Graph-SocialMap');
abstract        ('Easy way to create social map.');
author          ('Kang-min Liu (gugod@gugod.org)');
license         ('perl');
version_from    ('lib/Graph/SocialMap.pm');
requires        ('Spiffy' => 0.21);
requires        ('Graph' => 0.54);
requires        ('Graph::Writer::GraphViz' => 0.07);
requires        ('Quantum::Superpositions');
build_requires  ('YAML');
build_requires  ('Test::More');
build_requires  ('Test::Simple');

&WriteAll;
