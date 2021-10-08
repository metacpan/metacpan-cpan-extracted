package Geo::GoogleEarth::Pluggable::Plugin::Others;
use strict;
use warnings;

our $VERSION='0.17';

=head1 NAME

Geo::GoogleEarth::Pluggable::Plugin::Others - Geo::GoogleEarth::Pluggable Others Plugin Methods

=head1 SYNOPSIS

  use Geo::GoogleEarth::Pluggable;
  my $document=Geo::GoogleEarth::Pluggable->new;
  my @point=$document->MultiPoint(%data); #()
  my $point=$document->MultiPoint(%data); #[]

=head1 METHODS

Methods in this package are AUTOLOADed into the  Geo::GoogleEarth::Pluggable::Folder namespace at runtime.

=head2 MultiPoint

  my @point=$document->MultiPoint(
                         name=>"Point",              #SCALAR sprintf("%s (%s)", $name, $index)
                         coordinates=>[{}, {}, ...], #CODE ($index, $point)
                   #TODO#name=>["pt1", "pt2", ...],  #ARRAY
                   #TODO#name=>sub{sprintf("Point %s is a %s", shift, ref(shift))},
                              );

Note: Currently coordinates must be {lat=>$lat, lon=>$lon, alt=>$alt}

TODO: Coordinates can be any format supported by Placemark->coordinates

=cut

sub MultiPoint {
  my $self=shift; #$self isa Geo::GoogleEarth::Pluggable::Folder object
  my %data=@_;
  $data{"name"}||="Point";
  $data{"coordinates"}=[] unless ref($data{"coordinates"}) eq "ARRAY";
  my @point=();
  my $index=0;
  foreach my $pt (@{$data{"coordinates"}}) {
    my $name=sprintf("%s (%s)", $data{"name"}, $index++);
    push @point, $self->Point(
                              name=>$name,
                              %$pt
                             ); 
  }
  return wantarray ? @point : \@point;
}

=head1 TODO

=head1 BUGS

Please log on RT and send to the geo-perl email list.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis (mrdvt92)
  CPAN ID: MRDVT

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::GoogleEarth::Pluggable>

=cut

1;
