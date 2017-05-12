# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Tk.
#
# Image-Base-Tk is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Tk is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Tk.  If not, see <http://www.gnu.org/licenses/>.


# Tk::Photo
# Tk::Image
# Tk::options  configure(), cget()
#
# Tk::PNG
# Tk::JPEG
# Tk::TIFF
#    loaders

package Image::Base::Tk::Photo;
use 5.004;
use strict;
use Carp;

use vars '$VERSION', '@ISA';
$VERSION = 3;

use Image::Base;
@ISA = ('Image::Base');

# uncomment this to run the ### lines
#use Smart::Comments '###';


sub new {
  my ($class, %params) = @_;
  ### Image-Base-Tk new() ...

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    croak "Cannot clone Image::Base::Tk::Photo";

    #  how to clone a Photo?  how to get its originating widget to create new?
    # my $self = $class;
    # $class = ref $class;
    # if (! defined $params{'-tkphoto'}) {
    #   my $tkphoto = $self->{'-tkphoto'};
    #   my $new_tkphoto = $tkphoto->Photo (map {$_=>$tkphoto->cget($_)}
    #                                      qw(-width -height -gamma -palette));
    #   $new_tkphoto->copy($tkphoto);
    #   $params{'-tkphoto'} = $new_tkphoto;
    # }
    # # inherit everything else
    # %params = (%$self, %params);
    # ### copy params: \%params
  }

  if (! defined $params{'-tkphoto'}) {
    my $for_widget = delete $params{'-for_widget'}
      || croak 'Must have -for_widget to create new Tk::Photo';
    $params{'-tkphoto'} = $for_widget->Photo (-width => $params{'-width'},
                                              -height => $params{'-height'});
  }
  my $self = bless {}, $class;
  $self->set (%params);

  if (exists $params{'-file'}) {
    $self->load;
  }

  ### new made: $self
  return $self;
}

my %attr_to_option = (-width    => '-width',
                      -height   => '-height');
sub _get {
  my ($self, $key) = @_;
  ### Image-Base-Tk-Photo _get(): $key
  if (my $option = $attr_to_option{$key}) {
    ### $option
    return $self->{'-tkphoto'}->cget($option);
  }
  return $self->SUPER::_get ($key);
}

sub set {
  my ($self, %param) = @_;
  ### Image-Base-Tk-Photo set(): \%param

  # apply this first
  if (my $tkphoto = delete $param{'-tkphoto'}) {
    $self->{'-tkphoto'} = $tkphoto;
  }

  {
    my @configure;
    foreach my $key (keys %param) {
      if (my $option = $attr_to_option{$key}) {
        my $value = delete $param{$key};
        push @configure, $option, $value;
      }
    }
    ### @configure
    if (@configure) {
      $self->{'-tkphoto'}->configure (@configure);
    }
  }

  %$self = (%$self, %param);
}

sub load {
  my ($self, $filename) = @_;
  ### Image-Base-Tk-Photo load()

  if (@_ == 1) {
    $filename = $self->get('-file');
  } else {
    $self->set('-file', $filename);
  }
  my $tkphoto = $self->{'-tkphoto'};
  $tkphoto->read ($filename);
  $self->set (-file_format => $tkphoto->cget('-format'));
}

# undocumented, untested ...
sub load_string {
  my ($self, $str) = @_;
  ### Image-Base-Tk-Photo load()
  my $tkphoto = $self->{'-tkphoto'};
  $tkphoto->configure (-data => $str);
  $self->set (-file_format => $tkphoto->cget('-format'));
}

my %format_to_module = (png  => 'Tk::PNG',
                        jpeg => 'Tk::JPEG',
                        tiff => 'Tk::TIFF',
                       );
sub _format_use {
  my ($format) = @_;
  if (my $module = $format_to_module{lc($format)}) {
    eval "require $module; 1" or die;
  }
  return $format;
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-Tk-Photo save()
  if (@_ == 2) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  my $tkphoto = $self->{'-tkphoto'};
  ### file: $filename

  # croaks if an error ...
  $tkphoto->write ($filename,
                   -format => _format_use($self->get('-file_format')));
}

# undocumented, untested ...
sub save_fh {
  my ($self, $fh) = @_;
  print $fh $self->save_string;
}

# undocumented, untested ...
sub save_string {
  my ($self, $fh) = @_;
  # croaks if an error ...
  return $self->{'-tkphoto'}->data
    (-format => _format_use($self->get('-file_format')));
}

