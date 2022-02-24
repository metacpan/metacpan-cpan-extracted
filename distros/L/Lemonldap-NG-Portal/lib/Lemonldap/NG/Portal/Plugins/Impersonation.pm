package Lemonldap::NG::Portal::Plugins::Impersonation;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_MALFORMEDUSER
  PE_OK PE_BADCREDENTIALS
  PE_IMPERSONATION_SERVICE_NOT_ALLOWED
);

our $VERSION = '2.0.10';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::_tokenRule
);

# INITIALIZATION

use constant afterData => 'run';

has rule                  => ( is => 'rw', default => sub { 1 } );
has idRule                => ( is => 'rw', default => sub { 1 } );
has unrestrictedUsersRule => ( is => 'rw', default => sub { 0 } );

# Form timeout token generator (used if requireToken is set)
has ott => ( is => 'rw' );

# Captcha generator
has captcha => ( is => 'rw' );

sub hAttr {
    $_[0]->{conf}->{impersonationHiddenAttributes} . ' '
      . $_[0]->{conf}->{hiddenAttributes};
}

sub init {
    my ($self) = @_;

    # Parse Impersonation rules
    $self->rule(
        $self->p->buildRule(
            $self->conf->{impersonationRule}, 'impersonation'
        )
    );
    return 0 unless $self->rule;

    $self->idRule(
        $self->p->buildRule(
            $self->conf->{impersonationIdRule},
            'impersonationId'
        )
    );
    return 0 unless $self->idRule;

    $self->unrestrictedUsersRule(
        $self->p->buildRule(
            $self->conf->{impersonationUnrestrictedUsersRule},
            'impersonationUnrestrictedUsers'
        )
    );
    return 0 unless $self->unrestrictedUsersRule;

    # Initialize Captcha if needed
    if ( $self->{conf}->{captcha_login_enabled} ) {
        $self->captcha( $self->p->loadModule('::Lib::Captcha') ) or return 0;
    }

    # Initialize form token if needed (captcha provides also a token)
    else {
        $self->ott( $self->p->loadModule('::Lib::OneTimeToken') ) or return 0;
        $self->ott->timeout( $self->conf->{formTimeout} );
    }

    return 1;
}

# RUNNING METHOD

sub run {
    my ( $self, $req ) = @_;

    return $req->authResult
      if $req->authResult >
      PE_OK;    # Skip Impersonation if an error occurs during Auth process

    my $statut = PE_OK;
    my $unUser = 0;
    my $loginHistory =
      $req->{sessionInfo}->{_loginHistory};    # Store login history
    $req->{user} ||= $req->{sessionInfo}->{_impUser};   # If 2FA is enabled
    my $spoofId = $req->param('spoofId')                # Impersonation required
      || $req->{sessionInfo}->{_impSpoofId}             # If 2FA is enabled
      || $req->{user};    # Impersonation not required

    $self->logger->debug("No impersonation required")
      if ( $spoofId eq $req->{user} );

    unless ( $spoofId =~ /$self->{conf}->{userControl}/o ) {
        $self->userLogger->warn('Malformed spoofed Id');
        $self->logger->debug("Impersonation tried with spoofed Id: $spoofId");
        $spoofId = $req->{user};
        $statut  = PE_MALFORMEDUSER;
    }

    # Check activation & unrestrictedUsers rules
    if ( $spoofId ne $req->{user} ) {
        $self->logger->debug("Spoof Id: $spoofId / Real Id: $req->{user}");
        unless ( $self->rule->( $req, $req->sessionInfo ) ) {
            $self->userLogger->warn('Impersonation service not authorized');
            $spoofId = $req->{user};
            $statut  = PE_IMPERSONATION_SERVICE_NOT_ALLOWED;
        }
        $unUser = $self->unrestrictedUsersRule->( $req, $req->sessionInfo );
    }

    # Fill spoof session
    my ( $realSession, $spoofSession ) = ( {}, {} );
    $self->logger->debug("Rename real attributes...");
    foreach my $k ( keys %{ $req->{sessionInfo} } ) {
        if ( $self->{conf}->{impersonationSkipEmptyValues} ) {
            next unless defined $req->{sessionInfo}->{$k};
        }
        my $spk = "$self->{conf}->{impersonationPrefix}$k";
        unless ( $self->hAttr =~ /\b$k\b/
            || $k =~ /^(?:_imp|token|_type)\w*\b/ )
        {
            $realSession->{$spk} = $req->{sessionInfo}->{$k};
            $self->logger->debug("-> Store $k in realSession key: $spk");
        }
        $self->logger->debug("Delete $k");
        delete $req->{sessionInfo}->{$k};
    }

    $spoofSession = $self->_userData( $req, $spoofId, $realSession, $unUser );
    if ( $req->error ) {
        $self->setSecurity($req);
        if ( $req->error == PE_BADCREDENTIALS ) {
            $statut = PE_BADCREDENTIALS;  # Catch error to preserve protected Id
        }
        else {
            return $req->error;
        }
    }

    # Merging SSO Groups and hGroups & dedup
    $spoofSession->{groups}  ||= '';
    $spoofSession->{hGroups} ||= {};
    if ( $self->{conf}->{impersonationMergeSSOgroups} ) {
        $self->userLogger->warn("MERGING SSO groups and hGroups...");
        my $spg       = "$self->{conf}->{impersonationPrefix}groups";
        my $sphg      = "$self->{conf}->{impersonationPrefix}hGroups";
        my $separator = $self->{conf}->{multiValuesSeparator};

        ## GROUPS
        $realSession->{$spg} ||= '';
        my @spoofGrps = split /\Q$separator/, $spoofSession->{groups};
        my @realGrps  = split /\Q$separator/, $realSession->{$spg};

        ## hGROUPS
        $realSession->{$sphg} ||= {};

        # Merge specified groups/hGroups only
        my %intersct = %{ $realSession->{$sphg} };
        unless ( $self->{conf}->{impersonationMergeSSOgroups} eq 1 ) {
            %intersct = ();
            my %SSOgroups = map { $_, 1 } split /\Q$separator/,
              $self->{conf}->{impersonationMergeSSOgroups};

            $self->logger->debug("Filtering specified groups/hGroups...");
            @realGrps = grep { exists $SSOgroups{$_} } @realGrps;
            %intersct =
              map {
                $realSession->{$sphg}->{$_}
                  ? ( $_, $realSession->{$sphg}->{$_} )
                  : ()
              } keys %SSOgroups;
        }

        $self->logger->debug("Processing groups...");
        @spoofGrps = ( @spoofGrps, @realGrps );
        my %hash = map { $_, 1 } @spoofGrps;
        $spoofSession->{groups} = join $separator, sort keys %hash;

        $self->logger->debug("Processing hGroups...");
        $spoofSession->{hGroups} =
          { %{ $spoofSession->{hGroups} }, %intersct };
    }

    # Main session
    $self->p->updateSession( $req, $spoofSession );
    $req->{sessionInfo}->{_loginHistory} =
      $loginHistory;    # Restore login history
    $req->steps( [ $self->p->validSession, @{ $self->p->endAuth } ] );

    # Restore _httpSession for Double Cookies
    if ( $self->conf->{securedCookie} >= 2 ) {
        $self->p->updateSession( $req, $spoofSession,
            $req->{sessionInfo}->{real__httpSession} );
        $req->{sessionInfo}->{_httpSession} =
          $req->{sessionInfo}->{real__httpSession};
    }
    return $statut;
}

