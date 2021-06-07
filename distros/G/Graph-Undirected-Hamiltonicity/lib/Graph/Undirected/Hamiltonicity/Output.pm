package Graph::Undirected::Hamiltonicity::Output;

use Modern::Perl;
use Carp;
use Exporter qw(import);

our @EXPORT_OK = qw(
    &output
    &output_graph_svg
    &output_image_svg
    &output_adjacency_matrix_svg
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK, );

our $VERSION = '0.01';

##############################################################################

sub output {
    my ($input) = @_;

    my $format = $ENV{HC_OUTPUT_FORMAT} || 'none';

    return if $format eq 'none';

    if ( $format eq 'html' ) {
        if ( ref $input ) {
            output_image_svg(@_);
        } else {
            say $input;
        }

    } elsif ( $format eq 'text' ) {
        if ( ref $input ) {
            ### Print the graph's edge-list as a string.
            say "$input";
        } else {
            ### Strip out HTML
            $input =~ s@<LI>@* @gi;
            $input =~ s@<BR/>@@gi;
            $input =~ s@</?(LI|UL|OL|CODE|TT|PRE|H[1-6])>@@gi;
            $input =~ s@<HR[^>]*?>@=================@gi;
            say $input;
        }
    } else {
        croak "Environment variable HC_OUTPUT_FORMAT should be "
            . "one of: 'html', 'text', or 'none'\n";
    }

}

##########################################################################

sub output_image_svg {
    my ( $g, $hash_ref ) = @_;

    my %params = %{ $hash_ref // {} };
    my $image_size = $params{size} || 600;

    say qq{<div style="height: 600px; width: 1000px;">};

    ### Output image
    say qq{<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="100%" height="100%" version="1.1"
xmlns="http://www.w3.org/2000/svg">
};

    output_graph_svg( $g, { %params, image_size => $image_size } );
    if ( $g->vertices() <= 12 ) {
        output_adjacency_matrix_svg( $g,
            { %params, image_size => $image_size } );
    }
    say qq{</svg>};
    say qq{</div>\n};
}

##########################################################################

sub output_graph_svg {
    my ( $g, $hash_ref ) = @_;

    my %params = %{ $hash_ref // {} };

    my $Pi = 4 * atan2 1, 1;
    my $v = scalar( $g->vertices() );

    ### Compute angle between vertices
    my $angle_between_vertices = 2 * $Pi / $v;

    my $image_size = $params{size} || 600;

    ### Compute Center of image
    my $x_center = $image_size / 2;
    my $y_center = $x_center;
    my $border   = int( $image_size / 25 );    ### cellpadding in the image

    ### Compute vertex coordinates
    my $radius   = ( $image_size / 2 ) - $border;
    my $angle    = $Pi * ( 0.5 - ( 1 / $v ) );
    my @vertices = $g->vertices();

    @vertices = sort { $a <=> $b } @vertices;
    my $text_xml     = '';
    my $vertices_xml = '';
    my @vertex_coordinates;
    ### Draw vertices ( and include text labels )
    for my $vertex (@vertices) {

        my $x = ( $radius * cos($angle) ) + $x_center;
        my $y = ( $radius * sin($angle) ) + $y_center;

        $vertices_xml .= qq{<circle cx="$x" cy="$y" id="$vertex" r="10" />\n};
        $text_xml     .= q{<text x="};
        $text_xml     .= $x - ( length("$vertex") == 1 ? 4 : 8 );
        $text_xml     .= q{" y="};
        $text_xml     .= $y + 5;
        $text_xml     .= qq{">$vertex</text>\n};

        $vertex_coordinates[$vertex] = [ $x, $y ];
        $angle += $angle_between_vertices;
    }

    my $edges_xml = '';
    ### Draw edges
    foreach my $edge_ref ( $g->edges() ) {
        my ( $orig, $dest ) = @$edge_ref;

        if ( $orig > $dest ) {
            my $temp = $orig;
            $orig = $dest;
            $dest = $temp;
        }

        my $required = $params{required}
            || $g->get_edge_attribute( $orig, $dest, 'required' );

        my $override_attrs = "";
        if ( $required ) {
            $override_attrs = qq{ stroke-width="3" stroke="#FF0000" };
        }

        $edges_xml .= qq{<line id="${orig}_${dest}};
        $edges_xml .= q{" x1="};
        $edges_xml .= $vertex_coordinates[$orig]->[0];
        $edges_xml .= q{" y1="};
        $edges_xml .= $vertex_coordinates[$orig]->[1];
        $edges_xml .= q{" x2="};
        $edges_xml .= $vertex_coordinates[$dest]->[0];
        $edges_xml .= q{" y2="};
        $edges_xml .= $vertex_coordinates[$dest]->[1];
        $edges_xml .= qq{"$override_attrs />};
        $edges_xml .= "\n";
    }

    ### Output image
    say qq{<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="100%" height="100%" version="1.1"
xmlns="http://www.w3.org/2000/svg">

<g id="edges" style="opacity:1; stroke: black; stroke-opacity: 1; stroke-width: 1 ">
$edges_xml</g>

<g id="vertices"
 style="opacity: 1; fill: blue; fill-opacity: 1; stroke: black; stroke-opacity: 1">
$vertices_xml</g>

<g id="text_labels"
 style="opacity: 1; fill: lightgreen; fill-opacity: 1; stroke: lightgreen; stroke-opacity: 1">

$text_xml</g>

};

}

##########################################################################

sub output_adjacency_matrix_svg {

    my ( $g, $hash_ref ) = @_;

    my %params = %{ $hash_ref // {} };

    say qq{<?xml version="1.0" standalone="no"?>};
    say qq{<g style="opacity:1; stroke: black; stroke-opacity: 1">};

    my $square_size = 30;
    my @vertices = sort { $a <=> $b } $g->vertices();

    my $image_size = $params{image_size} || 600;

    my $x_init = $image_size + 60;
    my $y_init = $image_size - $square_size * scalar(@vertices);

    my $x       = $x_init;
    my $y       = $y_init;
    my $counter = 0;

    foreach my $i (@vertices) {
        if ($counter) {
            print q{<text x="};
            print $x - 25;
            print q{" y="};
            print $y + $square_size - 10;
            print qq{">$i</text>\n};    ### vertex label
        }

        print q{<text x="};
        print $x + 10 + ( $square_size * $counter++ );
        print q{" y="};
        print $y + 20;
        print qq{">$i</text>\n};        ### vertex label

        foreach my $j (@vertices) {

            last if $i == $j;

            my $fill_color;
            if ( $g->has_edge( $i, $j ) ) {
                $fill_color =
                       $params{required}
                    || $g->get_edge_attribute( $i, $j, 'required' )
                    ? '#FF0000'
                    : '#000000';
            } else {
                $fill_color = '#FFFFFF';
            }
            print qq{<rect x="$x" y="$y" width="$square_size" };
            print qq{height="$square_size" fill="$fill_color" />\n};

            $x += $square_size;
        }
        $y += $square_size;
        $x = $x_init;
    }

    say qq{\n</g>};

}

##########################################################################

1;    # End of Graph::Undirected::Hamiltonicity::Output
