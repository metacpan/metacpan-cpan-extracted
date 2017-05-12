#!perl -w
use strict;
use Test::More tests => 3;

BEGIN { use_ok('File::Find::Rule::Ext2::FileAttributes'); }

can_ok('File::Find::Rule', 'immutable'  );
can_ok('File::Find::Rule', 'appendable' );
