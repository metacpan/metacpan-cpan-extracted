package Mail::Decency::Policy::Basic;

use Moose;
extends 'Mail::Decency::Policy::Core';

use version 0.74; our $VERSION = qv( "v0.1.5" );

use mro 'c3';

use Net::DNS::Resolver;
use Regexp::Common qw/ net /;
use Email::Valid;
use Data::Dumper;
use Mail::Decency::Helper::IP qw/ is_local_host /;

=head1 NAME

Mail::Decency::Policy::Basic

=head1 CONFIG

    ---
    
    disable: 0
    
    weight_invalid_helo_hostname: -100
    
    weight_non_fqdn_helo_hostname: -100
    weight_non_fqdn_recipient: -100
    weight_non_fqdn_sender: -100
    
    weight_unknown_helo_hostname: -50
    weight_unknown_recipient_domain: -50
    weight_unknown_sender_domain: -50
    
    #weight_unknown_client_hostname: -50
    weight_unknown_reverse_client_hostname: -50


=head1 DESCRIPTION

Re-implementation of postfix's restriction directives but with scoring.

The following directives are re-implemented:

=over

=item * reject_invalid_helo_hostname -> weight_invalid_helo_hostname

Syntax of helo hostname is invalid (eg "???" or "#@%@@" or whatever is not syntactically correct)


=item * reject_non_fqdn_helo_hostname -> weight_non_fqdn_helo_hostname

Syntax is correct, but not in FQDN form (eg localhost, but not localhost.tld)

=item * reject_non_fqdn_recipient -> weight_non_fqdn_recipient

Recipient address is not FDQN (eg: "user" without domain or anything or "user@localhost" but not "user@localhost.tld").

=item * reject_non_fqdn_sender -> weight_non_fqdn_sender

Same as above but for sender address.


=item * reject_unknown_helo_hostname -> weight_unknown_helo_hostname

If the syntax is correct and in FQDN form but NOT an existing domain (has no A or MX record)

=item * reject_unknown_recipient_domain -> weight_unknown_recipient_domain

Recipient is in correct FQDN but recipient domain does not have an A or MX record.

=item * reject_unknown_sender_domain -> weight_unknown_sender_domain

Same as above, but for sender.


=item * reject_unknown_client_hostname -> weight_unknown_client_hostname

This matches if: 1) the client IP address->name mapping fails, 2) the name->address mapping fails, or 3) the name->address mapping does not match the client IP address

Stronger then weight_unknown_reverse_client_hostname which matches only 1)

=item * reject_unknown_reverse_client_hostname -> weight_unknown_reverse_client_hostname

See above.

=back

The order the tests will be performed is in as they are listed above.

=cut

=head1 CLASS ATTRIBUTES

=head2 weight_non_fqdn_sender : Int

Default: 0

=cut

has weight_non_fqdn_sender => ( is => 'rw', isa => 'Int', default => 0 );

=head2 weight_unknown_sender_domain : Int

Default: 0

=cut

has weight_unknown_sender_domain => ( is => 'rw', isa => 'Int', default => 0 );

=head2 weight_non_fqdn_recipient : Int

Default: 0

=cut

has weight_non_fqdn_recipient => ( is => 'rw', isa => 'Int', default => 0 );

=head2 weight_unknown_recipient_domain : Int

Default: 0

=cut

has weight_unknown_recipient_domain => ( is => 'rw', isa => 'Int', default => 0 );

=head2 weight_invalid_helo_hostname : Int

Default: 0

=cut

has weight_invalid_helo_hostname => ( is => 'rw', isa => 'Int', default => 0 );

=head2 weight_non_fqdn_helo_hostname : Int

Default: 0

=cut

has weight_non_fqdn_helo_hostname => ( is => 'rw', isa => 'Int', default => 0 );

=head2 weight_unknown_helo_hostname : Int

Default: 0

=cut

has weight_unknown_helo_hostname => ( is => 'rw', isa => 'Int', default => 0 );

=head2 weight_unknown_client_hostname : Int

Default: 0

=cut

has weight_unknown_client_hostname => ( is => 'rw', isa => 'Int', default => 0 );

=head2 weight_unknown_reverse_client_hostname : Int

Default: 0

=cut

