package Mail::Decency::Policy::Honeypot;

use Moose;
extends qw/
    Mail::Decency::Policy::Core
/;
with qw/
    Mail::Decency::Core::Meta::Database
    Mail::Decency::Core::Meta::Maintenance
/;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Mail::Decency::Helper::IP qw/ is_local_host /;
use Data::Dumper;

=head1 NAME

Mail::Decency::Policy::Honeypot

=head1 CONFIG

    ---
    
    disable: 0
    
    # attention: enabling this is a good idea if you want thos obvious
    #   spammy mails for later training with your spam filters.
    #   however, if you forget to handle the content filter side with
    #   the Honeycollect module, the mails might just pass to where they
    #   should not: the recipient.
    pass_for_collection: 1
    
    
    # time to live .. for maintenance
    maintenance_ttl: 14d
    
    # list of addresses
    addresses:
        # all incoming mails to those recipients go directly to the blacklist
        - some@address.tld
        - another@domain.tld
    
    # list of domains used for building the blacklist
    domains:
        
        # all incoming mails for this recipient domain
        - spamlover.tld
        
        # use the whoe domain, but some real existing users
        -
            domain: somedomain.tld
            exceptions:
                - realuser
                - anotheremail
    

=head1 DESCRIPTION

Honeypot facility. All hosts sending mails to a list of provided recipient emails and/or domains will be rejected and added to a blacklist.
Later on, this blacklist will be used for rejected any other mails

=head1 DATABASE

    CREATE TABLE honeypot_client_address (
        id INTEGER PRIMARY KEY,
        client_address varchar( 39 ),
        created INTEGER
    );
    CREATE UNIQUE INDEX honeypot_client_address_uk ON honeypot_client_address( client_address );
    CREATE INDEX honeypot_client_created_idx ON honeypot_client_address( created );

=head1 CLASS ATTRIBUTES


=head2 addresses : HashRef[Bool]

List of addresses used as honeypot targets

=cut

has addresses => ( is => 'rw', isa => 'HashRef[Bool]', predicate => 'has_addresses' );

=head2 domains : HashRef[Bool]

List of (FULL) domains used as honeypot targets

=cut

has domains => ( is => 'rw', isa => 'HashRef', predicate => 'has_domains' );

=head2 reject_message : Str

Reject message, if an IP was already on the honeypot blacklist.

Default: "Your host ip is blacklisted"

=cut

has reject_message => ( is => 'rw', isa => 'Str', default => 'Your host ip is blacklisted.' );

=head2 welcome_message : Str

Reject message, which will be thrown if a new IP is welcomed on the blacklist.

Default: "The honey has been served."

=cut

has welcome_message => ( is => 'rw', isa => 'Str', default => 'The honey has been served.' );

=head2 negative_cache : Bool

If enabled: negative answers (not on blacklist) will be stored, too.

=cut

has negative_cache => ( is => 'rw', isa => 'Bool', default => 1 );

=head2 pass_for_collection : Bool

If enabled: Do not reject honeypot mails, but flag them so that they can be collected via L<Mail::Decency::ContentFilter::HoneyCollector>

=cut

has pass_for_collection => ( is => 'rw', isa => 'Bool', default => 0 );

=head2 schema_definition : HashRef[Bool]

List of addresses used as honeyport targets

=cut

has schema_definition => ( is => 'ro', isa => 'HashRef[HashRef]', default => sub {
    {
        honeypot => {
            addresses => {
                client_address => [ varchar => 39 ],
                created        => 'integer',
                -unique        => [ 'client_address' ],
                -index         => [ 'created' ]
            },
        }
    };
} );


=head1 METHODS


=head2 init

=cut 

sub init {
    my ( $self ) = @_;
    
    die "Require either addresses or domains to run!\n"
        unless $self->config->{ addresses } || $self->config->{ domains };
    
    # init addresses 
    if ( $self->config->{ addresses } ) {
        $self->addresses( { map { ( $_ => 1 ) } @{ $self->config->{ addresses } } } );
    }
    
    # init domains
    if ( $self->config->{ domains } ) {
        $self->domains( {} );
        
        my $count = 1;
        foreach my $ref( @{ $self->config->{ domains } } ) {
            
            # having hashref -> using exceptions
            if ( ref( $ref ) ) {
                die "Missing 'domain' in domain $count\n"
                    unless $ref->{ domain };
                $self->domains->{ $ref->{ domain } } = { map {
                    ( $_ => 1 );
                } @{ $ref->{ exceptions } || [] } };
            }
            
            # being scalar -> full domain
            else {
                $self->domains->{ $ref }++;
            }
            $count++;
        }
    }
    
    # disable negative cache ?
    $self->negative_cache( 0 ) 
        if defined $self->config->{ negative_cache } && ! $self->config->{ negative_cache };
    
    # enable passing for collecting later on ?
    $self->pass_for_collection( 1 )
        if $self->config->{ pass_for_collection };
    
    # set messages
    foreach my $message( qw/ reject_message welcome_message / ) {
        $self->$message( $self->config->{ $message } )
            if $self->config->{ $message };
    }
    
}