#------------------------------------------------------------------------------
# drawing

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Image-Base-Tk-Photo xy() ...

  # "-to" doesn't allow negative coordinates
  if ($x < 0 || $y < 0) {
    return undef;
  }

  my $tkphoto = $self->{'-tkphoto'};
  if (@_ > 3) {
    if (lc($colour) eq 'none') {
      $tkphoto->transparencySet ($x, $y, 1);
    } else {
      $tkphoto->put ($colour, -to => $x,$y, $x+1,$y+1);
    }
  } else {
    # get() and transparencyGet() don't allow x,y outside photo
    if ($x >= $tkphoto->cget('-width')
        || $y >= $tkphoto->cget('-height')) {
      return undef;
    }

    if ($tkphoto->transparencyGet ($x, $y)) {
      return 'None';
    } else {
      return sprintf ('#%02X%02X%02X', $tkphoto->get ($x, $y));  # r,g,b
    }
  }
}

sub rectangle {
  my ($self, $x1, $y1, $x2, $y2, $colour, $fill) = @_;
  ### Image-Base-Tk-Photo rectangle() ...

  if ($fill && lc($colour) ne 'none') {
    ### filled rectangle with put() ...

    if ($x2 >= 0 && $y2 >= 0) {
      # "-to" doesn't allow negative coordinates
      if ($x1 < 0) { $x1 = 0; }
      if ($y1 < 0) { $y1 = 0; }

      ### put: "$x1,$y1  ".($x2+1).",".($y2+1)
      $self->{'-tkphoto'}->put ($colour, -to => $x1,$y1, $x2+1,$y2+1);
    }

  } else {
    ### unfilled or transparent rectangle with superclass lines ...
    shift->SUPER::rectangle(@_);
  }
}

sub line {
  my ($self, $x1, $y1, $x2, $y2, $colour) = @_;
  ### Image-Base-Tk-Photo line(): "$x1,$y1, $x2,$y2"

  if (lc($colour) eq 'none') {
    # any transparency by individual xy() pixels (with transparencySet())
    shift->SUPER::line(@_);
    return;
  }

  if ($x1 == $x2) {
    # vertical line by put() rectangle
    if ($x1 < 0) {
      ### vertical line all negative ...
      return;
    }
    if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1) }

  } elsif ($y1 == $y2) {
    # horizontal line by put() rectangle
    if ($y1 < 0) {
      ### horizontal line all negative ...
      return;
    }
    if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1) }

  } else {
    ### sloped line by individual xy() pixels ...
    shift->SUPER::line(@_);
    return;
  }

  # "-to" doesn't allow negative coordinates
  if ($x1 < 0) { $x1 = 0; }
  if ($y1 < 0) { $y1 = 0; }

  ### put(): "$x1,$y1, ".($x2+1).",".($y2+1)
  $self->{'-tkphoto'}->put ($colour, -to => $x1,$y1, $x2+1,$y2+1);
}

1;
__END__

=for stopwords Image-Base-Tk filename Ryde PNG JPEG PNM GIF BMP XPM XBM png jpeg MainWindow Xlib toplevel builtin

=head1 NAME

Image::Base::Tk::Photo -- draw with Tk::Photo

=for test_synopsis my $mw

=head1 SYNOPSIS

 use Image::Base::Tk::Photo;
 my $image = Image::Base::Tk::Photo->new (-for_widget => $mw,
                                          -width => 100,
                                          -height => 100);
 $image->rectangle (0,0, 99,99, 'white');
 $image->xy (20,20, 'black');
 $image->line (50,50, 70,70, '#FF00FF');
 $image->line (50,70, 70,50, '#0000AAAA9999');
 $image->save ('/some/filename.png');

=head1 CLASS HIERARCHY

C<Image::Base::Tk::Photo> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::Tk::Photo

=head1 DESCRIPTION

C<Image::Base::Tk::Photo> extends C<Image::Base> to create or update image
files using the C<Tk::Photo> module from Perl-Tk.

See L<Tk::Photo> for the supported file formats.  Perl-Tk 804 includes

   PNG, JPEG, XPM, XBM, GIF, BMP, PPM/PGM

   TIFF    separate Tk::TIFF module

A C<Tk::Photo> requires a C<Tk::MainWindow> and so an X display (etc),
though there's no need to actually display the MainWindow.  Drawing
operations use the Photo pixel/rectangle C<put()>.

