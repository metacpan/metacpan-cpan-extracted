#!/usr/bin/perl -w
use warnings;
use strict;

use Test::More qw(no_plan);
use Scalar::Util qw( refaddr );

use lib '..\lib';

use_ok('Lorem::Document');
use_ok('Lorem::Surface::Pdf');
use_ok('Lorem::Util');
use_ok('Lorem::Element::Div');

use Lorem::Util qw( in2pt pt2in );

my $doc    = Lorem::Document->new; 
ok($doc, 'pdf surface created');



$doc->new_header( left => '003_table.pdf', center => '003_table.pdf', right => '003_table.pdf' );

$doc->build( sub {
    my ($doc, $context) = @_;
    
    my ( $page, $table, $row, $cell, $text, $div );
    
    $page  = $doc->new_page;
    
    $table = $page->new_table( style => 'width: 100%; border-style: solid;');
    ok($table, 'table object created');
    
    $row = $table->new_row;
    $cell = $row->new_cell( style => 'width: 10%; border: solid;' );
    $text = $cell->new_text( content => '<b>#</b>' );

    $cell = $row->new_cell( style => 'width: 20%; border: solid;' );
    $cell->new_text( content => '<b>Species</b>' );
    
    $cell = $row->new_cell( style => 'width: 20%; border: solid;' );
    $cell->new_text( content => '<b>Information</b>' );
    
    $row = $table->new_row;
    $cell = $row->new_cell( style => 'width: 10%; border: solid;' );
    $cell->new_text( content => '<b>1.</b>' );
    
    $cell = $row->new_cell( style => 'width: 20%; vertical-align: middle; border: solid;' );
    $text = $cell->new_text( content => 'Bonobo');
    
    $cell = $row->new_cell( style => 'width: 20%; padding: 10; border: solid;' );
    
    $div = $cell->new_div( style => 'width: 100%; border: solid;' );
    $div->new_text( content => 'relative widths');
    $cell->new_text( content => 'The Bonobo (English pronunciation: /b??no?bo?/[3][4] /?b?n?bo?/[5]), Pan paniscus, previously called the Pygmy Chimpanzee and less often, the Dwarf or Gracile Chimpanzee,[6]'
                                . 'is a great ape and one of the two species making up the genus Pan. The other species in genus Pan is Pan troglodytes, or the Common Chimpanzee. Although the name "chimpanzee" is sometimes used to refer to both species together, it is usually understood as referring to the Common Chimpanzee, while Pan paniscus is usually referred to as the Bonobo.' );
});

my $surface = Lorem::Surface::Pdf->new(file_name => 't/output/014_table.pdf', width => in2pt(8.5), height => in2pt(11) );
$surface->print( $doc );

