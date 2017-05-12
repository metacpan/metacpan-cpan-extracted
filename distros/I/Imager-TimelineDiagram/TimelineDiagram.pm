package Imager::TimelineDiagram;

use 5.00503;
use strict;
use vars qw($VERSION);
use Imager;
use Imager::Fill;
use Imager::Color;
use Carp;

$VERSION = '0.15';

# create object
sub new {
    my ($class,@args) = @_;
    if (scalar(@args)%2 != 0) {
        carp("Invalid arguments. No in name/value pair format.");
        return(undef);
    }

    my %hashObject = (
        imageHeight => 440,
        imageWidth => 440,

        gridWidth => 401,
        gridHeight => 401,
        gridSpacing => 10,
        gridXOffset => 20,
        gridYOffset => 10,
        gridColor => Imager::Color->new(200,200,200),

        dataColor => Imager::Color->new(255,100,100),
        dataFormat => '%0.2f', # sprintf() format string
        dataLabelSide => 'right',
        showArrowheads => 1,

        labelColor => Imager::Color->new(0,0,0),
        labelSize => 12,
        labelFont => Imager::Font->new(file => 'ImUgly.ttf'),
    );

    my %hash = @args;
    for (keys %hash) {
        $hashObject{$_} = $hash{$_};
    }

    if (! defined($hashObject{'labelFont'})) {
        carp("Failed to load labelFont specified.");
        return(undef);
    }

    $hashObject{_image} = Imager->new(xsize => $hashObject{'imageWidth'},
                                      ysize => $hashObject{'imageHeight'},
                                      channels => 4);

    if (! defined($hashObject{'_image'})) {
        carp("Failed to create new Imager object : $!");
        return(undef);
    }

    my $self = bless(\%hashObject,$class||__PACKAGE__);
}

# set list of milestones.
sub set_milestones {
    my ($self,@milestones) = @_;
    $self->{_legend} = [@milestones];
} 

# and AoA of :
#   @array = (
#     ['processFrom','processTo','time'],
#     .
#     .
#     .
#   )
# time being units from start of timeline
sub add_points {
    my ($self,@aoa) = @_;
    $self->{_data} = [@aoa];
} 

# write out to disk/stdout
# but first, this is where the magic happens
sub write {
    my ($self,$file) = @_;
    $self->_draw_grid();
    $self->_draw_data();
    $self->{'_image'}->write(file => $file);
}



######## internal functions #######

# draw the grid and labels
sub _draw_grid { 
    my ($self) = @_;
    my $image = $self->{_image};

    my @v_lines;
    my @points = @{ $self->{_legend} };

    # for every $gridSpacing pixes across, draw a vertical line
    for (my $i=$self->{'gridXOffset'}; $i <= $self->{'gridWidth'} ;$i += $self->{'gridSpacing'}) {
        $image->line(color => $self->{'gridColor'}, x1 => $i, y1 => $self->{'gridYOffset'},
                                          x2 => $i, y2 => $self->{'gridYOffset'}+$self->{'gridHeight'});
        push(@v_lines,$i);
    }

    # for every $gridSpacing pixes across, draw a horizontal line
    for (my $i=$self->{'gridYOffset'}; $i < $self->{'gridYOffset'}+$self->{'gridHeight'} ;$i += $self->{'gridSpacing'}) {
        $image->line(color => $self->{'gridColor'}, x1 => $self->{'gridXOffset'}, y1 => $i,
                                          x2 => $self->{'gridWidth'}, y2 => $i);
    }

    # Logic Time:
    # There are scalar(@v_lines) rows in the grid.
    # There are scalar(@points) connection point.
    $self->{'px_per_point'} = int( scalar(@v_lines) / (scalar(@points)-1) ) * $self->{'gridSpacing'};
    my $current_px = $self->{'gridXOffset'};
    for (my $pn=0;$pn < scalar(@points);$pn++) {
        if ($current_px > $v_lines[-1]) {
            $current_px = $v_lines[-1];
        }
        $image->box(color => Imager::Color->new(0,0,0),
                xmin => $current_px-1, ymin => $self->{'gridYOffset'},
                xmax => $current_px+1, ymax => $self->{'gridHeight'}+$self->{'gridYOffset'},
                filled => 1
                );
        my @bbox = $self->{'labelFont'}->bounding_box(string => $points[$pn]);
        $image->string(font => $self->{'labelFont'},
                       text => $points[$pn],
                       x => $current_px-(($bbox[2]-$bbox[0])/2),   # current line/2
                       y => $self->{'gridYOffset'}+$self->{'gridHeight'}+($bbox[3]),                # grid + letter height
                       size => $self->{'labelSize'},
                       color => $self->{'labelColor'}
                      );
        $self->{_label_to_x_offset}{$points[$pn]} = $current_px;
        $current_px += $self->{'px_per_point'};
    }

    $image->string(
                  font => $self->{'labelFont'},
                  size => $self->{'labelSize'},
                  color => $self->{'labelColor'},
                  text => sprintf($self->{dataFormat},0),
                  x => $self->{'gridWidth'},
                  y => $self->{'gridYOffset'},
                  );
    $image->string(
                  font => $self->{'labelFont'},
                  size => $self->{'labelSize'},
                  color => $self->{'labelColor'},
                  text => sprintf($self->{dataFormat},($self->{'maxTime'} || $self->{_data}[-1][2])),
                  x => $self->{'gridWidth'},
                  y => $self->{'gridHeight'}+$self->{'gridYOffset'},
                  );
}

