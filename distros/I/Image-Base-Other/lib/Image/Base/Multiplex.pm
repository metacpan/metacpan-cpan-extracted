# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Other.
#
# Image-Base-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Other.  If not, see <http://www.gnu.org/licenses/>.


package Image::Base::Multiplex;
use 5.004;
use strict;
use Carp;
use vars '$VERSION', '@ISA';

$VERSION = 9;

use Image::Base;
@ISA = ('Image::Base');

# uncomment this to run the ### lines
#use Smart::Comments;


sub new {
  my $class = shift;

  if (ref $class) {
    # clone by copying fields, don't think need to copy images array
    return bless { %$class }, $class;
  }

  return bless { -images => [],
                 @_ }, $class;
}

sub _get {
  my ($self, $key) = @_;
  # ### Image-Base-Multiplex _get(): $key
  if ($key eq '-images') {
    return $self->SUPER::_get($key);
  } else {
    my $image = $self->{'-images'}->[0] || return undef;
    return $image->get($key);
  }
}
sub set {
  my $self = shift;
  # ### Image-Base-Multiplex set()

  my $set_file;
  for (my $i = 0; $i < @_; ) {
    my $key = $_[$i];
    $set_file = ($key eq '-file');
    if ($key eq '-images') {
      $self->{$key} = $_[$i+1];
      splice @_, $i, 2;
    } else {
      $i += 2
    }
  }

  my $images = $self->{'-images'};
  if ($set_file && @$images > 1) {
    croak 'Refusing to set multiple images to same -file';
  }

  foreach my $image (@$images) {
    $image->set(@_);
  }
}

sub load {
  my $self = shift;
  my $images = $self->{'-images'};
  if (@_ && @$images > 1) {
    croak 'Refusing to load multiple images from one file';
  }
  foreach my $image (@$images) { $image->load; }
}
sub save {
  my $self = shift;
  my $images = $self->{'-images'};
  if (@_ && @$images > 1) {
    croak 'Refusing to save multiple images to one file';
  }
  foreach my $image (@$images) { $image->save; }
}

sub xy {
  my $self = shift;
  ### Image-Base-Multiplex xy(): @_[1..$#_]
  my $images = $self->{'-images'};
  if (@_ > 2) {
    foreach my $image (@$images) { $image->xy(@_); }
  } else {
    my ($x, $y) = @_;
    my $image = $images->[0] || return undef;
    return $image->xy($x,$y);
  }
}
sub line {
  foreach my $image (@{shift->{'-images'}}) { $image->line(@_); }
}
sub rectangle {
  foreach my $image (@{shift->{'-images'}}) { $image->rectangle(@_); }
}
sub ellipse {
  foreach my $image (@{shift->{'-images'}}) { $image->ellipse(@_); }
}
sub diamond {
  foreach my $image (@{shift->{'-images'}}) { $image->diamond(@_); }
}

sub add_colours {
  foreach my $image (@{shift->{'-images'}}) {
    if (my $coderef = $image->can('add_colours')) {
      $image->$coderef(@_);
    }
  }
}

sub Image_Base_Other_xy_points {
  ### Multiplex xy_points
  foreach my $image (@{shift->{'-images'}}) {
    if (my $coderef = $image->can('Image_Base_Other_xy_points')) {
      $image->$coderef(@_);
    } else {
      for (my $i = 1; $i < @_; $i += 2) {
        $image->xy ($_[$i], $_[$i+1],
                    $_[0]);  # colour
      }
    }
  }
}
sub Image_Base_Other_rectangles {
  ### Multiplex rectangles
  foreach my $image (@{shift->{'-images'}}) {
    if (my $coderef = $image->can('Image_Base_Other_rectangles')) {
      $image->$coderef(@_);
    } else {
      for (my $i = 2; $i < @_; $i += 4) {
        ### rect: @_[$i .. $i+3], $_[0], $_[1]
        $image->rectangle (@_[$i .. $i+3],
                           $_[0],   # colour
                           $_[1]);  # fill
      }
    }
  }
}

1;
__END__

=for stopwords filename Ryde arrayref multi-output

=head1 NAME

Image::Base::Multiplex -- draw to multiple Image::Base objects simultaneously

=for test_synopsis my ($image1, $image2)

=head1 SYNOPSIS

 use Image::Base::Multiplex;
 my $multiplex_image = Image::Base::Multiplex->new
                           (-images => [$image1,$image2]);
 $multiplex_image->rectangle (0,0, 99,99, 'white');
 $multiplex_image->line (50,50, 70,70, '#FF00FF');

=head1 CLASS HIERARCHY

C<Image::Base::Multiplex> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::Multiplex

=head1 DESCRIPTION

C<Image::Base::Multiplex> operates on multiple C<Image::Base> objects
simultaneously so that one drawing call draws to a set of images.

=head1 FUNCTIONS

=over 4

=item C<$image = Image::Base::Multiplex-E<gt>new (key=E<gt>value,...)>

Create and return a new multiplex image object.  An initial list of target
images can be supplied,

    my $image = Image::Base::Multiplex->new
                   (-images => [ $image1, $image2 ]);

Or start empty and set some C<-images> later

    my $image = Image::Base::Multiplex->new ();

=item C<$image-E<gt>xy (...)>

=item C<$image-E<gt>line (...)>

=item C<$image-E<gt>rectangle (...)>

=item C<$image-E<gt>ellipse (...)>

=item C<$image-E<gt>diamond (...)>

These calls are passed through to each target image.

=item C<$image-E<gt>add_colours ($colour, $colour, ...)>

Call C<add_colours> on each target image which supports that method, and
skip those which don't.

=back

=head1 ATTRIBUTES

=over

=item C<-images> (arrayref of C<Image::Base> objects)

The target images to draw on.

=back

=head1 SEE ALSO

L<Image::Base>

L<G2> has a similar multi-output to its devices.

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-other/index.html

=head1 LICENSE

Image-Base-Other is Copyright 2010, 2011, 2012 Kevin Ryde

Image-Base-Other is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Image-Base-Other is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Image-Base-Other.  If not, see <http://www.gnu.org/licenses/>.

=cut
