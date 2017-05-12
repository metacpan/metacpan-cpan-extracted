
use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN { eval 'require Dancer2; Dancer2->VERSION( 0.16600101 ); 1' or plan skip_all => 'Test requires Dancer2 >= 0.166001_01' };
BEGIN { eval 'require Dancer2::Plugin::Ajax; 1' or plan skip_all => 'Test requires Dancer2::Plugin::Ajax' };

use Test::More;

BEGIN {
    package MyBase;
    use base 'Import::Base';
    our @IMPORT_MODULES = ( 'Dancer2', 'Dancer2::Plugin::Ajax' );
};

BEGIN { MyBase->import };

can_ok( __PACKAGE__, 'dancer_version' );
can_ok( __PACKAGE__, 'dsl' );
can_ok( __PACKAGE__, 'ajax' );

done_testing;

