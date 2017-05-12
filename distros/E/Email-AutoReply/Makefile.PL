use inc::Module::Install;

name            ('Email-AutoReply');
author          ('Adam Monsen <haircut@gmail.com>');
abstract_from   ('lib/Email/AutoReply.pm');
version_from    ('lib/Email/AutoReply.pm');
license         ('perl');
sign            (1);

requires        ('perl' => 5.008003);
requires        ('Spiffy', => 0.14);
requires        ('File::Path');
requires        ('Email::Address');
requires        ('Email::Send');
requires        ('Email::Simple');
requires        ('Mail::ListDetector');
requires        ('BerkeleyDB');
build_requires  ('Test::More');
recommends      ('Getopt::Declare'); # for one of the example scripts

auto_include_deps();

&WriteAll;
