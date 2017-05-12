package Image::WorldMap;
use strict;
use warnings;
use Carp;
use Image::Imlib2;
use Image::WorldMap::Label;
use vars qw($VERSION);
$VERSION = '0.15';

# Class method, creates a new map
sub new {
    my ( $class, $filename, $label ) = @_;

    my $self = {};

    my $image = Image::Imlib2->load($filename);
    if ( not defined $image ) {
        croak("Image::WorldMap: unable to load $filename");
        return;
    }
    my $w = $image->get_width;
    my $h = $image->get_height;
    $image->add_font_path("../");
    $image->add_font_path("examples/");

    $self->{IMAGE}  = $image;
    $self->{LABELS} = [];
    $self->{LABEL}  = $label;
    $self->{W}      = $w;
    $self->{H}      = $h;
    bless $self, $class;

    if ( defined $label ) {

        # Determine the label offset for the current font
        $image->load_font($label);
        my $testlabel
            = Image::WorldMap::Label->new( 0, 0,
            "This is a testy little label",
            $self->{IMAGE} );
        my ( $w, $h )
            = $testlabel->_boundingbox( $image,
            "This is a testy little label" );
        $Image::WorldMap::Label::YOFFSET = -int( $h / 2 );
        $Image::WorldMap::Label::XOFFSET = 4;
    }

    return $self;
}

sub add {
    my ( $self, $longitude, $latitude, $label, $dot_colour ) = @_;

    my ( $w, $h ) = ( $self->{W}, $self->{H} );
    $w /= 2;

    my $x = $longitude;
    my $y = $latitude;

    $x = $x * $w / 180;
    $y = $y * $h / 180;
    $y = -$y;
    $x += $w;
    $y += ( $h / 2 );

    #  print "Adding: $label at $longitude, $latitude ($x, $y)\n";

    # If we're not showing labels, delete the label
    undef $label unless $self->{LABEL};

    my $newlabel = Image::WorldMap::Label->new( int($x), int($y), $label,
        $self->{IMAGE}, $dot_colour );
    push @{ $self->{LABELS} }, $newlabel;
}

sub draw {
    my ( $self, $filename ) = @_;

    my $t_changes            = 0;
    my $t                    = 0.95;
    my $nlabels              = @{ $self->{LABELS} };
    my $changed              = 0;
    my $changed_successfully = 0;
    my $steps                = 0;

    my @labels   = ( @{ $self->{LABELS} } );
    my $overlaps = $self->_number_of_overlaps;

    #  warn "Initial overlaps: $overlaps\n";

    while (1) {

        last if $overlaps == 0;

        _fisher_yates_shuffle( \@labels );

        foreach my $l1 (@labels) {

            last if $overlaps == 0;

            my ( $l1x, $l1y, $l1w, $l1h )
                = ( $l1->{X}, $l1->{Y}, $l1->{LABELW}, $l1->{LABELH} );

            my ( $oldlabelx, $oldlabely ) = ( $l1->{LABELX}, $l1->{LABELY} );
            my $old_overlaps_single = $self->_number_of_overlaps_single($l1)
                || 0;
            my $mode = int( rand(8) );
            if ( $mode == 0 ) {

                # right
                $l1->{LABELX} = $l1x + $Image::WorldMap::Label::XOFFSET;
                $l1->{LABELY} = $l1y + $Image::WorldMap::Label::YOFFSET;
            } elsif ( $mode == 1 ) {

                # left
                $l1->{LABELX}
                    = $l1x - $l1w - $Image::WorldMap::Label::XOFFSET;
                $l1->{LABELY} = $l1y + $Image::WorldMap::Label::YOFFSET;
            } elsif ( $mode == 2 ) {

                # top
                $l1->{LABELX} = $l1x - $l1w / 2;
                $l1->{LABELY} = $l1y - $l1h;
            } elsif ( $mode == 3 ) {

                # bottom
                $l1->{LABELX} = $l1x - $l1w / 2;
                $l1->{LABELY} = $l1y;
            } elsif ( $mode == 4 ) {

                # top right
                $l1->{LABELX} = $l1x;
                $l1->{LABELY} = $l1y - $l1h;
            } elsif ( $mode == 5 ) {

                # top left
                $l1->{LABELX} = $l1x - $l1w;
                $l1->{LABELY} = $l1y - $l1h;
            } elsif ( $mode == 6 ) {

                # bottom right
                $l1->{LABELX} = $l1x;
                $l1->{LABELY} = $l1y;
            } elsif ( $mode == 7 ) {

                # bottom left
                $l1->{LABELX} = $l1x - $l1w;
                $l1->{LABELY} = $l1y;
            }

            my $overlaps_single = $self->_number_of_overlaps_single($l1) || 0;
            my $de = $overlaps_single - $old_overlaps_single;

            $steps++;

            if ( $de <= 0 ) {
                if ( $de == 0 ) {
                } else {
                    $changed_successfully++;
                    $changed++;

                    #	  warn "  Moved " . $l1->{TEXT} . " $de\n";
                }
                $overlaps += $overlaps_single - $old_overlaps_single;
            } elsif ( $de > 0 ) {
                my $p = 1 - exp( -$de / $t );

                #	warn "T $t, p $p\n";
                if ( rand(1) < $p ) {

                    # move label back
                    $l1->{LABELX} = $oldlabelx;
                    $l1->{LABELY} = $oldlabely;
                } else {

                    #	  warn "  Moved " . $l1->{TEXT} . " $de (worse)\n";
                    $changed++;
                    $overlaps += $overlaps_single - $old_overlaps_single;
                }
            }
        }

        #    warn "Overlaps: $overlaps\n";

        if ( $steps > $nlabels * 20 && $changed == 0 ) {

            #      warn "No changes\n";
            last;
        }

        if (   $changed_successfully > $nlabels * 5
            || $changed > $nlabels * 20 )
        {
            $t *= 0.9;
            $t_changes++;
            $changed              = 0;
            $changed_successfully = 0;
            $steps                = 0;

            #      warn "T $t, overlaps $overlaps\n";
        }
        last if $t_changes == 50;
    }

    my $image = $self->{IMAGE};

    # Grey out label background
    #  foreach my $l1 (@{$self->{LABELS}}) {
    #    my($l1x, $l1y, $l1w, $l1h) =
    #      ($l1->labelx, $l1->labely, $l1->labelwidth, $l1->labelheight);
    #    $image->set_color(255, 255, 255, 32);
    #    $image->fill_rectangle($l1x, $l1y, $l1w, $l1h);
    #  }
    map { $_->draw_dot($image) } @{ $self->{LABELS} };
    map { $_->draw_label($image) } @{ $self->{LABELS} };

    $image->save($filename);
}

