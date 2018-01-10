#!perl -Tw

use warnings;
use strict;

use Test::More tests => 4;

use HTML::Lint::Error;

my $err = HTML::Lint::Error->new( undef, undef, undef, 'elem-empty-but-closed' );

ok( $err->is_type( HTML::Lint::Error::STRUCTURE ) );
ok( !$err->is_type( HTML::Lint::Error::FLUFF, HTML::Lint::Error::HELPER ) );

$err = HTML::Lint::Error->new( undef, undef, undef, 'attr-unknown' );
ok( $err->is_type( HTML::Lint::Error::FLUFF ) );
ok( !$err->is_type( HTML::Lint::Error::STRUCTURE, HTML::Lint::Error::HELPER ) );
