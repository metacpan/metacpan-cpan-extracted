package Graph::Timeline::GD;

use strict;
use warnings;

use GD;
use GD::Text::Wrap;

use base 'Graph::Timeline';

our $VERSION = '1.5';

sub render {
    die "Timeline::GD->render() expected HASH as parameter" unless scalar(@_) % 2 == 1;

    my ( $self, %data ) = @_;

    %data = $self->_lowercase_keys(%data);
    $self->_valid_keys( 'render', \%data, (qw/border pixelsperday pixelspermonth pixelsperyear/) );
    $data{border} = 0 unless $data{border};

    # Validate the parameters

    my $counter = 0;
    $counter++ if $data{pixelsperday};
    $counter++ if $data{pixelspermonth};
    $counter++ if $data{pixelsperyear};

    if ( $counter == 0 ) {
        die "Timeline::GD->render() one of 'pixelsperday', 'pixelspermonth' or 'pixelsperyear' must be defined";
    }
    elsif ( $counter > 1 ) {
        die "Timeline::GD->render() only one of 'pixelsperday', 'pixelspermonth' or 'pixelsperyear' can be defined";
    }

    # Get the data to render

    my @pool = $self->data();

    die "Timeline::GD->render() there is no data to render" if scalar(@pool) == 2;

    my ( $start, $end ) = $self->_get_start_and_end(@pool);

    # Work out the width of a year in pixels

    my %years;
    my $image_width = 0;

    foreach my $year ( $start .. $end ) {
        $years{$year}->{year} = $year;
        $years{$year}->{days_in_year} = Date::Calc::Days_in_Year( $year, 12 );
        if ( $data{pixelsperday} ) {
            $years{$year}->{pixels_in_year} = $years{$year}->{days_in_year} * $data{pixelsperday};
        }
        elsif ( $data{pixelspermonth} ) {
            $years{$year}->{pixels_in_year} = 12 * $data{pixelspermonth};
        }
        else {
            $years{$year}->{pixels_in_year} = $data{pixelsperyear};
        }

        $image_width += $years{$year}->{pixels_in_year};

        $self->render_year( $years{$year} );
    }

    # Now we should build up the streams for the points and intervals

    my %intervals;
    my $sequence = 1;

    foreach my $record (@pool) {
        if ( $record->{type} eq 'interval' ) {
            my $done = 0;

            my $group = $record->{group};

            $record->{width}      = $self->_calculate_width( $record, 'start_start', 'end_end',   %years );
            $record->{width_pre}  = $self->_calculate_width( $record, 'start_start', 'start_end', %years );
            $record->{width_post} = $self->_calculate_width( $record, 'end_start',   'end_end',   %years );
            $self->render_interval($record);

            foreach my $stream ( @{ $intervals{$group} } ) {
                if ( $stream->[-1]->{end_end} lt $record->{start_start} ) {
                    push( @{$stream}, $record );
                    $done = 1;
                    last;
                }
            }

            push( @{ $intervals{$group} }, [$record] ) unless $done;
        }
        else {
            $record->{sequence} = $sequence++;
            $self->render_point($record);
            push( @{ $intervals{'--points--'}[0] }, $record );
        }
    }

    # Work out the full height of the image

    my $image_height = 0;

    # First the years

    my $max = 0;
    foreach my $year ( $start .. $end ) {
        die "Timeline::GD->render() key 'height' is not defined from render_year()" unless $years{$year}->{height};
        $max = $years{$year}->{height} if $years{$year}->{height} > $max;
    }
    $image_height += $max;

    # Then the intervals

    foreach my $group ( keys %intervals ) {
        foreach my $stream ( @{ $intervals{$group} } ) {
            $max = 0;
            foreach my $entry ( @{$stream} ) {
                die "Timeline::GD->render() key 'height' is not defined from render_" . $entry->{type} . "()" unless $entry->{height};
                $max = $entry->{height} if $entry->{height} > $max;
            }
            $image_height += $max;
        }
    }

    my $im = GD::Image->new( $image_width + ( 2 * $data{border} ), $image_height + ( 2 * $data{border} ) );
    my $white = $im->colorAllocate( 255, 255, 255 );

    my $ypointer = $data{border};

    # Render the big image, points first

    my $xpointer = $data{border};

    $max = 0;

    foreach my $entry ( @{ $intervals{'--points--'}[0] } ) {
        $max = $entry->{height};
        $xpointer = $data{border} + $self->_calc_start_x( $start, $entry->{start}, %years );
        $im->copy( $entry->{data}, $xpointer, $ypointer, 0, 0, $entry->{width}, $entry->{height} );
    }

    $ypointer += $max;

    # Render the big image, years next

    $xpointer = $data{border};

    foreach my $year ( $start .. $end ) {
        $im->copy( $years{$year}->{data}, $xpointer, $ypointer, 0, 0, $years{$year}->{pixels_in_year}, $years{$year}->{height} );
        $xpointer += $years{$year}->{pixels_in_year};
    }

    $ypointer += $years{$start}->{height};

    # Render the big image, intervals last

    foreach my $group ( sort keys %intervals ) {
        if ( $group ne '--points--' ) {
            foreach my $stream ( @{ $intervals{$group} } ) {
                $max = 0;
                foreach my $entry ( @{$stream} ) {
                    $max = $entry->{height} if $entry->{height} > $max;
                    $xpointer = $data{border} + $self->_calc_start_x( $start, $entry->{start_start}, %years );
                    $im->copy( $entry->{data}, $xpointer, $ypointer, 0, 0, $entry->{width}, $entry->{height} );
                }
                $ypointer += $max;
            }
        }
    }

    # Return the data

    return $im->png;
}

