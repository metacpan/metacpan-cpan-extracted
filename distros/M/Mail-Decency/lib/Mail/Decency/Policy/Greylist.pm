package Mail::Decency::Policy::Greylist;

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
use YAML;

=head1 NAME

Mail::Decency::Policy::Greylist


=head1 DESCRIPTION

A greylist implementation (http://www.greylisting.org/) for decency.

=head1 CONFIG

    --- 
    
    disable: 0
    
    # interval in seconds until a sender is allowed to re-send
    #   and pass
    min_interval: 60
    
    # per default, the greylist does not work as a whitelist, but
    #   a blacklist. it will reject (temporary) any mail not on the
    #   list, but does not explicit allow mails which are on the list
    #   to be passed (DUNNO).. you can enable passing by setting this
    #   to OK, thus any mail is on the list will pass.
    #   check with your restriction-classes to determine the better
    #   behavior for your mailserver
    pass_code: DUNNO
    
    # scoring awre. will put mails only on the permant whitelist
    #   (host or domain) if it has been scored zero or above
    #   this should keep suspicious mails from the whitelist
    scoring_aware: 1
    
    # policy for permanently whitelisting a whole sender server
    hosts_policy:
        
        # threshold of different sender mails
        unique_sender: 5
        
        # threshold of mails received from ONE address finally
        #   putting the host on the whitelist
        one_address: 10
    
    # policy for permanently whitelisting a whole sender domain
    #   use this with care and SPF (beforehand!)
    domains_policy:
        
        # threshold of different sender mails
        unique_sender: 5
        
        # threshold of mails received from ONE address finally
        #   putting the host on the whitelist
        one_address: 10
    

=head1 DATABASE

    -- contains all sender host ips, which are or are to be
    --  whitelisted due to lot's of positives
    CREATE TABLE greylist_client_addresss (
        id INTEGER PRIMARY KEY,
        client_address VARCHAR( 39 ),
        counter integer,
        last_seen integer
    );
    CREATE UNIQUE INDEX greylist_client_addresss_uk ON greylist_client_addresss( client_address );
    
    -- contains all sender_domains, which are or are to be
    --  whitelisted due to lot's of positives
    CREATE TABLE greylist_sender_domain (
        id INTEGER PRIMARY KEY,
        sender_domain varchar( 255 ),
        counter integer,
        last_seen integer,
        unique_sender BLOB
    );
    CREATE UNIQUE INDEX greylist_sender_domain_uk ON greylist_sender_domain( sender_domain );
    
    -- contains all (sender -> recipient) address pairs which
    --  are used to allow the second send attempt
    CREATE TABLE greylist_sender_recipient (
        id INTEGER PRIMARY KEY,
        sender_address varchar( 255 ),
        recipient_address varchar( 255 ),
        counter integer,
        last_seen integer,
        unique_sender BLOB
    );
    CREATE UNIQUE INDEX greylist_sender_recipient_uk ON greylist_sender_recipient( sender_address, recipient_address );

=head1 CLASS ATTRIBUTES


=head2 hosts_policy : HashRef[HashRef[Int]]

Determines accommodation requirements per host (IP)

=cut

has hosts_policy    => ( is => 'rw', isa => 'HashRef[HashRef[Int]]', predicate => 'has_hosts_policy' );

=head2 domains_policy : HashRef[HashRef[Int]]

Determines accommodation requirements per domain (sender)

=cut

has domains_policy  => ( is => 'rw', isa => 'HashRef[HashRef[Int]]', predicate => 'has_domains_policy' );

=head2 min_interval : Int

Min interval 

=cut

has min_interval => ( is => 'rw', isa => 'Int', default => 600 );

=head2 reject_message : Str

Message for greylisted rejection.

Default: "Greylisted - Patience, young jedi"

=cut

has reject_message  => ( is => 'rw', isa => 'Str', default => "Greylisted - Patience, young jedi" );

=head2 pass_code : Str

Set to "OK" if mails on the found on the greylist shall be whitelisted. Per default, they just won't be rejected (DUNNO).

=cut

has pass_code => ( is => 'rw', isa => 'Str', default => "DUNNO" );

=head2 scoring_aware : Bool

If scoring aware, will not use the host- and domain policies if score is below zero (spammy).

=cut

has scoring_aware => ( is => 'rw', isa => 'Bool', default => 0 );

=head2 schema_definition : HashRef[HashRef]

Database schema

=cut

has schema_definition => ( is => 'ro', isa => 'HashRef[HashRef]', default => sub {
    {
        greylist => {
            client_address => {
                client_address => [ varchar => 39 ],
                counter        => 'integer',
                last_seen      => 'integer',
                -unique        => [ 'client_address' ]
            },
            sender_domain => {
                sender_domain => [ varchar => 255 ],
                counter       => 'integer',
                last_seen     => 'integer',
                max_unique    => 'integer',
                max_one       => 'integer',
                unique_sender => 'blob',
                -unique       => [ 'sender_domain' ]
            },
            sender_recipient => {
                sender_address    => [ varchar => 255 ],
                recipient_address => [ varchar => 255 ],
                counter           => 'integer',
                last_seen         => 'integer',
                max_unique        => 'integer',
                max_one           => 'integer',
                unique_sender     => 'blob',
                -unique           => [ 'sender_address', 'recipient_address' ]
            }
        }
    };
} );



=head1 METHODS


=head2 init

=cut 

sub init {
    my ( $self ) = @_;
    
    # having sender policies ?
    foreach my $policy( qw/ hosts_policy domains_policy / ) {
        next unless defined $self->config->{ $policy };
        die "$policy is not a hashref!\n"
            unless ref( $self->config->{ $policy } ) eq 'HASH';
        die "provide unique_sender and/or one_address for $policy\n"
            unless $self->config->{ $policy }->{ one_address }
            && $self->config->{ $policy }->{ unique_sender };
    }
    
    # min interval before re-send is considered ok
    $self->min_interval( $self->config->{ min_interval } )
        if defined $self->config->{ min_interval };
    
    # reject code (temporary)
    $self->reject_message( $self->config->{ reject_message } )
        if $self->config->{ reject_message };
    
    # set pass code .. DUNNO, OK, ..
    $self->pass_code( $self->config->{ pass_code } )
        if $self->config->{ pass_code };
    
    # enable scoring awareness
    $self->scoring_aware( 1 )
        if $self->config->{ scoring_aware };
    
    return;
}


=head2 handle

=cut

sub handle {
    my ( $self, $server, $attrs_ref ) = @_;
    
    # don bother with loopback addresses! EVEN IF ENABLED BY FORCE!
    #return if is_local_host( $attrs_ref->{ client_address } );
    
    #
    # CACHES
    #
    
    my @caches = ();
    
    # is on sender->recipient cache (has been send less then min-interval before ?!
    push @caches, "Greylist-SR-$attrs_ref->{ sender_address }-$attrs_ref->{ recipient_address }";
    push @caches, "Greylist-H-$attrs_ref->{ client_address }";
    push @caches, "Greylist-D-$attrs_ref->{ sender_domain }";
    
    my $pass = 0;
    foreach my $cache( @caches ) {
        my $cached = $self->cache->get( $cache );
        if ( $cached && ( $cached eq 'OK' || $cached - $self->min_interval <= time() ) ) {
            $pass++;
            last;
        }
    }
    
    # update databases
    unless ( $pass ) {
        $pass = $self->update_pass( $attrs_ref );
    }
    
    # pass
    if ( $pass ) {
        $self->go_final_state( $self->pass_code ) if $self->pass_code !~ /^(DUNNO|PREPEND)/;
    }
    else {
        
        # or not..
        $self->go_final_state( 450 => $self->reject_message )
    }
}


=head2 update_pass

Add counters to pass databases

=cut

sub update_pass {
    my ( $self, $attrs_ref ) = @_;
    
    my $pass = 0;
    
    # use host and domain whitelisting only if we don't care for hosting
    #   or the score of the mail looks like hame
    #   remark: in context with SPF beforehand we will not add sender
    #   domains or hosts to the whitelist if the look somewhat bogus
    if ( ! $self->scoring_aware || $self->session_data->spam_score >= 0 ) {
        
        my @update_policy;
        push @update_policy, [ hosts => client_address => 'H' ]
            if $self->has_hosts_policy;
        push @update_policy, [ domains => sender_domain => 'D' ]
            if $self->has_domains_policy;
        
        foreach my $ref( @update_policy ) {
            my ( $policy, $attr, $cache ) = @$ref;
            
            # read existing data .. attr: client_address | sender_domain
            my $data_ref = $self->database->get( greylist => $attr => {
                $attr => $attrs_ref->{ $attr }
            } ) || {
                total         => 0,
                max_unique    => 0,
                max_one       => 0,
                unique_sender => {},
                last_seen     => time()
            };
            
            # convert unique sender to hashref, if given in YAML
            eval {
                $data_ref->{ unique_sender } = YAML::Load( $data_ref->{ unique_sender } )
                    unless ref( $data_ref->{ unique_sender } );
            };
            $data_ref->{ unique_sender } = {} if $@;
            
            # increment total
            $data_ref->{ total }++;
            
            # increment unique sender policy
            unless ( $data_ref->{ unique_sender }->{ $attrs_ref->{ sender_address } }++ ) {
                $data_ref->{ max_unique }++;
            }
            
            # determine MAX "send by one sender"
            ( $data_ref->{ max_one } ) = sort { $b <=> $a } values %{ $data_ref->{ unique_sender } };
            
            # write  back
            $self->logger->debug3( "Write to $attr database: $attrs_ref->{ $attr }" );
            $self->database->set( greylist => $attr => {
                $attr => $attrs_ref->{ $attr }
            }, $data_ref );
            
            # write to cache if positive
            my $policy_meth = "${policy}_policy";
            my $do_cache = (
                $self->$policy_meth->{ unique_sender }
                && $self->$policy_meth->{ unique_sender } <= $data_ref->{ max_unique }
            ) || (
                $self->$policy_meth->{ one_sender }
                && $self->$policy_meth->{ one_sender } <= $data_ref->{ max_one }
            );
            if ( $do_cache ) {
                $self->cache->set( "Greylist-$cache-$attrs_ref->{ $attr }", "OK" );
                $pass++;
            }
        }
    }
    
    # update sender->recipient database
    my $sr_ref = $self->database->get( greylist => sender_recipient => {
        sender_address    => $attrs_ref->{ sender_address },
        recipient_address => $attrs_ref->{ recipient_address },
    } ) || {
        counter   => 0,
        last_seen => time()
    };
    
    # increment, if time passed
    if ( $sr_ref->{ last_seen } + $self->min_interval <= time() ) {
        $sr_ref->{ counter }++;
    }
    
    # write  back
    $self->database->set( greylist => sender_recipient => {
        sender_address    => $attrs_ref->{ sender_address },
        recipient_address => $attrs_ref->{ recipient_address },
    }, $sr_ref );
    
    # positive counter -> allow and update cache
    if ( $sr_ref->{ counter } ) {
        $self->cache->set( "Greylist-SR-$attrs_ref->{ sender_address }-$attrs_ref->{ recipient_address }", "OK" );
        $pass++;
    }
    
    return $pass;
}


=head2 maintenance

Called by policy server in maintenance mode. Cleans up obsolete entries in greylist databsae

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
