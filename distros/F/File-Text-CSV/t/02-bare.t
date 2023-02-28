#! perl -T

use Test::More tests => 13;
use Test::Fatal;
use utf8;
use_ok( 'File::Text::CSV' );

-d "t" && chdir "t";

my $f;

is( exception { $f = File::Text::CSV->open("bare.csv") },
    undef, "open OK" );

my $row;

is( exception { $row = $f->read_arrayref }, undef, "read_arrayref1" );

ok( UNIVERSAL::isa( $row, 'ARRAY' ), 'aref' );

ok( $row->[0] eq '20160110'
    && $row->[1] eq 'David Bowie'
    && $row->[2] == 69, 'data1' );

is( exception { $row = $f->read_arrayref }, undef, "read_arrayref2" );
is( join("|", @$row), '20160118|Glenn Frey|67', 'data2' );
is( exception { $row = $f->read_arrayref }, undef, "read_arrayref3" );
is( join("|", @$row), '20160128|Paul Kantner|74', 'data3' );
is( exception { $row = $f->read_arrayref }, undef, "read_arrayref4" );
is( join("|", @$row), '20160209|André van den Heuvel|88', 'data4' );

is( exception { $row = $f->read_arrayref }, undef, "read_arrayrefN" );
ok( !defined($row), 'EOF' );
