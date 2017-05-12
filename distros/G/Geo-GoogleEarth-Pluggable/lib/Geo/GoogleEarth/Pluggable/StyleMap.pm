package Geo::GoogleEarth::Pluggable::StyleMap;
use base qw{Geo::GoogleEarth::Pluggable::StyleBase};
use Scalar::Util qw{blessed};
use XML::LibXML::LazyBuilder qw{E};
use warnings;
use strict;

our $VERSION='0.09';
our $PACKAGE=__PACKAGE__;

=head1 NAME

Geo::GoogleEarth::Pluggable::StyleMap - Geo::GoogleEarth::Pluggable StyleMap Object

=head1 SYNOPSIS

  use Geo::GoogleEarth::Pluggable;
  my $document=Geo::GoogleEarth::Pluggable->new;
  my $style=$document->StyleMap(%data);
  print $document->render;

=head1 DESCRIPTION

Geo::GoogleEarth::Pluggable::StyleMap is a L<Geo::GoogleEarth::Pluggable::Base> with a few other methods.

=head1 USAGE

  my $style=$document->StyleMap(
                                normal    => $style1,
                                highlight => $style2,
                               );

=head1 CONSTRUCTOR

=head2 new

  my $style=$document->StyleMap;

=head1 METHODS

=head2 type

Returns the object type.

  my $type=$style->type;

=cut

sub type {"StyleMap"};

=head2 node

Generates XML that looks like this.

  <StyleMap id="StyleMap-perl-69">
    <Pair>
      <key>normal</key>
      <styleUrl>#Style-perl-19</styleUrl>
    </Pair>
    <Pair>
      <key>highlight</key>
      <styleUrl>#Style-perl-11</styleUrl>
    </Pair>
  </StyleMap>

=cut

sub node {
  my $self=shift;
  my @element=();
  foreach my $key (keys %$self) {
    #$key should be either "normal" or "highlight"
    next if $key eq "document";
    next if $key eq "id";
    my $value=$self->{$key}||'';
    if (blessed($value) and $value->can("type") and $value->type=~m/^Style/) {
      $value=$value->url;
    }
    push @element, E(Pair=>{}, E(key=>{}, $key), E(styleUrl=>{}, $value));
  }
  return E(StyleMap=>{id=>$self->id}, @element);
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

L<Geo::GoogleEarth::Pluggable>, L<XML::LibXML::LazyBuilder>, L<Scalar::Util>

=cut

1;