sub render_year {
    my ( $self, $year ) = @_;

    # height of a year

    $year->{height} = 15;

    # Create a year line

    my $im = GD::Image->new( $year->{pixels_in_year}, $year->{height} );
    my $base;

    if ( $year->{year} % 2 == 0 ) {
        $base = $im->colorAllocate( 255, 0, 0 );
    }
    else {
        $base = $im->colorAllocate( 0, 255, 0 );
    }

    my $ink = $im->colorAllocate( 255, 255, 255 );

    my $wrapbox = GD::Text::Wrap->new(
        $im,
        line_space => 4,
        color      => $ink,
        text       => $year->{year},
        align      => 'center',
    );

    $wrapbox->set_font(gdSmallFont);

    $wrapbox->draw( 0, 0 );

    $year->{data} = $im;
}

sub render_interval {
    my ( $self, $record ) = @_;

    # height of a year

    my $height = 30;

    # Create a year line

    my $im = GD::Image->new( $record->{width}, $height );
    my $base = $im->colorAllocate( 127, 127, 127 );
    my $ink  = $im->colorAllocate( 255, 255, 255 );
    my $edge = $im->colorAllocate( 180, 180, 180 );

    if ( $record->{width_pre} ) {
        $im->filledRectangle( 0, 0, $record->{width_pre} - 1, $height, $edge );
    }

    if ( $record->{width_post} ) {
        $im->filledRectangle( $record->{width} - $record->{width_post}, 0, $record->{width}, $height, $edge );
    }

    my $wrapbox = GD::Text::Wrap->new(
        $im,
        line_space => 4,
        color      => $ink,
        text       => $record->{label},
        align      => 'center',
    );

    $wrapbox->set_font(gdSmallFont);

    $wrapbox->draw( 0, 0 );

    $record->{data}   = $im;
    $record->{height} = $height;
}

sub render_point {
    my ( $self, $record ) = @_;

    # height and width of a point

    my $height = 30;
    my $width  = 100;

    my $im = GD::Image->new( $width, $height );
    my $base = $im->colorAllocate( 255, 255, 255 );
    my $ink  = $im->colorAllocate( 0,   0,   0 );

    $im->transparent($base);

    my $wrapbox = GD::Text::Wrap->new(
        $im,
        width      => ( $width - 2 ),
        height     => ( $height / 2 ),
        line_space => 4,
        color      => $ink,
        text       => $record->{label},
        align      => 'left',
    );

    $wrapbox->set_font(gdSmallFont);

    if ( $record->{sequence} % 2 == 1 ) {
        $wrapbox->draw( 2, 0 );
        $im->line( 0, 0, 0, $height, $ink );
    }
    else {
        $wrapbox->draw( 2, ( $height / 2 ) );
        $im->line( 0, ( $height / 2 ), 0, $height, $ink );
    }

    $record->{data}   = $im;
    $record->{height} = $height;
    $record->{width}  = $width;
}

