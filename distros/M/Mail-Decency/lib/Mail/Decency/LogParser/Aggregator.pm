package Mail::Decency::LogParser::Aggregator;

use Moose;
extends qw/
    Mail::Decency::LogParser::Core
/;
with qw/
    Mail::Decency::Core::Meta::Maintenance
/;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Data::Dumper;

our @CUMULATE_TYPE = qw/ ip from_domain to_domain /;

=head1 NAME

Mail::Decency::LogParser::Aggregator


=head1 DESCRIPTION

Aggregates events (sent, reject, bounced) by IP, sender domain and recipient domain in database.

=head1 CLASS ATTRIBUTES

=head2 interval_formats : ArrayRef[Str]

Intervals in strftime format for L<DateTime>

=cut

has interval_formats => ( is => 'rw', isa => 'ArrayRef[Str]', default => sub { [] } );

=head2 maintenance_ttl : Int

Maintenance Time To Live. In maintenance mode, all entries from the database older then (now - ttl) will be wiped.

=cut
has maintenance_ttl => ( is => 'rw', isa => 'Int', default => 86400 * 90 );

=head2 schema_definition : ArrayRef[Str]

Schema for Aggregator is:

=over

=item * Aggregator

=over

=item * (ip|from_domain|to_domain)

=over

=item * (ip|from_domain|to_domain)

Varchar 255 (39 for IP) .. 

=item * type

Varchar 25 .. either sent, bounced or reject

=item * interval

Varchar 25 .. the interval value, such as '2010-06-17'

=item * format

Varchar 25 .. the interval format, such as '%Y-%m-%d'

=item * counter

Integer .. the amount 

=item * last_update

Integer (timestamp) .. last time updated

=back

=back

=back

=cut

has schema_definition => ( is => 'ro', isa => 'HashRef[HashRef]', default => sub {
    {
        aggregator => {
            ip => {
                ip          => [ varchar => 39 ],
                type        => [ varchar => 25 ], # bounced, sent, reject
                interval    => [ varchar => 25 ],
                format      => [ varchar => 25 ],
                counter     => 'integer',
                transfer    => 'integer',
                last_update => 'integer',
                -unique     => [ 'ip', 'type', 'interval', 'format' ]
            },
            from_domain => {
                from_domain => [ varchar => 255 ],
                type        => [ varchar => 25 ], # bounced, sent, reject
                interval    => [ varchar => 25 ],
                format      => [ varchar => 25 ],
                counter     => 'integer',
                transfer    => 'integer',
                last_update => 'integer',
                -unique     => [ 'from_domain', 'type', 'interval', 'format' ]
            },
            to_domain => {
                to_domain   => [ varchar => 255 ],
                type        => [ varchar => 25 ], # bounced, sent, reject
                interval    => [ varchar => 25 ],
                format      => [ varchar => 25 ],
                counter     => 'integer',
                transfer    => 'integer',
                last_update => 'integer',
                -unique     => [ 'to_domain', 'type', 'interval', 'format' ]
            },
        }
    };
} );

=head1 METHODS


=head2 setup

=cut

sub setup {
    my ( $self ) = @_;
    $self->config->{ interval_formats } ||= [ '%Y-%m-%d', '%Y-%m', '%Y' ];
    $self->interval_formats( $self->config->{ interval_formats } );
}


=head2 handle_data

Checks wheter incoming mail is whilist for final recipient

=cut

sub handle_data {
    my ( $self, $parsed_ref ) = @_;
    
    # no relevant
    return 
        unless ( $parsed_ref->{ reject } || $parsed_ref->{ bounced } || $parsed_ref->{ sent } );
    
    # determine attributes
    my %db = map { ( $_ => $parsed_ref->{ $_ } ) }
        grep { defined $parsed_ref->{ $_ } }
        qw/ ip from_address to_address from_domain to_domain /
    ;
    
    # determine intervals
    my $dt = DateTime->now( time_zone => 'local' );
    my @intervals = ( [ 'total', 'total' ] );
    push @intervals, [ $dt->strftime( $_ ), $_ ]
        for @{ $self->interval_formats };
    
    foreach my $ref( @intervals ) {
        my ( $interval, $format ) = @$ref;
        
        foreach my $type( grep { defined $db{ $_ } } @CUMULATE_TYPE ) {
            $self->database->usr_lock;
            my $entry_ref = $self->database->get( aggregator => $type => my $search_ref = {
                $type    => $db{ $type },
                interval => $interval,
                format   => $format,
                type     => $parsed_ref->{ reject }
                    ? 'reject'
                    : ( $parsed_ref->{ bounced }
                        ? 'bounced'
                        : 'sent'
                    )
            } ) || { counter => 0, transfer => 0 };
            $entry_ref->{ last_update } = time();
            $entry_ref->{ counter } ++;
            $entry_ref->{ transfer } += $parsed_ref->{ size }
                if defined $parsed_ref->{ size };
            $self->database->set( aggregator => $type => $search_ref, $entry_ref );
            $self->database->usr_unlock;
        }
    }
}



=head2 print_stats

=cut

sub print_stats {
    my ( $self ) = @_;
    
    foreach my $table( @CUMULATE_TYPE ) {
        
        foreach my $type( qw/ sent bounced reject / ) {
            print "# $table: $type\n";
            
            foreach my $format( @{ $self->interval_formats } ) {
                my ( $handle, $meth ) = $self->database->search_read( aggregator => $table, {
                    type   => $type,
                    format => $format
                } );
                
                while ( my $ref = $handle->$meth ) {
                    print "$ref->{ $table };$type;$ref->{ interval };$ref->{ counter };$format\n";
                }
            }
            print "\n";
        }
    }
    
}



=head2 maintenance

Remove old cumulated entries. See maintenance_ttl

=cut

sub maintenance {
    my ( $self ) = @_;
    my $obsolete_time = time() - $self->maintenance_ttl;
    
    $self->logger->debug0( "Clear obsolete entries (TTL ". $self->maintenance_ttl. ")" );
    
    foreach my $table( @CUMULATE_TYPE ) {
        $self->database->remove( aggregator => $table, {
            last_update => {
                '<' => $obsolete_time
            }
        } );
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
