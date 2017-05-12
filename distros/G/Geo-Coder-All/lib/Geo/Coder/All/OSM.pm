package Geo::Coder::All::OSM;
use Moose;
use namespace::autoclean;
use Carp;
use Geo::Coder::OSM;
use Data::Dumper;
use Locale::Codes::Country;
with 'Geo::Coder::Role::Geocode';
has 'OSM' => (
    is      =>  'ro',
    isa     =>  'Geo::Coder::OSM',
    default => sub { Geo::Coder::OSM->new();},
);

sub geocode_local{
    my ($self,$rh_args) = @_;
    croak "Location String needed" unless ($rh_args->{location});    
    my $rh_response = $self->OSM->geocode(location => $rh_args->{location});
    print STDERR Dumper($rh_response) if($rh_args->{DEBUG});
    return $self->_process_response($rh_response);
}
    
sub reverse_geocode_local {
    my ($self,$rh_args) = @_;
    croak 'latlng needed to reverse geocode' unless($rh_args->{latlng});
    my $rh_response = $self->OSM->reverse_geocode(latlng=>$rh_args->{latlng});
    print STDERR Dumper($rh_response) if($rh_args->{DEBUG});
    return $self->_process_response($rh_response);
}

sub _process_response {
    my ($self,$rh_response) = @_;
    return undef unless($rh_response);
    my $rh_data;
    $rh_data->{geocoder}        = 'OSM';
    $rh_data->{address}         = $rh_response->{display_name};
    $rh_data->{coordinates}{lat}= $rh_response->{lat};
    $rh_data->{coordinates}{lon}= $rh_response->{lon};
    $rh_data->{country}         = $rh_response->{address}{country};
    $rh_data->{country_code_alpha_3} = uc(country2code($rh_response->{address}{country},'alpha-3'));
    $rh_data->{country_code}    = uc($rh_response->{address}{country_code});
    return $rh_data;
}
__PACKAGE__->meta->make_immutable;
1;
