#!/usr/bin/perl -w
use warnings;
use strict;

use Test::More qw(no_plan);
use Scalar::Util qw( refaddr );

use_ok('Lorem::Document');
use_ok('Lorem::Surface::Pdf');
use_ok('Lorem::Util');
use_ok('Lorem::Element::Div');

use Lorem::Util qw( in2pt pt2in );

my $doc    = Lorem::Document->new; 
ok($doc, 'pdf surface created');

$doc->set_margin_top( in2pt(.5) );
$doc->set_margin_left( in2pt(.5) );
$doc->set_margin_right( in2pt(.5) );
$doc->set_header_margin( in2pt(.125) );
$doc->new_header( left => '&lt;div>', center => '', right => '' );

$doc->build( sub {
    my ($doc, $context) = @_;
    
    my ( $page, $div );
    $page  = $doc->new_page;
    $div   = $page->new_div;
    $div->new_text( content => 'TEXT1' );
    $div->new_text( content => 'TEXT2' );
    #$div->style->set_border_left_width('thick');
    #$div->style->set_border_left_style('solid');
    #$div->style->set_border_left_color('red');
});

my $surface = Lorem::Surface::Pdf->new(file_name => 't/output/003_div.pdf', width => in2pt(8.5), height => in2pt(11) );
$surface->print( $doc );

