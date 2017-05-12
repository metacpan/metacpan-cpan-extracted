package Mail::Decency::Policy::Association;

use Moose;
extends qw/
    Mail::Decency::Policy::Core
/;

use version 0.74; our $VERSION = qv( "v0.1.5" );

use Mail::Decency::Helper::IP qw/ is_local_host /;
use Net::DNS;
use Net::Netmask;
use Net::Domain::TLD qw/ tlds /;
use Data::Dumper;

=head1 NAME

Mail::Decency::Policy::Association

=head1 DESCRIPTION

This module tries to figure out wheter the sender domain is somewhat related to the sending server.

There are three methods to determine wheter this is the case:

=over

=item 1. direct IP hit

The sender IP name is equal to the A or AAAA of the domain or the resolved (CNAME, MX) record.

Example 1: sender ip is 123.123.123.123 and the first MX record of the sender domain sender.tld is points to mail.sender.tld which has the IP 123.123.123.123

Example 2: sender ip is 123.123.213.123 and the A record of sender.tld is 123.123.123.123

=item 2. domain hit

Tries to identify the association via the domain name. 

Example: sender domain is something.sender.tld and the reverse hostname of the sender IP is mail.domain.tld -> both under sender.tld.

=item 3. IP range hit

Tries to identify the relation via ip ranges.

Example: ip of the sender is 123.123.123.123 and ip of the A record of the sender domain is 123.123.123.122 which is within a /31 subnet

The bigger the subnet, the lower the positive weight (can be adjusted).

=back

If no relation could be determined, the session will be scored negatively.

Keep in mind: the association of the sender ip to the sender domain does not imply at all that the mail is not spam. Only the opposite gives a hint, that the mail might be forged - or one of those webservers not associated to the domain sending a (maybe even valid) mail.

=head1 CONFIG

    ---
    
    disable: 0
    
    weight_direct_hit: 20
    weight_domain_hit: 15
    weight_range_hit:
        31: 20
        30: 20
        29: 10
        28: 10
        27: 10
        26: 5
        25: 5
        24: 5
    weight_no_hit: -20
    


=head1 CLASS ATTRIBUTES

=head2 resolver : Net::DNS::Resolver

Will be created automatically.

=cut

has resolver => ( is => 'ro', isa => 'Net::DNS::Resolver', default => sub { Net::DNS::Resolver->new } );

=head2 rx_tlds* : RegexpRef

Pre-compiled regex containing tlds.

=cut

has rx_tlds => ( is => 'rw', isa => 'RegexpRef', default => sub {
    my $s = join( "|", sort { length($b) <=> length($a) } tlds() );
    return qr/\.($s)$/;
} );
has rx_tlds_com => ( is => 'rw', isa => 'RegexpRef', default => sub {
    my $s = join( "|", map { "com\\.$_" } sort { length($b) <=> length($a) } tlds() );
    return qr/\.($s)$/;
} );
has rx_tlds_co => ( is => 'rw', isa => 'RegexpRef', default => sub {
    my $s = join( "|", map { "co\\.$_" } sort { length($b) <=> length($a) } tlds() );
    return qr/\.($s)$/;
} );

=head2 weight_direct_hit : Int

The sender domain is directly associated to the client address

=cut

has weight_direct_hit => ( is => 'rw', isa => 'Int', default => 20 );

=head2 weight_range_hit : HashRef[Int]

The sender domain is associated via an ip range to the client address .. 

=cut

has weight_range_hit => ( is => 'rw', isa => 'HashRef[Int]', default => sub { {
    31 => 20,
    30 => 20,
    29 => 10,
    28 => 10,
    27 => 10,
    26 => 5,
    25 => 5,
    24 => 5
} } );

=head2 weight_domain_hit : Int

The sender domain is via a shared domain name to the client address. Eg the client address resolves to smtp.somedomain.tld and the sender is somedomain.tld or the sender's mx is mx.somedomain.tld whereas they at least somedomain.tld

=cut

has weight_domain_hit => ( is => 'rw', isa => 'Int', default => 15 );

=head2 weight_no_hit

Negative score. No match found.

=cut

has weight_no_hit => ( is => 'rw', isa => 'Int', default => -20 );





=head1 METHODS


=head2 init

Checks weight_range_hit for correctness, reads config

=cut 

sub init {
    my ( $self ) = @_;
    
    if ( defined $self->config->{ weight_range_hit } ) {
        die "Association: weight_range_hit has to be a HashRef\n"
            unless ref( $self->config->{ weight_range_hit } ) eq 'HASH';
        while ( my ( $k, $v ) = each %{ $self->config->{ weight_range_hit } } ) {
            die "Association: weight_range_hit key '$k' is not an integer\n"
                unless $k =~ /^\d+$/;
            die "Association: weight_range_hit value '$v' for key '$k' is not an integer\n"
                unless $v =~ /^\d+$/;
        }
    }
    
    foreach my $key( qw/ weight_direct_hit weight_domain_hit weight_no_hit weight_range_hit / ) {
        $self->$key( $self->config->{ $key } )
            if defined $self->config->{ $key };
    }
    
    return;
}


=head2 handle

Never handle anything from localhost. Handle results are cached. First checks for exact match, then domain hit, then range hit.

=cut

