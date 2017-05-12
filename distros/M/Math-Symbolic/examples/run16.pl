#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib/';
use Carp;
use Math::Symbolic qw/:all/;
use Math::Symbolic::MiscCalculus qw/:all/;

my $taylor = TaylorPolynomial 'sin(x)', 10, 'x', 'x_0';
$taylor->implement( e => Math::Symbolic::Constant->euler() );
print $taylor, "\n\n";

my $t = $taylor->implement( x_0 => 0 );
print +( $_ * PI / 4 ), ":\nTaylor: " . $taylor->value( x => $_ * PI / 4 ),
  "\nExact: ", sin( $_ * PI / 4 ), "\n"
  for 0 .. 10;

my $error = TaylorErrorLagrange 'sin(x)', 100, 'x', 'x_0', 'theta';
$error = $error->simplify();

print "\nErrors:";
print "For " . ( $_ * PI / 4 ) . ": ",
  $error->value( theta => 1, x_0 => 0, x => $_ * PI / 4 ), "\n"
  for 0 .. 100;

print "Would you like to plot the results using Imager? (y/n)\n";
print ": ";
my $answer = <STDIN>;

exit unless $answer =~ /^\s*y/i;

require Imager;
my $img = Imager->new( xsize => 800, ysize => 600 );

my $white  = Imager::Color->new( 255, 255, 255 );
my $green  = Imager::Color->new( 0,   255, 0 );
my $red    = Imager::Color->new( 255, 0,   0 );
my $blue   = Imager::Color->new( 0,   0,   255 );
my $yellow = Imager::Color->new( 255, 255, 0 );

$img->line( color => $blue, x1 => 0,   x2 => 800, y1 => 300, y2 => 300 );
$img->line( color => $blue, x1 => 400, x2 => 400, y1 => 0,   y2 => 600 );

print "\nThe white plot is the original sine. The green plot is the third\n"
  . "order Taylor polynomial and the red plot is the tenth order Taylor\n"
  . "polynomial. Finally, the yellow plot is the twentieth order Taylor\n"
  . "polynomial. All polynomials approximate around 0.\n";

my $third = TaylorPolynomial 'sin(x)', 3, 'x', 'x_0';
$third->implement( e => Math::Symbolic::Constant->euler(), x_0 => 0 );

my $twenty = TaylorPolynomial 'sin(x)', 20, 'x', 'x_0';
$twenty->implement( e => Math::Symbolic::Constant->euler(), x_0 => 0 );

my $sine = parse_from_string('sin(x)');

use Math::Symbolic::Compiler qw/compile_to_sub/;

foreach my $ary (
    [ $third,  $green ],
    [ $taylor, $red ],
    [ $twenty, $yellow ],
    [ $sine,   $white ]
  )
{
    my ( $tree, $color ) = @$ary;
    my ($sub) = compile_to_sub($tree);
    die unless defined $sub and ref $sub eq 'CODE';
    my $prev;
    foreach ( -150 .. 150 ) {
        my $x = $_ * PI / 50;
        my $y = $sub->($x);
        if ( not defined $prev ) {
            $prev = [ $x, $y ];
            next;
        }
        $img->line(
            color => $color,
            x1    => ( $prev->[0] * 40 ) + 400,
            x2    => ( $x * 40 ) + 400,
            y1    => -( $prev->[1] * 40 ) + 300,
            y2    => -( $y * 40 ) + 300,
        );
        $prev = [ $x, $y ];
    }
}

print "The image will be written to the file 'image.png'.\n";
$img->write( file => 'image.png' ) or die $img->errstr;
