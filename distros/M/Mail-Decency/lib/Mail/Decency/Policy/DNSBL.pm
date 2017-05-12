package Mail::Decency::Policy::DNSBL;

use Moose;
use mro 'c3';
extends 'Mail::Decency::Policy::Core';

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Net::DNSBL::Client;
use Data::Dumper;
use Mail::Decency::Helper::IP qw/ is_local_host /;

=head1 NAME

Mail::Decency::Policy::DNSBL

=head1 DESCRIPTION

Implementation of a DNS-based Blackhole List using L<Net::DNSBL::Client>.

=head2 CONFIG

    ---
    
    disable: 0
    
    harsh: 0
    
    blacklist:
        
        -
            host: ix.dnsbl.manitu.net
            weight: -100
        -
            host: psbl.surriel.com
            weight: -80
        -
            host: dnsbl.sorbs.net
            weight: -70
    

=head1 DESCRIPTION

Check external DNS blacklists (DNSBL). Allows weighting per blacklis or harsh policies (first hit serves).


=head1 CLASS ATTRIBUTES

=head2 blacklist

ArrayRef of blacklists

=head2 weight

HashRef of ( domain => weight ) for each blacklist

=head2 dnsbl

Instance of L<Net::DNSBL::Client>

=head2 harsh

Bool value determining wheter first blacklist hit rejects mail

=cut

has blacklist => ( is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { [] } );
has weight    => ( is => 'rw', isa => 'HashRef[Int]', default => sub { {} } );
has dnsbl     => ( is => 'ro' );
has harsh     => ( is => 'ro', isa => 'Bool' );

=head1 METHODS



=head2 init

=cut

sub init {
    my ( $self ) = @_;
    
    # @@@@@@@@@@@@@ TODO @@@@@@@@@@@@@@@@@@
    # >> Deactivate for localhost
    # >> Test performance of Net::DNS
    # @@@@@@@@@@@@@ TODO @@@@@@@@@@@@@@@@@@
    
    # check blacklists
    die "DNSBL: Require 'blacklist' as array\n"
        unless defined $self->config->{ blacklist } && ref( $self->config->{ blacklist } ) eq 'ARRAY';
    
    # build blacklists
    my $num = 1;
    my @blacklists = ();
    foreach my $ref( @{ $self->config->{ blacklist } } ) {
        die "DNSBL: Blacklist $num is not a hashref\n"
            unless ref( $ref ) eq 'HASH';
        push @blacklists, {
            domain => $ref->{ host }
        };
        $self->weight->{ $ref->{ host } } = $ref->{ weight } || -100;
        $num++;
    }
    
    # remember blacklists
    $self->blacklist( \@blacklists );
    
    # setup new dnsbl client
    $self->{ dnsbl } = Net::DNSBL::Client->new( { timeout => $self->config->{ timeout } || 3 } );
    
    # wheter use harash policy ?
    $self->{ harsh } = $self->config->{ harsh } || 0;
    
    return $self->next::method();
}


=head2 handle

Checks wheter incoming mail is whilist for final recipient

=cut

sub handle {
    my ( $self, $server, $attrs_ref ) = @_;
    
    my @reject_info;
    
    # go through all blacklists one bye one
    #   don't stress all blacklists, if not required!
    foreach my $list_ref( @{ $self->blacklist } ) {
        
        # query blacklist now
        $self->dnsbl->query_ip( $attrs_ref->{ client_address }, [ $list_ref ] );
        
        # retreive anwer
        my $result_ref = $self->dnsbl->get_answers;
        $result_ref = $result_ref->[0] if ref( $result_ref ) eq 'ARRAY';
        
        # any hit ??
        if ( $result_ref && ref( $result_ref ) eq 'HASH' && $result_ref->{ hit } ) {
            # collect weight
            my $add_weight = $self->weight->{ $list_ref->{ domain } } || 0;
            
            # log out ..
            $self->logger->debug0( "Hit on $list_ref->{ domain } for $attrs_ref->{ client_address }, weight $add_weight ('$attrs_ref->{ sender_address }' -> '$attrs_ref->{ recipient_address }')" );
            
            # update reject details..
            push @reject_info, "$result_ref->{ domain }";
            my $reject_info = "Blacklisted on ". join( ", ", @reject_info );
            
            # add weight .. (throws exception if final state)
            $self->add_spam_score( 
                $add_weight, "$list_ref->{ domain }: hit ($add_weight)", $reject_info );
            
            # final state if harsh policy
            $self->go_final_state( REJECT => $reject_info ) if $self->harsh;
        }
        
        # no hit -> pass
        else {
            $self->logger->debug3( "Pass on $list_ref->{ domain } for $attrs_ref->{ client_address } ('$attrs_ref->{ sender_address }' -> '$attrs_ref->{ recipient_address }')" );
        }
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
