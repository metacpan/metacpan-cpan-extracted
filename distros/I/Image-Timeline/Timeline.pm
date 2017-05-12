package Image::Timeline;

use strict;
use GD;

# Not a required module, but try to load at compile time
BEGIN {eval "use Date::Format"}

use vars qw($VERSION);
$VERSION = 0.11;

sub new {
  my ($pkg, %args) = @_;
  my $self = {
	      width => 900,
	      font => gdTinyFont,
	      bar_stepsize => 50,  # The gridsize for the top reference bar
	      vspacing => 2,
	      hmargin => 3,
	      bg_color => [255,255,255],
	      bar_color => [255,0,0],
	      endcap_color => [0,155,0],
	      legend_color => [0,0,0],
	      text_color => [0,0,0],
	      date_format => '',
	      to_string => sub { $_[0] },
	      right_margin => 0,
	      %args
	     };

  # subtract right_margin to width to avoid cutting last legend
  $self->{width} -= $self->{right_margin};
  return bless $self, $pkg;
}

sub add {
  my ($self, $label, $start, $end) = @_;
  
  $self->{data}{$label}{start} = $start;
  $self->{data}{$label}{end}   = $end;
}

sub write {
  my ($self, $format, $filename, @args) = @_;

  my $image = $self->draw;

  local *OUT;
  open OUT, ">$filename" or die "Can't create '$filename': $!";
  binmode(OUT);
  print OUT $image->$format(@args);
  close OUT;
}

sub write_png { my $s = shift; $s->write('png', @_) }
sub write_gif { my $s = shift; $s->write('gif', @_) }

sub _create_image {
  my ($self, $w, $h) = @_;
  my $image = GD::Image->new($w + $self->{right_margin},$h);

  # Allocate some colors
  foreach (qw(bg bar endcap legend text)) {
    $self->{colors}{$_} = $image->colorAllocate(@{$self->{"${_}_color"}});
  }
  $image->fill(0,0,$self->{colors}{bg});

  return $image;
}

sub _create_channels {
  my ($self) =  @_;
  
  my $data = $self->{data};
  my $channels = $self->{channels} = [];
  
  # Populate the channels
 LOOP: foreach my $label (sort {$data->{$a}{'start'} <=> $data->{$b}{'start'}} keys %$data) {
    #warn "Inserting '$label'";
    # Check each channel to find an empty space:
    foreach my $channel (@$channels) {
      if ($self->_channel_is_free($channel, $data->{$label}{'start'})) {
	$self->_add_to_channel($channel, $label);
	#warn "Adding '$label' to existing channel $channel";
	next LOOP;
      }
    }
    
    # All channels are full for this start-time.  Make a new channel.
    push @$channels, my $new = {};
    $self->_add_to_channel($new, $label);
    #warn "Adding '$label' to new channel";
  }
}

sub _minmax {
  # Find min & max dates
  my ($self) = @_;
  return ($self->{min}, $self->{max}) if exists $self->{min};

  my ($min,$max) = map {$_->{start}, $_->{end}} (each %{$self->{channels}[0]})[1];
  foreach my $channel (@{$self->{channels}}) {
    foreach my $entry (values %$channel) {
      if ($entry->{start} < $min) {$min = $entry->{start}}
      if ($entry->{end}   > $max) {$max = $entry->{end}}
    }
  }
  return ($self->{min}, $self->{max}) = ($min, $max);
}

sub draw_legend {
  # Draw the top legend bar
  my ($self, $image) = @_;
  my ($min, $max) = $self->_minmax;
  my $color = $self->{colors}{legend};
  
  my $step = $self->{bar_stepsize}; # For convenience
  if ($step =~ /^(\d+)%$/) { # Convert from percentage
    $step = ($max - $min) * $1 / 100;
  }

  my $start_at = int($min/$step) * $step;
  for (my $i=$start_at; $i <= $max + $step; $i += $step) {
    $image->line($self->_convert($i), 2, $self->_convert($i), 8, $color);
    my $label = $self->{date_format} ? $self->_UTC_to_string($i) : $self->{to_string}->($i);
    $image->string($self->{font}, $self->_convert($i)+1, 4, $label, $color);
  }
  
  # Long top line
  $image->line($self->_convert($start_at), 2, $self->_convert((int($max/$step)+1) * $step) + $self->{right_margin}, 2, $color);
}

