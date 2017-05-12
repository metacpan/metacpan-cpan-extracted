# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### Tests load
use Data::Dumper;

BEGIN { $| = 1; print "1..8\n"; }
END { print "not ok 1\n" unless $loaded; }
use lib "./lib";
use Graph::ChartSVG;
$loaded = 1;
print "ok 1\n";

########################## Test basic
my @text  = qw( text1 eg1 sample1 e.g.1 ex1 );
my $graph = Graph::ChartSVG->new(
    active_size => [ 800, 400 ],
    bg_color    => '0x00fff0',
    frame => Graph::ChartSVG::Frame->new( color => '0xff00ff', thickness => 1 ),
    border => Graph::ChartSVG::Border->new( top => 150, bottom => 80, left => 100, right => 100 ),

    grid => Graph::ChartSVG::Grid->new(
        debord => Graph::ChartSVG::Border->new( top => 20, bottom => 10, left => 10, right => 10 ),

        x => Graph::ChartSVG::Grid_def->new(
            color     => '1292FF',
            number    => 5,
            thickness => 2,
            label     => Graph::ChartSVG::Label->new(
                font  => 'verdana',
                color => '0000ff',
                size  => 15,
                text  => \@text,
                space => 10,
                align => 'right',
# rotation => -30,
            ),
        ),
    ),
);

print(
    ( $graph->{ active_size }[0] == 800 && $graph->{ active_size }[1] == 400 && scalar keys %{ $graph } == 5 )
    ? "ok 2\n"
    : "not ok 2\n"
);

########################## Test render
my $result1 = $graph->render;
print( $result1->{ -document }{ height } == 630 ? "ok 3\n" : "not ok 3\n" );
##########################
#
########################### Test frame
#
my $result2 = $graph->frame( Graph::ChartSVG::Frame->new( color => '0x0000ff', thickness => 1 ) );
print( $graph->{ frame }{ color } eq '0x0000ff' ? "ok 4\n" : "not ok 4\n" );
###########################
#
########################### Test data
my @dot;

for my $ind ( 0 .. 600 )
{
    $dot[$ind] = exp( $ind );
}
my $data1 = Graph::ChartSVG::Data->new( type => 'bar_down', color => '0x00ff00', label => 'src_all', thickness => 0, scale => 0.2 );
$data1->data_set( \@dot );
$graph->add( $data1 );

print( scalar( @{ ( $graph->{ Layer }->[0]->{ data_set } ) } ) == 601 ? "ok 5\n" : "** not ok 5 \n" );
###########################
#
########################### Test glyph

my $result4 = Graph::ChartSVG::Glyph->new(
    x        => $graph->border->left,
    y        => 'active_max',
    type     => 'line',
    filled   => 1,
    color    => '0faFff',
    data_set => [
        {
            data => [ [ 0, 0 ], [ 8, 10 ], [ 0, 10 ], [ 0, 10 + 20 ], [ 0, 10 ], [ -8, 10 ], [ 0, 0 ] ],
            thickness => 3
        }
    ]
);

$graph->add( $result4 );

print( $graph->{ Layer }->[1]->{ data_set }->[0]->{ data }->[1][0] == 8 ? "ok 6\n" : "** not ok 6 \n" );
###########################
#
########################### Test text
my $result5 = Graph::ChartSVG::Glyph->new(

    x    => 100,
    y    => 'active_max',
    type => 'text',
    size => 12,

    anchor       => 'middle',
    color        => '0xff0000',
    font         => 'Sans',             # the TrueType font to use
                                        # letter_spacing => 10,
    word_spacing => 15,
    stretch      => 'extra-expanded',
    font_weight  => 'lighter',
    data_set     => [
        {
            text => "text test 1",
            x    => 0,
            y    => 0,
# rotation => -45,
            style => 'normal',
#    anchor =>'middle',
        },
        {
            text     => "text test 2",
            x        => 10,
            y        => 20,
            rotation => -45,
            style    => 'oblique',
            anchor   => 'middle',
        },
    ],
);

$graph->add( $result5 );

print( $graph->{ Layer }->[2]->{ data_set }[1]->{ text } eq 'text test 2' ? "ok 7\n" : "** not ok 7 \n" );
###########################
#
########################### Test reduce
my @dot1;
my $a;
for my $ind ( 0 .. 800 )
{
     $dot1[$ind] = $ind;
    # $dot1[$ind] =int(50 - rand(100));
}

my ( $dot_reduced, $stats ) = $graph->reduce(
    
        data  => \@dot1,
        start => 50,
        end   => 360,
        init  => 300,
   #     type => 'nrz'
);

# print Dumper(@dot1);
# print Dumper(@$dot_reduced);
# print Dumper($stats ) ;
print( ( $stats->{ avg } == 400 && $stats->{ max } == 800 && $stats->{ sum } == 320400 && $dot_reduced->[1] == 300 && $dot_reduced->[180] == 335 && $dot_reduced->[360] == 798.5 ) ? "ok 8\n" : "** not ok 8 \n" );
#
###########################
#
