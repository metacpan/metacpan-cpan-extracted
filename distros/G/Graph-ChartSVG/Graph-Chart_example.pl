#!/usr/bin/perl

use strict;
use feature qw( say );
use Data::Dumper;
use List::Util qw( max );

use Devel::Size qw(size total_size);

use subs qw /say/;
###
# possible font impact, georgia, times, serif verdana
sub say
{
    my $msg = shift;
#     $msg =~ s/\n/ /g;
    my $line = ( caller( 0 ) )[2];
    my $sub = ( caller( 1 ) )[3] || ( caller( 0 ) )[3];
    print "[$line] [$sub] $msg\n";
}

use lib "./lib";
#push @INC,'/home/GIT/sandbox/Moose/';
use Graph::ChartSVG;
#my @COLORS =  qw( ccbc32  4169e1 7fffd4 7cfc00  f4a460 ff69b4 9932cc  6a5540 F5C5FF 5fa042 53e0a0  ec98e7 6e5ecd ff0000  );
my @COLORS =  qw( ff0000  00ff00 0000ff 7cfc00  f4a460 ff69b4 9932cc  6a5540 F5C5FF 5fa042 53e0a0  ec98e7 6e5ecd ff0000  );
#$Data::Dumper::Sortkeys = \&skip;

my @size = ( 750, 400 );

my $f = Frame->new( color => 'ff0000', thickness => 3 );
my $graph = Graph::ChartSVG->new( active_size => \@size, bg_color => 'FCF4C6', frame => $f, png_tag => 1 );
# my $graph = Graph::Chart->new( active_size => \@size, png_tag => 1 );
my $b = Border->new( top => 200, bottom => 100, left => 80, right => 200 );

$graph->border( $b );

my $l = Data->new( type => 'line', color => 'ff9800A0', thickness => 3, label => 'oblique' );


my @data;
#say Dumper($graph);
for ( 1 .. 400 )
{
    push @data, $_ / 2;
}
$l->data_set( \@data );
$graph->add( $l );
;
my @data1;
#$#data1 = $#data +1;
$#data1 = 100;
for ( 50 .. 160 )
{
    push @data1, $_ * rand( 3 );
}
my $l1 = Data->new( type => 'bar_up', color => '00ff00', thickness => 2, label => 'random' );
#say Dumper( \@data1 );
$l1->data_set( \@data1 );
# # $graph->add( $l1 );

my @data10;
#$#data1 = $#data +1;
$#data10 = 100;
for ( 50 .. 160 )
{
    push @data10, rand( 200 );
}
my $l10 = Data->new( type => 'bar_down', color => '0000ff', thickness => 2, label => 'random2' );
#say Dumper( \@data1 );
$l10->data_set( \@data10 );
# $graph->add( $l10 );
my @data2;
$#data2 = $#data + 1;

for ( 1 .. 200 )
{
    push @data2, $_ / 2;
}
my $l2 = Data->new(
    type      => 'bar_down',
    color     => '00ffff',
    thickness => 3,
    label     => 'line_bar',
    offset    => 50
);
#say Dumper( \@data1 );

$l2->data_set( \@data2 );
# # $graph->add( $l2);
my @data100;
for ( my $a = 160 ; $a >= 50 ; $a-- )
{
    push @data100, 1000 +$a;
}
my @data101;
for ( 0 .. 100 )
{
    push @data101, 100 + ( $_ / 3 );
# push @data101,100;
}
for ( my $a = 101 ; $a >= 0 ; $a-- )

{
    push @data101, 100 + ( $a / 3 );

}

my @data102;
$#data102 = 50;

for ( 0 .. 160 )
{
    push @data102, 70 + ( $_ / 4 );
# push @data102, 100;
}
my @off;
$#off = 220;

my $scale = 200/ max(@data100);
#my $stack1 = Data->new( type => 'bar_stack', color => [ '0000ff70', '00ff0070', 'ff000070' ], label => 'stacked1', thickness => 1 );
my $stack1 = Data->new( type => 'bar_stack_up', color => \@COLORS, label => 'stacked1', thickness => 3,scale => $scale );
$stack1->data_set( [ \@data100, \@data101, \@data102 ] );
$graph->add( $stack1 );
push @off, @data100;
my $b1 = Data->new( type => 'bar', color => '0000ff70'  , label => 'test100' , scale=> 0.2);
$b1->data_set( \@off );
$graph->add( $b1 );