sub _convert {
  # A little baroque ... converts date to x-value
  my ($self, $time) = @_;
  return (   $time     - $self->{min}) * ($self->{width}-2*$self->{hmargin}) 
       / ($self->{max} - $self->{min}) 
       + $self->{hmargin};
}

sub draw_channels {
  my ($self, $image) = @_;
  my ($fheight, $fwidth) = ($self->{font}->height,$self->{font}->width);

  my $y;
  foreach my $channel ({}, @{$self->{channels}}) {  # leave an empty channel at the top
    $y += $self->{height}/(@{$self->{channels}} + 2);
    
    # Need to draw them in order to avoid collisions
    my @labels = sort {$channel->{$a}{start} <=> $channel->{$b}{start}} keys %$channel;
    my $above = 0;
    foreach my $i (0..$#labels) {
      my $label = $labels[$i];
      my $x_start = $self->_convert($channel->{$label}{start});
      my $x_end   = $self->_convert($channel->{$label}{end});

      # Draw the long line:
      $image->line($x_start, $y, $x_end, $y, $self->{colors}{bar});

      # Draw the endcaps:
      $image->line($x_start, $y-1, $x_start, $y+1, $self->{colors}{endcap});
      $image->line($x_end,   $y-1, $x_end,   $y+1, $self->{colors}{endcap});

      # Write the label (above the bar if it would collide)
      if ($above)                                                           { $above = 0 }
      elsif (!defined $labels[$i+1])                                        { $above = 0 }
      elsif (length($label) * $fwidth > 
	     $self->_convert($channel->{$labels[$i+1]}{start}) - $x_start)  { $above = 1 }
      else                                                                  { $above = 0 }
      
      my $string_y = ($above ?
		      $y - $fheight - 1 :
		      $y + 1);
      $image->string($self->{font}, $x_start, $string_y, $label, $self->{colors}{text});
    }
  }
}

sub draw {
  my ($self) = @_;
  
  $self->_create_channels;

  # Add 2 to leave room for header
  my $fheight = $self->{font}->height;
  $self->{height} = (@{$self->{channels}} + 2) * (2*$fheight + $self->{vspacing});
  
  my $image = $self->_create_image($self->{width}, $self->{height});
  $self->draw_legend($image);
  $self->draw_channels($image);
  
  return $image;
}

sub _channel_is_free {
  my ($self, $channel, $time) = @_;

  # Step through the entries in this channel:
  foreach my $data (values %$channel) {
    return 0 if ($data->{start} <= $time  
		  and
		 $data->{end}   >= $time);
  }

  return 1;
}

sub _add_to_channel {
  my ($self, $channel, $label) = @_;
  
  foreach (qw(start end)) {
    $channel->{$label}{$_} = $self->{data}{$label}{$_};
  }
}

sub _UTC_to_string {
  my ($self,$UTC) = @_;
  
  require Date::Format;
  return  Date::Format::time2str($self->{date_format}, $UTC);
}

1;
__END__

=head1 NAME

Image::Timeline - Create GIF or PNG timelines

=head1 SYNOPSIS

  use Image::Timeline;
  my $t = new Image::Timeline(width => 400);
  $t->add('J.S. Bach', 1685, 1750);
  $t->add('Beethoven', 1770, 1827);
  $t->add('Brahms',    1833, 1897);
  $t->add('Ravel',     1875, 1937);
  ...
   # For older versions of GD:
  $t->write_gif('composers.gif');
   # For newer versions of GD:
  $t->write_png('composers.png');
  
  # Get the GD object
  my $img = $t->draw;

=head1 DESCRIPTION

