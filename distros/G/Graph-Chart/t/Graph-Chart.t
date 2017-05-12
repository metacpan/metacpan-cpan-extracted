# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### Tests load

BEGIN { $| = 1; print "1..8\n"; }
END { print "not ok 1\n" unless $loaded; }
use lib "./lib";
use Graph::Chart;
$loaded = 1;
print "ok 1\n";

#########################

########################## Test basic
my $graph = Graph::Chart->new(
    size     => [ 800, 400 ],
    bg_color => '0x00fff0',
    frame => { color => '0xff00ff', thickness => 1 },
    border => [ 150, 80, 100, 100 ],
    grid   => {
        debord => [ 5, 20, 10, 30 ],
        x      => {
            color => '0x0000f0',

            number => 10,
            type   => 'log',
            y      => {
                color     => '0x00fff0',
                number    => 8,
                thickness => 1,
            }
        },
    }
);

print( ( $graph->{ size }[0] == 800 && $graph->{ size }[1] == 400 && scalar keys %{ $graph } == 6 )
    ? "ok 2\n"
    : "not ok 2\n" );

########################## Test render
my $result1 = $graph->render;
print( $result1 =~ /^.PNG/ ? "ok 3\n" : "not ok 3\n" );
##########################

########################## Test frame

my $result2 = $graph->frame( { color => '0x0000ff', thickness => 1 } );
print( $graph->{ frame }{ color } eq '0000ff00' ? "ok 4\n" : "not ok 4\n" );
##########################

########################## Test data
my @dot;

for my $ind ( 0 .. 600 )
{
    $dot[$ind] = exp( $ind );
}

my $result3 = $graph->data(
    {
        layer    => 4,
        set      => \@dot,
        type     => 'line',
        bar_size => 1,
#        color     => '0x00ff00',
        color => [
            '0xff0000', '0xff0000', '0xff0000', '0xff0000',
            '0x00ff00', '0x00ff00', '0x00ff00', 'gdTransparent',
            'gdTransparent'
        ],
        thickness => 1,
        scale     => 'log',
    }
);
print( scalar( @{ ( $graph->{ data } )->[4]->{ set } } ) == 601 ? "ok 5\n" : "** not ok 5 \n" );
##########################

########################## Test glyph
my $result4 = $graph->glyph(
    {
        x     => 'active_min',
        y     => 'active_max',
        type  => 'filled',
        color => '0x00FFff',
        data  => [ [ 0, 0 ], [ 8, 10 ], [ 0, 10 ], [ 0, 10 + 20 ], [ 0, 10 ], [ -8, 10 ], [ 0, 0 ] ]
    }
);

print( scalar( keys %{ $result4->[0] } ) == 5 ? "ok 6\n" : "** not ok 6 \n" );
##########################

########################## Test text
my $result5 = $graph->glyph(
    {
        x     => 100,
        y     => 'active_max',
        type  => 'text',
        color => 0xff0000,
        size  => 12,
        font  => '/usr/lib/cinelerra/fonts/lucon.ttf',
        data  => [ [ 'hello world', 0, 0, 30 ], [ 'hello universe', 100, 0 ], ],

    }
);

print( scalar( keys %{ $result5->[1] } ) == 7 ? "ok 7\n" : "** not ok 7 \n" );
##########################

########################## Test reduce
my @dot1;
for my $ind ( 0 .. 800 )
{
    $dot1[$ind] = $ind;
}

my ( $dot_reduced, $stats ) = $graph->reduce(
    {
        data  => \@dot1,
        start => 50,
        end   => 360,
        init  => 300
    }
);

print(
    (
             $stats->{ avg } == 400
          && $stats->{ max } == 800
          && $stats->{ sum } == 320400
          && $dot_reduced->[1] == 300
          && $dot_reduced->[180] == 335
          && $dot_reduced->[360] == 798.5
    ) ? "ok 8\n" : "** not ok 8 \n"
);

##########################