=head2 handle

=cut

sub handle {
    my ( $self, $server, $attrs_ref ) = @_;
    
    # don bother with loopback addresses! EVEN IF ENABLED BY FORCE!
    return if is_local_host( $attrs_ref->{ client_address } );
    
    # ist sender blacklisted
    if ( my $cached_ref = $self->client_blacklisted( $attrs_ref->{ client_address } ) ) {
        
        $self->go_final_state( REJECT => $self->welcome_message );
    }
    
    # being on domains list ?
    if ( $self->has_domains && defined( my $ref = $self->domains->{ $attrs_ref->{ recipient_domain } } ) ) {
        
        # having exceptions
        if ( !ref( $ref ) || ! defined $ref->{ $attrs_ref->{ recipient_prefix } } ) {
            
            # set final state (throws finalte state excetpion)
            $self->add_to_blacklist( $attrs_ref );
            
            # set final state (throws exception)
            if ( $self->pass_for_collection ) {
                $self->go_final_state( 'OK' );
            }
            else {
                $self->go_final_state( REJECT => $self->welcome_message );
            }
        }
    }
    
    # being on addresses list ?
    if ( $self->has_addresses && defined $self->addresses->{ $attrs_ref->{ recipient_address } } ) {
        $self->add_to_blacklist( $attrs_ref );
        
        # set final state (throws exception)
        $self->go_final_state( REJECT => $self->welcome_message );
    }
    
    # not found
    return ;
}


=head2 client_blacklisted

Check wheter client is blacklisted.. first in cache, then in database

=cut

sub client_blacklisted {
    my ( $self, $address ) = @_;
    
    # try cache
    my $cache_name = 'Honeypot-'. $address;
    my $cached     = $self->cache->get( $cache_name );
    if ( $cached ) {
        return $cached eq 'USEME';
    }
    
    # try database
    my $res = $self->database->get( honeypot => addresses => {
        client_address => $address
    } );
    if ( $res ) {
        
        # refresh entry ??!
        if ( $res->{ created } + $self->maintenance_ttl < time() ) {
            $self->add_to_blacklist( {
                client_address => $address
            } );
        }
        
        # save to cache
        $self->cache->set( $cache_name => "USEME" );
        return 1;
    }
    
    # write negative cache also!!
    $self->cache->set( $cache_name => "IGNORE" )
        unless $self->negative_cache;
    
    return 0;
}

=head2 add_to_blacklist

Add some ip to the blacklist

=cut

sub add_to_blacklist {
    my ( $self, $attrs_ref ) = @_;
    $self->database->set( honeypot => addresses => {
        client_address => $attrs_ref->{ client_address },
    }, {
        created => time()
    } );
    return;
}


=head2 go_final_state

Overwrite parent mehtod, go only in a final reject state if "pass_for_collection" is 0, otherwise go in final accept, but set flag (for Honeycollector in content filters..)

=cut

sub go_final_state {
    my ( $self, $state ) = @_;
    if ( $self->pass_for_collection ) {
        $self->set_flag( 'honey' );
        $self->next::method( "PREPEND" );
    }
    else {
        $self->next::method( $state => $self->welcome_message );
    }
}





=head2 maintenance

Called by policy server in maintenance mode. Cleans up outdated entries in honeypot database

=cut

sub maintenance {
    my ( $self ) = @_;
    my $obsolete_time = time() - $self->maintenance_ttl;
    while ( my ( $schema, $tables_ref ) = each %{ $self->schema_definition } ) {
        while ( my ( $table, $ref ) = each %{ $tables_ref } ) {
            $self->database->remove( $schema => $table => {
                last_seen => {
                    '<' => $obsolete_time
                }
            } );
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
