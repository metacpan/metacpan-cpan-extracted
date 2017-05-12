package Mail::Decency::LogParser::GeoSource;

use Moose;
extends qw/
    Mail::Decency::LogParser::Core
/;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Geo::IP;
use Data::Dumper;

=head1 NAME

Mail::Decency::LogParser::GeoSource


=head1 DESCRIPTION

Log statistics about geographical sender sources.

=head1 CLASS ATTRIBUTES

=head2 interval_formats : ArrayRef[Str]

Intervals in strftime format for L<DateTime>

=cut

has interval_formats => ( is => 'rw', isa => 'ArrayRef[Str]', default => sub { [] } );

=head2 geo_ip : Geo::IP

Instance of Geo::IP

=cut

has geo_ip => ( is => 'ro', isa => 'Geo::IP', default => sub { Geo::IP->new( GEOIP_STANDARD ) } );

=head2 enable_per_sender : Bool

Wheter source stats should be enabled per sender domain.. CAN BECOME VERY HUGE!!

Default: 0

=cut

has enable_per_sender => ( is => 'rw', isa => 'Bool', default => 0 );

=head2 enable_per_recipient : Bool

Wheter source stats should be enabled per recipient domain..

Default: 0

=cut

has enable_per_recipient => ( is => 'rw', isa => 'Bool', default => 0 );

=head2 schema_definition : HashRef[HashRef]

Schema for database

=cut

has schema_definition   => ( is => 'ro', isa => 'HashRef[HashRef]', default => sub {
    {
        geo => {
            source => {
                from_domain => [ varchar => 255 ],
                to_domain   => [ varchar => 255 ],
                country     => [ varchar => 2 ],
                type        => [ varchar => 25 ],
                interval    => [ varchar => 25 ],
                counter     => 'integer',
                last_update => 'integer',
                -unique     => [ 'from_domain', 'to_domain', 'country', 'type', 'interval' ]
            },
        }
    };
} );

=head1 METHODS

=head2 init

=cut

sub setup {
    my ( $self ) = @_;
    
    $self->config->{ interval_formats } ||= [ '%Y-%m-%d', '%Y-%m', '%Y' ];
    $self->interval_formats( $self->config->{ interval_formats } );
    
    $self->enable_per_recipient( 1 )
        if $self->config->{ enable_per_recipient };
    
    $self->enable_per_sender( 1 )
        if $self->config->{ enable_per_sender };
    
    
}


=head2 handle

Checks wheter incoming mail is whilist for final recipient

=cut

sub handle_data {
    my ( $self, $parsed_ref ) = @_;
    
    # no relevant
    return 
        if ! $parsed_ref->{ ip } || ! $parsed_ref->{ final } || ! ( $parsed_ref->{ reject } || $parsed_ref->{ bounced } || $parsed_ref->{ sent } );
    
    # determine country
    my $country = $self->geo_ip->country_code_by_addr( $parsed_ref->{ ip } ) || "";
    #return unless $country;
    
    # setup save pairs
    my @pairs = ( [ qw/ total total / ] );
    push @pairs, [ $parsed_ref->{ from_domain }, 'total' ]
        if $self->enable_per_sender && $parsed_ref->{ from_domain };
    push @pairs, [ 'total', $parsed_ref->{ to_domain } ]
        if $self->enable_per_recipient && $parsed_ref->{ to_domain };
    push @pairs, [ $parsed_ref->{ from_domain }, $parsed_ref->{ to_domain } ]
        if $self->enable_per_sender && $self->enable_per_recipient
        && $parsed_ref->{ from_domain } && $parsed_ref->{ to_domain };
    
    # determin types
    my @types = qw/ total /;
    push @types, 'reject' if $parsed_ref->{ reject };
    push @types, 'bounce' if $parsed_ref->{ bounced };
    push @types, 'sent'   if $parsed_ref->{ sent };
    
    
    # determine intervals
    my $dt = DateTime->now( time_zone => 'local' );
    my @intervals = ( 'total' );
    push @intervals, map { $dt->strftime( $_ ) } @{ $self->interval_formats };
    
    foreach my $interval( @intervals ) {
        
        foreach my $type( @types ) {
            
            foreach my $ref( @pairs ) {
                my ( $from, $to ) = @$ref;
                
                $self->database->usr_lock;
                my $entry_ref = $self->database->get( geo => source => my $search_ref = {
                    from_domain => $from,
                    to_domain   => $to,
                    type        => $type,
                    interval    => $interval,
                    country     => $country,
                } ) || { counter => 0 };
                $entry_ref->{ last_update } = time();
                $entry_ref->{ counter } ++;
                $self->database->set( geo => source => $search_ref, $entry_ref );
                $self->database->usr_unlock;
            }
        }
    }
}



=head2 print_stats

=cut

sub print_stats {
    my ( $self ) = @_;
    
    foreach my $type( qw/ sent bounced reject / ) {
        print "# FROM $type\n";
        
        my ( $handle, $meth ) = $self->database->search_read( geo => source => {
            type        => $type,
            from_domain => { "!=" => 'total' },
        } );
        while ( my $ref = $handle->$meth ) {
            print "$ref->{ type };$ref->{ interval };$ref->{ from_domain };$ref->{ to_domain };$ref->{ country };$ref->{ counter }\n";
        }
        
        print "\n# TO $type\n";
        ( $handle, $meth ) = $self->database->search_read( geo => source => {
            type      => $type,
            to_domain => { "!=" => 'total' }
        } );
        while ( my $ref = $handle->$meth ) {
            print "$ref->{ type };$ref->{ interval };$ref->{ from_domain };$ref->{ to_domain };$ref->{ country };$ref->{ counter }\n";
        }
        
        print "\n# TOTAL $type\n";
        ( $handle, $meth ) = $self->database->search_read( geo => source => {
            type        => $type,
            from_domain => 'total',
            to_domain   => 'total'
        } );
        while ( my $ref = $handle->$meth ) {
            print "$ref->{ type };$ref->{ interval };$ref->{ from_domain };$ref->{ to_domain };$ref->{ country };$ref->{ counter }\n";
        }
        print "\n\n";
    }
    
}


=head2 maintenance

Remove old cumulated entries. See maintenance_ttl

=cut

sub maintenance {
    my ( $self ) = @_;
    my $obsolete_time = time() - $self->maintenance_ttl;
    
    $self->logger->debug0( "Clear obsolete entries (TTL ". $self->maintenance_ttl. ")" );
    
    $self->database->remove( geo => source => {
        last_update => {
            '<' => $obsolete_time
        }
    } );
    
}







=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
