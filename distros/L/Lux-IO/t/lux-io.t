use strict;
use Test::More tests => 10;

BEGIN { use_ok('Lux::IO') };

# Lux::db_flags_t
is Lux::IO::DB_RDONLY, 0x0000;
is Lux::IO::DB_RDWR  , 0x0002;
is Lux::IO::DB_CREAT , 0x0200;
is Lux::IO::DB_TRUNC , 0x0400;

# Lux::IO::db_index_t
is Lux::IO::NONCLUSTER, 0;
is Lux::IO::CLUSTER   , 1;

# Lux::IO::insert_mode_t
is Lux::IO::OVERWRITE  , 0;
is Lux::IO::NOOVERWRITE, 1;
is Lux::IO::APPEND     , 2;
