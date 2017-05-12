use strict;
use warnings;
use inc::Module::Install;

name	 'File-VirusScan';
all_from 'lib/File/VirusScan.pm';
license  'gpl';

build_requires 'Test::More';
build_requires 'Test::Class';
build_requires 'Test::Exception';


requires 'File::Temp';
requires 'IO::File';
requires 'IO::Dir';
requires 'Scalar::Util';
requires 'Data::ResultSet';
requires 'Class::Accessor::Fast';

# Required for some scanners, but not all.  However, if we don't make it a
# 'requires', automated tests fail on some platforms.
# TODO: 'recommends' and have tests short-circuit?
requires 'IO::Socket::INET';
requires 'IO::Socket::UNIX';
requires 'IO::Select';
requires 'HTML::TokeParser';

#author_tests('xt');

WriteAll;
