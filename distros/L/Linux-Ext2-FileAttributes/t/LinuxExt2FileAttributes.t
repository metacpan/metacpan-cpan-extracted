#!perl -w
use strict;
use Test::More tests => 7;

BEGIN { use_ok('Linux::Ext2::FileAttributes') }

# check three immutable functions
can_ok('Linux::Ext2::FileAttributes', 'is_immutable');
can_ok('Linux::Ext2::FileAttributes', 'clear_immutable');
can_ok('Linux::Ext2::FileAttributes', 'set_immutable');

# check three append only
can_ok('Linux::Ext2::FileAttributes', 'is_append_only');
can_ok('Linux::Ext2::FileAttributes', 'clear_append_only');
can_ok('Linux::Ext2::FileAttributes', 'set_append_only');