sub _userData {
    my ( $self, $req, $spoofId, $realSession, $unUser ) = @_;
    my $realId = $req->{user};
    my $raz    = 0;
    $req->{user} = $spoofId;

    # Compute Macros and Groups with real and spoof sessions
    $req->sessionInfo($realSession);
    $req->steps( [
            'getUser',        'setAuthSessionInfo',
            'setSessionInfo', $self->p->groupsAndMacros,
            'setLocalGroups'
        ]
    );
    if ( my $error = $self->p->process($req) ) {
        if ( $error == PE_BADCREDENTIALS ) {
            $self->userLogger->warn(
                    'Impersonation requested for an invalid user ('
                  . $req->{user}
                  . ")" );
        }
        $self->logger->debug("Process returned error: $error");
        $req->error($error);
        $raz = 1;
    }

    # Check identities rule if Impersonation required
    if ( $realId ne $spoofId ) {
        $self->logger->info("\"$realId\" is an unrestricted user!") if $unUser;
        unless ( $unUser || $self->idRule->( $req, $req->sessionInfo ) ) {
            $self->userLogger->warn(
                    'Impersonation requested for an invalid user ('
                  . $req->{user}
                  . ")" );
            $self->logger->debug('Identity NOT authorized');
            $raz = 1;
        }
    }

    # Same real and spoof session - Compute Macros and Groups
    if ($raz) {
        $req->{sessionInfo} = {};
        $req->{sessionInfo} = {%$realSession};
        $req->{user}        = $realId;
        $req->steps( [
                'getUser',                 'setSessionInfo',
                $self->p->groupsAndMacros, 'setLocalGroups'
            ]
        );
        $self->logger->debug('Reset Impersonation process');
        $req->error(PE_BADCREDENTIALS);
        if ( my $error = $self->p->process($req) ) {
            $self->logger->debug("Process returned error: $error");
            $req->error($error);
        }
    }

    # Compute groups & macros again with real authenticationLevel
    $req->sessionInfo->{authenticationLevel} =
      $realSession->{real_authenticationLevel};
    delete $req->sessionInfo->{groups};
    $req->steps(
        [ 'setSessionInfo', $self->p->groupsAndMacros, 'setLocalGroups' ] );
    if ( my $error = $self->p->process($req) ) {
        $self->logger->debug("Impersonation: Process returned error: $error");
        $req->error($error);
    }

    $self->logger->debug("Return \"$req->{user}\" sessionInfo");
    return $req->{sessionInfo};
}

sub setSecurity {
    my ( $self, $req ) = @_;
    if ( $self->captcha ) {
        $self->captcha->setCaptcha($req);
    }
    elsif ( $self->ottRule->( $req, {} ) ) {
        $self->ott->setToken($req);
    }
}

1;
