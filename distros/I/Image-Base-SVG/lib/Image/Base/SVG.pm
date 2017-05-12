# Copyright 2011 Kevin Ryde

# This file is part of Image-Base-SVG.
#
# Image-Base-SVG is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-SVG is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-SVG.  If not, see <http://www.gnu.org/licenses/>.


package Image::Base::SVG;
use 5.006;  # SVG is 5.6 for weakening
use strict;
use Carp;
use SVG; # version 2.50 needs an import() to create methods

use vars '$VERSION', '@ISA';
$VERSION = 4;

use Image::Base;
@ISA = ('Image::Base');

# uncomment this to run the ### lines
#use Devel::Comments '###';


sub new {
  my ($class, %params) = @_;
  ### Image-Base-SVG new(): %params

  # $obj->new(...) means make a copy, with some extra settings
  if (ref $class) {
    my $self = $class;
    $class = ref $self;
    croak "Cannot clone $class yet ..."

    # if (! defined $params{'-svg_object'}) {
    #   $params{'-svg_object'} = $self->{'-svg_object'}->cloneNode;
    # }
    # # inherit everything else
    # %params = (%$self, %params);
    # ### copy params: \%params
  }

  my $svg = delete $params{'-svg_object'};
  if (! $svg) {
    $svg = SVG->new ((exists $params{'-width'}
                      ? (width => delete $params{'-width'})
                      : ()),
                     (exists $params{'-height'} ?
                      (height => delete $params{'-height'})
                      : ()));
  }

  my $self = bless { -svg_object => $svg }, $class;
  ### %params
  $self->set (%params);
  return $self;
}

# these two not documented yet
my %key_to_cdata = ('-title'       => 'title',
                    '-description' => 'desc');

my %key_to_attribute = ('-width'  => 'width',
                        '-height' => 'height');
sub _get {
  my ($self, $key) = @_;
  ### _get(): $key

  if (my $tagname = $key_to_cdata{$key}) {
    my $elem;      
    return (($elem = _get_tag($self,$tagname))
            && $elem->getCDATA);

  } elsif (my $aname = $key_to_attribute{$key}) {
    return _svg_element($self)->getAttribute ($aname);

  } else {
    return $self->{$key};
  }
}

sub set {
  my $self = shift;
  while (@_) {
    my $key = shift;
    @_ or croak "Odd number of arguments to set()";
    my $value = shift;

    if (my $tagname = $key_to_cdata{$key}) {
      my $elem = _get_or_create_tag($self,$tagname);
      $elem->cdata ($value);

    } elsif (my $aname = $key_to_attribute{$key}) {
      ### $aname
      ### $value
      _svg_element($self)->setAttribute ($aname, $value);

    } else {
      $self->{$key} = $value;
    }
  }
}
sub _get_tag {
  my ($self,$tagname) = @_;
  my $svg = $self->{'-svg_object'};
  return ($svg->getElements($tagname))[0];
}
sub _get_or_create_tag {
  my ($self,$tagname) = @_;
  my $svg = $self->{'-svg_object'};
  my @elems = $svg->getElements($tagname);
  if (@elems) {
    return $elems[0];
  } else {
    return $svg->tag($tagname);
  }
}
sub _svg_element {
  my ($self) = @_;
  my $svg = $self->{'-svg_object'};
  ### docroot: $svg->{'-docroot'}
  ### elems: join(',',$svg->getElements())

  return ($svg->getElements($svg->{'-docroot'}))[0]
    || die "Oops, -docroot element not found";
}

sub xy {
  my ($self, $x, $y, $colour) = @_;
  ### Image-Base-SVG xy(): @_[1 .. $#_]

  my $svg = $self->{'-svg_object'};
  if (@_ == 3) {
    return undef;  # no pixel fetching available
  } else {
    $svg->rectangle (x => $x, y => $y,
                     width => 1, height => 1,
                     fill => $colour);
  }
}

sub rectangle {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### Image-Base-SVG rectangle(): @_[1 .. $#_]

  $fill ||= ($x1 == $x2 || $y1 == $y2);  # 1xN or Nx1 done filled
  if (! $fill) {
    $x1 += .5;  # for stroke width 1
    $y1 += .5;
    $x2 -= .5;
    $y2 -= .5;
  }
  $self->{'-svg_object'}->rectangle (x => $x1,
                                     y => $y1,
                                     width  => $x2-$x1+1,
                                     height => $y2-$y1+1,
                                     ($fill?'fill':'stroke') => $colour);
}

sub ellipse {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### Image-Base-SVG ellipse(): @_[1 .. $#_]

  $fill ||= ($x1 == $x2 || $y1 == $y2);
  my $rx = ($x2-$x1+1) / 2;
  my $ry = ($y2-$y1+1) / 2;
  if (! $fill) {
    $rx -= .5;  # for stroke width 1
    $ry -= .5;
  }
  $self->{'-svg_object'}->ellipse (cx => ($x1+$x2+1) / 2,
                                   cy => ($y1+$y2+1) / 2,
                                   rx => $rx,
                                   ry => $ry,
                                   ($fill?'fill':'stroke') => $colour);
}

sub line {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### Image-Base-SVG rectangle(): @_[1 .. $#_]

  $self->{'-svg_object'}->line (x1 => $x1+.5,
                                y1 => $y1+.5,
                                x2 => $x2+.5,
                                y2 => $y2+.5,
                                stroke => $colour,
                                'stroke-linecap' => "square");
}

sub diamond {
  my ($self, $x1,$y1, $x2,$y2, $colour, $fill) = @_;
  ### Image-Base-SVG diamond(): @_[1 .. $#_]

  $fill ||= ($x1 == $x2 || $y1 == $y2);  # 1xN or Nx1 done filled
  if ($fill) {
    $x2++;
    $y2++;
  } else {
    $x1 += .5;  # for stroke width 1
    $y1 += .5;
    $x2 += .5;
    $y2 += .5;
  }
  my $xm = ($x1+$x2)/2;
  my $ym = ($y1+$y2)/2;
  $self->{'-svg_object'}->polygon (points => "$xm,$y1 $x1,$ym $xm,$y2 $x2,$ym",
                                   ($fill?'fill':'stroke') => $colour);
}

sub load {
  my ($self, $filename) = @_;
  if (@_ > 1) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### $filename

  # stringize any oopery to stop SVG::Parser being clever ... maybe
  $filename = "$filename";

  # use SVG::Parser qw(SVG::Parser::SAX=XML::LibXML::SAX::Parser);
  # use SVG::Parser qw(SVG::Parser::SAX=XML::LibXML::SAX::Parser);

  eval 'use SVG::Parser; 1' or die;
  my $parser = SVG::Parser->new (
                                 # -debug => 1,
                                );
  my $svg = $parser->parse_file ($filename);
  $self->{'-svg_object'} = $svg;
}

sub save {
  my ($self, $filename) = @_;
  ### Image-Base-SVG save(): @_
  if (@_ > 1) {
    $self->set('-file', $filename);
  } else {
    $filename = $self->get('-file');
  }
  ### $filename

  open my $fh, '>', $filename,
    or croak "Cannot create $filename: $!";

  if (! $self->save_fh ($fh)) {
    my $err = "Error writing $filename: $!";
    { local $!; close $fh; }
    croak $err;
  }
  close $fh
    or croak "Error closing $filename: $!";
}

# not yet documented ...
sub save_fh {
  my ($self, $fh) = @_;
  ### save_fh() ...
  ### elements: $self->{'-elements'}
  ### height: $self->{'-height'}

  my $svg = $self->{'-svg_object'};
  # $svg->comment ("\n\tGenerated using ".ref($self)." version ".$self->VERSION."\n");
  return print $fh $svg->xmlify;
}

# sub _add_comment {
#   my ($self) = @_;
#   my $svg_element = _svg_element($self);
#   my $generated
#     = "\n\tGenerated using ".ref($self)." version ".$self->VERSION."\n";
#   foreach my $comment ($svg_element->getElements('comment')) {
#     if ($comment->cdata eq $generated) {
#       return;
#     }
#   }
#   $self->{'-svg_object'}->comment ($generated);
# }

1;
__END__

=for stopwords SVG filename Ryde