sub _draw_oldish {
    my ( $self, $filename ) = @_;

    my @labels   = ( @{ $self->{LABELS} } );
    my $overlaps = $self->_number_of_overlaps;

    foreach ( 1 .. 20 ) {
        foreach my $l1 (@labels) {
            my ( $l1x, $l1y, $l1w, $l1h )
                = ( $l1->{X}, $l1->{Y}, $l1->{LABELW}, $l1->{LABELH} );

            my ( $oldlabelx, $oldlabely ) = ( $l1->{LABELX}, $l1->{LABELY} );
            my $old_overlaps_single = $self->_number_of_overlaps_single($l1);
            my $mode                = int( rand(4) );
            if ( $mode == 0 ) {
                $l1->{LABELX} = $l1x + $Image::WorldMap::Label::XOFFSET;
                $l1->{LABELY} = $l1y + $Image::WorldMap::Label::YOFFSET;
            } elsif ( $mode == 1 ) {
                $l1->{LABELX}
                    = $l1x - $l1w - $Image::WorldMap::Label::XOFFSET;
                $l1->{LABELY} = $l1y + $Image::WorldMap::Label::YOFFSET;
            } elsif ( $mode == 2 ) {
                $l1->{LABELX} = $l1x - $l1w / 2;
                $l1->{LABELY} = $l1y - $l1h;
            } elsif ( $mode == 3 ) {
                $l1->{LABELX} = $l1x - $l1w / 2;
                $l1->{LABELY} = $l1y;
            }

            my $overlaps_single = $self->_number_of_overlaps_single($l1);
            if ( $overlaps_single > $old_overlaps_single ) {
                $l1->{LABELX} = $oldlabelx;
                $l1->{LABELY} = $oldlabely;
            } else {
                $overlaps += $overlaps_single - $old_overlaps_single;
            }
        }

        warn "Overlaps: $overlaps\n";
        last if $overlaps == 0;
    }

    my $image = $self->{IMAGE};

    #  foreach my $l1 (@{$self->{LABELS}}) {
    #    my($l1x, $l1y, $l1w, $l1h) =
    #      ($l1->labelx, $l1->labely, $l1->labelwidth, $l1->labelheight);
    #    $image->set_color(255, 255, 255, 32);
    #    $image->fill_rectangle($l1x, $l1y, $l1w, $l1h);
    #  }
    map { $_->draw_dot($image) } @{ $self->{LABELS} };
    map { $_->draw_label($image) } @{ $self->{LABELS} };

    $image->save($filename);
}

sub _number_of_overlaps_single {
    my ( $self, $l1 ) = @_;

    my $overlaps = 0;
    my @labels   = ( @{ $self->{LABELS} } );

    my $l1text = $l1->{TEXT};
    my ( $l1x, $l1y, $l1w, $l1h )
        = ( $l1->{LABELX}, $l1->{LABELY}, $l1->{LABELW}, $l1->{LABELH} );
    return unless $l1text;
    foreach my $l2 (@labels) {
        next if $l1 eq $l2;
        my $l2text = $l2->{TEXT};
        next unless $l2text;

        #      warn "Comparing $l1text against $l2text...\n";
        my ( $l2x, $l2y, $l2w, $l2h )
            = ( $l2->{LABELX}, $l2->{LABELY}, $l2->{LABELW}, $l2->{LABELH} );
        my $x = $l1x > $l2x ? $l1x : $l2x;
        my $y = $l1y > $l2y ? $l1y : $l2y;
        my $w
            = ( $l1x + $l1w < $l2x + $l2w ? $l1x + $l1w : $l2x + $l2w ) - $x;
        my $h
            = ( $l1y + $l1h < $l2y + $l2h ? $l1y + $l1h : $l2y + $l2h ) - $y;
        if ( $w > 0 && $h > 0 ) {
            $overlaps++;
        }
    }
    return $overlaps;
}

