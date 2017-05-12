package Graph::Timeline::DiagonalGD;

use strict;
use warnings;

use GD;
use GD::Text::Wrap;

use base 'Graph::Timeline';

our $VERSION = '1.5';

sub render {
    die "Timeline::DiagonalGD->render() expected HASH as parameter" unless scalar(@_) % 2 == 1;

    my ( $self, %data ) = @_;

    %data = $self->_lowercase_keys(%data);
    $self->_valid_keys( 'render', \%data, (qw/border graph-width label-width colours/) );
    $data{border} = 0 unless $data{border};

    # Validate the parameters

    my $counter = 0;
    foreach my $key ( 'graph-width', 'label-width' ) {
        $counter++ if $data{$key};
    }

    if ( $counter != 2 ) {
        die "Timeline::DiagonalGD->render() 'graph-width' and 'label-width' must be defined";
    }

    # Get the data to render

    my @pool = sort { $a->{start_start} cmp $b->{start_start} } $self->data();

    die "Timeline::DiagonalGD->render() there is not enough data to render" if scalar(@pool) < 2;

    my $number_of_rows = scalar @pool;
    my $start_graph    = 0;
    my $end_graph      = 0;

    my $image_width = $data{'label-width'} + $data{'graph-width'} + ( $data{'border'} * 2 );
    my $image_height = ( $number_of_rows * 20 ) + ( $data{'border'} * 2 ) + 40;

    my $image = GD::Image->new( $image_width, $image_height );

    my $white = $image->colorAllocate( 255, 255, 255 );
    my $black = $image->colorAllocate( 0,   0,   0 );

    my $start_label = $pool[0]->{start_start};
    my $end_label   = '';
    foreach my $x (@pool) {
        my $start = $self->_calc_seconds( $pool[0]->{start_start}, $x->{start_start} );
        my $end   = $self->_calc_seconds( $pool[0]->{end_end},     $x->{end_end} );

        $end_graph = $end if $end > $end_graph;

        $x->{graph_start} = $start;
        $x->{graph_end}   = $end;

        $end_label = $x->{end_end} if $end_label lt $x->{end_end};
    }

    ##
    ## Setting up the title for the page
    ##

    my $wrapbox = GD::Text::Wrap->new(
        $image,
        width  => $data{'graph-width'},
        height => 20,
        color  => $black,
        text   => $self->_title_line( $start_label, $end_label ),
        align  => 'center',
    );

    $wrapbox->set_font(gdSmallFont);
    $wrapbox->draw( $data{border} + $data{'label-width'}, $data{border} + 2 );

    $wrapbox = GD::Text::Wrap->new(
        $image,
        width  => $data{'graph-width'},
        height => 20,
        color  => $black,
        text   => ( split( 'T', $start_label ) )[1],
        align  => 'left',
    );

    $wrapbox->set_font(gdSmallFont);
    $wrapbox->draw( $data{border} + $data{'label-width'}, $data{border} + 22 );

    $wrapbox = GD::Text::Wrap->new(
        $image,
        width  => $data{'graph-width'},
        height => 20,
        color  => $black,
        text   => ( split( 'T', $end_label ) )[1],
        align  => 'right',
    );

    $wrapbox->set_font(gdSmallFont);
    $wrapbox->draw( $data{border} + $data{'label-width'}, $data{border} + 22 );

    my $pos    = $data{border} + 40;
    my $offset = $data{border} + $data{'label-width'};

    my %colours;

    ##
    ## Rather than calculate this twice lets store the values as we go along
    ##

    my @map_line;
    my @map_box;

    foreach my $x (@pool) {
        next if $x->{type} eq 'marker';

        my $element_start = int( ( $x->{graph_start} / $end_graph ) * $data{'graph-width'} ) + $offset;
        my $element_end   = int( ( $x->{graph_end} / $end_graph ) * $data{'graph-width'} ) + $offset;

        $element_end = $element_start + 1 if $element_end <= $element_start;

        ##
        ## Set up the map elements
        ##

        if ( $x->{url} ) {
            push @map_line, $self->_map_line( $x->{url}, $data{border}, $pos, ( $image_width - $data{border} ), $pos + 19 );
            push @map_box, $self->_map_box( $x->{url}, $element_start, $pos, $element_end, $pos + 19, $image_width );
        }

        ##
        ## Select the colour to use
        ##

        unless ( defined( $colours{ $x->{label} } ) ) {
            if ( defined( $data{colours}{ $x->{label} } ) ) {
                $colours{ $x->{label} } = $image->colorAllocate( @{ $data{colours}{ $x->{label} } } );
            }
            else {
                $colours{ $x->{label} } = $black;
            }
        }
        my $colour = $colours{ $x->{label} };

        ##
        ## Draw the line
        ##

        $image->line( $offset, $pos, $element_start, $pos, $colour );
        $image->line( $offset, $pos + 20, $element_start, $pos + 20, $colour );

        ##
        ## Draw the box
        ##

        $image->filledRectangle( $element_start, $pos, $element_end, $pos + 20, $colour );

        ##
        ## Draw the label
        ##

        my $wrapbox = GD::Text::Wrap->new(
            $image,
            width  => $data{'label-width'},
            height => 20,
            color  => $colour,
            text   => $x->{id},
            align  => 'left',
        );

        $wrapbox->set_font(gdSmallFont);
        $wrapbox->draw( $data{border}, $pos + 2 );

        $pos += 20;
    }

    ##
    ## Store the maps for the later call
    ##

    $self->{map_line} = [@map_line];
    $self->{map_box}  = [@map_box];

    return $image->png;
}