For reference, to draw arbitrary graphics in Perl-Tk the choice is between a
C<Tk::Canvas> with arcs etc, or a C<Tk::Photo> of pixels which is set as the
C<-image> of a C<Tk::Label> or similar.  Is that right?  No drawing area
widget as such?

=head2 Colours

Colour names are anything recognised by L<Tk_GetColor(3tk)>, plus "None",

    X server names     usually /etc/X11/rgb.txt
    #RGB               hex
    #RRGGBB            hex
    #RRRGGGBBB         hex
    #RRRRGGGGBBBB      hex
    None               transparent

The hex forms end up going to Xlib which means the shorter ones are padded
with zeros, so "#FFF" is "#F000F000F000" which is a light grey rather than
white.  See L<X(7)> "COLOR NAMES".

"None" means a transparent pixel, as per C<$tkphoto-E<gt>transparencySet()>.

=head1 FUNCTIONS

See L<Image::Base/FUNCTIONS> for the behaviour common to all Image-Base
classes.

=over 4

=item C<$image = Image::Base::Tk::Photo-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  It can be given an existing
C<Tk::Photo>,

    $image = Image::Base::Tk::Photo->new (-tkphoto => $tkphoto);

Or it can create a new C<Tk::Photo>.  The C<-for_widget> option gives a
widget hierarchy where the new C<Tk::Photo> will be used.  A toplevel
C<Tk::MainWindow> is suitable.

    $image = Image::Base::Tk::Photo->new (-for_widget => $widget);

C<-width> and C<-height> size can be given.  Zero or omitted gives the usual
auto-sizing of C<Tk::Photo>.

    $image = Image::Base::Tk::Photo->new (-for_widget => $widget,
                                          -width => 200,
                                          -height => 100);

Or a file can be read,

    $image = Image::Base::Tk::Photo->new
                (-for_widget => $widget,
                 -file => '/some/filename.xpm');

A C<Tk::Photo> must be explicitly destroyed with C<$tkphoto-E<gt>delete()>
the same as all C<Tk::Image> types (see L<Tk::Image>).
C<Image::Base::Tk::Photo> doesn't currently do that in its own destruction.
Should it do so when it created the photo?  But probably don't want to
destroy when merely set in as a C<-tkphoto>.

=item C<$new_image = $image-E<gt>new (key=E<gt>value,...)>

This is supposed to clone the image object, but it's not implemented yet.
How to clone a C<Tk::Photo>?

=item C<$image-E<gt>load ()>

=item C<$image-E<gt>load ($filename)>

Read the current C<-file>, or set C<-file> to C<$filename> and then read.

The file format is recognised automatically by C<Tk::Photo> from the formats
registered.  Some formats are builtin, but for PNG, JPEG and TIFF the
corresponding format modules C<Tk::PNG>, C<Tk::JPEG> or C<Tk::TIFF> must be
used first.  For example,

    use Tk::PNG;
    $image->load ('/my/filename.png');

=item C<$image-E<gt>save ()>

=item C<$image-E<gt>save ($filename)>

Save to C<-file>, or with a C<$filename> argument set C<-file> then save to
that.

The saved file format is taken from C<-file_format> (see L</ATTRIBUTES>
below) if that was set, either from a C<load()> or explicit C<set()>.

For convenience, when saving PNG, JPEG and TIFF the necessary C<Tk::PNG>,
C<Tk::JPEG> or C<Tk::TIFF> module is loaded automatically.  Any other
non-builtin formats will require their modules loaded before attempting a
C<save()>.

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer)

=item C<-height> (integer)

Setting these changes the size of the image.

=item C<-tkphoto>

The underlying C<Tk::Photo> object.

=item C<-file_format> (string or C<undef>)

The file format as a string like "png" or "jpeg", or C<undef> if unknown or
never set.

After C<load> the C<-file_format> is the format read.  Setting
C<-file_format> can change the format for a subsequent C<save()>.

There's no attempt to check or validate the C<-file_format> value since it's
possible to add new formats to Tk::Photo at run time.  Expect C<save()> to
croak if the format is unknown.

=back

=head1 SEE ALSO

L<Tk::Photo>,
L<Image::Base>,
L<Image::Base::Tk::Canvas>

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-tk/index.html

=head1 LICENSE

Image-Base-Tk is Copyright 2010, 2011, 2012 Kevin Ryde

Image-Base-Tk is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-Tk is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Image-Base-Tk.  If not, see <http://www.gnu.org/licenses/>.

=cut
