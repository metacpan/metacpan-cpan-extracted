use strict;
use lib '.';
use inc::Module::Install;

name            ('Makefile-DOM');
#requires        (perl => '5.006001');
perl_version    ('5.006001');
all_from        ('lib/Makefile/DOM.pm');

repository 'http://github.com/agentzh/makefile-dom-pm';

#install_script  ('script/pgmake');

requires        ('List::MoreUtils' => '0.21');
requires        ('Params::Util'    => '0.22');
#requires        ('Scalar::Util'    => '1.17');
#requires        ('Text::Balanced'  => '1.95');
requires        ('Clone'           => '0.18');

#build_requires  ('Test::More'      => '0.62');
#build_requires  ('IPC::Run3'       => '0.036');
#build_requires  ('File::Temp'      => '0.16');
#build_requires  ('File::Spec'      => '3.12');
#build_requires  ('Cwd'             => '3.12');
#build_requiers  ('FindBin'         => '1.47');

use_test_base;

tests('t/*.t t/mdom/*.t t/mdom/*/*.t'); # t/*/*.t t/*/*/*t t/*/*/*/*.t');

auto_install;
WriteAll;