my @off1;
$#off1 = 350;

push @off1, @data101;
my $b2 = Data->new( type => 'bar', color => '00ff0070' , label => 'test101');
$b2->data_set( \@off1 );
$graph->add( $b2 );

my @off2;
$#off2 = 360;

push @off2, @data102;
my $b3 = Data->new( type => 'bar', color => 'ff0000', label => 'test102',scale => 0.6 );
# say Dumper( \@off2 );
$b3->data_set( \@off2 );
$graph->add( $b3 );

# my $bar1 = Data->new( type => 'bar_down', color => 'ff00ff' ,label => 'bar1') ;
# $bar1->data_set(   \@data100  );
# $graph->add( $bar1);

# # my $bar2 = Data->new( type => 'bar_down', color => 'f0f00f' ,label => 'bar2') ;
# $bar2->data_set(   \@data102  );
# $graph->add( $bar2);
my ( $Mal,$Mlan)= $graph->label( 'test102' );
say "($Mal,$Mlan)";
 $graph->move($Mlan,2);
my $g1 = Glyph->new(

    x        => $graph->border->left + $#data1,
    y        => 'active_max',
    type     => 'line',
    filled   => 0,
    color    => '0faFff',
    data_set => [
        {
            data => [ [ 0, 0 ], [ 8, 10 ], [ 0, 10 ], [ 0, 10 + 20 ], [ 0, 10 ], [ -8, 10 ], [ 0, 0 ] ],
            thickness => 3
        }
      ]

);

my $g2 = Glyph->new(
    label => 'hello',
#    x     => 'active_min',
#    y     => 'active_min',
#x => 0,
#y=>0,
    type     => 'text',
    color    => 'ff0000',
    size     => 24,           # if the glyph's type is 'text', this is the font size
    font     => 'Verdana',    # the TrueType font to use
    data_set => [             # the data set contain an array with all the text to plot followed by the relative position + the optional rotation
        {
            text     => 'hello world ' . time,
            x        => 0,
            y        => 0,
            rotation => -45,
            style    => 'oblique'
        },
        {
            text     => 'hello universe',
            x        => 100,
            y        => 20,
            rotation => 0,
            style    => 'bold italic',
            anchor   => 'start',
            color    => '0000ff',
            stroke   => '00ff00'
        },
    ],

);

my $g3 = Glyph->new(

    x         => 'active_min',
    y         => 'active_min',
    thickness => 20,
    color     => 'ff0fff',
    data_set  => [ { data => [ [ 0, 0 ], [ $graph->active_size->[0], 0 ] ], } ]

);
my $g4 = Glyph->new(
    label => 'hello1',
    x     => 'active_min',
    y     => 'active_min',
#x => 0,
#y=>0,
    type     => 'text',
    color    => 'ff0000',
    size     => 24,           # if the glyph's type is 'text', this is the font size
    font     => 'Verdana',    # the TrueType font to use
    data_set => [             # the data set contain an array with all the text to plot followed by the relative position + the optional rotation
        {
            text     => 'hello world2 ' . time,
            x        => 0,
            y        => 0,
            rotation => -45,
            style    => 'oblique'
        },
        {
            text     => 'hello universe2',
            x        => 0,
            y        => 0,
            rotation => 0,
            font     => 'times',
            style    => 'bold italic',
            anchor   => 'start',
            color    => '0000ff',
            stroke   => 'ff0000'
        },
    ],

);
my $g5 = Glyph->new(

    x        => 100,
    y        => 100,
    type     => 'ellipse',
    filled   => 0,
    color    => '0f0Fffa0',
    data_set => [ { cx => 50, cy => 100, rx => 40, ry => 100, thickness => 40 }, { cx => 300, cy => 100, rx => 50, ry => 50, color => 'ff0000a0', thickness => 4 } ]

);
# $graph->add( $g1 );
# $graph->add( $g2 );
# $graph->add( $g3 );
# $graph->add( $g4 );
# $graph->add( $g5 );

my $START = 1280268000;
my @date;
my @date2;
for ( 0 .. 12 )
{
    my $ticks = $START + ( $_ * 7200 );
#     say $ticks;
    my ( $s, $m, $h ) = ( localtime( $ticks ) )[ 0, 1, 2 ];
    push @date, sprintf( "%02d:%02d:%02d", $h, $m, $s ), '';
    push @date2, scalar( localtime( $ticks ) );
    push @date2, '';
}
my $max = max( @data ) * 1.1;
my @text;
my @text2;
for ( 0 .. 10 )
{
    push @text, ( $_ * $max / 10 );
    push @text2, $_ * $max;
}

$graph->grid(

Grid->new(
        debord => Border->new( top => 20, bottom => 10, left => 10, right => 10 ),

x => Grid_def->new(
            color     => '1292FF',
            number    => 11,
            thickness => 2,
            label     => Label->new(
                font     => 'verdana',
                color    => '0000ff',
                size     => 20,
                text     => \@text,
                space    => 0,
                align    => 'right',
                rotation => -30,
            ),
            label2 => Label->new(
                font  => 'times',
                color => '0000ff',
                size  => 20,
                text  => \@text2,
                space => 10,
# align => 'right',
# rotation => -45,
            ),
        ),

y => Grid_def->new(
            color     => '00fff0',
            number    => 25,
            thickness => 1,
            label     => Label->new(
                font  => 'verdana',
                color => 'ff00ff',
                size  => 14,
#                text               => [ 1000000, undef, '20', undef, 12256985, undef, 555 ],
                text     => \@date,
                space    => 10,
                rotation => -30,
                align    => 'right',
# 		surround => { color => '0x0000ff' , thickness => 1 },
            ),
            label2 => Label->new(
                font         => 'verdana',
                font_scaling => 0.558,
                color        => 'B283FF',
                size         => 16,
#                text               => [ 1000000, undef, '20', undef, 12256985, undef, 555 ],
                text     => \@date2,
                align    => 'right',
                space    => 10,
                rotation => -30,
# 		surround => { color => '0x0000ff' , thickness => 1 },
            ),
        )
    )
);

# $graph->Tag( { titi => 'qwerty', size => 1200 } );

my $O1 = Overlay->new(
    type     => 'v',
    debord_1 => 50,
    debord_2 => 30,
    color    => '0f0Fff70',
    data_set => { 10 => 50, 70 => 100, 200 => 400 }

);
# $graph->add( $O1 );

my $O2 = Overlay->new(

    type     => 'h',
    debord_1 => 50,
    debord_2 => 30,

# color    => 'ff000070',
    color    => '00fff870',
    data_set => { 0 => 100, 200 => 300 }

);
# $graph->add( $O2 );
#say Dumper($graph);

my $total_size = total_size( $graph );
#say "size before rendering=$total_size";
$graph->render;

#say Dumper($graph);
 $total_size = total_size( $graph );
#say "size after rendering=$total_size";

write_svg( $graph->image, '/tmp/test.svg' );
#write_png( $graph->image, '/tmp/test.png' );
convert_svg2png('/tmp/test.svg','/tmp/test.png'  );
# say Dumper($graph );

# my $graph_read = Graph::ChartSVG->new();
# my $svg        = $graph_read->img_from( '/tmp/test.svg' );

#say Dumper($svg);
sub skip
{
    my ( $hash ) = @_;
    my %h = %$hash;
    delete $h{ image };
    return [ keys %h ];
}

sub write_svg
{
    my $out  = shift;
    my $file = shift;
    open( my $IMG, '>', $file ) or die $!;
    binmode $IMG;
    print $IMG $out;
    close $IMG;

}

sub write_png
{
    my $out  = shift;
    my $file = shift; 
	use Image::LibRSVG;
    my $rsvg = new Image::LibRSVG();
        $rsvg->loadFromString( $out );
        $rsvg->saveAs( $file );


}
sub convert_svg2png
{
    my $in  = shift;
    my $out = shift; 
   `/usr/bin/inkscape $in -e $out`;
}
