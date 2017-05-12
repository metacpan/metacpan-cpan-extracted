package Mail::Decency::Policy;

use Moose;
extends qw/
    Mail::Decency::Core::Server
/;
with qw/
    Mail::Decency::Core::Stats
    Mail::Decency::Core::ExportImport
    Mail::Decency::Core::DatabaseCreate
    Mail::Decency::Core::Excludes
/;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use feature qw/ switch /;

use Data::Dumper;
use Scalar::Util qw/ weaken blessed /;
use Time::HiRes qw/ tv_interval gettimeofday /;

use Mail::Decency::Helper::IP qw/ is_local_host /;
use Mail::Decency::Core::POEForking::Postfix;
use Mail::Decency::Core::Exception;
use Mail::Decency::Core::SessionItem::Policy;

use constant CRLF => qq[\x0D\x0A]; # RFC 2821, 2.3.7

=head1 NAME

Mail::Decency::Policy

=head1 SYNOPSIS

    use Mail::Decency::Policy;
    
    # run in server mode
    my $policy = Mail::DecencyPolicy->new( {
        config => '/etc/decency/policy.yml'
    } );
    $policy->run;
    
    # run in maintenance mode
    $policy->maintenance;
    
    # print statistics
    $policy->print_stats;

=head1 DESCRIPTION

Policy server for Postfix or other MTAs. Could be combined with L<Mail::Decency::ContentFilter>. Besides the existing Modules it is easy extendable for custom needs.

=head1 POSTFIX

To implement this in postfix, add a "check_policy_service" directive in one of the restriction classes: 

    smtpd_recipient_restrictions =
        # ...
        check_policy_service inet:127.0.0.1:15000
        # ...

If you want to place this anywhere before the smtpd_recipient_restrictions, you probaly have to enable "smtpd_delay_reject" (depending on the modules you use, but to be save..)

    smtpd_delay_reject = yes

=head1 CONFIG

The configuration can be provided via YAML file or as HashRef.

Example:

    ---
    
    include:
        - database.yml
        - cache.yml
        - logging.yml
    
    weight_threshold: -100
    force_check_local: 1
    
    default_reject_message: "use decency"
    no_reject_detail: 0
    
    disable_prepend: 0
    forward_scoring: 1
    forward_sign_key: sign.key
    
    enable_stats: 1
    
    
    server:
        host: 127.0.0.1
        port: 15000
        instances: 3
    
    
    policy:
        - CWL: policy/cwl.yml
        - DNSBL: policy/dnsbl.yml
        - CBL: policy/cbl.yml
        - SPF: policy/spf.yml
        - Association: policy/association.yml
        - GeoWeight: policy/geo-weight.yml
        - Honeypot: policy/honeypot.yml
        - Greylist: policy/greylist.yml
        - Throttle: policy/throttle.yml
    


=head2 DATABASE

SQL CREATE statements (SQLite) for the stats role:

    -- TABLE: stats_contentfilter_performance (SQLITE):
    CREATE TABLE STATS_CONTENTFILTER_PERFORMANCE (calls varchar(10), runtime real, period varchar(10), type varchar(32), start integer, module varchar(32), id INTEGER PRIMARY KEY);
    
    CREATE UNIQUE INDEX STATS_CONTENTFILTER_PERFORMANCE_MODULE_PERIOD_START_TYPE ON STATS_CONTENTFILTER_PERFORMANCE (module, period, start, type);
    
    -- TABLE: stats_contentfilter_response (SQLITE):
    CREATE TABLE STATS_CONTENTFILTER_RESPONSE (period varchar(10), type varchar(32), start integer, module varchar(32), id INTEGER PRIMARY KEY);
    
    CREATE UNIQUE INDEX STATS_CONTENTFILTER_RESPONSE_MODULE_PERIOD_START_TYPE ON STATS_CONTENTFILTER_RESPONSE (module, period, start, type);


