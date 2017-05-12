use strict;
use warnings;

use Lorem;
use Lorem::Util qw( in2pt );

my $doc = Lorem->new_document;

$doc->style->parse( 'margin: 50;' );

my $page = $doc->new_page( style => 'align: center' );

my $table = $page->new_table( style => 'border: thick solid black;' );

my $puzzle = [
    [qw( x 8 x x 4 9 6 1 x) ],
    [qw( x x x x 2 x 9 4 3) ],
    [qw( x x 2 3 6 x x x x) ],
    [qw( x x x x x 8 x 3 x) ],
    [qw( 6 3 5 4 x 2 7 8 9) ],
    [qw( x 1 x 6 x x x x x) ],
    [qw( x x x x 8 4 2 x x) ],
    [qw( 1 4 7 x 9 x x x x) ],
    [qw( x 2 8 5 7 x x 6 x) ],
];

for my $rowx ( 0..8 ) {
    my $row = $table->new_row( );
    

    if ( $rowx == 2 || $rowx == 5 ) {
        $row->style->parse( 'border-bottom: thick solid;' );
    }
    else {
        $row->style->parse( 'border-bottom-style: solid;' );
    }
    
    for my $colx ( 0..8 ) {
        my $cell = $row->new_cell( style => 'width: 24; height: 24; text-align: center; vertical-align: middle;' );
        $cell->new_text( content => $puzzle->[$rowx][$colx] ) if $puzzle->[$rowx][$colx] ne 'x';
        
        if ( $colx == 2 || $colx == 5 ) {
            $cell->style->parse( 'border-right: thick solid; ' )
        }
        else {
            $cell->style->parse( 'border-right-style: solid; ' )
        }
        
    }
}

my $surface = Lorem::Surface::Pdf->new(file_name => 'sudoku2.pdf', width => in2pt(8.5), height => in2pt(11) );
$surface->print( $doc );
