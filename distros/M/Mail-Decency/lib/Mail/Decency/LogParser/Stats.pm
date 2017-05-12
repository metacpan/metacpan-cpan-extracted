package Mail::Decency::LogParser::Stats;

use Moose;
extends qw/
    Mail::Decency::LogParser::Core
/;
with qw/
    Mail::Decency::LogParser::Core::CSV
    Mail::Decency::LogParser::Core::CacheWrite
/;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Data::Dumper;

=head1 NAME

Mail::Decency::LogParser::Stats


=head1 DESCRIPTION

Generates usage statistics by configurable granulity (

=head1 CLASS ATTRIBUTES

=cut

has intervals         => ( is => 'rw', isa => 'ArrayRef[Int]', default => sub { [] } );
has use_date_interval => ( is => 'rw', isa => 'Bool' );

=head1 METHODS


=head2 init

=cut

sub setup {
    my ( $self ) = @_;
    
    # setup interval caches
    if ( defined $self->config->{ intervals } && ref( $self->config->{ intervals } ) eq 'ARRAY' ) {
        $self->intervals( $self->config->{ intervals } );
    }
    else {
        $self->intervals( [ 600, 86400 ] );
    }
    
    $self->cache_prefix( 'lp-stats' );
    
    # wheter use date caches
    $self->use_date_interval( $self->config->{ use_date_interval } ? 1 : 0 );
}


=head2 handle

Checks wheter incoming mail is whilist for final recipient

=cut

sub handle_data {
    my ( $self, $parsed_ref ) = @_;
    my ( %data );
    
    
    #
    # CONNECTIONS
    #
    
    if ( defined $parsed_ref->{ connection } ) {
        my $type = $parsed_ref->{ connection } ? 'connect' : 'disconnect';
        push @{ $data{ connections } ||= [] }, [ $type, $parsed_ref->{ ip } ];
    }
    
    elsif ( $parsed_ref->{ reject } || $parsed_ref->{ bounced } || $parsed_ref->{ sent } || $parsed_ref->{ deferred } ) {
        
        my %db = map { ( $_ => $parsed_ref->{ $_ } ) }
            grep { defined $parsed_ref->{ $_ } }
            qw/ ip from_address to_address from_domain to_domain /
        ;
        
        my @types;
        
        
        #
        # REJECTIONS
        #
        
        if ( $parsed_ref->{ reject } ) {
            @types = qw/ total_reject /;
            
            if ( index( $parsed_ref->{ code }, '4' ) == 0 ) {
                push @types, qw/ temp_reject /;
            }
            else {
                push @types, qw/ hard_reject /;
            }
            
            $db{ code } = $parsed_ref->{ code };
            $db{ message } = $parsed_ref->{ message };
        }
        
        
        #
        # BOUNCED MAIL
        #
        
        elsif ( $parsed_ref->{ bounced } ) {
            @types = qw/ total bounced /;
        }
        
        
        #
        # BOUNCED MAIL
        #
        
        elsif ( $parsed_ref->{ deferred } ) {
            push @types, 'deferred';
        }
        
        
        #
        # FINAL 
        #
        
        elsif ( $parsed_ref->{ final } ) {
            @types = qw/ total /;
            push @types, 'sent' if $parsed_ref->{ sent };
        }
        
        
        if ( $parsed_ref->{ final } || $parsed_ref->{ bounced } ) {
            $self->_cumulate( \%db );
        }
        
        
        if ( @types ) {
            
            # by ip, sender-email and sender domain
            foreach my $type( @types ) {
                $data{ $type } = \%db;
            }
        }
    }
    
    return unless keys %data;
    
    $self->current_data( \%data );
}


=head2 _cumulate

=cut

sub _cumulate {
    my ( $self, $db_ref ) = @_;
    
}







=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