=head1 CLASS ATTRIBUTES

See L<Mail::Decency::Policy::Core>


=head2 weight_threshold : Int

Threshold of spam score before reject ( actual score <= threeshold == spam )

=cut

has weight_threshold => ( is => 'rw', isa => 'Int', default => -100 );

=head2 session_data : Mail::Decency::Core::SessionItem::Policy

Instance of L<Mail::Decency::Core::SessionItem::Policy>

=cut

has session_data => ( is => 'rw', isa => 'Mail::Decency::Core::SessionItem::Policy' );

=head2 pass_localhost : Bool

Wheter passing everything from localhost or not

Default: 1

=cut

has pass_localhost => ( is => 'rw', isa => 'Bool', default => 1 );

=head2 default_reject_message : Str

Default reject message string (after the SMTP REJECT command .. "REJECT message")

Default: use decency

=cut

has default_reject_message => ( is => 'rw', isa => 'Str', default => "use decency" );


=head2 no_reject_detail : Bool

Wheter pass detailed information of why a particular REJECT has been thrown to the sender or not (not=always the default message)/

Default: 0

=cut

has no_reject_detail => ( is => 'rw', isa => 'Bool', default => 0 );

=head2 forward_scoring : Bool

Wheter forward scoring informations after policies or not

Default: 0

=cut

has forward_scoring => ( is => 'rw', isa => 'Bool', default => 0 );

=head2 disable_prepend : Bool

Wheter disabling the prepend of instance information fully (implies forward_scoring=0)

Default: 0

=cut

has disable_prepend => ( is => 'rw', isa => 'Bool', default => 0 );

=head2 forward_sign_key : Str

Path to a file containing a private key for signing forwarded

=cut

has forward_sign_key  => ( is => 'rw', isa => 'Str', predicate => 'has_forward_sign_key', trigger => sub {
    my ( $self, $key_file ) = @_;
    
    # check file
    $key_file = $self->config_dir . "/$key_file"
        if $self->has_config_dir && ! -f $key_file;
    die "Could not access policy_sign_pub key file '$key_file'\n"
        unless -f $key_file;
    
    # read key
    open my $fh, '<', $key_file
        or die "Cannot open policy_sign_pub key file for read: $!\n";
    my $key_content = join( "", <$fh> );
    close $fh;
    
    # try load rsa and init private key
    my $load_rsa = eval "use Crypt::OpenSSL::RSA; 1;";
    if ( $load_rsa ) {
        $self->forward_sign_key_priv( Crypt::OpenSSL::RSA->new_private_key( $key_content ) );
    }
    
    # failure in loading -> bye
    else {
        die "Could not load Crypt::OpenSSL::RSA, cannot sign headers! Error: $@\n";
    }
    
    return;
} );

=head2 forward_sign_key_priv : Crypt::OpenSSL::RSA

Instance of L<Crypt::OpenSSL::RSA> representing the forward sign key

=cut

has forward_sign_key_priv => ( is => 'rw', isa => 'Crypt::OpenSSL::RSA' );


=head1 METHODS

=head2 init

Loads policy modules, inits caches, inits databases ..

=cut