sub map {
    my ( $self, $style, $name ) = @_;

    die "Timeline::DiagonalGD->map() The map requires a name" unless $name;

    my $text = "<map name=\"$name\">\n";

    if ( $style eq 'line' ) {
        foreach my $line ( @{ $self->{map_line} } ) {
            $text .= "    $line\n";
        }
    }
    elsif ( $style eq 'box' ) {
        foreach my $line ( @{ $self->{map_box} } ) {
            $text .= "    $line\n";
        }
    }
    else {
        die "Timeline::DiagonalGD->map() Unknown map style, use 'line' or 'box'";
    }

    $text .= "</map>\n";

    return $text;
}

sub _map_line {
    my ( $self, $url, $x1, $y1, $x2, $y2 ) = @_;

    return " <area shape=\"rect\" coords=\"$x1,$y1,$x2,$y2\" href=\"$url\" />";
}

sub _map_box {
    my ( $self, $url, $x1, $y1, $x2, $y2, $max_width ) = @_;

    my $new_x1 = $x1 - 5;
    my $new_x2 = $x2 + 5;

    $new_x2 = $max_width if $new_x2 > $max_width;

    return $self->_map_line( $url, $new_x1, $y1, $new_x2, $y2 );
}

sub _title_line {
    my ( $self, $start, $end ) = @_;

    my $start_date = ( split( 'T', $start ) )[0];
    my $end_date   = ( split( 'T', $end ) )[0];

    if ( $start_date eq $end_date ) {
        return $start_date;
    }
    else {
        return "$start_date to $end_date";
    }
}

sub _calc_seconds {
    my ( $self, $base, $date ) = @_;

    my ( $date_date, $date_time ) = split( 'T', $date );
    my ( $base_date, $base_time ) = split( 'T', $base );

    my ( $dyear, $dmonth,  $dday )    = split( '[\/-]', $date_date );
    my ( $dhour, $dminute, $dsecond ) = split( ':',  $date_time );
    my ( $byear, $bmonth,  $bday )    = split( '[\/-]', $base_date );
    my ( $bhour, $bminute, $bsecond ) = split( ':',  $base_time );

    my ( $D_y, $D_m, $D_d, $Dh, $Dm, $Ds ) = Date::Calc::Delta_YMDHMS( $byear, $bmonth, $bday, $bhour, $bminute, $bsecond, $dyear, $dmonth, $dday, $dhour, $dminute, $dsecond );

    if ( $D_y or $D_m ) {
        die "Timeline::DiagonalGD->render() Date range spans into months or years. No can do";
    }

    my $total = $Ds + ( 60 * $Dm ) + ( 60 * 60 * $Dh ) + ( 60 * 60 * 24 * $D_d );

    return $total;
}

1;

=head1 NAME

Graph::Timeline::DiagonalGD - Render timeline data with GD

=head1 VERSION

This document refers to verion 1.5 of Graph::Timeline::DiagonalGD, September 29, 2009

=head1 SYNOPSIS