sub _number_of_overlaps {
    my ($self) = @_;
    my %seen;

    my $overlaps = 0;
    my @labels   = ( @{ $self->{LABELS} } );

    foreach my $l1 (@labels) {
        my ( $l1x, $l1y, $l1w, $l1h, $l1text ) = (
            $l1->{LABELX}, $l1->{LABELY}, $l1->{LABELW},
            $l1->{LABELH}, $l1->{TEXT}
        );
        next unless $l1text;
        foreach my $l2 (@labels) {
            next if $seen{$l1}{$l2}++;
            next if $seen{$l2}{$l1}++;
            next if $l1 eq $l2;
            my $l2text = $l2->{TEXT};
            next unless $l2text;

            #      warn "Comparing $l1text against $l2text...\n";
            my ( $l2x, $l2y, $l2w, $l2h )
                = ( $l2->{LABELX}, $l2->{LABELY}, $l2->{LABELW},
                $l2->{LABELH} );
            my $x = $l1x > $l2x ? $l1x : $l2x;
            my $y = $l1y > $l2y ? $l1y : $l2y;
            my $w = ( $l1x + $l1w < $l2x + $l2w ? $l1x + $l1w : $l2x + $l2w )
                - $x;
            my $h = ( $l1y + $l1h < $l2y + $l2h ? $l1y + $l1h : $l2y + $l2h )
                - $y;

            #      warn "Overlap: $w x $h\n";
            if ( $w > 0 && $h > 0 ) {

                #        warn "Overlaps!\n";
                $overlaps++;
            }

        }
    }
    return $overlaps;
}

# fisher_yates_shuffle( \@array ) :
# generate a random permutation of @array in place
sub _fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ( $i = @$array; --$i; ) {
        my $j = int rand( $i + 1 );
        @$array[ $i, $j ] = @$array[ $j, $i ];
    }
}

__END__

=head1 NAME

Image::WorldMap - Create graphical world maps of data

=head1 SYNOPSIS

  use Image::WorldMap;
  my $map = Image::WorldMap->new("earth-small.png", "maian/8");
  $map->add(4.91, 52.35, "Amsterdam.pm");
  $map->add(-2.355399, 51.3828, "Bath.pm");
  $map->add(-0.093999, 51.3627, "Croydon.pm");
  $map->draw("test.png");

=head1 DESCRIPTION

This module helps create graphical world maps of data, such as the
Perl Monger World Map (http://www.astray.com/Bath.pm/). This module
takes in a number of label locations (longitude/latitude) and outputs
an image. It can attach text to the labels, and tries to make sure
that labels do not overlap.

It is intended to be used to create images of information such as
"where are all the Perl Monger groups?", "where in the world are all
the CPAN mirrors?" and so on.

This module comes with a low-resolution image of the world. Additional
larger images have not been bundled with the module due to their size,
but are available at: http://www.astray.com/WorldMap/

=cut

=head1 METHODS

=head2 new

The constructor. It takes two mandatory arguments, the filename of the
image of the earth used for the background, and whether or not to
display labels.

The label option is actually a font size and name. You must have a
local truetype font in your directory. The font name format is
"font_name/size". For example. If there is a font file called
cinema.ttf somewhere in the font path you might use "cinema/20" to
load a 20 pixel sized font of cinema.

  # Without labels
  my $map = Image::WorldMap->new("earth-small.png");

  # With labels
  my $map = Image::WorldMap->new("earth-small.png", "maian/8");

=head2 add

This adds a node to the map, with an optional label. Longitude and
latitude are given as a decimal, with (0, 0) representing a point on
the Greenwich meridian and the equator and (-180, -180) top-left and
(180, 180) bottom-right on a projection of the Earth.

  $map->add(-2.355399, 51.3828, "Bath.pm");

You can also add a colour as a red, green, blue triple. For example,
to make the Bath.pm dot orange, you could do:

  $map->add(-2.355399, 51.3828, "Bath.pm", [255,127,0]);

=head2 draw

This draws the map and writes it out to a file. The file format is
chosen from the filename, but is typically PNG.

  $map->draw("text.png");

=head1 NOTES

This module tries hard to make sure that labels do not overlap. This
is an NP-hard problem. It currently uses a simulated annealing method
with some optimisations. It could be faster still.

The label positioning method used is random: if you run the program
again, you will get a different set of label positions, which may or
may not be better.

The images produced by this module are quite large, as they contain
lots of colour information. You should probably reduce the size
somehow (such as using the Gimp to convert it to use indexed colours)
before using the image on the web.

=head1 COPYRIGHT

Copyright (C) 2001-2, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Leon Brocard, acme@astray.com
