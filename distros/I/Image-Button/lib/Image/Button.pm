package Image::Button;

use strict;
use vars qw($VERSION);

$VERSION = "0.53";
# $Id: Button.pm,v 1.5 2003/02/22 15:41:19 joanmg Exp $

use GD 1.20;
use Cwd 'abs_path';

sub new
{
    my $pkg = shift;
    my %args = (@_);
    my $self = bless {}, $pkg;
    $self->allocate(%args);
    return $self;
}

# You might need to override allocate when subclassing.  Be careful,
# though: for the copy constructor to work and everything to be clean
# and nice, the entries in the $self dictionary have to have the same
# names as the arguments.
sub allocate
{
    my $self = shift;
    my %args = (text     => '',
                file     => '',
                font     => undef,
                fontsize => 12,
                btcolor  => [ 238, 238, 204 ],
                fgcolor  => [ 0, 0, 0 ],
                bgcolor  => [ 255, 255, 255 ],
                vmargin  => 4,
                hmargin  => 4,
                @_,);

    unless ($args{file}) {
        if ($args{text}) {
            $args{file} = $self->fileFromText(text => $args{text});
        }
    }
    # There might be something in $self, coming from a possibly
    # overridden new function.  The arguments to allocate take
    # precedence.
    %$self = (%$self, %args);
}

sub print
{
    die "Button class should override print.\n";
}

sub copy
{
    my $self = shift;
    my %args = (@_);

    unless ($args{file}) {
        if ($args{text}) { 
            $args{file} = $self->fileFromText(text => $args{text});
        }
    }

    my $nself = {};
    %$nself = (%$self, %args);
    bless $nself, ref($self);
    return $nself;
}

# Used by Button::Set to change values.  
sub override
{
    my $self = shift;
    my %args = (self => {},
                @_,);
    while (my ($par, $val) = each(%{ $args{self} })) { 
        $self->{$par} = $val;
    }
}

# Used by Button::Set to set the text size.
sub textSize
{
    my $self = shift;
    my %args = (texth => undef,
                textw => undef,
                @_,);
    $self->{texth} = $args{texth};
    $self->{textw} = $args{textw};
}

# Used by Button::Set when it needs to figure out a common size for a
# set of buttons.  Returns width and height.
sub getSize
{
    my $self = shift;

    my $text = $self->{text};
    my $font = $self->{font};
    my $size = $self->{fontsize};
    
    $font = $self->getFont($font);

    my @bounds = &GD::Image::stringFT('GD::Image', 0, $font,
                                      $size, 0, 0, 0, $text);
    if (!@bounds) {
        die "Error figuring out bounds for '$text': $@\n";
    }

    return ($bounds[2] - $bounds[0], $bounds[1] - $bounds[7]);
}

# We need the absolute path of the font.  Using TTFONTS environment
# variable to point to the fonts directory; is there a standard
# way/place to do that? ##!!
sub getFont
{
    my $self = shift;
    my ($font) = @_;

    if ($font !~ m|^/|) {
        if (-f $font) {
            $font = abs_path . "/$font";
        }
        elsif ($ENV{TTFONTS}) {
            $font = $ENV{TTFONTS} . "/$font";
        }
    }
    die "Cound not find absolute path for font $font\n" unless -f $font;
    return $font;
}

# Applies prefix and postfix.  Should be the same for all button types.
sub buildFile
{
    my $self = shift;
    my %args = (file    => $self->{file},
                prefix  => '',
                postfix => '',
                @_,);

    my $file = $args{file}; die "Need output file\n" unless $file;
    if ($args{prefix}) { $file = "$args{prefix}$file" }
    if ($args{postfix}) {
        my $short = $file;
        my $ext   = '';
        if ($short =~ s/(\..+?)$//) {
            $ext = $1;
        }
        $file = "$short$args{postfix}$ext";
    }
    $file;
}

sub fileFromText
{
    my $self = shift;
    my %args = (text => '',
                @_,);
    my $text = $args{text};

    # Don't want spaces in my file names
    $text =~ s/\s+/-/g;

    # Don't want tildes either
    my %toplain = ('á' => "a", 'à' => "a", 'ä' => "a",
                   'é' => "e", 'è' => "e", 'ë' => "e", 
                   'í' => "i", 'ì' => "i", 'ï' => "i", 
                   'ó' => "o", 'ò' => "o", 'ö' => "o",
                   'ú' => "u", 'ù' => "u", 'ü' => "u");
    while (my ($accent, $plain) = each(%toplain)) {
        $text =~ s/$accent/$plain/g;
    }

    return "$text.png";
}

