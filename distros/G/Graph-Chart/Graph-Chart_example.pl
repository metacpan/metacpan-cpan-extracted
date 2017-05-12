#!/usr/bin/perl
use feature qw( say );
use strict;
use Data::Dumper;

use lib "./lib";
use Graph::Chart;

my $START = 1280268000;
    my @date;
    for ( 0 .. 12 )
    {
    my $ticks = $START+ ( $_ *7200 );
#     say $ticks;
    my ($s ,$m ,$h ) = (localtime($ticks))[0,1,2];
    push @date , sprintf("%02d:%02d:%02d", $h , $m , $s ), '' ;
    
    }
my $graph = Graph::Chart->new(
    size     => [ 720, 400 ],
    bg_color => '0xfffff0',
    #frame  => { color => '0xff00ff', thickness => 1 },
    border => [ 150, 80, 100, 100 ],
    grid   => {
#        debord => [ 5, 20, 10, 30 ],
#        x      => {
#            color  => '0x0000f0',
#	    
#            number => 11,
##	    type => 'log',
#            label  => {
##                font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
#                font  => '/usr/lib/cinelerra/fonts/trebucbi.ttf',
#                color => '0x0000f0',
#                size  => 10,
#                text  => [ 'toto', undef, 'truc', 'bazar', 122 ],
## 		space => 80,
#                align    => 'right',
#                rotation => 30,
#            },
#
#            label2 => {
#                font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
#                color => '0xff0000',
#                size  => 10,
#                text  => [ 'TOTO', undef, 'TRUC', 'BAZAZ', 221 ],
#                space => 50,
#                align => 'right',
#                 rotation => -30,
#            },
#        },
#        x_up      => {
#            color  => '0xff00ff',
#            number => 10,
#	    type => 'log',
#            label  => {
##                font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
#                font  => '/usr/lib/cinelerra/fonts/trebucbi.ttf',
#                color => '0xff0000',
#                size  => 10,
#                text  => [ 'toto', undef, 'truc', 'bazar', 122 ],
## 		space => 80,
#                align    => 'right',
#                rotation => -30,
#            },
#
#            label2 => {
#                font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
#                color => '0xff0000',
#                size  => 10,
#                text  => [ 'TOTO', undef, 'TRUC', 'BAZAZ', 221 ],
#                space => 50,
#                align => 'right',
#                 rotation => -30,
#            },
#        },
#		    x_down      => {
#            color  => '0xff00ff',
#            number => 10,
#	    type => 'log',
#            label  => {
##                font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
#                font  => '/usr/lib/cinelerra/fonts/trebucbi.ttf',
#                color => '0xff0000',
#                size  => 10,
#                text  => [ 'toto', undef, 'truc', 'bazar', 122 ],
## 		space => 80,
#                align    => 'right',
#                rotation => 30,
#            },
#	    },
        y => {
            color     => '0x00fff0',
            number    => 25,
            thickness => 1,
            label     => {
#                 font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
                font               => '/usr/lib/cinelerra/fonts/trebuc.ttf',
                kerning_correction => 0.85,
                color              => '0xff0000',
                size               => 12,
#                text               => [ 1000000, undef, '20', undef, 12256985, undef, 555 ],
		text      => \@date,
# 		space => 10,
                rotation => 45,
# 		surround => { color => '0x0000ff' , thickness => 1 },
            },
	     label2     => {
#                 font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
		 font  => '/usr/lib/cinelerra/fonts/trebuc.ttf',
		 kerning_correction => 0.85,
                 color => '0xff0000',
                 size  => 12,
                 text  => [ 1000000, undef, '20', undef, 12256985, undef, 555 ],
 #		space => 10,
                 rotation => 30,

 # 		surround => { color => '0x0000ff' , thickness => 1 },
             }
          }

    },

#	reticle => {
#	debord => 30,
#	color => '0xff0000',
#	number => 10,
#	label_middle => {
#		font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
##		kerning_correction => 0.85,
#		color => '0xff0000',
#                size  => 10,
##		space => 10,
##		rotate => 'follow',
#		rotate => 'perpendicular',
##		rotation => 30,
#                text => [70001231220,45,90,135,180,225,270,3150000 , 1 ,2],
#		},
##	label => {
##		font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
###		kerning_correction => 0.85,
##		color => '0xff0000',
##                size  => 12,
###		space => 10,
##		rotate => 'follow',
###		rotate => 'perpendicular',
###		rotation => 30,
##                text => [70001231220,45,90,135,180,225,270,3150000 , 1 ,2],
##		},
#},

);

#$graph->reticle(
#{
#	label => {
#		font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
##		kerning_correction => 0.85,
#		color => '0xff0000',
#                size  => 12,
#		space => 40,
##		rotate => 'follow',
##		rotate => 'perpendicular',
#		rotation => 30,
#                text => [70001231220,45,90,135,180,225,270,3150000 , 1 ,2],
#		},}
#);



$graph->frame( { color => '0x0000ff', thickness => 2 } );


# $graph->grid(
#     {
#         x => {
#             color  => '0xff00ff',
#             number => 5,
#             label  => {
#                 font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
#                 color => '0xff0000',
#                 size  => 10,
#                 text  => [ 'toto', undef, 'truc', 'bazar', 122 ]
#             }
#         }
#     }
# );

#$graph->grid(
#{
#         y => {
#             color     => '0x00fff0',
#             number    => 8,
#             thickness => 1,
#             label     => {
##                 font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
#		 font  => '/usr/lib/cinelerra/fonts/trebuc.ttf',
#		 kerning_correction => 0.85,
#                 color => '0xff0000',
#                 size  => 12,
#                 text  => [ 1000000, undef, '20', undef, 12256985, undef, 555 ],
## 		space => 10,
#                 rotation => 45,
# # 		surround => { color => '0x0000ff' , thickness => 1 },
#             },
#	     label2     => {
##                 font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
#		 font  => '/usr/lib/cinelerra/fonts/trebuc.ttf',
#		 kerning_correction => 0.85,
#                 color => '0xff0000',
#                 size  => 12,
#                 text  => [ 1000000, undef, '20', undef, 12256985, undef, 555 ],
# #		space => 10,
#                 rotation => 30,
#
# # 		surround => { color => '0x0000ff' , thickness => 1 },
#             }
#	     },
#	     x      => {
#            color  => '0xff00ff',
#            number => 5,
#            label  => {
##                font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
#		font  => '/usr/lib/cinelerra/fonts/trebucbi.ttf',
#                color => '0xff0000',
#                size  => 10,
#                text  => [ 'bazar', 123, 'crut', 'much', 0 ],
## 		space => 80,
#		align => 'right',
#                 rotation => 30,
#            }
#         }
#
#}
#);

my @dot;
$#dot = 9;

for my $ind ( 0 .. 400 )
{

    $dot[$ind] = rand( 300 );
#$dot[$ind] = $ind;
#$dot[$ind] = 50+rand( 100 );
}
#@dot = (45);
#$graph->data(
#    {
#        layer => 10,
#        set   => \@dot,
#        type  => 'line',
#	bar_size => 1,
#        color => '0x0000ff',
#	thickness => 1,
##	scale => 0.6,
#        scale => 1.1,
##        scale => 'auto',
#    }
#);
my @dot1;
#$#dot1 = 19;

for my $ind ( 0 .. 800 )
{
#    $dot1[$ind] = rand( 200 );
$dot1[$ind] = $ind;
#$dot1[$ind] = 50 +rand( 200 );
#$dot1[$ind] =  150 +(90 * ( sin( ( $ind / 30 ) * 3.14159)));

#    $dot1[$ind] = exp( $ind );
#$dot1[$ind] = 10 **($ind);
#$dot1[$ind] = $ind*$ind;

#say "$ind = ".$dot1[$ind] ;
}
my ( $dot_reduced , $stats ) = $graph->reduce( { data => \@dot1 ,
start => 50,
end => 360,
init => 300 
});

say Dumper($stats);
say $dot_reduced->[1];
say $dot_reduced->[180];
 say $dot_reduced->[361];
 
my $max = 1000;
my @text;
for ( 0 .. 10 )
{
        push @text, ( $_ * $max / 10 );
}

$graph->grid(

  {
       
        x      => {
            color  => '0x0000f0',
	    
            number => 11,
#	    type => 'log',
            label  => {
                font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
#                font  => '/usr/lib/cinelerra/fonts/trebucbi.ttf',
                color => '0x0000f0',
                size  => 10,
                text  =>\@text,
 		space => 80,
                align    => 'right',
#                rotation => 30,
            },

            label2 => {
                font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
                color => '0xff0000',
                size  => 10,
                text  => [ 'TOTO', undef, 'TRUC', 'BAZAZ', 221 ],
                space => 50,
                align => 'right',
                 rotation => -30,
            },
        },
	}
	);
;

my $res =$graph->data(
    {
        layer     => 4,
	set       => $dot_reduced ,
        type      => 'line',
        bar_size  => 1,
        color     => '0x00ff00',
#		color => [
#	'0xff0000',
#	'0xff0000',
#	'0xff0000',
#	'0xff0000',
#	'0x00ff00',
#	'0x00ff00',
#	'0x00ff00',
#	'gdTransparent',
#	'gdTransparent'
#	],
        thickness => 1,
#	offset   => 200,
#	scale => 1,
        scale => '90%',
#        scale => $max,
#        scale =>'auto',
#        scale => 'log',
#	scale => 'ln',
    }
);
#my $res =$graph->data;
#say Dumper(scalar(@{($graph->{ data })->[4]->{set}}));

#$graph->data(
#    {
#        layer => 0,
#        set   => \@dot,
#        type  => 'line',
#	bar_size => 1,
#        color => '0xff0000',
#	thickness => 5,
##        scale => 1.1,
##        scale => 'auto',
#    }
#);
my @alarm;
for ( 90 .. 180 )
{
    $alarm[$_] = 1;

}

#
#$graph->overlay(
#{
#	layer => 1,
#	set   => \@alarm,
#	color => '0xFFFECE',
##	color => '0xFFD2D2',
#	opacity => 100,
#	type => 'pie',
#	merge  => 1,
##	debord => 50,
#}
#);
#
#my @alarm1;
#for ( 100 .. 250 )
#{
#$alarm1[ $_  ] = 1;
#
#}
#
#
#$graph->overlay(
#{
#	layer => 0,
#	set   => \@alarm1,
#	color => '0xFFD2D2',
#	opacity => 100,
#	merge  => 0,
#	type => 'pie',
#}
#);

#$graph->glyph(
#    {
#        x => 0,
#        y => 0,
#
#        color => '0x00ff00',
#        data  => [
#            [ 0,   0 ],
#            [ 20,  4 ],
#            [ 0,   4 ],
#            [ 0,   4 + 20 ],
#            [ 0,   4 ],
#            [ -20, 4 ],
#            [ 0,   0 ]
#
#          ]
#
#    }
#);

say "xmax=".$graph::x_active_max;

$graph->glyph(
    {
        x     => $graph->active->{ x }{min} + 200,
        y     => $graph->active->{ y }{max},
        type  => 'filled',
        color => '0x00FFff',
        data  => [
            [ 0,  0 ],
            [ 8,  10 ],
            [ 0,  10 ],
            [ 0,  10 + 20 ],
            [ 0,  10 ],
            [ -8, 10 ],
            [ 0,  0 ]
          ]
    }
);

#$graph->glyph(
#    {
#        x => 'active_min',
#        y => 'active_min',
#
##        color     => '0xff0000',
#	color => [
#	'0xff0000',
#	'0xff0000',
#	'0xff0000',
#	'0xff0000',
#	'0x00ff00',
#	'0x00ff00',
#	'0x00ff00',
#	'gdTransparent',
#	'gdTransparent'
#	],
#        thickness => 3,
#        data      => [
#            [ -20,   100 ],
#            [ 820, 180 ],
#          ]
#    }
#);
#
#my $res = $graph->glyph(
#    {
#        x     => 100,
#        y     => 'active_max',
#        type  => 'text',
#        color => 0xff0000,
#        size  => 12,
#        font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
#        data  => [ 
#	     [ 'hello world', 0, 0, 30 ], 
#	     [ 'hello universe', 100, 0 ], 
#	],
#
#    }
#);



my $png_out = $graph->render( { tag => { toto => 'azerty', si => 100 } } );

#my $png_out = $graph->render( );
write_png( $png_out, '/tmp/img.png' );
my $png_out1 = $graph->png_zEXt( { eerer => 1, ggg => 'zed' } );
write_png( $png_out1, '/tmp/img.png' );

# $graph->size( [ 500, 300 ] );
# $graph->bg_color('00ffff');
#
#
# my $png_out1 = $graph->render;
# write_png( $png_out1, '/tmp/img1.png' );

# say Dumper($png_out);

sub write_png
{
    my $out  = shift;
    my $file = shift;
    open( my $IMG, '>', $file ) or die $!;
    binmode $IMG;
    print $IMG $out;
    close $IMG;

}
