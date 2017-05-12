use strict;
use warnings;

use lib 'buildlib';
use Test::More tests => 1;
use File::Spec::Functions qw( catfile );

BEGIN { use_ok('KinoSearch1::Index::SegInfos') }
use KinoSearch1::Test::TestUtils qw( create_index );

create_index( "a", "a b" );

my $sinfos = KinoSearch1::Index::SegInfos->new;