This module creates bar-format timelines using the GD.pm module.
Timelines are automatically laid out so that their entries don't
overlap each other.  Depending on the version of GD you have, you can
produce several different file formats, including GIF or PNG files.

See the file C<t/truth.gif> for example output.

=head1 METHODS

=head2 new()

Creates a new timeline object.  Accepts several named parameters that
affect how the timeline is created:

=over 4

=item width

How many pixels wide the image should be.  Default is 900 pixels, for
no good reason.

=item font

Which GD font should be used to label each entry in the timeline.
Default is C<gdTinyFont>.

=item bar_stepsize

The "tick interval" on the timeline's legend at the top.  Default is
50 (i.e. 50 years).  If the stepsize ends with the C<%> character, it
will be interpreted as a percentage of the total data width.

Note that the stepsize is given in terms of the data space
(i.e. years), not in terms of the image space (i.e. pixels).

=item vspacing

How many pixels of vertical space should be left between entries.
Default is 2.

=item hmargin

How many pixels should be left at the far right and far left of the
image.  Default is 3.

=item bg_color

=item bar_color

=item endcap_color

=item legend_color

=item text_color

These parameters affect the colors of the image.  Each associated
value should be a 3-element array reference, specifying RGB values
from 0 to 255.  For instance, the default value of C<bar_color> is
pure red, specified as C<[255,0,0]>.  The defaults are reasonable, but
not necessarily attractive.

=item date_format

By default, the numerical data describing an entry's start and end
point are also used as the label for the legend at the top of the
timeline.  Typically this means that the data represent years.
However, if you supply the C<date_format> parameter, the data will be
assumed to be a Unix timestamp (similar to the output of the C<time()>
function), and it will be passed to the C<Date::Format> C<time2str>
function, using the C<date_format> parameter as the formatting string.

=item to_string

The function used to convert the numerical data describing and entry's
start and end point can be defined using this parameter. This function is
only used if the C<date_format> parameter is not defined and should take
one argument, the numerical value.

=item right_margin

How many pixels should be left over the right margin so that the last
legend isn't cut from the image.

=back

=head2 add(label, start, end)

Adds a new entry to the timeline.  Supply a label that you want to
include in the image, the starting date, and the ending date.

=head2 draw()

Creates the C<GD> object and returns it.  This method is where all the
real work is done - the code must figure out things like how to
squeeze the entries most compactly but avoid collisions between bars,
when to draw labels above their bars and when below (again, to avoid
collisions between labels), the image's height (a function of how many
concurrent entries it contains), and so on.

=head2 write_png(filename)

=head2 write_gif(filename)

A convenience method which writes the timeline to a file.  Because of
some Unisys/Compuserve/GD patent issues that I don't want to get
involved in, writing PNG output requires a version of GD newer than
1.19, while writing GIF output requires GD version 1.19 or older.
See the GD.pm documentation for more information on this issue.

=head2 write(format, filename, [arguments])

Writes the timeline in the specified format to the specified file.
For example, C<< $t->write('png', 'foo.png') >> writes a PNG file to
F<foo.png>.  The format can be any format supported by your version of
GD, which may include C<png>, C<gif>, C<jpeg>, C<gd>, C<gd2>, and
C<wbmp> in recent versions of GD.  Any extra arguments will be passed
to the GD rendering method, which may be useful for methods like
C<jpeg> or C<wbmp>.


=head1 LIMITATIONS

Currently all dates/times are specified as integers, which are meant
to represent years.  Finer granularity (time of day) isn't supported
yet, but it probably could be if it's desired (or someone gives me a
patch).

Doesn't yet fully test the PNG capabilities during 'make test'.  This
is just because I haven't yet found time to build all the necessary
PNG libraries on my system, so I haven't gotten the benchmark image
built.  Please let me know whether this works correctly, and maybe
even send me the 't/testdata.png' file created so I can include it
here.

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 COPYRIGHT

Copyright 2001-2002 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), GD(3), Date::Format(3)

=cut
