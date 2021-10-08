package Geo::GoogleEarth::Pluggable::Style;
use base qw{Geo::GoogleEarth::Pluggable::StyleBase};
use Scalar::Util qw{reftype};
use XML::LibXML::LazyBuilder qw{E};
use warnings;
use strict;

our $VERSION='0.17';
our $PACKAGE=__PACKAGE__;

=head1 NAME

Geo::GoogleEarth::Pluggable::Style - Geo::GoogleEarth::Pluggable Style Object

=head1 SYNOPSIS

  use Geo::GoogleEarth::Pluggable;
  my $document=Geo::GoogleEarth::Pluggable->new();
  my $style=$document->Style();

=head1 DESCRIPTION

Geo::GoogleEarth::Pluggable::Style is a L<Geo::GoogleEarth::Pluggable::Base> with a few other methods.

=head1 USAGE

  my $style=$document->Style(id=>"Style_Internal_HREF",
                             iconHref=>"http://.../path/image.png");

=head1 CONSTRUCTOR

=head2 new

  my $style=$document->Style(id=>"Style_Internal_HREF",
                             iconHref=>"http://.../path/image.png");

=head1 METHODS

=head2 type

Returns the object type.

  my $type=$style->type;

=cut

sub type {"Style"};

=head2 node

=cut

sub node {
  my $self=shift;
  my @element=();
  foreach my $style (keys %$self) {
    next if $style eq "document";
    next if $style eq "id";
    my @subelement=();
    if (reftype($self->{$style}) eq "HASH") {
      foreach my $key (keys %{$self->{$style}}) {
        my $value=$self->{$style}->{$key};
        #printf "Style: %s, Key: %s, Value: %s\n", $style, $key, $value;
        #push @subelement, E(key=>{}, $key);
        if ($key eq "color") {
          push @subelement, E($key=>{}, $self->color($value));
        } elsif ($key eq "href") {
          if ($style eq "ListStyle") { #Google Earth Inconsistency!
            push @subelement, E(ItemIcon=>{}, E($key=>{}, $value));
          } else {
            push @subelement, E(Icon=>{}, E($key=>{}, $value)); #which way to default
          }
        } elsif (ref($value) eq "HASH") { #e.g. hotSpot
          push @subelement, E($key=>$value);
        } elsif (ref($value) eq "ARRAY") {
          push @subelement, E($key=>{}, join(",", @$value));
        } else {
          push @subelement, E($key=>{}, $value);
        }
      }
    } else {
      warn("Warning: Expecting $style to be a hash reference.");
    }
    push @element, E($style=>{}, @subelement);
  }
  return E(Style=>{id=>$self->id}, @element);
}

=head2 color

Returns a color code for use in the XML structure given many different inputs.

  my $color=$style->color("FFFFFFFF"); #AABBGGRR in hex
  my $color=$style->color({color="FFFFFFFF"});
  my $color=$style->color({red=>255, green=>255, blue=>255, alpha=>255});
  my $color=$style->color({rgb=>[255,255,255], alpha=>255});
  my $color=$style->color({abgr=>[255,255,255,255]});
 #my $color=$style->color({name=>"blue", alpha=>255});  #TODO with ColorNames

Note: alpha can be 0-255 or "0%"-"100%"

=cut

sub color {
  my $self=shift;
  my $color=shift;
  if (ref($color) eq "HASH") {
    if (defined($color->{"color"})) {
      return $color->{"color"} || "FFFFFFFF";
    } else {
      my $a=$color->{"a"} || $color->{"alpha"} || $color->{"abgr"}->[0];
      my $b=$color->{"b"} || $color->{"blue"}  || $color->{"abgr"}->[1] || 0;
      my $g=$color->{"g"} || $color->{"green"} || $color->{"abgr"}->[2] || 0;
      my $r=$color->{"r"} || $color->{"red"}   || $color->{"abgr"}->[3] || 0;
      $a=255 unless defined $a;
      if ($a=~m/(\d+)%/) {
        $a=$1/100*255;
      }
      return unpack("H8", pack("C4", $a,$b,$g,$r));
    }
  } else {
    return $color || "FFFFFFFF";
  }
}

=head1 BUGS

Please log on RT and send to the geo-perl email list.

=head1 SUPPORT

Try geo-perl email list.

=head1 AUTHOR

    Michael R. Davis (mrdvt92)
    CPAN ID: MRDVT

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::GoogleEarth::Pluggable> creates a GoogleEarth Document.

=cut

1;
