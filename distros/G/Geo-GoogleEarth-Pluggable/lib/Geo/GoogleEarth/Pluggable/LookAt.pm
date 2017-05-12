package Geo::GoogleEarth::Pluggable::LookAt;
use strict;
use warnings;
use base qw{Geo::GoogleEarth::Pluggable::Constructor};
use XML::LibXML::LazyBuilder qw{E};

our $VERSION="0.14";

=head1 NAME

Geo::GoogleEarth::Pluggable::LookAt - Geo::GoogleEarth::Pluggable LookAt package

=head1 SYNOPSIS

  my $lookat=$document->LookAt(
                               latitude  => 38.1741527,
                               longitude => -96.7839388,
                               range     => 3525808,
                               heading   => 0,
                               tilt      => 0,
                              );

Assign LookAt during construction

  my $folder=$document->Folder(name=>"MyLook", lookat=>$lookat);
  my $point=$folder->Point(lat=>$lat, lon=>$lon, lookat=>$lookat);

Assign LookAt afer construction

  $document->lookat($lookat);
  $folder->lookat($lookat);
  $point->lookat($lookat);

Do it all at one time

  my $point=$folder->Point(lat    => $lat,
                           lon    => $lon,
                           lookat => $document->LookAt(%data));

=head1 DESCRIPTION

Provides a way to configure a LookAt for all Folders and Placemarks.

=head1 USAGE

=head1 CONSTRUCTOR

All Folder objects have a LookAt constructor.

  my $object=$document->LookAt(%data);
  my $object=$folder->LookAt(%data);

=head2 new

=head2 type

Returns the object type.

  my $type=$lookat->type;


=cut

sub type {"LookAt"};

=head2 latitude

=cut

sub latitude {
  my $self=shift;
  $self->{"latitude"}=shift if @_;
  return $self->{"latitude"};
}

=head2 longitude

=cut

sub longitude {
  my $self=shift;
  $self->{"longitude"}=shift if @_;
  return $self->{"longitude"};
}

=head2 range

=cut

sub range {
  my $self=shift;
  $self->{"range"}=shift if @_;
  return $self->{"range"};
}

=head2 tilt

=cut

sub tilt {
  my $self=shift;
  $self->{"tilt"}=shift if @_;
  return $self->{"tilt"};
}

=head2 heading

=cut

sub heading {
  my $self=shift;
  $self->{"heading"}=shift if @_;
  return $self->{"heading"};
}

=head2 node

Returns the L<XML::LibXML::LazyBuilder> element for the LookAt object.

=cut

sub node {
  my $self=shift;
  my @elements=();
  my %skip=map {$_=>1} qw{document};
  foreach my $key (sort keys %$self) {
    next if exists $skip{$key};
    push @elements, E($key => {}, $self->{$key});
  }
  return E(LookAt => {}, @elements);
}

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

L<Geo::GoogleEarth::Pluggable> creates a GoogleEarth Document.

=cut

1;