has weight_unknown_reverse_client_hostname => ( is => 'rw', isa => 'Int', default => 0 );

=head2 resolver : Net::DNS::Resolver

Will be created automatically.

=cut

has resolver => ( is => 'ro', isa => 'Net::DNS::Resolver', default => sub {
    Net::DNS::Resolver->new
} );

=head1 METHODS


=head2 init

=cut

sub init {
    my ( $self ) = @_;
    
    foreach my $attr( qw/
        weight_invalid_helo_hostname
        
        weight_non_fqdn_helo_hostname
        weight_non_fqdn_recipient
        weight_non_fqdn_sender
        
        weight_unknown_helo_hostname
        weight_unknown_sender_domain 
        weight_unknown_recipient_domain
        
        
        weight_unknown_reverse_client_hostname
        weight_unknown_client_hostname
        
    / ) {
        $self->$attr( $self->config->{ $attr } )
            if defined $self->config->{ $attr };
    }
    
    # check ...
    die "Do not use weight_unknown_reverse_client_hostname AND weight_unknown_client_hostname.. only one of those\n"
        if $self->weight_unknown_reverse_client_hostname && $self->weight_unknown_client_hostname;
    
}



=head2 handle

Either build stats per country or score with negative or positve weight per country or do both

=cut

sub handle {
    my ( $self, $server, $attrs_ref ) = @_;
    
    #
    # INVALID
    #
    
    # helo hostname
    if ( $self->weight_invalid_helo_hostname && $attrs_ref->{ helo_name } !~ /$RE{net}{domain}/ ) {
        $self->logger->debug0( "Helo hostname is invalid ($attrs_ref->{ helo_name })" );
        $self->add_spam_score(
            $self->weight_invalid_helo_hostname,
            "Helo hostname is invalid",
            "Helo hostname is invalid"
        );
    }
    
    #
    # FQDN
    #
    
    my @fqdn_checks = (
        [
            $self->weight_non_fqdn_helo_hostname,
            'user@'. $attrs_ref->{ helo_name },
            "Helo hostname is not in FQDN",
        ],
        [
            $self->weight_non_fqdn_recipient,
            $attrs_ref->{ recipient_address },
            "Recipient address is not in FQDN",
        ]
    );
    
    # MAIL FROM may be empty (bounce)
    push @fqdn_checks, [
        $self->weight_non_fqdn_sender,
        $attrs_ref->{ sender_address },
        "Sender address is not in FQDN",
    ] if $attrs_ref->{ sender_address };
    
    foreach my $ref( @fqdn_checks ) {
        if ( $ref->[0] && ! Email::Valid->address( -address => $ref->[1], -fqdn => 1 ) ) {
            $self->logger->debug0( "$ref->[2] ($ref->[1])" );
            $self->add_spam_score( $ref->[0], $ref->[2], $ref->[2] );
        }
    }
    
    
    # stop here, for local host
    return if is_local_host( $attrs_ref->{ client_address } );
    
    #
    # UNKNOWN
    #
     
    
    my @unknwon_checks = (
        [
            $self->weight_unknown_helo_hostname,
            $attrs_ref->{ helo_name },
            "Helo hostname is unknown",
        ],
        [
            $self->weight_unknown_sender_domain,
            $attrs_ref->{ recipient_domain },
            "Recipient domain is unknown",
        ],
    );
    
    # MAIL FROM may be empty (bounce)
    push @unknwon_checks, [
        $self->weight_unknown_recipient_domain,
        $attrs_ref->{ sender_domain },
        "Sender domain is unknown",
    ] if $attrs_ref->{ sender_address };
    
    
    foreach my $ref( @unknwon_checks ) {
        next unless $ref->[0];
        
        unless ( $self->_has_a_or_mx( $ref->[1] ) ) {
            $self->logger->debug0( "$ref->[2] ($ref->[1])" );
            $self->add_spam_score( $ref->[0], $ref->[2], $ref->[2] );
        }
    }
    
    #
    # REVERSE STUFF
    #
    
    if ( ( my $weight = $self->weight_unknown_reverse_client_hostname || $self->weight_unknown_client_hostname ) < 0 ) {
        
        # MX and A for client
        unless ( $self->_has_a_or_mx( $attrs_ref->{ client_name } ) ) {
            $self->logger->debug0( "Client domain is unknown ($attrs_ref->{ client_name })" );
            $self->add_spam_score( $weight,
                "Client domain is unknown",
                "Client domain is unknown"
            );
        }
        
        # name -> address mapping OR name -> address does not match
        elsif ( $self->weight_unknown_client_hostname ) {
            my $res = $self->resolver->search( $attrs_ref->{ client_address }, 'PTR' );
            my @ptr = $res ? ( grep {
                defined $_ && $_->ptrdname eq $attrs_ref->{ client_name };
            } $res->answer ) : ();
            
            # name -> address fail
            unless ( @ptr ) {
                $self->logger->debug0( "Client PTR mapping failed ($attrs_ref->{ client_address }. $attrs_ref->{ client_name })" );
                $self->add_spam_score( $self->weight_unknown_client_hostname,
                    "Client PTR mapping failed",
                    "Client PTR mapping failed"
                );
            }
            
            # check name -> address
            else {
                
                my $ip_ref = $self->_resolute_domain_to_ip( $attrs_ref->{ client_name } );
                my $ip_ok = $ip_ref && $#$ip_ref > -1
                    ? scalar grep { $_ eq $attrs_ref->{ client_address } } @$ip_ref > 0
                    : 0
                ;
                
                unless ( $ip_ok ) {
                    $self->logger->debug0( "Client domain -> address mapping wrong ($attrs_ref->{ client_address }. $attrs_ref->{ client_name })" );
                    $self->add_spam_score( $self->weight_unknown_client_hostname,
                        "Client domain -> address mapping wrong",
                        "Client domain -> address mapping wrong"
                    );
                }
            }
        }
    }
    
    # remember final result
    $self->add_spam_score( 0,
        "Basic checks passed",
        ""
    );
    
    return ;
}