sub _calculate_width {
    my ( $self, $record, $start, $end, %years ) = @_;

    return 0 if $record->{$start} eq $record->{$end};

    my ( $first_year, $first_month, $first_day ) = split( '[\/-]', ( split( 'T', $record->{$start} ) )[0] );
    my ( $last_year,  $last_month,  $last_day )  = split( '[\/-]', ( split( 'T', $record->{$end} ) )[0] );

    # Calculate pixel width

    my $width = 0;

    if ( $first_year eq $last_year ) {
        $width += ( $years{$first_year}->{pixels_in_year} / $years{$first_year}->{days_in_year} ) * ( Date::Calc::Delta_Days( $first_year, $first_month, $first_day, $last_year, $last_month, $last_day ) + 1 );
    }
    else {
        foreach my $year ( $first_year .. $last_year ) {
            if ( $year == $first_year ) {
                $width += ( $years{$year}->{pixels_in_year} / $years{$year}->{days_in_year} ) * ( Date::Calc::Delta_Days( $first_year, $first_month, $first_day, $first_year, '12', '31' ) + 1 );
            }
            elsif ( $year == $last_year ) {
                $width += ( $years{$year}->{pixels_in_year} / $years{$year}->{days_in_year} ) * ( Date::Calc::Delta_Days( $last_year, 1, 1, $last_year, $last_month, $last_day ) + 1 );
            }
            else {
                $width += $years{$year}->{pixels_in_year};
            }
        }
    }

    return int($width);
}

sub _calc_start_x {
    my ( $self, $start_graph, $start_interval, %years ) = @_;

    my ( $first_year, $first_month, $first_day ) = split( '[\/-]', ( split( 'T', $start_graph ) )[0] );
    my ( $last_year,  $last_month,  $last_day )  = split( '[\/-]', ( split( 'T', $start_interval ) )[0] );

    my $x = 0;

    foreach my $year ( $first_year .. $last_year ) {
        if ( $year != $last_year ) {
            $x += $years{$year}->{pixels_in_year};
        }
        else {
            $x += ( $years{$year}->{pixels_in_year} / $years{$year}->{days_in_year} ) * ( Date::Calc::Delta_Days( $last_year, 1, 1, $last_year, $last_month, $last_day ) + 1 );
        }
    }

    return $x;
}

sub _get_start_and_end {
    my ( $self, @pool ) = @_;

    my $start = $pool[0]->{start};
    my $end   = $pool[0]->{end};

    foreach my $record (@pool) {
        $end = $record->{end} if $record->{end} gt $end;
    }

    $start = ( split( '[\/-]', $start ) )[0];
    $end   = ( split( '[\/-]', $end ) )[0];

    return $start, $end;
}

1;

=head1 NAME

Graph::Timeline::GD - Render timeline data with GD

=head1 VERSION

This document refers to verion 1.5 of Graph::Timeline::GD, September 29, 2009

=head1 SYNOPSIS

This subclass produces the GD object of the timeline. The user has to subclass from this class if they want
a GD rendering of the timeline data. By overriding the render_year( ), render_point( ) and render_interval( ) 
methods the user can supply a less garish and more pleasing display.

  use Graph::Timeline::GD;

  my $x = Graph::Timeline::GD->new();

  while ( my $line = <> ) {
    chomp($line);

    my ( $label, $start, $end, $group ) = split ( ',', $line );
    if($end) {
      $x->add_interval( label => $label, start => $start, end => $end, group => $group );
    }
    else {
      $x->add_point( label => $label, start => $start, group => $group );
    }
  }

  $x->window(start=>'1900/01/01', end=>'1999/12/31');

  open(FILE, '>test.png');
  binmode(FILE);
  print FILE $x->render( border => 2, pixelsperyear => 35 );
  close(FILE);

