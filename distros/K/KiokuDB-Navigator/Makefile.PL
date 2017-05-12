use strict;
use warnings;
use inc::Module::Install;

name 'KiokuDB-Navigator';
all_from 'lib/KiokuDB/Navigator.pm';
license 'perl';

# prereqs
requires 'KiokuDB'                    => '0.34';
requires 'KiokuDB::Cmd'               => '0.02';
requires 'JSORB'                      => '0.04';
requires 'MooseX::Types::Path::Class' => '0.05';
requires 'File::ShareDir'             => '1.00';
requires 'Browser::Open'              => '0.03';
requires 'POSIX';
requires 'Path::Class';

install_share;

# things the tests need
build_requires 'Test::More'      => '0.62';
build_requires 'Test::Exception' => '0.21';

tests('t/*.t t/*/*.t');

WriteAll();

