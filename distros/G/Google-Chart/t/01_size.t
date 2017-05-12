use strict;
use Test::More (tests => 22);
use Test::Exception;

BEGIN
{
    use_ok("Google::Chart::Size");
}

{
    my $size = Google::Chart::Size->new( width => 100, height => 100 );
    ok($size);
    isa_ok($size, "Google::Chart::Size");
    is( $size->width, 100 );
    is( $size->height, 100 );
    is( $size->as_query, "chs=100x100" );
}

{
    package Test::Google::Chart::Size;
    use Moose;
    has 'size' => (
        is => 'rw',
        isa => 'Google::Chart::Size',
        coerce => 1
    );
    no Moose;
}

{
    my $test = Test::Google::Chart::Size->new( size => "100x200" );

    my $size = $test->size;
    ok( $size );
    isa_ok( $size, "Google::Chart::Size" );
    is( $size->width, 100 );
    is( $size->height, 200 );
    is( $size->as_query, "chs=100x200" );

    dies_ok {
        Test::Google::Chart::Size->new( size => "10.1x20.3" )
    } "bad spec";

}

{
    my $test = Test::Google::Chart::Size->new( size => {
        args => {
            width => 100,
            height => 200
        }
    } );

    my $size = $test->size;
    ok( $size );
    isa_ok( $size, "Google::Chart::Size" );
    is( $size->width, 100 );
    is( $size->height, 200 );
    is( $size->as_query, "chs=100x200" );
}

{
    my $test = Test::Google::Chart::Size->new( 
        size => {
            width => 100,
            height => 200
        }
    );

    my $size = $test->size;
    ok( $size );
    isa_ok( $size, "Google::Chart::Size" );
    is( $size->width, 100 );
    is( $size->height, 200 );
    is( $size->as_query, "chs=100x200" );
}

