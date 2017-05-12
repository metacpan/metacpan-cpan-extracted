package Geo::Coder::All::TomTom;
use Moose;
use namespace::autoclean;
use Geo::Coder::TomTom;
use Carp;
use Data::Dumper;
use Locale::Codes::Country;
with 'Geo::Coder::Role::Geocode';

has 'TomTom' => (
    is      =>  'ro',
    isa     =>  'Geo::Coder::TomTom',
    default => sub{ Geo::Coder::TomTom->new();}
);

sub geocode_local {
    my ($self,$rh_args) = @_;
    croak "Location string required" unless ($rh_args->{location});
    my $rh_response = $self->TomTom->geocode(location => $rh_args->{location} );
    print STDERR Dumper($rh_response) if($rh_args->{DEBUG});
    return $self->_process_response($rh_response);
}

sub reverse_geocode_local{
    my ($self,$rh_args) = @_;
    return 'Reverse Geocode is not available for TomTom';
}

sub _process_response {
    my ($self,$rh_response) = @_;   
    return undef unless($rh_response);
    my $rh_data;
    $rh_data->{geocoder} = 'TomTom';  
    $rh_data->{address} = $rh_response->{formattedAddress};  
    $rh_data->{country} = $rh_response->{country};
    #TODO: get country code using Locale::Codes module
    $rh_data->{country_code} = uc(country2code($rh_response->{country},'alpha-2'));
    $rh_data->{country_code_alpha_3} = uc(country2code($rh_response->{country},'alpha-3'));
    $rh_data->{coordinates}{lat} = $rh_response->{latitude};  
    $rh_data->{coordinates}{lon} = $rh_response->{longitude};  
    return $rh_data;
}
__PACKAGE__->meta->make_immutable;
1;
