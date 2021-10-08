package Geo::GoogleEarth::Pluggable::Base;
use warnings;
use strict;
use base qw{Geo::GoogleEarth::Pluggable::Constructor};

our $VERSION='0.17';

=head1 NAME

Geo::GoogleEarth::Pluggable::Base - Geo::GoogleEarth::Pluggable Base package

=head1 SYNOPSIS

  use base qw{Geo::GoogleEarth::Pluggable::Base};

=head1 DESCRIPTION

The is the base of all Geo::GoogleEarth::Pluggable packages.

=head1 USAGE

=head1 CONSTRUCTOR

=head2 new

  my $document = Geo::GoogleEarth::Pluggable->new(key1=>value1,
                                                  key2=>[value=>{opt1=>val1}],
                                                  key3=>{value=>{opt2=>val2}});

=head1 METHODS

=head2 name

Sets or returns the name property.

  my $name=$folder->name;
  $placemark->name("New Name");
  $document->name("New Name");

=cut

sub name {
  my $self=shift;
  $self->{'name'}=shift if @_;
  return $self->{'name'};
}

=head2 description

Sets or returns the description property.

  my $description=$folder->description;
  $placemark->description("New Description");
  $document->description("New Description");

=cut

sub description {
  my $self=shift;
  $self->{'description'}=shift if @_;
  return $self->{'description'};
}

=head2 Snippet

Returns the Snippet used in the Snippet XML element or a Placemark.  The default Snippet from Google Earth is to use the first line of the description however this package defaults to a zero line Snippet.

Snippet is rendered with maxLines as the length of the array ref and the content joined with new lines.

Typical use

  $document->Point(Snippet=>"Line 1");
  $document->Point(Snippet=>["Line 1", "Line 2"]);

Extended used

  my $snippet=$placemark->Snippet;                     #[] always array reference
  $placemark->Snippet([]);                             #default
  $placemark->Snippet(["line 1", "line 2", "line 3"]); 
  $placemark->Snippet("My Snippet Text");              #folded into array reference.
  $placemark->Snippet("line 1", "line 2", "line 3");   #folded into array reference

=cut

sub Snippet {
  my $self=shift;
  if (@_ == 1) {
    $self->{"Snippet"}=shift;
  } elsif (@_ > 1) {
    $self->{"Snippet"}=[@_];
  }
  #force undef to default empty array reference
  $self->{"Snippet"}=[] unless defined $self->{"Snippet"};
  #force to array reference
  $self->{"Snippet"}=[$self->{"Snippet"}] unless ref($self->{"Snippet"}) eq "ARRAY";
  return $self->{"Snippet"};
}
  
=head2 lookat

Sets or returns a L<Geo::GoogleEarth::Pluggable::LookAt> object

=cut

sub lookat {
  my $self=shift;
  $self->{"lookat"}=shift if @_;
  return $self->{"lookat"};
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
