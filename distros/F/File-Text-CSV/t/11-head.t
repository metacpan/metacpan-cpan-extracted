#! perl -T

use Test::More tests => 13;
use Test::Fatal;
use utf8;
use_ok( 'File::Text::CSV' );

-d "t" && chdir "t";

my @c = qw( Date Name Age );

my $f;

is( exception { $f = File::Text::CSV->open("head.csv", { header => 1 }) },
    undef, "open OK" );

my $row;

is( exception { $row = $f->read }, undef, "read1" );

ok( UNIVERSAL::isa( $row, 'HASH' ), ref($row) );

ok( $row->{Date} eq '20160110'
    && $row->{Name} eq 'David Bowie'
    && $row->{Age} == 69, 'data1' );

is( exception { $row = $f->read }, undef, "read2" );
is( join("|", @$row{@c}), '20160118|Glenn Frey|67', 'data2' );
is( exception { $row = $f->read }, undef, "read3" );
is( join("|", @$row{@c}), '20160128|Paul Kantner|74', 'data3' );
is( exception { $row = $f->read }, undef, "read4" );
is( join("|", @$row{@c}), '20160209|André van den Heuvel|88', 'data4' );

is( exception { $row = $f->read }, undef, "readN" );
ok( !defined($row), 'EOF' );
