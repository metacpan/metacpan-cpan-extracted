#!/usr/bin/perl -w
use warnings;
use strict;

use Test::More qw( no_plan );
use Scalar::Util qw( refaddr );

use TryCatch;
use Carp qw( confess );

use_ok('Lorem::Document');
use_ok('Lorem::Surface::Pdf');
use_ok('Lorem::Util');
use_ok('Lorem::Element::Div');

use Lorem::Util qw( in2pt pt2in );

my $doc    = Lorem::Document->new; 
ok($doc, 'pdf surface created');

$doc->style->set_margin( 50 );


$doc->build( sub {
    my ($doc, $context) = @_;
    
    my ( $page, $div );
    $page  = $doc->new_page;
   
    $div   = $page->new_div;
    $div->style->set_width( '100%' );
    $div->style->set_border( 'solid' );
    
    my $inner = $div->new_div;
    $inner->style->set_margin( 50 );
    $inner->style->set_width( '50%' );
    $inner->style->set_border( 'solid' );
    $inner->style->set_padding( 10 );
    $inner->new_text( content => 'holla' );

});
try {
    my $surface = Lorem::Surface::Pdf->new(file_name => 't/output/015_div_relative_width.pdf', width => in2pt(8.5), height => in2pt(11) );
    $surface->print( $doc );
}
catch ($e) {
    confess $e;
}


