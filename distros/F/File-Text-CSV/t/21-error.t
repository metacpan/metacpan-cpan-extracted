#! perl -T

use Test::More tests => 12;
use Test::Fatal;
use utf8;
use_ok( 'File::Text::CSV' );

-d "t" && chdir "t";

my $f;

is( exception { $f = File::Text::CSV->open("err02.csv") },
    undef, "open OK" );

my $row;

is( exception { $row = $f->read }, undef, "read1" );

ok( UNIVERSAL::isa( $row, 'ARRAY' ), 'aref' );

ok( $row->[0] eq '20160110'
    && $row->[1] eq 'David Bowie'
    && $row->[2] == 69, 'data1' );

is( exception { $row = $f->read }, undef, "read2" );
is( join("|", @$row), '20160118|Glenn Frey|67', 'data2' );
like( exception { $row = $f->read },
      qr/Incorrect number of fields: 4 \(should be 3\)/, "read3" );
is( exception { $row = $f->read }, undef, "read4" );
is( join("|", @$row), '20160209|André van den Heuvel|88', 'data4' );

is( exception { $row = $f->read }, undef, "readN" );
ok( !defined($row), 'EOF' );
