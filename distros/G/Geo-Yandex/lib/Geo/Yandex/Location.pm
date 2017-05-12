package Geo::Yandex::Location;

use vars qw ($VERSION);
$VERSION = '0.3';

use strict;
use utf8;
use XML::LibXML;

sub new {
    my ($class, $context, $featureMember) = @_;
    
    my $this = {
    };
    
    bless $this, $class;
    $this->parse($context, $featureMember);

    return $this;
}

sub parse {
    my ($this, $context, $featureMember) = @_;
    
    my $metadata = ${$context->findnodes('.//gml:metaDataProperty', $featureMember)}[0];
    $this->{'kind'}         = $this->get_single_value($context, './/ygeo:kind',             $metadata);
    $this->{'address'}      = $this->get_single_value($context, './/ygeo:text',             $metadata);
    $this->{'country'}      = $this->get_single_value($context, './/xal:CountryName',       $metadata);
    $this->{'locality'}     = $this->get_single_value($context, './/xal:LocalityName',      $metadata);
    $this->{'thoroughfare'} = $this->get_single_value($context, './/xal:ThoroughfareName',  $metadata);
    $this->{'premise'}      = $this->get_single_value($context, './/xal:PremiseNumber',     $metadata);

    my $bound = ${$context->findnodes('.//gml:boundedBy', $featureMember)}[0];
    $this->{'lowerCorner'}  = $this->get_single_value($context, './/gml:lowerCorner',       $bound);
    $this->{'upperCorner'}  = $this->get_single_value($context, './/gml:upperCorner',       $bound);

    my $point = ${$context->findnodes('.//gml:Point', $featureMember)}[0];
    $this->{'pos'}          = $this->get_single_value($context, './/gml:pos',               $point);

    ($this->{'longitude'}, $this->{'latitude'}) = split / /, $this->{'pos'};   
}

sub get_single_value {
    my ($this, $context, $xpath, $node) = @_;
    
    my @children = $context->findnodes($xpath, $node);
    
    return @children ? $children[0]->textContent : undef;
}

sub kind {
    my $this = shift;
    
    return $this->{'kind'};
}

sub address {
    my $this = shift;
    
    return $this->{'address'};
}

sub country {
    my $this = shift;
    
    return $this->{'country'};
}

sub locality {
    my $this = shift;
    
    return $this->{'locality'};
}

sub thoroughfare {
    my $this = shift;
    
    return $this->{'thoroughfare'};
}

sub premise {
    my $this = shift;
    
    return $this->{'premise'};
}

sub lowerCorner {
    my $this = shift;
    
    return $this->{'lowerCorner'};
}

sub upperCorner {
    my $this = shift;
    
    return $this->{'upperCorner'};
}

sub pos {
    my $this = shift;
    
    return $this->{'pos'};
}

sub longitude {
    my $this = shift;
    
    return $this->{'longitude'};
}

sub latitude {
    my $this = shift;
    
    return $this->{'latitude'};
}

1;

__END__

=head1 NAME

Geo::Yandex::Location - Presents location data produced by Yandex Maps API

=head1 SYNOPSIS

    my @locations = $geo->location(address => $addr);
    
    for my $item (@locations) {
        say $item->address . ' (' . $item->kind .') ' .
            $item->latitude . ',' . $item->longitude;
    }

    
=head1 ABSTRACT

Geo::Yandex::Location is an object which may be returned by C<Geo::Yandex::location> method in response to search query. The object is a combination of fields that describe the location in hand.

=head1 DESCRIPTION

Normally you do not create Geo::Yandex::Location objects yourself. These objects are intended to be read-only, and are created during geographical query initiated by calling C<location> method of C<Geo::Yandex> instance. All the methods listed below return either a scalar with text or numeric data, or undef in case those pieces of information cannot be applied to the location. Particular fields are formed according to GML specification (http://www.opengis.net/gml/).

=head2 kind
    
    say $location->kind;

Type of the object, such as I<street> or I<house>.

=head2 address

    say $location->address;
    
Full and "correct" address of the location. This address may differ from initial request. 

=head2 country

    say $location->country;

The name of the country where the object is located. Note that this name may be already contained within C<address> field.

=head2 locality

    say $location->country;
    
The name of the locality, for example the name of the city if the location was a city.

=head2 thoroughfare

    say $location->thoroughfare;
    
Thoroughfare name. E. g., the name of the street.

=head2 premise

    say $location->premise;
    
Premise information (house number). May contain several parts, e. g. I<building> part of the address.

=head2 lowerCorner, upperCorner;

    say $location->lowerCorner;
    say $location->lowerCorner;

Boundaries of the location. Each value is a string containing the pair of longitude and latitude. For exact format please refer to GML specification.

=head2 pos

    say $location->pos

Exact position of the location. Contains two numbers (latitude and longitude), separated by space. Use C<longitude> and C<latitude> methods to work with these data separately.
    
=head longitude, latitude;

    say $location->longitude;
    say $location->latitude;
    
Latitude and longitude of the location. These values may be obtained together with C<pos> method.    
    
=head1 AUTHOR

Andrew Shitov, <andy@shitov.ru>

=head1 COPYRIGHT AND LICENCE

Geo::Yandex::Location module is a free software.
You may redistribute and (or) modify it under the same terms as Perl, whichever version it is.

=cut
