package Acme::Colour;

use strict;
use Error;
use Graphics::ColorNames;
use List::Util qw(max min);
use vars qw($VERSION);

$VERSION = '1.01';

use overload '""' => \&colour,
             '+'  => \&oadd,
             '-'  => \&osub;

my(%r, %g, %b);

sub import {
  my $class = shift;
  my $hash  = { @_ };

  $class->build_colours();

  if ($hash->{constants}) {
    overload::constant(
      'q' => \&createnew
    );
  } else {
    # do nothing for now
  }
}

sub build_colours {
  my $class = shift;

  if (scalar(keys %r) == 0) {
    tie my %COLOURS, 'Graphics::ColorNames', 'X';

    foreach my $colour (keys %COLOURS) {
      next if $colour =~ /\d/;
      my($r, $g, $b) = map { hex($_) / 255 } ($COLOURS{$colour} =~ /^\#?([\da-f][\da-f])([\da-f][\da-f])([\da-f][\da-f])/i);
      $r{$colour} = $r;
      $g{$colour} = $g;
      $b{$colour} = $b;
      #    print "$colour: $r/$g/$b\n";
    }
  }
}

sub createnew {
  my $colour = shift;
  my $interp = shift;

  if (exists $r{$interp}) {
    return Acme::Colour->new($interp);
  } else {
    return $interp;
  }
}

sub oadd {
  my $a = shift;
  my $b = shift;
  $a->add($b);
  return $a;
}

sub osub {
  my $a = shift;
  my $b = shift;
  $a->mix($b);
  return $a;
}

sub new {
  my($class, $colour) = @_;

  my $self = {};
  bless $self, $class;

  if (defined $colour) {
    unless (exists $r{$colour}) {
      throw Error::Simple("Colour $colour is unknown");
    }
    $self->{colour} = $colour;
  } else {
    $self->{colour} = $self->default;
  }

  return $self;
}

sub default {
  return "white";
}

sub colour {
  my $self = shift;
  return $self->{colour};
}

sub add {
  my $self = shift;
  my $add = shift;
  my $factor = shift;
  $factor = 1 unless defined $factor;

  my $colour = $self->colour;

  throw Error::Simple("Colour $colour is unknown")
    unless exists $r{$colour};
  throw Error::Simple("Colour $add is unknown")
    unless exists $r{$add};

  my($r1, $g1, $b1) = ($r{$colour}, $g{$colour}, $b{$colour});
  my($r2, $g2, $b2) = ($r{$add}, $g{$add}, $b{$add});
  $r1 += $r2 * $factor;
  $g1 += $g2 * $factor;
  $b1 += $b2 * $factor;
  $r1 = 1 if $r1 > 1;
  $g1 = 1 if $g1 > 1;
  $b1 = 1 if $b1 > 1;
  my $closest = $self->closest($r1, $g1, $b1);
  $self->{colour} = $closest;
}

sub mix {
  my $self = shift;
  my $add = shift;
  my $factor = shift;
  $factor = 1 unless defined $factor;

  my $colour = $self->colour;

  throw Error::Simple("Colour $colour is unknown")
    unless exists $r{$colour};
  throw Error::Simple("Colour $add is unknown")
    unless exists $r{$add};

  my($r1, $g1, $b1) = ($r{$colour}, $g{$colour}, $b{$colour});
  my($r2, $g2, $b2) = ($r{$add}, $g{$add}, $b{$add});

  ($r1, $g1, $b1) = (1 - $r1, 1 - $g1, 1 - $b1);
  ($r2, $g2, $b2) = (1 - $r2, 1 - $g2, 1 - $b2);

  $r1 += $r2 * $factor;
  $g1 += $g2 * $factor;
  $b1 += $b2 * $factor;
  $r1 = 1 if $r1 > 1;
  $g1 = 1 if $g1 > 1;
  $b1 = 1 if $b1 > 1;

  ($r1, $g1, $b1) = (1 - $r1, 1 - $g1, 1 - $b1);

  my $closest = $self->closest($r1, $g1, $b1);
  $self->{colour} = $closest;
}

sub closest {
  my($self, $r1, $g1, $b1) = @_;

  my $bestdelta = 100;
  my $closest;
  foreach my $colour (sort keys %r) {
    my($r2, $g2, $b2) = ($r{$colour}, $g{$colour}, $b{$colour});
    my $delta = sqrt(($r1 - $r2)**2 + ($g1 - $g2)**2 + ($b1 - $b2)**2);
    if ($delta < $bestdelta) {
      $closest = $colour;
      $bestdelta = $delta;
    }
  }
  return $closest;
}

1;

__END__

=head1 NAME

Acme::Colour - additive and subtractive human-readable colours

=head1 SYNOPSIS

  # light
  $c = Acme::Colour->new("black");
  $colour = $c->colour; # black
  $c->add("red");   # $c->colour now red
  $c->add("green"); # $c->colour now yellow

  # pigment
  $c = Acme::Colour->new("white");
  $c->mix("cyan");    # $c->colour now cyan
  $c->mix("magenta"); # $c->colour now blue

=head1 DESCRIPTION

The Acme::Colour module mixes colours with human-readable names.

There are two types of colour mixing: the mixing of lights and the
mixing of pigments. If one take two differently coloured beams of
light and projects them on to a screen, the mixing of these lights
occurs according to the principle of additive colour mixing. If one
mixes two differently coloured paints they mix according to the
principle of subtractive colour mixing.

=head1 METHODS

=head2 new()

The new() method creates a new colour. It takes an optional argument
which is the initial colour used:

  $c = Acme::Colour->new("black");

=head2 colour()

The colour() method returns the current colour. Note that
stringification of the colour object magically returns the colour too:

  $colour = $c->colour; # black
  print "The colour is $c!\n";

=head2 add()

The add() method performs additive mixing on the colour. It takes in
the colour to add in:

  $c->add("red");

=head2 mix()

The mix() method performs subtractive mixing on the colour. It takes
in the colour to mix in:

  $c->mix("cyan");

=head1 ALTERNATIVE INTERFACE

There is an alternative interface to this module which overloads
string quoting. This is very cute, but is not recommended in
production code. Strings containing colour names magically get
converted into Acme::Colour objects and additive and subtractive
mixing is performed on these "strings" using "+" and "-":

  use Acme::Colour constants => 1; # note special invocation

  my $red = "red";            # now an Acme::Colour object
  my $green = "green";        # likewise
  my $yellow = $red + $green; # add()s the two colours

  my $cyan = "cyan";           # now an Acme::Colour object
  my $magenta = "magenta";     # likewise
  my $blue = $cyan - $magenta; # mix()es the two colours

=head1 NOTES

A good explanation of colour and colour mixing is available at:
http://www.photoshopfocus.com/cool_tips/tips_color_basics_p1.htm

This module throws an exception upon unknown colours.

No, "colour" is not a typo.

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2002-3, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut
