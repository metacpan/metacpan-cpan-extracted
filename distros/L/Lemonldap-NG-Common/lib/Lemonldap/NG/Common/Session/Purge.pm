package Lemonldap::NG::Common::Session::Purge;

use strict;
use Lemonldap::NG::Common::Conf;
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::Apache::Session;
use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::Safelib;
use Lemonldap::NG::Common::PSGI::Request;
use JSON;
use Mouse;
use Time::HiRes;
use POSIX qw(strftime);

use constant defaultLogger => 'Lemonldap::NG::Common::Logger::Std';

has logLevel => ( is => 'rw' );
has force    => ( is => 'rw' );
has audit    => ( is => 'rw' );
has json     => ( is => 'rw' );
has conf => (
    is      => 'ro',
    default => sub {
        my $ca = Lemonldap::NG::Common::Conf->new()
          or die $Lemonldap::NG::Common::Conf::msg;
        my $conf =
             $ca->getConf
          or die "Unable to get configuration ($!)"
          or die "Unable to get configuration ($!)";
        my $localconf = $ca->getLocalConf(PORTALSECTION)
          or die "Unable to get local configuration ($!)";
        if ($localconf) {
            $conf->{$_} = $localconf->{$_} foreach ( keys %$localconf );
        }
        $conf->{logLevel} = $_[0]->logLevel || $conf->{logLevel} || 'info';
        return $conf;
    },
    lazy => 1,
);

has logger => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        my $conf = $self->conf;
        my $logger =
          $self->conf->{logger} || $ENV{LLNG_DEFAULTLOGGER} || defaultLogger;
        $logger =~ s/^::/Lemonldap::NG::Common::Logger::/;
        $logger = defaultLogger
          if $logger eq 'Lemonldap::NG::Common::Logger::Apache2';
        eval "require $logger";
        die $@ if ($@);
        my $err;

        unless ( $conf->{logLevel} =~ /^(?:debug|info|notice|warn|error)$/ ) {
            $err = "Bad logLevel value $conf->{logLevel}, use 'info'";
            $conf->{logLevel} = 'info';
        }
        $logger = $logger->new($conf);
        $logger->error($err) if $err;
        return $logger;
    },
    lazy => 1,
);

has userLogger => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        my $conf = $self->conf;
        my $logger =
          $self->conf->{userLogger} || $ENV{LLNG_USERLOGGER} || defaultLogger;
        $logger =~ s/^::/Lemonldap::NG::Common::Logger::/;
        $logger = defaultLogger
          if $logger eq 'Lemonldap::NG::Common::Logger::Apache2';
        eval "require $logger";
        die $@ if ($@);
        my $err;

        unless ( $conf->{logLevel} =~ /^(?:debug|info|notice|warn|error)$/ ) {
            $err = "Bad logLevel value $conf->{logLevel}, use 'info'";
            $conf->{logLevel} = 'info';
        }
        $logger = $logger->new($conf);
        $logger->error($err) if $err;
        return $logger;
    },
    lazy => 1,
);

has _auditLogger => (
    is      => 'ro',
    default => sub {
        my $self = shift;
        my $conf = $self->conf;
        my $logger =
             $self->conf->{auditLogger}
          || $ENV{LLNG_AUDITLOGGER}
          || "Lemonldap::NG::Common::AuditLogger::UserLoggerCompat";

        eval "require $logger";
        die $@ if ($@);

        $logger = $logger->new($self);
        return $logger;
    },
    lazy => 1,
);

has persistent_backend_options => (
    is      => 'ro',
    default => sub {
        my $conf   = $_[0]->conf;
        my $logger = $_[0]->logger;

        my $type;
        my $options;

        # sessions
        if ( $conf->{persistentStorage} ) {
            $type = 'persistent';
        }
        else {
            $type = 'global';
        }

        # load module
        my $module = $conf->{"${type}Storage"};
        eval "use $module";
        die $@ if ($@);

        $options = { %{ $conf->{"${type}StorageOptions"} // {} } };
        $options->{backend} = $module;

        $logger->debug("persistent session backend $module will be used");
        return $options;
    },
    lazy => 1,
);

has backends => (
    is      => 'ro',
    default => sub {
        my $conf   = $_[0]->conf;
        my $logger = $_[0]->logger;
        my %backends;
        my $module;

        # Sessions
        if ( $conf->{globalStorage} ) {

            # Load module
            $module = $conf->{globalStorage};
            eval "use $module";
            die $@ if ($@);
            $conf->{globalStorageOptions}->{backend} = $module;

            # Add module in managed backends
            $backends{SSO} = $conf->{globalStorageOptions};

            $logger->debug("Session backend $module will be used");
        }

        # SAML
        if ( $conf->{samlStorage}
            or keys %{ $conf->{samlStorageOptions} ||= {} } )
        {

            # Load module
            $module = $conf->{samlStorage} || $conf->{globalStorage};
            eval "use $module";
            die $@ if ($@);
            $conf->{samlStorageOptions}->{backend} = $module;

            # Add module in managed backends
            $backends{SAML} = $conf->{samlStorageOptions};

            $logger->debug("SAML backend $module will be used");
        }

        # CAS
        if ( $conf->{casStorage}
            or keys %{ $conf->{casStorageOptions} ||= {} } )
        {

            # Load module
            $module = $conf->{casStorage} || $conf->{globalStorage};
            eval "use $module";
            die $@ if ($@);
            $conf->{casStorageOptions}->{backend} = $module;

            # Add module in managed backends
            $backends{CAS} = $conf->{casStorageOptions};

            $logger->debug("CAS backend $module will be used");
        }

        # Captcha
        if ( $conf->{captchaStorage}
            or keys %{ $conf->{captchaStorageOptions} ||= {} } )
        {

            # Load module
            $module = $conf->{captchaStorage} || $conf->{globalStorage};
            eval "use $module";
            die $@ if ($@);
            $conf->{captchaStorageOptions}->{backend} = $module;

            # Add module in managed backends
            $backends{Captcha} = $conf->{captchaStorageOptions};

            $logger->debug("Captcha backend $module will be used");
        }

        # OpenIDConnect
        if ( $conf->{oidcStorage}
            or keys %{ $conf->{oidcStorageOptions} ||= {} } )
        {

            # Load module
            $module = $conf->{oidcStorage} || $conf->{globalStorage};
            eval "use $module";
            die $@ if ($@);
            $conf->{oidcStorageOptions}->{backend} = $module;

            # Add module in managed backends
            $backends{OIDC} = $conf->{oidcStorageOptions};

            $logger->debug("OIDC backend $module will be used");
        }
        return \%backends;
    },
    lazy => 1,
);

has force => ( is => 'ro' );

my %PSESSION_FILTERS = (
    age => {
        filter => sub {
            my ( $self, $entry, $value ) = @_;
            return ( defined( $entry->{_utime} )
                  and $entry->{_utime} < ( time - $value ) );
        }
    },
    update => {
        filter => sub {
            my ( $self, $entry, $value ) = @_;
            my $min_updateTime =
              strftime( "%Y%m%d%H%M%S", localtime( time - $value ) );
            my $filter_result = ( defined( $entry->{_updateTime} )
                  and $entry->{_updateTime} < $min_updateTime );
        }
    },
    login => {
        filter => sub {
            my ( $self, $entry, $value ) = @_;
            my $lastLogin =
              $entry->{_loginHistory}->{successLogin}->[0]->{_utime};

            my $filter_result = (
                not defined($lastLogin)
                  or ( defined($value) and ( $lastLogin < ( time - $value ) ) )
            );
        }
    },
    sfdevice => {
        filter => sub {
            my ( $self, $entry, $value ) = @_;
            return !Lemonldap::NG::Common::Safelib::has2f_internal($entry);
        }
    },
);

sub purge {
    my ($self) = @_;

    my $internal_stats;

    # Compute the list of backends here to avoid having big timing
    # inconsistencies
    my $backends = $self->backends;

    # Trigger lazy init
    my $conf = $self->conf;

    $self->logger->info("Session purge started");
    $internal_stats->{start_time}->{total} = Time::HiRes::time();

    while ( my ( $type, $options ) = each %$backends ) {
        $self->_purge_for_backend( $type, $options, $internal_stats );
    }

    $internal_stats->{end_time}->{total} = Time::HiRes::time();

    my $total_purged = 0;
    $total_purged += $_ for values %{ $internal_stats->{nb_purged} };
    $internal_stats->{nb_purged}->{total} = $total_purged;

    my $total_error = 0;
    $total_error += $_ for values %{ $internal_stats->{nb_error} };
    $internal_stats->{nb_error}->{total} = $total_error;

    my $return_stats;
    for my $type ( "total", sort keys %{ $self->backends } ) {
        $return_stats->{$type}->{errors} = $internal_stats->{nb_error}->{$type};
        $return_stats->{$type}->{purged} =
          $internal_stats->{nb_purged}->{$type};
        $return_stats->{$type}->{duration_u} = int(
            1000000 * (
                $internal_stats->{end_time}->{$type} -
                  $internal_stats->{start_time}->{$type}
            )
        );
    }

    my $log = "Session purge completed: ";
    if ( $self->json ) {
        $log .= to_json($return_stats);
    }
    else {
        my @logentries;
        for my $type ( "total", sort keys %{ $self->backends } ) {
            my $logentry .= "$type (";
            $logentry    .= $return_stats->{$type}->{purged} . " purged, ";
            $logentry    .= $return_stats->{$type}->{errors} . " errors in ";
            $logentry    .= $return_stats->{$type}->{duration_u} . " us";
            $logentry    .= ")";
            push @logentries, $logentry;
        }
        $log .= join( ', ', @logentries );
    }

    $self->logger->info($log);
    $self->logger->warn(
"$total_error sessions remaining, try to purge them with force (option -f)"
    ) if $total_error;

    return {
        success => !($total_error),
        purged  => $total_purged,
        errors  => $total_error,
        stats   => $return_stats,
    };
}

sub _purge_for_backend {
    my ( $self, $type, $options, $internal_stats ) = @_;
    my $conf = $self->conf;
    $self->logger->debug("Cleaning $type sessions");

    $internal_stats->{nb_error}->{$type}   = 0;
    $internal_stats->{nb_purged}->{$type}  = 0;
    $internal_stats->{start_time}->{$type} = Time::HiRes::time();

    if ( $options->{backend} eq "Apache::Session::Memcached" ) {
        $internal_stats->{end_time}->{$type} = Time::HiRes::time();
        return;
    }

    my @t;

    # Memorize some OIDC parameters
    my ( $rpActivity, $rtMinTimeout );
    foreach my $rp ( keys %{ $conf->{oidcRPMetaDataOptions} || {} } ) {
        my $v = $conf->{oidcRPMetaDataOptions}->{$rp}
          ->{oidcRPMetaDataOptionsRtActivity};
        next unless $v;

        # Store the mapping ClientID -> RT timeout
        $rpActivity->{ $conf->{oidcRPMetaDataOptions}->{$rp}
              ->{oidcRPMetaDataOptionsClientID} } = $v;
        $rtMinTimeout = $v if !$rpActivity or $v < $rpActivity;
    }

    my $checkRtExpiration = sub {
        my ($id, $session) = @_;
        return unless $session->{_session_kind} eq 'OIDCI';
        return unless $session->{_type} eq 'refresh_token';
        my $v = $session->{_oidcRtUpdate} or return;
        my $timeout = $rpActivity->{ $session->{client_id} } or return;
        push @t, $id if $v + $timeout < time;
    };

    # Real purge
    if ( $options->{backend}->can('deleteIfLowerThan') ) {
        $self->logger->debug("Found deleteIfLowerThan() in backend, using it");
        my ( $success, $rows ) = $options->{backend}->deleteIfLowerThan(
            $options,
            {
                not => { '_session_kind' => 'Persistent' },
                or  => {
                    _utime => time - $conf->{timeout},
                    (
                        $conf->{timeoutActivity}
                        ? ( _lastSeen => time - $conf->{timeoutActivity} )
                        : ()
                    )
                }
            }
        );

        if ($success) {
            if ($rows) {
                $internal_stats->{nb_purged}->{$type} += $rows;
            }
            if ($rtMinTimeout) {
                my $rtSessions = $options->{backend}
                  ->searchLt( $options, '_oidcRtUpdate', time - $rtMinTimeout );
                if ($rtSessions) {
                    foreach my $id ( keys %$rtSessions ) {
                        $checkRtExpiration->( $id, $rtSessions->{$id} );
                    }
                }
            }
            $internal_stats->{end_time}->{$type} = Time::HiRes::time();
            return unless @t;
        }
    }

    else {
        # Get all expired sessions
        Lemonldap::NG::Common::Apache::Session->get_key_from_all_sessions(
            $options,
            sub {
                my $entry = shift;
                my $id    = shift;
                my $time  = time;

                $self->logger->debug("Check session $id");

                # Empty session need to be removed
                unless ($entry) {
                    push @t, $id;
                    $self->logger->debug(
                        "Session $id is empty (corrupted?), delete forced");
                }

                # Do net check sessions without _utime
                return undef unless $entry->{_utime};

                # Do not expire persistent sessions
                return undef if ( $entry->{_session_kind} eq "Persistent" );

                # Session expired
                if ( $time - $entry->{_utime} > $conf->{timeout} ) {
                    push @t, $id;
                    $self->logger->debug("Session $id expired");
                }

                # User has no activity, so considere the session has expired
                elsif ( $conf->{timeoutActivity}
                    and $entry->{_lastSeen}
                    and $time - $entry->{_lastSeen} > $conf->{timeoutActivity} )
                {
                    push @t, $id;
                    $self->logger->debug("Session $id inactive");
                }
                elsif ($rtMinTimeout) {
                    $checkRtExpiration->( $id, $entry );
                }
                undef;
            }
        );
    }

    # Delete sessions
    my @errors;
    for my $id (@t) {

        my $session = Lemonldap::NG::Common::Session->new(
            storageModule        => $options->{backend},
            storageModuleOptions => $options,
            cacheModule          => $conf->{localSessionStorage},
            cacheModuleOptions   => $conf->{localSessionStorageOptions},
            id                   => $id,
        );

        unless ( $session->data ) {
            $self->logger->debug("Error while opening session $id");
            print STDERR "Error on session $id\n";
            $internal_stats->{nb_error}->{$type}++;
            push @errors, $id;
            next;
        }

        unless ( $session->remove ) {
            $self->logger->debug("Error while deleting session $id");
            print STDERR "Error on session $id\n";
            $internal_stats->{nb_error}->{$type}++;
            push @errors, $id;
            next;
        }
        $self->logger->debug("Session $id has been purged");
        $internal_stats->{nb_purged}->{$type}++;
    }

    $self->_cleanup_lock_files( $type, $options, $internal_stats );
    $self->_cleanup_errors( $type, $options, $internal_stats, \@errors );

    $internal_stats->{end_time}->{$type} = Time::HiRes::time();
}

sub _cleanup_lock_files {
    my ( $self, $type, $options, $internal_stats ) = @_;
    my $conf = $self->conf;

    # Remove lock files for File backend
    if ( $options->{backend} =~ /^Apache::Session::(?:Browseable::)?File$/i ) {
        require Apache::Session::Lock::File;
        my $l              = Apache::Session::Lock::File->new;
        my $lock_directory = $options->{LockDirectory} || $options->{Directory};
        $l->clean( $lock_directory, $conf->{timeout} );
    }
    return;
}

sub _cleanup_errors {
    my ( $self, $type, $options, $internal_stats, $errors_ref ) = @_;
    my @errors = @$errors_ref;
    my $conf   = $self->conf;

    # Force deletion of corrupted sessions for File backend
    if (    $options->{backend} =~ /^Apache::Session::(?:Browseable::)?File$/i
        and $self->force )
    {
        foreach (@errors) {
            my $id = $_;
            eval { unlink $options->{Directory} . "/$id"; };
            if ($@) {
                $self->logger->error("Unable to remove session $id");
            }
            else {
                $self->logger->warn("Session $id removed with force");
                $internal_stats->{nb_error}->{$type}--;
            }
        }
    }

    # Force deletion of corrupted sessions for DBI backend
    if ( $options->{backend} =~
/^Apache::Session::(?:Browseable::)?(MySQL|Postgres|DBI|Oracle|Informix|MySQLJSON|PgHstore|PgJSON|SQLLite|Sybase)$/i
        and $self->force )
    {
        my $dbi = DBI->connect_cached( $options->{DataSource},
            $options->{UserName}, $options->{Password} );
        my $table = $options->{TableName} || "sessions";
        my $req   = $dbi->prepare("DELETE from $table WHERE id=?");
        foreach (@errors) {
            my $id  = $_;
            my $res = $req->execute($id);
            unless ( $res == 1 ) {
                $self->logger->error("Fail to delete session $id with force");
            }
            else {
                $self->logger->warn("Session $id removed with force");
                $internal_stats->{nb_error}->{$type}--;
            }
        }
    }

    # Force deletion of corrupted sessions for LDAP backend
    if (    $options->{backend} =~ /^Apache::Session::(?:Browseable::)?LDAP$/i
        and $self->force )
    {
        my $useTls = 0;
        my $tlsParam;
        my @servers = ();
        foreach my $server ( split /[\s,]+/, $options->{ldapServer} ) {
            if ( $server =~ m{^ldap\+tls://([^/]+)/?\??(.*)$} ) {
                $useTls   = 1;
                $server   = $1;
                $tlsParam = $2 || "";
            }
            else {
                $useTls = 0;
            }
            push @servers, $server;
        }
        my $ldap =
          Net::LDAP->new( \@servers, keepalive => 1, onerror => undef, );
        unless ($ldap) {
            print STDERR "Unable to connect to LDAP server\n";
            $internal_stats->{nb_error}->{$type}++;
            return;
        }

        # Start TLS if needed
        if ($useTls) {
            my %h = split( /[&=]/, $tlsParam );
            $h{verify} ||= $options->{ldapVerify} || "require";
            $h{cafile} ||= $options->{ldapCAFile}
              if ( $options->{ldapCAFile} );
            $h{capath} ||= $options->{ldapCAPath}
              if ( $options->{ldapCAPath} );
            my $start_tls = $ldap->start_tls(%h);
            if ( $start_tls->code ) {
                print STDERR "STARTTLS error: "
                  . $start_tls->code . ': '
                  . $start_tls->error;
                $internal_stats->{nb_error}->{$type}++;
                return;
            }
        }

        my $bind = $ldap->bind( $options->{ldapBindDN},
            password => $options->{ldapBindPassword} );
        my $attrId = $options->{ldapAttributeId} | "cn";
        foreach (@errors) {
            my $id = $_;
            my $sessionDn =
              $attrId . "=" . $id . "," . $options->{ldapConfBase};
            my $delete = $ldap->delete($sessionDn);
            if ( $delete->is_error ) {
                $self->logger->error("Fail to delete session $id with force");
            }
            else {
                $self->logger->warn("Session $id removed with force");
                $internal_stats->{nb_error}->{$type}--;
            }
        }
    }
    return;
}

sub persistentPurge {
    my ( $self, $filters ) = @_;

    my $internal_stats;

    $self->logger->info("Persistent session purge started");

    $internal_stats->{start_time}->{total} = Time::HiRes::time();

    $self->_purge_persistent( $filters, $internal_stats );

    $internal_stats->{end_time}->{total} = Time::HiRes::time();

    my $total_purged = 0;
    $total_purged += $_ for values %{ $internal_stats->{nb_purged} };
    $internal_stats->{nb_purged}->{total} = $total_purged;

    my $total_error = 0;
    $total_error += $_ for values %{ $internal_stats->{nb_error} };
    $internal_stats->{nb_error}->{total} = $total_error;

    my $return_stats;
    for my $type ( "total", 'Persistent' ) {
        $return_stats->{$type}->{errors} = $internal_stats->{nb_error}->{$type};
        $return_stats->{$type}->{purged} =
          $internal_stats->{nb_purged}->{$type};
        $return_stats->{$type}->{duration_u} = int(
            1000000 * (
                $internal_stats->{end_time}->{$type} -
                  $internal_stats->{start_time}->{$type}
            )
        );
    }

    my $log = "Persistent session purge completed: ";
    if ( $self->json ) {
        $log .= to_json($return_stats);
    }
    else {
        my @logentries;
        for my $type ( "total", "Persistent" ) {
            my $logentry .= "$type (";
            $logentry    .= $return_stats->{$type}->{purged} . " purged, ";
            $logentry    .= $return_stats->{$type}->{errors} . " errors in ";
            $logentry    .= $return_stats->{$type}->{duration_u} . " us";
            $logentry    .= ")";
            push @logentries, $logentry;
        }
        $log .= join( ', ', @logentries );
    }

    $self->logger->info($log);

    return {
        success => 1,

        purged => $total_purged,
        errors => $total_error,
        stats  => $return_stats,
    };
}

sub _purge_persistent {
    my ( $self, $filters, $internal_stats ) = @_;
    my $type    = "Persistent";
    my $conf    = $self->conf;
    my $options = $self->persistent_backend_options;

    my @t;

    $internal_stats->{nb_error}->{$type}   = 0;
    $internal_stats->{nb_purged}->{$type}  = 0;
    $internal_stats->{start_time}->{$type} = Time::HiRes::time();

    # Get all expired sessions
    Lemonldap::NG::Common::Apache::Session->get_key_from_all_sessions(
        $options,
        sub {
            my $entry = shift;
            my $id    = shift;
            my $time  = time;

            $self->logger->debug("Check session $id");

            unless ($entry) {
                $self->logger->debug("Session $id is empty");
                return;
            }

            # Ignore non-persistent sessions
            return unless ( $entry->{_session_kind} eq "Persistent" );

            # safety check: do not remove if there are no filters
            my $remove = keys %$filters ? 1 : 0;

            while ( my ( $filter_type, $value ) = each %$filters ) {
                if ( my $filter_configuration =
                    $PSESSION_FILTERS{$filter_type} )
                {
                    my $filter_result =
                      $filter_configuration->{filter}
                      ->( $self, $entry, $value );
                    $self->logger->debug(
                        "$filter_type filter result: " . int($filter_result) );
                    $remove &&= $filter_result;
                }
                else {
                    $self->logger->debug("Unknown filter $filter_type");
                    $remove = 0;
                }
            }

            push @t, $id if $remove;

        }
    );

    # Delete sessions
    my @errors;
    for my $id (@t) {

        my $session = Lemonldap::NG::Common::Session->new(
            storageModule        => $options->{backend},
            storageModuleOptions => $options,
            cacheModule          => $conf->{localSessionStorage},
            cacheModuleOptions   => $conf->{localSessionStorageOptions},
            id                   => $id,
        );

        unless ( $session->data ) {
            $self->logger->debug("Error while opening session $id");
            print STDERR "Error on session $id\n";
            $internal_stats->{nb_error}->{$type}++;
            push @errors, $id;
            next;
        }

        unless ( $session->remove ) {
            $self->logger->debug("Error while deleting session $id");
            print STDERR "Error on session $id\n";
            $internal_stats->{nb_error}->{$type}++;
            push @errors, $id;
            next;
        }
        $self->logger->debug("Session $id has been purged");
        $self->_auditPurgePsession( $session->data ) if $self->audit;
        $internal_stats->{nb_purged}->{$type}++;
    }
    $internal_stats->{end_time}->{$type} = Time::HiRes::time();
}

sub localPurge {
    my ($self) = @_;
    $self->logger->debug( __PACKAGE__ . "::localPurge() called" );
    my $conf = $self->conf;
    if ( $conf->{localSessionStorage} ) {
        eval "require $conf->{localSessionStorage}";
        die $@ if $@;
        $conf->{localSessionStorageOptions}->{default_expires_in} ||= 600;
        my $s = $conf->{localSessionStorage}
          ->new( $conf->{localSessionStorageOptions} );
        $s->purge();
    }
}

sub auditLog {
    my ( $self, $req, %info ) = @_;
    $self->_auditLogger->log( $req, %info );
}

sub _auditPurgePsession {
    my ( $self, $session ) = @_;
    my $dummy_req = Lemonldap::NG::Common::PSGI::Request->new(
        { PATH_INFO => "", REQUEST_URI => "" } );
    my $uid = $session->{_session_uid};
    $self->auditLog(
        $dummy_req,
        message => ("Persistent session for $uid was removed"),
        code    => "PSESSION_REMOVED",
        user    => $uid,
    );
}

1;