1;

=head1 NAME

Image::Button - Base class for building PNG buttons using GD.

=head1 SYNOPSIS

  use Image::Button::Rect;

  my $b1 = new Image::Button::Rect(text     => 'text b1',
                                   font     => 'newsgotn.ttf',
                                   fontsize => 20,
                                   file     => 'b1.png');

  # $b2 is like $b1, but with different text and going to another file
  my $b2 = $b1->copy(text => 'text b2',
                     file => 'b2.png');

  $b1->print;
  $b2->print;

=head1 DESCRIPTION

Image::Button builds simple PNG buttons of the type you would use in
an on-line application.  It provides facilities to build several of
them, possibly related (same width and/or height).  Modules to create
different types of buttons can be easily integrated.  The buttons it
can create so far would not cause a graphic designer to jump from his
chair, drooling with excitement.  But he wouldn't fall from his chair
in disgust either (I hope).

=head2 Fonts

Image::Button uses GD with TrueType support, which requires freetype
(http://www.freetype.org).  It also requires true type fonts.  It's
remarkably difficult to find free fonts out there that can be used to
make decent buttons (clean, non-pretentious, ideally sans-serif).  Let
me know if you find any.

The TrueType fonts should be located either in the current directory
or in the directory pointed at by the environment variable I<TTFONTS>.

=head2 Adding new button types

Image::Button is a base class intended to be derived by classes
implementing different types of buttons.  Available so far are:

=over 4

=item F<Image::Button::Plain>, 

plain rectangular buttons with an optional border,

=item F<Image::Button::Rect>, 

rectangular three dimensional buttons.

=back

If you want to implement a new type of button (say, oval) you can take
advantage of the existing infrastructure by deriving from
Image::Button, and overriding the I<print>, I<getSize> and I<textSize>
functions, as Image::Button::Plain does.

=head1 FUNCTIONS

There is only OO interface to the packages, and all function calls
require named parameters.

=head2 Constructor

The way to construct the button will depend on the button type being
constructed, but it will generally be of the form:

  my $b = new Image::Button::Rect(text     => 'text',
                                  font     => 'newsgotn.ttf',
                                  fontsize => 20,
                                  fgcolor  => [ 85, 85, 136 ], # text
                                  btcolor  => [ 238, 238, 204 ],
                                  bgcolor  => [ 255, 255, 255 ],
                                  file     => 'file.png');

See the man page of the button you are trying to construct for a
description of the arguments.

=head2 Print the button

    $b->print(file    => 'button.png',
              prefix  => '',
              postfix => '');

Prints the button to a file.  If the I<file> argument is not set it
will print to the one specified in the button constructor.  The
I<prefix> and I<postfix> arguments are prepended and appended to the
file name, respectively.  They are useful when printing sets of
buttons, where you might want to print them several times, with small
modifications, to different file names (for example, changing the
color).

=head2 Copy the button

    $b2 = $b->copy(text     => 'new text',
                   file     => 'button2.png',
                   fontsize => 21);

Copy constructor.  If no arguments are specified returns an exact copy
of the original button.  If called with any of the arguments of the
original button constructor it will override the original button's
values.  Use it to build sets of related buttons; for example, same
font and colors, but different texts and output files. 

=head2 Change the button

  $b->override(self => { btcolor  => [10, 10, 10],
                         fontsize => 12 });

Accepts a dictionary reference I<self> with new parameters.  Any
parameter that the button's constructor understands can be reset here.

=head1 SEE ALSO

F<Image::Button::Plain> for specifics on plain rectangular buttons.

F<Image::Button::Rect> for specifics on 3D rectangular buttons.

F<Image::Button::Set> for building sets of related buttons.

=head1 TODO

Add tests.  Oval buttons.  Triangular buttons (arrow type).

=head1 AUTHOR

Juan M. García-Reyero E<lt>joanmg@twostones.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2003 Juan M. García-Reyero.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


