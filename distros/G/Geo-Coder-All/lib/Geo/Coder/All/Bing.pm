package Geo::Coder::All::Bing;
use Moose;
use namespace::autoclean;
use Carp;
use Locale::Codes::Country;
use Data::Dumper;
use Geo::Coder::Bing;
with 'Geo::Coder::Role::Geocode';
has 'Bing' =>(
    is => 'rw',
    isa => 'Geo::Coder::Bing',
    writer => 'set_bing_geocoder'
);
sub geocode_local {
    my ($self,$rh_args)= @_;
    croak "API key needed" unless ($rh_args->{key});
    croak "Location string needed" unless ($rh_args->{location});
    my $rh_data;
    $self->set_bing_geocoder(Geo::Coder::Bing->new(
        key    => $rh_args->{key},
    ));
    my $rh_response = $self->Bing->geocode(location => $rh_args->{location});
    print STDERR Dumper($rh_response) if($rh_args->{DEBUG});
    return $self->_process_response($rh_response);
}
sub reverse_geocode_local{
    my ($self,$rh_args) = @_;
    return 'Reverse Geocode is not available for Bing';
}
sub _process_response{
    my ($self,$rh_response ) = @_;
    return undef unless($rh_response);
    my $rh_data;
    $rh_data->{geocoder}        = 'Bing';
    return $rh_data unless($rh_response->{address});
    $rh_data->{address}         = $rh_response->{address}{formattedAddress} ;
    $rh_data->{country}         = $rh_response->{address}{countryRegion} ;
    $rh_data->{country_code}    = uc(country2code($rh_data->{country})) if($rh_data->{country});
    $rh_data->{country_code_alpha_3} = uc(country2code($rh_data->{country},'alpha-3')) ;
    if( $rh_response->{point}{type} eq 'Point' && @{$rh_response->{point}{coordinates}} == 2){
        $rh_data->{coordinates}{lat} = $rh_response->{point}{coordinates}[0];
        $rh_data->{coordinates}{lon} = $rh_response->{point}{coordinates}->[1];
    }
    return $rh_data;
}
__PACKAGE__->meta->make_immutable;
1;
