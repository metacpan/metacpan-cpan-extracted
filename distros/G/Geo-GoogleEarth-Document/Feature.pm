package Geo::GoogleEarth::Document::Feature;
use strict;
use base qw{Geo::GoogleEarth::Document::Base};
use Geo::GoogleEarth::Document::TimeSpan;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '0.01';
}

=head1 NAME

Geo::GoogleEarth::Document::Feature - Geo::GoogleEarth::Document::Feature

=head1 SYNOPSIS

	None, Feature is an abstract class.

=head1 DESCRIPTION

Geo::GoogleEarth::Document::Feature is a L<Geo::GoogleEarth::Document::Base> with a few other methods.

=head1 USAGE

	None, Feature is an abstract class.

=head1 CONSTRUCTOR

=head2 new

	None, Feature is an abstract class.

=head1 METHODS

=head2 type

Returns the object type.

  my $type=$Feature->type;

=cut

sub type {
  my $self=shift();
  return "Feature";
}

=head2 structure

Returns a hash reference for feeding directly into L<XML::Simple>.

my $structure = $Feature->structure;
<!-- abstract element; do not create -->
<!-- Feature id="ID" -->                
	<!-- Document,Folder, NetworkLink,Placemark, GroundOverlay,PhotoOverlay,ScreenOverlay --> 
	<name>...</name>                      
	<!-- string --> <visibility>1</visibility>            
	<!-- boolean --> <open>0</open>                        
	<!-- boolean --> <atom:author>...<atom:author>         
	<!-- xmlns:atom --> <atom:link>...</atom:link>            
	<!-- xmlns:atom --> <address>...</address>                
	<!-- string --> <xal:AddressDetails>...</xal:AddressDetails>  
	<!-- xmlns:xal --> <phoneNumber>...</phoneNumber>        
	<!-- string --> <Snippet maxLines="2">...</Snippet>   
	<!-- string --> <description>...</description>        
	<!-- string --> <AbstractView>...</AbstractView>      
	<!-- Camera or LookAt --> <TimePrimitive>...</TimePrimitive>    
	<!-- TimeStamp or TimeSpan --> <styleUrl>...</styleUrl>              
	<!-- anyURI --> <StyleSelector>...</StyleSelector> 
	<Region>...</Region> 
	<Metadata>...</Metadata>              
	<!-- deprecated in KML 2.2 --> <ExtendedData>...</ExtendedData>      
	<!-- new in KML 2.2 --> 
<-- /Feature -->

=cut

sub structure {
	my $self = shift();
	my $structure = { id=>$self->id };
	my %skip=map {$_=>1} (qw{id});

	foreach my $key (keys %$self) {
		next if exists $skip{$key};
		$structure->{$key} = {content=>$self->function($key)};	 
	}
	return $structure;
}

=head2 id

=cut

sub id {
  my $self=shift();
  $self->{'id'}=shift() if (@_);
  return $self->{'id'};
}

=head2 address

Sets or returns address

  my $address=$placemark->address;

=cut

sub address {
	my $self=shift();
	return $self->function('address', @_);
}

=head2 description

Set or returns the description.  Google Earth uses this as the HTML description in the Placemark popup window.

=cut

sub description {
	my $self=shift();
	return $self->function('description', @_);
}

=head2 snippet

Sets or returns the "snippet", which is the descriptive text shown in the
places list.  Optionally sets the maximum number of lines to show.

  my $snippet=$placemark->snippet($text);
  $placemark->snippet($text, {maxLines=>2});
  $placemark->snippet("", {maxLines=>0});        #popular setting

=cut

sub snippet {
	my $self=shift();
	return $self->function('Snippet', @_);
}

=head2 visibility

Sets or returns visibility

	my $visibility=$placemark->visibility;

=cut

sub visibility {
	my $self=shift();
	return $self->function('visibility', @_);
}

=head2 open

Sets or returns open-ness

	my $open = $folder->open;

=cut

sub open {
	my $self = shift;
	return $self->function('open', @_);
}

=head2 TimeSpan

Sets or returns TimeSpan object

   my $ts = $placemark->TimeSpan;

=cut

sub TimeSpan {
	my $self = shift();
	my $TS = Geo::GoogleEarth::Document::TimeSpan->new(@_);
	$self->{TimeSpan} = $TS->structure;
	return $TS;
}


=head1 BUGS

=head1 SUPPORT

	Contact the author.

=head1 AUTHOR

	David Hillman
	CPAN: DAHILLMA

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Geo::GoogleEarth::Document> creates a GoogleEarth KML Document.

=cut

1;
