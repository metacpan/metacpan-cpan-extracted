use v5.40;
use blib;
use LibUI qw[:all];

sub make_gradient ( $w, $h ) {
    my $pixels = '';
    for my $y ( 0 .. $h - 1 ) {
        for my $x ( 0 .. $w - 1 ) {
            my $r = int( 255 * $x / ( $w - 1 ) );
            my $g = int( 255 * $y / ( $h - 1 ) );
            my $b = 255 - $r;
            $pixels .= pack 'C4', $r, $g, $b, 255;
        }
    }
    return ( $pixels, $w, $h );
}

sub make_checker( $w, $h ) {
    my $pixels = '';
    for my $y ( 0 .. $h - 1 ) {
        for my $x ( 0 .. $w - 1 ) {
            my $v = ( int( $x / 8 ) + int( $y / 8 ) ) % 2 ? 200 : 80;
            $pixels .= pack 'C4', $v, $v, $v + 40, 255;
        }
    }
    return ( $pixels, $w, $h );
}

sub make_circles( $w, $h ) {
    my $cx     = $w / 2;
    my $cy     = $h / 2;
    my $pixels = '';
    for my $y ( 0 .. $h - 1 ) {
        for my $x ( 0 .. $w - 1 ) {
            my $dx   = $x - $cx;
            my $dy   = $y - $cy;
            my $dist = sqrt( $dx * $dx + $dy * $dy );
            my $r    = $dist < 10 ? 255 : $dist < 20 ? 0   : 50;
            my $g    = $dist < 10 ? 80  : $dist < 20 ? 200 : 50;
            my $b    = $dist < 10 ? 200 : $dist < 20 ? 80  : 200;
            my $a    = $dist < 28 ? 255 : 0;
            $pixels .= pack 'C4', $r, $g, $b, $a;
        }
    }
    return ( $pixels, $w, $h );
}
my @img_data = ( [ Checker => \&make_checker ], [ Circles => \&make_circles ], [ Gradient => \&make_gradient ] );
#
uiInit( { Size => 0 } );
#
my $main = uiNewWindow( 'uiImage', 480, 400, 0 );
uiWindowOnClosing( $main, sub { uiQuit(); return 1 }, undef );
uiWindowSetMargined( $main, 1 );
#
my $vbox = uiNewVerticalBox();
uiBoxSetPadded( $vbox, 1 );
uiWindowSetChild( $main, $vbox );
#
my $model = uiNewTableModel(
    {   NumColumns => sub {2},
        ColumnType => sub { $_[2] == 0 ? UI_TABLE_COLUMN_IMAGE : UI_TABLE_COLUMN_STRING },
        NumRows    => sub { scalar @img_data },
        CellValue  => sub ( $h, $m, $row, $col ) {
            if ( $col == 0 ) {
                my ( $pixels, $w, $hh ) = $img_data[$row][1]->( 64, 64 );
                my $img = uiNewImage( $w, $hh );
                uiImageAppend( $img, $pixels, $w, $hh, $w * 4 );
                return uiNewTableValueImage($img);
            }
            else {
                return uiNewTableValueString( $img_data[$row][0] );
            }
        },
        SetCellValue => sub { }
    }
);
my $table = uiNewTable($model);
uiTableAppendImageColumn( $table, 'Image', 0 );
uiTableAppendTextColumn( $table, 'Name', 1, -1, undef );
uiBoxAppend( $vbox, $table, 1 );
#
uiControlShow($main);
uiMain();