=head2 _has_a_or_mx

Returns bool wheter given domain has A or MX record

=cut

sub _has_a_or_mx {
    my ( $self, $domain ) = @_;
    
    my $cached = $self->cache->get( "basic-has-a-or-mx-$domain" );
    return $cached eq 'OK' ? 1 : 0 if $cached;
    
    # has A records ?
    my $res = $self->resolver->search( $domain, 'A' );
    my @a_rec = $res ? ( grep { defined $_ && $_->address } $res->answer ) : ();
    
    # no A records ..
    unless ( @a_rec ) {
        
        # has MX records ?
        my $res_mx = $self->resolver->search( $domain, 'MX' );
        my @mx_rec = $res_mx ? ( grep { defined $_ && $_->exchange } $res_mx->answer ) : ();
        
        # also no MX recors -> fail
        unless ( @mx_rec ) {
            $self->cache->set( "basic-has-a-or-mx-$domain", "NOPE" );
            return 0;
        }
    }
    
    $self->cache->set( "basic-has-a-or-mx-$domain", "OK" );
    return 1;
}


=head2 _resolute_domain_to_ip

Resolutes either A or MX recrod to IP(s)

=cut

sub _resolute_domain_to_ip {
    my ( $self, $domain ) = @_;
    
    my $cached = $self->cache->get( "basic-resolute-to-ip-$domain" );
    return $cached if $cached;
    
    # has A records ?
    my $res = $self->resolver->search( $domain, 'A' );
    my @a_rec = $res ? ( grep { defined $_ && $_->address } $res->answer ) : ();
    
    # found those A records
    if ( @a_rec ) {
        @a_rec = map { $_->address } @a_rec;
        $self->cache->set( "basic-resolute-to-ip-$domain", \@a_rec );
        return \@a_rec;
    }
    
    # has MX records ?
    my $res_mx = $self->resolver->search( $domain, 'MX' );
    my @mx_rec = $res_mx ? ( grep { defined $_ && $_->exchange } $res_mx->answer ) : ();
    
    # found those A records
    if ( @mx_rec ) {
        foreach my $mx_rec( @mx_rec ) {
            my $ip_ref = $self->_resolute_domain_to_ip( $mx_rec->exchange );
            if ( $ip_ref && $#$ip_ref > -1 ) {
                $self->cache->set( "basic-resolute-to-ip-$domain", $ip_ref );
                return $ip_ref;
            }
        }
    }
    
    return ;
}



=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut



1;
