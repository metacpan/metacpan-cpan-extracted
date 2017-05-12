package Geo::Coder::All;
use Moose;
use namespace::autoclean;
use Module::Runtime qw(require_module);

my %VALID_GEOCODER_LIST = map { $_ => 1} qw(
    Google
    OSM
    TomTom
    Ovi
    Bing
);
has 'geocoder'              => (is=>'rw',isa=>'Str',default=>'Google');
has 'key'                   => (is=>'rw',isa=>'Str',default=>'',    reader=>'get_key');
has 'langauge'              => (is=>'rw',isa=>'Str',default=>'en',  reader=>'get_language',             init_arg=>'language');
has 'google_client'         => (is=>'rw',isa=>'Str',default=>'',    reader=>'get_google_client',        init_arg=>'client');
has 'google_apiver'         => (is=>'rw',isa=>'Num',default=>3,     reader=>'get_google_apiver',        init_arg=>'apiver');
has 'google_encoding'       => (is=>'rw',isa=>'Str',default=>'utf8',reader=>'get_google_encoding',      init_arg=>'encoding');
has 'google_country_code'   => (is=>'rw',isa=>'Str',default=>'',    reader=>'get_google_country_code',  init_arg=>'country_code');
has 'google_sensor'         => (is=>'rw',isa=>'Str',default=>'',    reader=>'get_google_sensor',        init_arg=>'sensor');

has 'geocoder_engine' => (
    is  => 'rw',
    init_arg => undef,
    lazy => 1,
    isa => 'Object',
    builder => '_build_geocoder_engine',
    handles =>{
        geocode         => 'geocode_local',
        reverse_geocode => 'reverse_geocode_local'
        } 
    );

sub _build_geocoder_engine {
    my $self        = shift;
    my $geocoder    = $self->geocoder;
    
    if(!$VALID_GEOCODER_LIST{$geocoder} && $geocoder !~ /::/ ){
        $geocoder = 'Google';
        $self->geocoder('Google');
    }
    
    my $class = ($geocoder =~ /::/ ? $geocoder : 'Geo::Coder::All::'.$geocoder);
    require_module($class);
    return $class->new(); 
}

around 'geocode' => sub{
    my ($orig,$class,$rh_args) =  @_;
    return $class->$orig($class->_process_args($rh_args));
};

around 'reverse_geocode' => sub{
    my ($orig,$class,$rh_args) =  @_;
    return $class->$orig($class->_process_args($rh_args));
};
#process the args passed to create new Geo::Coder::Google
sub _process_args {
    my ($self,$rh_args) =@_;
    $rh_args->{key}         ||= $self->get_key;
    $rh_args->{language}    ||= $self->get_language;
    $rh_args->{google_apiver}= $self->get_google_apiver || $rh_args->{apiver} if($self->geocoder eq 'Gooole');
    $rh_args->{google_client}= $self->get_google_client || $rh_args->{client} if($self->geocoder eq 'Google');
    $rh_args->{google_encoding}= $self->get_google_encoding || $rh_args->{encoding} if($self->geocoder eq 'Google');
    $rh_args->{google_country_code}= $self->get_google_country_code || $rh_args->{country_code} if($self->geocoder eq 'Google');
    return $rh_args;
}

=head1 NAME

Geo::Coder::All - Geo::Coder::All

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';


=head1 DESCRIPTION

Geo::Coder::All is wrapper for other geocoder cpan modules such as Geo::Coder::Google,Geo::Coder::Bing,Geo::Coder::Ovi,Geo::Coder::OSM and Geo::Coder::TomTom. Geo::Coder::All provides common geocode output format for all geocoder.


=head1 SYNOPSIS

    use Geo::Coder::All;
    #For google geocoder
    my $google_geocoder = Geo::Coder::All->new();#geocoder defaults to Geo::Coder::Google::V3
    #You can also use optional params for google api
    my $google_geocoder = Geo::Coder::All->new(key=>'GMAP_KEY',client=>'GMAP_CLIENT');

    #For Bing 
    my $bing_geocoder = Geo::Coder::All->new(geocoder=>'Bing',key=>'BING_API_KEY');

    #For Ovi 
    my $ovi_geocoder = Geo::Coder::All->new(geocoder=>'Ovi');

    #For OSM 
    my $osm_geocoder = Geo::Coder::All->new(geocoder=>'OSM');

    #For TomTom 
    my $tomtom_geocoder = Geo::Coder::All->new(geocoder=>'TomTom');

    #Currently supported geocoders are 
    Geo::Coder::Google
    Geo::Coder::Bing
    Geo::Coder::TomTom
    Geo::Coder::Ovi
    Geo::Coder::OSM
    #only Geo::Coder::Google is installed by default if you need to use other then you should install them manually

    #IF you want use geocder that is not listed above then you can now specify fully qualified class wrapper name to add your own custom handling for response. Please have look at how Geo::Coder::All::Google is working.

=head1 METHODS

Geo::Coder::All offers geocode and reverse_geocode methods

=over 2

=item geocode

For Google geocoder , we can directly set the different geocoding options when calling geocode and reverse_geocode methods. i.e If you use Geo::Coder::Google you will have to create new instance every single time you need to change geocoding options

    $rh_location = $google_geocoder->geocode({location => 'London'});
    #above will return London from United Kingdom
    #With geocoding options 
    #Following will return London from Canada as we used country_code is  ca (country_code is ISO 3166-1 )
    $rh_location = $google_geocoder->geocode({location => 'London',language=>'en',country_code=>'ca',encoding=>'utf8',sensor=>1});
    #in spanish
    $rh_location = $google_geocoder->geocode({location => 'London',language=>'es',country_code=>'ca',encoding=>'utf8',sensor=>1});
    #default encodings is set to 'utf8' you can change to other such as 'latin1'
    #You can also set DEGUB=>1 to dump raw response from the geocoder api

You cal also set GMAP_KEY and GMAP_CLIENT directly from geocode/reverse_geocode method and it will just work

=item reverse_geocode

For Google reverse_geocoder 

    $rh_location = $google_geocoder->reverse_geocode({latlng=>'51.508515,-0.1254872',language=>'en',encoding=>'utf8',sensor=>1})
    #in spanish
    $rh_location = $google_geocoder->reverse_geocode({latlng=>'51.508515,-0.1254872',language=>'es',encoding=>'utf8',sensor=>1})
    
=back

=head1 SEE ALSO

L<Geo::Coder::Many>,
L<Geo::Coder::Google>,
L<Geo::Coder::Bing>,
L<Geo::Coder::Ovi>,
L<Geo::Coder::OSM> and 
L<Geo::Coder::TomTom>.

=head1 AUTHOR

Rohit Deshmukh, C<< <raigad1630 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-coder-all at rt.cpan.org>, or through
the web interface at L<https://github.com/raigad/geo-coder-all/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::All

=head1 ACKNOWLEDGEMENTS

Peter Sergeant, C<< <sargie@cpan.org> >>

Neil Bowers, C<< <neilb@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Rohit Deshmukh.

=cut

1; # End of Geo::Coder::All
