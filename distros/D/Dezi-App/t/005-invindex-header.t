use strict;
use warnings;
use Test::More tests => 4;
use Data::Dump qw( dump );

use_ok('Dezi::InvIndex');

# use test dir as mock invindex since we just want header file
ok( my $invindex = Dezi::InvIndex->new( path => 't/' ),
    "new invindex" );

ok( my $header = $invindex->get_header, "get header" );

diag( dump $header->Index );

is( $header->Index->{Format}, 'Test', "Test index format" );
