package Lemonldap::NG::Portal::Plugins::Impersonation;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants
  qw( PE_OK PE_BADCREDENTIALS PE_IMPERSONATION_SERVICE_NOT_ALLOWED PE_MALFORMEDUSER );

our $VERSION = '2.0.4';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INITIALIZATION

use constant afterData => 'run';

has rule   => ( is => 'rw', default => sub { 1 } );
has idRule => ( is => 'rw', default => sub { 1 } );

sub hAttr {
    $_[0]->{conf}->{impersonationHiddenAttributes} . ' '
      . $_[0]->{conf}->{hiddenAttributes};
}

sub init {
    my ($self) = @_;
    my $hd = $self->p->HANDLER;

    # Parse activation rule
    $self->logger->debug(
        "Impersonation rule -> " . $self->conf->{impersonationRule} );
    my $rule =
      $hd->buildSub( $hd->substitute( $self->conf->{impersonationRule} ) );
    unless ($rule) {
        $self->error( "Bad impersonation rule -> " . $hd->tsv->{jail}->error );
        return 0;
    }
    $self->rule($rule);

    # Parse identity rule
    $self->logger->debug( "Impersonation identities rule -> "
          . $self->conf->{impersonationIdRule} );
    $rule =
      $hd->buildSub( $hd->substitute( $self->conf->{impersonationIdRule} ) );
    unless ($rule) {
        $self->error(
            "Bad impersonation identities rule -> " . $hd->tsv->{jail}->error );
        return 0;
    }
    $self->idRule($rule);

    return 1;
}

# RUNNING METHOD

sub run {
    my ( $self, $req ) = @_;
    my $spoofId = $req->param('spoofId') || $req->{user};
    $self->logger->debug("No impersonation required")
      if ( $spoofId eq $req->{user} );
    my $statut = PE_OK;

    if ( $spoofId !~ /$self->{conf}->{userControl}/o ) {
        $self->userLogger->error('Malformed spoofed Id');
        $self->logger->debug("Impersonation tried with spoofed Id: $spoofId");
        $spoofId = $req->{user};
        $statut  = PE_MALFORMEDUSER;
    }

    # Check activation rule
    if ( $spoofId ne $req->{user} ) {
        $self->logger->debug("Spoofied Id: $spoofId / Real Id: $req->{user}");
        unless ( $self->rule->( $req, $req->sessionInfo ) ) {
            $self->userLogger->error('Impersonation service not authorized');
            $spoofId = $req->{user};
            $statut  = PE_IMPERSONATION_SERVICE_NOT_ALLOWED;
        }
    }

    # Fill spoof session
    my ( $realSession, $spoofSession ) = ( {}, {} );
    $self->logger->debug("Rename real attributes...");
    my $spk = '';
    foreach my $k ( keys %{ $req->{sessionInfo} } ) {
        if ( $self->{conf}->{impersonationSkipEmptyValues} ) {
            next unless defined $req->{sessionInfo}->{$k};
        }
        $spk = "$self->{conf}->{impersonationPrefix}$k";
        unless ( $self->hAttr =~ /\b$k\b/ ) {
            $realSession->{$spk} = $req->{sessionInfo}->{$k};
            $self->logger->debug("-> Store $k in realSession key: $spk");
        }
        $self->logger->debug("Delete $k");
        delete $req->{sessionInfo}->{$k};
    }

    $spoofSession = $self->_userDatas( $req, $spoofId, $realSession );
    if ( $req->error ) {
        if ( $req->error == PE_BADCREDENTIALS ) {
            $statut = PE_BADCREDENTIALS;
        }
        else {
            return $req->error;
        }
    }

    # Update spoofed session
    $self->logger->debug("Populating spoofed session...");
    foreach (qw (_auth _userDB)) {
        $self->logger->debug("Processing $_...");
        $spk = "$self->{conf}->{impersonationPrefix}$_";
        $spoofSession->{$_} = $realSession->{$spk};
    }

    # Merging SSO Groups and hGroups & dedup
    $spoofSession->{groups} ||= '';
    if ( $self->{conf}->{impersonationMergeSSOgroups} ) {
        $self->userLogger->warn("MERGING SSO groups and hGroups...");
        my $spg       = "$self->{conf}->{impersonationPrefix}groups";
        my $sphg      = "$self->{conf}->{impersonationPrefix}hGroups";
        my $separator = $self->{conf}->{multiValuesSeparator};
        $realSession->{$spg} ||= '';

        $self->logger->debug("Processing groups...");
        my @spoofGrps = my @realGrps = ();
        @spoofGrps = split /\Q$separator/, $spoofSession->{groups};
        @realGrps  = split /\Q$separator/, $realSession->{$spg};
        @spoofGrps = ( @spoofGrps, @realGrps );
        my %hash = map { $_, 1 } @spoofGrps;
        $spoofSession->{groups} = join $separator, sort keys %hash;

        $self->logger->debug("Processing hGroups...");
        $spoofSession->{hGroups} ||= {};
        $realSession->{$sphg} ||= {};
        $spoofSession->{hGroups} =
          { %{ $spoofSession->{hGroups} }, %{ $realSession->{$sphg} } };
    }

    # Main session
    $self->p->updateSession( $req, $spoofSession );
    $req->steps( [ $self->p->validSession, @{ $self->p->endAuth } ] );

    # Restore _httpSession for double Cookies
    if ( $self->conf->{securedCookie} >= 2 ) {
        $self->p->updateSession( $req, $spoofSession,
            $req->{sessionInfo}->{real__httpSession} );
        $req->{sessionInfo}->{_httpSession} =
          $req->{sessionInfo}->{real__httpSession};
    }
    return $statut;
}

sub _userDatas {
    my ( $self, $req, $spoofId, $realSession ) = @_;
    my $realId = $req->{user};
    $req->{user} = $spoofId;
    my $raz = 0;

    # Compute Macros and Groups with real and spoofed sessions
    $req->{sessionInfo} = {%$realSession};

    # Search user in database
    $req->steps( [
            'getUser',   'setSessionInfo',
            'setMacros', 'setGroups',
            'setLocalGroups'
        ]
    );
    if ( my $error = $self->p->process($req) ) {
        if ( $error == PE_BADCREDENTIALS ) {
            $self->userLogger->warn(
                    'Impersonation requested for an unvalid user ('
                  . $req->{user}
                  . ")" );
        }
        $self->logger->debug("Process returned error: $error");
        $req->error($error);
        $raz = 1;
    }

    # Check identity rule if impersonation required
    if ( $realId ne $spoofId ) {
        unless ( $self->idRule->( $req, $req->sessionInfo ) ) {
            $self->userLogger->warn(
                    'Impersonation requested for an unvalid user ('
                  . $req->{user}
                  . ")" );
            $self->logger->debug('Identity not authorized');
            $raz = 1;
        }
    }

    # Same real and spoofed session - Compute Macros and Groups
    if ($raz) {
        $req->{sessionInfo} = {};
        $req->{sessionInfo} = {%$realSession};
        $req->{user}        = $realId;
        $req->steps( [
                'getUser',   'setSessionInfo',
                'setMacros', 'setGroups',
                'setLocalGroups'
            ]
        );
        $self->logger->debug('Spoofed session equal real session');
        $req->error(PE_BADCREDENTIALS);
        if ( my $error = $self->p->process($req) ) {
            $self->logger->debug("Process returned error: $error");
            $req->error($error);
        }
    }

    return $req->{sessionInfo};
}

1;
