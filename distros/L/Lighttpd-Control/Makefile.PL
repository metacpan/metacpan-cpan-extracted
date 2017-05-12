use strict;
use warnings;
use inc::Module::Install;

die "This module is not for use on Windows, sorry."
    if  $^O eq 'Win32' or $^O eq 'cygwin';

name 'Lighttpd-Control';
all_from 'lib/Lighttpd/Control.pm';
license 'perl';

# prereqs
requires 'Moose' => 0.32;
requires 'MooseX::Types::Path::Class';

# things the tests need
build_requires 'Test::More';
build_requires 'Test::Exception';
build_requires 'Test::WWW::Mechanize';

tests('t/*.t');

WriteAll();