All the user needs to do is create a package that subclasses Graph::Timeline::GD

  package MyTimeLine;

  use base Graph::Timeline::GD;

  sub render_year { ... }

  sub render_interval { ... }

  sub render point { ... }

  1;

The default methods in Graph::Timeline::GD will show you how to write your own methods and the timeline 
script in the examples directory will show you how read in data, set up the timeline and draw various 
graphs with it.

=head1 DESCRIPTION

=head2 Overview

Only three methods need to be overridden to create your own GD image of the data. 

=over 4

=item render_year( YEAR )

The years that form the axis of the graph are rendered by render_year( ). A scalar pointing to the data 
for the year to be rendered is passed to the method. All you have to do is create an image of the correct 
size and decorate it.

=item render_interval( RECORD )

To render an interval this method takes the record of the interval. RECORD is a pointer to a hash that 
contains the all the data you should require, the important ones are:

=over 4

=item width

This the width of the required image.

=item label

The label that came from the data.

=item group

The group that the interval belongs to.

=back

Additionally the following are also defined but you may have no need for them

=over 4

=item end, end_start, end_end, width_post

End is the end date as defined in the data, end_start and end_end define a subinterval that the end of the data occured in.
For example if the end date is 1980/12/15 then end, end_start and end_end will be the same and width_post will be 0. However
should the end date be an interval like 1980/12 (something during December 1980) then end_start will be 1980/12/01 and
end_end will be 1980/12/31. Width_post will contain the number of pixels that represent the width of the subinterval.

=item start, start_start, start_end, width_pre

The same subinterval messing about for the start date as for the end date (defined above).

=back

=item render_point( RECORD )

Just the same as render_interval but with the addition of the sequence data, as points are rendered they
are numbered sequentualy from 1.

=back 

=head2 Constructors and initialisation

=over 4

=item new( )

Inherited from Graph::Timeline

=back

=head2 Public methods

=over 4

=item render( HASH )

The method called to return the rendered image. This takes a hash of configuration options however only
one of the pixelsper* keys can be supplied (being as they are mutually exclusive) and border is optional.

=over 4

=item border

The number of pixels to use as a border around the graph.

=item pixelsperyear

The number of pixels the year will be rendered in

=item pixelspermonth

The number of pixels to render a month in, the number of pixels a year will be this value times twelve

=item pixelsperday

The number of pixels to render a day in, the number of pixels in a year will be calculated from this

=back

=item render_year( SCALAR )

Override this method to render a year.

=item render_interval( SCALAR )

Override this method to render an interval.

=item render_point( SCALAR )

Override this method to render a point.

=back

=head2 Private methods

=over 4

=item _calculate_width

A method to calculate the width in pixels of an interval

=item _calc_start_x

A method to calculate at what offset a year, interval or point should be placed in the final image

=item _get_start_and_end

A method to find the first and last date

=back

=head1 ENVIRONMENT

None

=head1 DIAGNOSTICS

=over 4

=item Timeline->new() takes no arguments

When the constructor is initialised it requires no arguments. This message is given if 
some arguments were supplied.

=item Timeline::GD->render() expected HASH as parameter

Render expects a hash and did not get one

=item Timeline::GD->render() one of 'pixelsperday', 'pixelspermonth' or 'pixelsperyear' must be defined

One of the required parameters needs to be defined

=item Timeline::GD->render() only one of 'pixelsperday', 'pixelspermonth' or 'pixelsperyear' can be defined

Only on parameter can be defined

=item Timeline::GD->render() key 'height' is not defined from render_year()

The method that renders the year has not set the height key, this is required

=item Timeline::GD->render() key 'height' is not defined from render_interval()

The method that renders an interval has not set the height key, this is required

=item Timeline::GD->render() there is no data to render

None of the input data got passed through the call to window()

=back

=head1 BUGS

None

=head1 FILES

See the timeline script in the examples directory

=head1 SEE ALSO

Graph::Timeline - The core timeline class

=head1 AUTHORS

Peter Hickman (peterhi@ntlworld.com)

=head1 COPYRIGHT

Copyright (c) 2003, Peter Hickman. All rights reserved.

This module is free software. It may be used, redistributed and/or 
modified under the same terms as Perl itself.
