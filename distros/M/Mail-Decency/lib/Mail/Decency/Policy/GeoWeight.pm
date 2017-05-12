package Mail::Decency::Policy::GeoWeight;

use Moose;
extends 'Mail::Decency::Policy::Core';

use version 0.74; our $VERSION = qv( "v0.1.6" );

use Geo::IP;
use Data::Dumper;
use DateTime;

=head1 NAME

Mail::Decency::Policy::GeoWeight

=head1 DESCRIPTION

Implements weighting and statistics by countries. It can be used for collecting stats from which countries the senders come from as well as for fighting spam by scoring certain countries (negative or positive).

B<This module requires Geo::IP which itself requires various libraries on your OS.> 

=head1 CONFIG

    ---
    disable: 0
    
    enable_stats: 1
    
    weight_classes:
        -
            countries:
                - DE
                - US
                - AU
            weight: 10
        -
            countries:
                - SE
                - DK
            weight: 5
        - { countries: [ 'XX' ], weight: -100 }
    
    weight_default: -5


=head1 CLASS ATTRIBUTES


=head2 weight_by_country : HashRef

Weight class, containging one or multiple country codes and a weighting (positive or negative)

=cut

has weight_by_country => ( is => 'rw', isa => 'HashRef[Int]', default => sub { {} } );

=head2 weight_default : Int

Weight for all values not specified via "weight_by_country"

=cut

has weight_default    => ( is => 'rw', isa => 'Int', default => 0 );

=head2 enable_stats : Bool

Enable statistics by country (either stats or weight or both should be enabled)

=cut

has enable_stats      => ( is => 'rw', isa => 'Bool', default => 0 );

=head2 enable_weight : Bool

Enable weighting (either stats or weight or both should be enabled)

=cut

has enable_weight     => ( is => 'rw', isa => 'Bool', default => 1 );

=head2 geo_ip : Geo::IP

=cut

has geo_ip            => ( is => 'ro', isa => 'Geo::IP', default => sub { Geo::IP->new( GEOIP_STANDARD ) } );

=head2 schema_definition

Database schema

=cut

has schema_definition => ( is => 'ro', isa => 'HashRef[HashRef]', default => sub {
    {
        geo => {
            stats => {
                country   => [ varchar => 2 ],
                interval  => [ varchar => 25 ],
                counter   => 'integer',
                -unique   => [ 'country', 'interval' ]
            },
        }
    };
} );


=head1 METHODS

=head2 init

Checks weight classes

=cut

sub init {
    my ( $self ) = @_;
    
    # enable stats
    $self->enable_weight( 0 )
        if $self->config->{ disable_weight };
    
    if ( $self->enable_weight ) {
        
        # having weight classes -> check and setup
        if ( defined ( my $weight_classes_ref = $self->config->{ weight_classes } ) ) {
            my @classes = ref( $weight_classes_ref ) eq 'ARRAY'
                ? @{ $weight_classes_ref }
                : ( $weight_classes_ref )
            ;
            
            # check classes
            foreach my $class_ref( @classes ) {
                die "'$class_ref' is not a HashRef! weight_classes should be ArrayRef[HashRef]\n"
                    unless ref( $class_ref ) eq 'HASH';
                die "Require 'countries' as ArrayRef\n"
                    unless defined $class_ref->{ countries } && ref( $class_ref->{ countries } ) eq 'ARRAY';
                die "Require 'weight' for countries '". join( ", ", @{ $class_ref->{ countries } } ). "'\n"
                    unless defined $class_ref->{ weight } && $class_ref->{ weight } =~ /^\d+$/;
                
                foreach my $country( @{ $class_ref->{ countries } } ) {
                    die "Please use 2-char country code format like 'DE' or 'US'.. '$country' does not fit\n"
                        unless length( $country ) == 2 && $country =~ /^[a-z]{2}$/i;
                    $self->weight_by_country->{ uc( $country ) } = $class_ref->{ weight };
                }
            }
        }
        
        # having default weight ..
        $self->weight_default( $self->config->{ weight_default } )
            if defined $self->config->{ weight_default };
    }
    
    # enable stats
    $self->enable_stats( 1 )
        if $self->config->{ enable_stats };
    
    die "You have to enable at least one of stats or weight\n"
        unless $self->enable_stats || $self->enable_weight;
    
    return ;
}


=head2 handle

Either build stats per country or score with negative or positve weight per country or do both

=cut

sub handle {
    my ( $self, $server, $attrs_ref ) = @_;
    
    # get client's country
    my $country = $self->geo_ip->country_code_by_addr( $attrs_ref->{ client_address } );
    
    # no country determiend .. probably LAN ip ..
    return unless $country;
    
    # write for stats
    if ( $self->enable_stats ) {
        my $dt = DateTime->now( time_zone => 'local' );
        my @intervals = ( 'total' );
        push @intervals, (
            $dt->strftime( '%Y' ),
            $dt->strftime( '%Y-%m' ),
            $dt->strftime( '%Y-%m-%d' ),
        );
        $self->database->increment( geo => stats => {
            country  => $country,
            interval => $_
        }, 1, 'counter' ) for @intervals;
    }
    
    if ( $self->enable_weight ) {
        
        # having determiend weight
        my $weight = defined $self->weight_by_country->{ $country }
            ? $self->weight_by_country->{ $country }
            : $self->weight_default
        ;
        if ( $weight ) {
            $self->add_spam_score( $weight, join( ";",
                "Weight: $weight",
                "Country: $country"
            ), "GeoWeight: $weight" );
        }
    }
    
    return ;
}



=head2 print_stats

Print statistics per country

=cut

sub print_stats {
    my ( $self ) = @_;
    
    my $dt = DateTime->now( time_zone => 'local' );
    my @intervals = ( 'total' );
    push @intervals, (
        $dt->strftime( '%Y' ),
        $dt->strftime( '%Y-%m' ),
        $dt->strftime( '%Y-%m-%d' ),
    );
    
    print "\n# **** GEO STATS ****\n\n";
    foreach my $interval( @intervals ) {
        
        my ( $handle, $meth ) = $self->database->search_read( geo => stats => {
            interval => $interval
        } );
        print "# Interval $interval\n";
        while ( my $ref = $handle->$meth ) {
            print "$ref->{ interval };$ref->{ country };$ref->{ counter }\n";
        }
        print "\n";
    }
}



=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut




1;