sub handle {
    my ( $self, $server, $attrs_ref ) = @_;
    
    # don bother with loopback addresses! EVEN IF ENABLED BY FORCE!
    return if is_local_host( $attrs_ref->{ client_address } );
    
    # if spf module is used and passes -> no need to verify this again
    return if $self->session_data->has_flag( 'spf_pass' );
    
    #
    # CACHES
    #
    
    my $cache_name = "Association-$attrs_ref->{ sender_domain }-$attrs_ref->{ client_address }";
    if ( my $cached = $self->cache->get( $cache_name ) ) {
        return $self->add_spam_score( @$cached );
    }
    
    
    #
    # GET DOMAIN DNS
    #
    
    my $domain_ref = $self->get_records( $attrs_ref->{ sender_domain } );
    
    # not a valid domain, no records found!
    return $self->finish( $cache_name => $self->weight_no_hit => "Association: No hit, sender domain not found", "Sender domain could not be resolved" )
        if scalar keys %{ $domain_ref } == 0;
    
    
    
    #
    # EXACT IP MATCH
    #
    
    if ( 
        ( defined $domain_ref->{ A } && defined $domain_ref->{ A }->{ $attrs_ref->{ client_address } } )
        || ( defined $domain_ref->{ AAAA } && defined $domain_ref->{ AAAA }->{ $attrs_ref->{ client_address } } )
    ) {
        $self->finish( $cache_name => $self->weight_direct_hit => "Association: Direct IP hit" );
    }
    
    
    #
    # IP RANGE MATCHING
    #   only with ipv4
    #
    if ( defined ( my $ips_ref = $domain_ref->{ A } ) ) {
        foreach my $ip( keys %$ips_ref ) {
            foreach my $net( keys %{ $self->weight_range_hit } ) {
                my $mask = Net::Netmask->new( "$ip/$net" );
                if ( $mask->match( $attrs_ref->{ client_address } ) ) {
                    my $weight = $self->weight_range_hit->{ $net };
                    return $self->finish( $cache_name => $weight => "Association: Range hit in /$net-network" );
                }
            }
        }
    }
    
    
    #
    # DOMAIN PREFIX MATCHING
    #
    
    my $client_ref = $self->get_records( $attrs_ref->{ client_address } );
    my @rdns = defined $client_ref && defined $client_ref->{ PTR }
        ? keys %{ $client_ref->{ PTR } }
        : ()
    ;
    
    CHECK_RDNS:
    foreach my $rdns( @rdns ) {
        my ( $rx, $prefix );
        
        # get all regular expressions for matching
        my $rx_tlds     = $self->rx_tlds;
        my $rx_tlds_co  = $self->rx_tlds_co;
        my $rx_tlds_com = $self->rx_tlds_com;
        
        # is a prefixed com domain (eg somedomain.com.asia)
        if ( $rdns =~ /^(.+?)$rx_tlds_com/ ) {
            $prefix = $1;
            $rx = $rx_tlds_com;
        }
        
        # is a prefixed co domain (eg somedomain.co.uk)
        elsif ( $rdns =~ /^(.+?)$rx_tlds_co/ ) {
            $prefix = $1;
            $rx = $rx_tlds_co;
        }
        
        # is not prefix, but has a tld (eg somedomain.com)
        elsif ( $rdns =~ /^(.+?)$rx_tlds/ ) {
            $prefix = $1;
            $rx = $rx_tlds;
        }
        
        next CHECK_RDNS unless $prefix;
        
        # found prefix (orig: domain.tld -> domain)
            
        # get last prefix .. from mail.somewhere it would be somewhere
        my @prefix = split( /\./, $prefix );
        $prefix = pop @prefix;
        
        ALL_RECORDS:
        foreach my $rr( qw/ PTR MX CNAME / ) {
            my $records_ref = $domain_ref->{ $rr } || next ALL_RECORDS;
            
            # check all found records
            foreach my $dns( keys %$records_ref ) {
                
                # does match ?
                if ( $dns =~ /^(.+?)$rx/ ) {
                    
                    # extract the last prefix (from some.domain.tld that would be domain)
                    my $dns_prefix = $1;
                    my @dns_prefix = split( /\./, $dns_prefix );
                    $dns_prefix = pop @dns_prefix;
                    
                    # is actually matching, we got a winner
                    if ( $dns_prefix eq $prefix ) {
                        
                        # return here
                        return $self->finish( $cache_name =>
                            $self->weight_domain_hit => "Association: Domain hit" );
                    }
                }
            }
        }
    }
    
    #
    # NO MATCH AT ALL!
    #
    return $self->finish( $cache_name => $self->weight_no_hit => "Association: No hit", "Sender IP not associated with sender domain" );
}


=head2 finish

Write to cache, add spam score.

=cut

sub finish {
    my ( $self, $cache_name, $weight, $details, $reject_message ) = @_;
    
    # cache result
    $self->cache->set( $cache_name => [
        $weight => $details => $reject_message
    ] );
    
    # return here
    return $self->add_spam_score( $weight => $details => $reject_message );
}


=head2 get_records

Retreive records for a hostname (A, CNAME, MX) / ip (PTR) 

=cut

sub get_records {
    my ( $self, $domain, $seen_ref, $records_ref ) = @_;
    $seen_ref ||= {};
    $seen_ref->{ $domain } ++;
    $records_ref ||= {};
    
    # init methods for record types
    my %meth = qw(
        PTR     ptrdname
        A       address
        CNAME   cname
        MX      exchange
    );
    
    foreach my $class( qw/ A CNAME MX PTR / ) {
        
        # retreive records of this type
        my $resolver_res = $self->resolver->search( $domain, $class );
        
        # not any -> bye
        next unless $resolver_res;
        
        foreach my $rr( $resolver_res->answer ) {
            
            # get method
            my $meth = $meth{ $rr->type } || 'address';
            
            # init empty, if not existing
            $records_ref->{ $rr->type } ||= {};
            
            # remember this
            $records_ref->{ $rr->type }->{ $rr->$meth } = 1;
            
            # get next records, unless already seen
            $self->get_records( $rr->$meth, $seen_ref, $records_ref )
                unless $seen_ref->{ $rr->$meth };
        }
    }
    
    return $records_ref;
}


=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut



1;
