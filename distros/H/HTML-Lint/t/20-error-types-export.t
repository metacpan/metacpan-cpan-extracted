#!perl -Tw

use warnings;
use strict;

use Test::More tests => 4;

use HTML::Lint::Error ':types';

my $err = HTML::Lint::Error->new( undef, undef, undef, 'elem-empty-but-closed' );

ok( $err->is_type( STRUCTURE ) );
ok( !$err->is_type( FLUFF, HELPER ) );

$err = HTML::Lint::Error->new( undef, undef, undef, 'attr-unknown' );
ok( $err->is_type( FLUFF ) );
ok( !$err->is_type( STRUCTURE, HELPER ) );