sub _draw_data {
    my ($self) = @_;
    if (! $self->{'px_per_point'}) {
        $self->_draw_grid();
    }
    my $image = $self->{'_image'};

    # ok, more logic :
    #   the grid is $self->{'gridHeight'} pixes high
    #   the highest scale needed is $self->{'maxTime'} || $self->{_data}[-1][2]
    #   there is no negative time, the scale begins at 0
    #   so ...
    #
    #   gridHeight/maxTime pixels per second

    my $px_per_sec = ($self->{'gridHeight'}/($self->{'maxTime'} || $self->{_data}[-1][2]));
    foreach my $aref (@{ $self->{_data} }) {
        my $from = $aref->[0];
        my $to   = $aref->[1];
        my $time = $aref->[2];
 
        my $fromX = $self->{_label_to_x_offset}{$from};
        my $toX   = $self->{_label_to_x_offset}{$to};
        my $timeY = $px_per_sec * $time;
       
        #print "[$fromX,$timeY] -> [$toX,$timeY]\n";
        $image->line(color => $self->{'dataColor'},
                     x1 => $fromX , y1 => $timeY,
                     x2 => $toX ,   y2 => $timeY,
                    );

        my $dlX;
        my @bbox = $self->{'labelFont'}->bounding_box(string => sprintf($self->{'dataFormat'},$time));
        my $dlY = $timeY;
        if ($self->{'dataLabelSide'} eq 'left') {
            $dlX = ( $fromX < $toX ? $fromX : $toX ) - 5 - ($bbox[2]-$bbox[0]);
        } else {
            $dlX = ( $fromX > $toX ? $fromX : $toX ) + 5;
        }
        $image->string(font => $self->{'labelFont'},
                       size => $self->{'labelSize'},
                       color => $self->{'labelColor'},
                       text => sprintf($self->{'dataFormat'},$time),
                       x => $dlX,
                       y => $dlY,
                      );

        if ($self->{'showArrowheads'}) {
            my ($ahBkX,$ahBkY1,$ahBkY2);
            if ($toX > $fromX) {
                $ahBkX = $toX-3;
            } else {
                $ahBkX = $toX+3;
            }
            $ahBkY1 = $timeY-2;
            $ahBkY2 = $timeY+2;
            # ploygon's are anti-aliased ... and that core's my Imager :(
            #$image->polygon(x => [$toX,$ahBkX,$ahBkX],y => [$timeY,$ahBkY1,$ahBkY2],color => $self->{'dataColor'});
            $image->polyline(x => [$toX,$ahBkX,$ahBkX,$toX],y => [$timeY,$ahBkY1,$ahBkY2,$timeY],color => $self->{'dataColor'});
        }
    }
}

1;
__END__

=head1 NAME

Imager::TimelineDiagram - Perl extension for creating Timeline Diagrams (designed to show system interaction over time)

=head1 SYNOPSIS

  use Imager::TimelineDiagram;
  use Imager::Font;

  my $tg = Imager::TimelineDiagram->new(
                                      #maxTime => 10,
                                      #dataLabelSide => 'left',
                                      labelFont => Imager::Font->new(file => 't/ImUgly.ttf'),
                                     );

  $tg->set_milestones(qw(A B C D E));

  my @points = (
     # From, To, AtTime
     ['A','B',1.0],
     ['B','C',2.0],
     ['C','D',3.3],
     ['D','C',4.3],
     ['C','A',5.0],
  );

  $tg->add_points(@points);

  $tg->write('foo.png');

=head1 ABSTRACT

  Module for creating Timeline Diagrams.

=head1 DESCRIPTION

Module for creating Timeline Diagrams. 

=head2 OPTIONS

=over 6
=item new

  Create a new object. Returns undef on error. Takes the following options (listed with defaults) :
    imageHeight => 440,
    imageWidth => 440,

    gridWidth => 401,
    gridHeight => 401,
    gridSpacing => 10,
    gridXOffset => 20,
    gridYOffset => 10,
    gridColor => Imager::Color->new(200,200,200),  # grey

    dataColor => Imager::Color->new(255,100,100),  # red-ish
    dataFormat => '%0.2f', # sprintf() format string
    dataLabelSide => 'right',
    showArrowheads => 1,

    labelColor => Imager::Color->new(0,0,0),
    labelSize => 12,
    labelFont => Imager::Font->new(file => 'ImUgly.ttf'),

=item set_milestones

  Set the names of the stop-lines on the diagram. In the original usage these represented processes and the module was used to show the message processing time.

=item add_points

  Add the data. This method takes an array of arrays with data in the form of :

   @array = (
     ['processFrom','processTo','time'],
     .
     .
     .
   )

  Where the 'time' is the amount of time since the beginig of the timeline. (So, it should be greater than all previoud values)

=item write

  This method takes a single argument of file name and outputs the image. The format of the image is decided by the file extention using Imager's internal logic.

=back

=head2 EXPORT

None by default.

=head2 TODO

If you have the time to spend, feel free to work on these and send me patches.

=over 6

=item  * Add ability to pass DateTime objects in add_points

=item  * Make the module auto-populate the milestones if not provided

=item  * Provide API access to Imager object

=item  * Add more formatting options.

=back

=head1 HISTORY

=over 8

=item 0.15

Documentation added (pod).

=item 0.10

Original version


=back


=head1 SEE ALSO

perl, Imager

=head1 AUTHOR

Matt Sanford <mzsanford@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Matt Sanford

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