=head1 NAME

Image::Base::SVG -- SVG image file output

=head1 SYNOPSIS

 use Image::Base::SVG;
 my $image = Image::Base::SVG->new (-width => 100,
                                                    -height => 100);
 $image->rectangle (0,0, 99,99, 'b');
 $image->xy (20,20, 'o');
 $image->line (50,50, 70,70, 'o');
 $image->line (50,50, 70,70, 'o');
 $image->save ('/some/filename.svg');

=head1 CLASS HIERARCHY

C<Image::Base::SVG> is a subclass of C<Image::Base>,

    Image::Base
      Image::Base::SVG

=head1 DESCRIPTION

C<Image::Base::SVG> extends C<Image::Base> to create or
update SVG format image files using the C<SVG.pm> module (see
L<SVG::Manual>).

C<Image::Base> is pixel oriented so isn't really the sort of thing SVG is
meant for, but this module can direct some C<Image::Base> style code at an
C<SVG> object.  Of course the C<SVG> module has many more features if used
natively.

It's often fairly easy to spit out SVG directly too, and for instance the
C<Image::Base::SVGout> module can do that.  The advantages of the C<SVG>
document object model comes when combining images or fragments, or going
through elements for post-facto mangling.

In the current code the SVG elements emitted assume some default style
attributes such as stroke-width 1.  Perhaps that should be set explicitly on
each element.

=head2 Colours

Colour names are per the SVG spec, which is CSS style syntax

    #RGB                    hex, 1 digit
    #RRGGBB                 hex, 2 digit
    rgb(255,255,255)        integers 0 to 255
    rgb(100%,100%,100%)     percentages
    http://www.w3.org/TR/2008/REC-CSS2-20080411/syndata.html#value-def-color

plus extra names

    http://www.w3.org/TR/2003/REC-SVG11-20030114/types.html#ColorKeywords

=head1 FUNCTIONS

=over 4

=item C<$image = Image::Base::SVG-E<gt>new (key=E<gt>value,...)>

Create and return a new image object.  A new image can be started with just

    $image = Image::Base::SVG->new;

Generally C<-width> and C<-height> should be set, but it works to do that
later after creating.

Or an existing C<SVG> object can be given,

    my $svg = SVG->new;
    ...
    $image = Image::Base::SVG->new (-svg_object => $svg);

=item C<$image-E<gt>xy ($x, $y, $colour)>

=item C<$colour = $image-E<gt>xy ($x, $y)>

Get or set an individual pixel.

Currently for a get the return is always C<undef> as there's no support for
picking out elements etc from the SVG.  Perhaps the simple elements drawn by
this C<Image::Base::SVG> could be read back, but arbitrary SVG from a
C<load()> would need a full rasterize in the worst case.

=item C<$image-E<gt>load ()>

=item C<$image-E<gt>load ($filename)>

Load an SVG file into C<$image>, either from the current C<-file> attribute,
or set that to C<$filename> then load.

This uses the C<SVG::Parser> module.  See that module for how to choose
between Expat or SAX for its underlying XML parse, and in turn see
L<XML::SAX> for its further choice of libxml, pure perl, etc.  LibXML might
be unhelpfully strict.

=item C<$image-E<gt>save ()>

=item C<$image-E<gt>save ($filename)>

Save the image to an SVG file, either the current C<-file> option, or set
that option to C<$filename> and save to there.

=back

=head1 ATTRIBUTES

=over

=item C<-width> (integer)

=item C<-height> (integer)

Setting C<-width> or C<-height> changes the SVG canvas size.  In the current
code it doesn't affect the elements already drawn to it.  Is that how it
should be?

=back

=head1 SEE ALSO

L<Image::Base>,
L<SVG>,
L<SVG::Manual>,
L<SVG::Parser>

L<Image::Base::SVGout>

=head1 HOME PAGE

http://user42.tuxfamily.org/image-base-svg/index.html

=head1 LICENSE

Image-Base-SVG is Copyright 2011 Kevin Ryde

Image-Base-SVG is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Image-Base-SVG is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Image-Base-SVG.  If not, see <http://www.gnu.org/licenses/>.

=cut