sub init {
    my ( $self ) = @_;
    
    # init name
    $self->name( "policy" );
    
    # mark es inited
    $self->{ inited } ++;
    
    $self->init_logger();
    $self->init_postfix_server();
    $self->init_cache();
    $self->init_database();
    
    $self->logger->info( "Startup Phase" );
    
    # set another default reject message
    $self->default_reject_message( $self->config->{ default_reject_message } )
        if $self->config->{ default_reject_message };
    
    # display always default message and no detail ?
    $self->no_reject_detail( 1 )
        if $self->config->{ no_reject_detail };
    
    # check policy..
    $self->config->{ policy } = []
        unless defined $self->config->{ policy }
        && ref( $self->config->{ policy } ) eq 'ARRAY'
        && scalar @{ $self->config->{ policy } } > 0;
    
    # use weighting ?
    if ( defined $self->config->{ weight_threshold } ) {
        $self->weight_threshold( $self->config->{ weight_threshold } );
    }
    
    # disable local passing ?
    if ( $self->config->{ force_check_local } ) {
        $self->pass_localhost( 0 );
    }
    
    # disable prepending at all ?
    if ( $self->config->{ disable_prepend } ) {
        $self->disable_prepend( 1 );
    }
    
    # prepend scoring info to header ?
    elsif ( $self->config->{ forward_scoring } ) {
        $self->forward_scoring( 1 );
        
        # having sign key ?
        if ( $self->config->{ forward_sign_key } ) {
            $self->forward_sign_key( $self->config->{ forward_sign_key } );
        }
    }
    
    weaken( my $self_weak = $self );
    foreach my $policy_ref( @{ $self->config->{ policy } } ) {
        my ( $name, $config_ref ) = %$policy_ref;
        my $policy = $self->gen_child(
            "Mail::Decency::Policy" => $name => $config_ref );
        $policy_ref->{ $name } = $policy->config if $policy;
    }
    
    
    $self->logger->info( "  Setup done" );
    
    return;
}



=head2 get_handlers

Returns subref to handlers, called by L<Mail::Decency::Core::POEForking::Postfix>

    # all handlers
    my $handlers_ref = $policy->get_handlers();
    
    # only the awl handler
    my $handlers_ref = $policy->get_handlers( qw/ AWL / );

=cut

sub get_handlers {
    my ( $self ) = @_;
    
    # check wheter having config!
    die "No config has been set\n"
        unless $self->has_config;
    
    # init policies
    $self->init() unless $self->inited;
    
    weaken( my $self_weak = $self );
    
    
    return sub {
        my ( $server, $attrs_ref ) = @_;
        
        # don bother with loopback addresses
        return {
            action => 'DUNNO'
        } if $self->pass_localhost && is_local_host( $attrs_ref->{ client_address } );
        
        # start handling-session
        $self->session_init( $attrs_ref );
        
        # apply all policies
        foreach my $policy( @{ $self_weak->childs } ) {
            
            if ( $self->has_exclusions && $self->do_exclude( $policy ) ) {
                $self->logger->debug2( "Exclude $policy" );
                next;
            }
            
            # determine weight before, so we can increment stats
            my $weight_before  = $self->session_data->spam_score;
            my $start_time_ref = [ gettimeofday() ];
            
            # perform policy
            eval {
                
                # set timeout for module..
                my $alarm = \( local $SIG{ ALRM } );
                if ( $policy->timeout ) {
                    $$alarm = sub {
                        Mail::Decency::Core::Exception::Timeout
                            ->throw( { message => "Timeout" } );
                    };
                    alarm( $policy->timeout + 1 );
                }
                
                $policy->handle( $server, $attrs_ref );
            };
            my $err = $@;
            alarm( 0 );
            
            # update stats
            if ( $self->enable_stats ) {
                my ( $response_prefix ) = split( ' ', $self->session_data->response );
                my $weight_diff = $self->session_data->spam_score - $weight_before;
                $self->update_stats( $policy => $response_prefix => $weight_diff, tv_interval( $start_time_ref, [ gettimeofday() ] ) );
            }
            
            # handle error, if any
            given ( $err ) {
                
                # REJECT
                when( blessed( $_ ) && $_->isa( 'Mail::Decency::Core::Exception::Reject' ) ) {
                    $self->add_response_message( $_->message );
                    last;
                }
                # OK
                when( blessed( $_ ) && $_->isa( 'Mail::Decency::Core::Exception::Accept' ) ) {
                    $self->add_response_message( $_->message );
                    last;
                }
                # PREPEND (finish with response)
                when( blessed( $_ ) && $_->isa( 'Mail::Decency::Core::Exception::Prepend' ) ) {
                    $self->add_response_message( $_->message );
                    last;
                }
                # ERROR
                when( defined $_ && "$_" ne "" ) {
                    $self->logger->error( "Error in $policy: $_" );
                }
                # DUNNO
                default {
                    $self->logger->debug2( "State after $policy: ". $self->session_data->response );
                }
            }
            
            # finish, if last
            last if $self->session_data->response ne 'DUNNO';
        }
        
        
        # clear info and stash to cache
        my $response = $self->session_cleanup();
        
        # update global policy stats
        if ( $self->enable_stats ) {
            my ( $response_prefix ) = split( ' ', $response );
            $self->update_stats( PolicyCore => $response_prefix );
        }
        
        $self->logger->debug3( "Response after policies: $response" );
        
        # return final answer (REJECT, OK, DUNNO, 4xx, 5xx, ..)
        return {
            action => $response
        };
    };
}


