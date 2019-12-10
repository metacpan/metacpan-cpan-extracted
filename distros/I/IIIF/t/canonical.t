use strict;
use Test::More 0.98;
use IIIF::Request;

my @tests = (

    # region
    full                 => 'full',
    '0,0,300,200'        => 'full',
    '0,300,1,1'          => '0,300,1,1',
    '200,0,1,1'          => '200,0,1,1',
    square               => '0,0,200,200',
    'pct:41.6,7.5,40,70' => '125,15,120,140',
    'pct:0,0,100,100'    => 'full',

    # size
    '300,200' => 'full',
    'pct:100' => 'full',
    'pct:0.9' => '3,2',
    '150,'    => '150,100',
    ',100'    => '150,100',
    '^3000,'  => '^3000,2000',
    '!225,100' => '150,100',
    '!225,200' => '225,150',
    '^!360,360' => '^360,240',

    # both
);

while ( my ( $req, $exp ) = splice @tests, 0, 2 ) {
    check_canonical( $req, $exp, 300, 200 );
}


# region
check_canonical( 'square', 'full', 100, 100 );

check_invalid( 'pct:0,0,0.1,0.1', 2, 2 ); # too small
check_invalid( '100,100,1,1', 100, 100 ); # out of bounds

# size
check_invalid( 'pct:1', 2, 200 ); # too small
check_invalid( 'pct:1', 200, 2 ); # too small
check_invalid( '!225,300', 300, 200 ); # upscale needed

# size and region
check_invalid( '0,0,10,10/pct:1', 200, 200 ); # too small

# upscale to maxWidth / maxHeight
check_canonical( '^max', '^100,150', 20, 30, maxWidth => 100, maxHeight => 200 );
check_canonical( '^max', '^67,100', 20, 30, maxHeight => 100 );
check_canonical( '^max', '^max', 20, 30, maxWidth => 100 ); # ignore if maxHeight missing

# constraints by maxWidth / maxHeight
check_invalid( 'max', 200, 200, maxHeight => 100 );
check_invalid( '^100,200', 100, 100, maxHeight => 100 );
check_invalid( ',200', 100, 100, maxHeight => 100 );
check_invalid( '100,', 100, 120, maxHeight => 100 );

sub check_invalid {
    my ( $req, $width, $height, %max ) = @_;
    ok !IIIF::Request->new($req)->canonical( $width, $height, %max ),
      "$req invalid at ${width}x$height" .
      join '', map { " $_=" . $max{$_} } keys %max;
}

sub check_canonical {
    my ( $req, $exp, $width, $height, %max ) = @_;
    $req = IIIF::Request->new($req);
    $exp = IIIF::Request->new($exp);
    is $req->canonical( $width, $height, %max ), $exp,
      "$req => $exp at ${width}x$height" .
      join '', map { " $_=" . $max{$_} } keys %max;
}

done_testing;