This class is used to clear charts where earliest starting event is at the top of the page 
and the next event to start follows it (and so on). For each event a box is drawn relative
to the length of the event. You get something like this:

 first event      : XX
 second event     :  XXXXX
 third event      :    XX
 fourth event:    :     XXXXXX

Optionally a client side imagemap can be generated for the events that have a url defined.

An example of usage follows. Note that the labels down the left hand side are based on the
id attribute and the colour of the event box on the label.

 #!/usr/bin/perl

 use strict;
 use warnings;

 use Graph::Timeline::DiagonalGD;

 my $x = Graph::Timeline::DiagonalGD->new();

 while ( my $line = <> ) {
     chomp($line);

      next if $line =~ m/^\s*$/;
      next if $line =~ m/^\s*#/;
 
      my ( $id, $label, $start, $end, $url ) = split( ',', $line );
      $x->add_interval( label => $label, start => $start, end => $end, id => $id, url => $url );
 }

 my %render = (
   'graph-width' => 400,
   'label-width' => 150,
   'border'      => 10,
   'colours'     => {
      'Ended_Successfully' => [ 128, 128, 128 ],
      'Failed'             => [ 255, 0,   0 ]
   }
 );

 open( FILE, '>test_diagonal1.png' );
 binmode(FILE);
 print FILE $x->render(%render);
 close(FILE);

 open( FILE, '>test_diagonal1.map' );
 print FILE $x->map( 'box', 'image1' );
 close(FILE);

=head1 DESCRIPTION

Render a diagonal event graph based on the input data. 

=head2 Overview

The render method controls the display. This is inturn controlled by the parameters
that are passed in to it.

=head2 Constructors and initialisation

=over 4

=item new( )

Inherited from Graph::Timeline

=back

=head2 Public methods

=over 4

=item render( HASH )

The hight of the image created will be 20 pixels per event reported plus 40 pixels for the title, plus an
additional 2 * border. The width of the image will be 2 * border + label-width + graph-width.

=over 4

=item border

The number of pixels to use as a border around the graph. If omitted will be set to 0.

=item label-width

The number of pixels used to display the id of the event.

=item graph-width

The number of pixels within which the events will be drawn. 

=item colours

When an event is rendered the label is used as a key to this hash to return a list of values to use
for the colour for that event:

  'colours' => {
    'Ended_Successfully' => [ 128, 128, 128 ],
    'Failed'             => [ 255, 0,   0 ]
  }

The values are for the RGB triplet, if no value is supplied for a label the event will be draw 
in black.

=back

=item map( style, name )

Produce a client side imagemap for the data that has a url defined. 

=over 4

=item style

There are two styles available. 'line' or 'box'. For line the clickable area is the whole line
that the event occurs on. For box the clickable area is the box drawn for the event plus 5 pixels 
to the left and right.

=item name

This is the name that will be used for the imagemap

=back

=back

=head2 Private methods

=over 4

=item _calc_seconds

A method to calculate the duration of an event in seconds.

=item _title_line

The the events are within one day return just a day to use as the title, if they span more than
one day return a string 'start TO end' to display as the title.

=back

=head1 ENVIRONMENT

None

=head1 DIAGNOSTICS

=over 4

=item Timeline->new() takes no arguments

When the constructor is initialised it requires no arguments. This message is given if 
some arguments were supplied.

=item Timeline::DiagonalGD->render() expected HASH as parameter

Render expects a hash and did not get one

=item Timeline::DiagonalGD->render() 'graph-width' and 'label-width' must be defined

Both of these parameters must be defined.

=item Timeline::DiagonalGD->render() there is not enough data to render

None of the input data got passed through the call to window()

=item Timeline::DiagonalGD->render() Date range spans into months or years. No can do

It is assumed that the data will span, at best, a few days. More than that and we can't 
realy draw this graph.

=item Timeline::DiagonalGD->map() Unknown map style, use 'line' or 'box'

Maps come in type styles, 'line' or 'box'. You tried to use something else

=item Timeline::DiagonalGD->map() The map requires a name

You must supply a name for the map

=back

=head1 BUGS

None

=head1 FILES

See the diagonal script in the examples directory

=head1 SEE ALSO

Graph::Timeline - The core timeline class

=head1 AUTHORS

Peter Hickman (peterhi@ntlworld.com)

=head1 COPYRIGHT

Copyright (c) 2007, Peter Hickman. All rights reserved.

This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.