#
#               RUNTIME
#


=head2 start

Starts all POE servers without calling the POE::Kernel->run

=cut

sub start {
    my ( $self ) = @_;
    Mail::Decency::Core::POEForking::Postfix->new( $self );
}


=head2 run 

Start and run the server via POE::Kernel->run

=cut

sub run {
    my ( $self ) = @_;
    $self->start;
    
    POE::Kernel->run;
}



#
#               SESSION
#


=head2 session_init $attributes_ref

Called at start of every handle cycle. Inits all handle/session-variables

=cut

sub session_init {
    my ( $self, $attrs_ref ) = @_;
    
    # assure we have that:
    $attrs_ref->{ instance } ||= "NOQUEUE-". time(). int( rand() * 999999 );
    
    # create new session
    my $session = Mail::Decency::Core::SessionItem::Policy->new(
        id    => $attrs_ref->{ instance },
        cache => $self->cache,
        from  => $attrs_ref->{ sender },
        to    => $attrs_ref->{ recipient },
    );
    
    # add the sign key, if we can   
    $session->sign_key( $self->forward_sign_key_priv )
        if $self->has_forward_sign_key;
    
    # check wheter session already in cache (policy might have multiple instances
    my $cached;
    if ( ( $cached = $self->cache->get( "POLICY-$attrs_ref->{ instance }" ) ) && ref( $cached ) ) {
        $session->update_from_cache( $cached );
    }
    
    # set session
    $self->session_data( $session );
    
    # get recipient prefix and domain
    ( $attrs_ref->{ recipient_prefix }, $attrs_ref->{ recipient_domain } )
        = split( /@/, $attrs_ref->{ recipient }, 2 );
    $attrs_ref->{ recipient_address } = $attrs_ref->{ recipient };
    
    # get sender prefix and domain
    ( $attrs_ref->{ sender_prefix }, $attrs_ref->{ sender_domain } )
        = split( /@/, $attrs_ref->{ sender }, 2 );
    $attrs_ref->{ sender_address } = $attrs_ref->{ sender };
    
    return $attrs_ref;
}


=head2 session_cleanup

Clears all info from session cache, returns final response

=cut

sub session_cleanup {
    my ( $self ) = @_;
    
    # get current response
    my $session = $self->session_data;
    my $response = $session->response;
    
    # set prepened info
    if ( ( $response eq 'DUNNO' || $response eq 'PREPEND' ) && ! $self->disable_prepend ) {
        
        # generate the header ..
        my ( $header, $sign_error )
            = $session->generate_instance_header( $self->forward_scoring );
        $self->logger->error( "Sign error: $sign_error" )
            if $sign_error;
        
        
        # header will look like this:
        #  X-Decency-Instance: <instance>|<sign>|<weight>|<flag,flag,...>|<detail>|<detail>|...
        #   this is tested under postfix with up to 10_000 characters! Postfix splits the
        #   lines at 989 characters, but transports all of them.
        $response = 'PREPEND X-Decency-Instance: '. $header;
    }
    
    elsif ( $response =~ /^(?:[45]\d\d|REJECT)/ ) {
        # determine reject message (could be from multiple modules)
        my $message = $self->no_reject_detail
            ? $self->default_reject_message
            : join( " / ", @{ $self->session_data->message } )
                || $self->default_reject_message
        ;
        $response .= " $message";
    }
    
    # update/insert cache
    $self->cache->set( "POLICY-". $session->id => $session->for_cache, time()+ 600 );
    
    # remove from session
    $session->cleanup;
    
    # return bool wheter first instance or not
    return $response;
}



#
#               SCORING / STATE CHANGE
#


=head2 add_spam_score $module, $weight, $details, $reject_message

Add weight and filter info to current instance.

Throws _FinalStateException if weighting indicates spam

=over

=item * $module

The module which called the method.

=item * $weight

Positive or negative score.

=item * $details

Details for the MIME header

=item * $reject_message

If this scoring makes the rejection final, this is the rejection message

=back

=cut

sub add_spam_score {
    my ( $self, $module, $weight, $details, $reject_message ) = @_;
    
    # get info ref
    my $session = $self->session_data;
    
    # increment weight
    $session->add_spam_score( $weight );
    
    # add info
    my @details = ( "Module: $module", "Score: $weight" );
    push @details, $details if $details;
    $session->add_spam_details( join( "; ", @details ) );
    
    # being spam -> go to final state
    if ( $session->spam_score <= $self->weight_threshold ) {
        $self->logger->debug0( "Threshold hit after ". $module->name. " with: ". $session->spam_score. " <= ". $self->weight_threshold );
        
        # send reject message
        $self->go_final_state( $module => REJECT => $reject_message );
    }
    
    # add reject message for future use
    else {
        $self->add_response_message( $reject_message );
    }
    
    # no spam, return ..
    return 0;
}



=head2 go_final_state $module, $state, $message

Throws Mail::Decency::Core::Exception exception if state is not DUNNO.

Adds message to list of response messages 


=cut

sub go_final_state {
    my ( $self, $module, $state, $message ) = @_;
    if ( $state && $state ne 'DUNNO' ) {
        $self->session_data->response( $state );
        $self->logger->debug0( "Final state from $module: $state" );
        
        if ( $state eq 'OK' ) {
            Mail::Decency::Core::Exception::Accept->throw( { message => $message || "" } );
        }
        if ( $state eq 'PREPEND' ) {
            Mail::Decency::Core::Exception::Prepend->throw( { message => $message || "" } );
        }
        else {
            Mail::Decency::Core::Exception::Reject->throw( { message => $message || "" } );
        }
        #die _FinalStateException->new( $message );
    }
    elsif( $message ) {
        $self->add_response_message( $message );
    }
}


=head2 add_response_message $message

Add message (not details) to response

=cut

sub add_response_message {
    my ( $self, $message ) = @_;
    
    # add reject info (only reject info, no positive nor detailed informations)
    push @{ $self->session_data->message }, $message
        if $message;
    
    return ;
}


=head1 SEE ALSO

=over

=item * L<Mail::Decency::Policy::Association>

=item * L<Mail::Decency::Policy::CBL>

=item * L<Mail::Decency::Policy::CWL>

=item * L<Mail::Decency::Policy::Core>

=item * L<Mail::Decency::Policy::DNSBL>

=item * L<Mail::Decency::Policy::Greylist>

=item * L<Mail::Decency::Policy::GeoWeight>

=item * L<Mail::Decency::Policy::Honeypot>

=item * L<Mail::Decency::Policy::SPF>

=item * L<Mail::Decency::Policy::Throttle>

=item * L<Mail::Decency::Core::Stats>

=item * L<Mail::Decency::Core::SessionItem>

=item * L<Mail::Decency::Core::SessionItem::Policy>

=item * L<Mail::Decency>

=back


=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
