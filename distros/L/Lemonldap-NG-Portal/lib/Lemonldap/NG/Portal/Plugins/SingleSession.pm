package Lemonldap::NG::Portal::Plugins::SingleSession;

use strict;
use Mouse;
use MIME::Base64;
use JSON qw(from_json to_json);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_NOTOKEN
  PE_TOKENEXPIRED
);

our $VERSION = '2.0.12';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::OtherSessions
);

use constant endAuth => 'run';

has singleIPRule       => ( is => 'rw' );
has singleSessionRule  => ( is => 'rw' );
has singleUserByIPRule => ( is => 'rw' );
has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->conf->{formTimeout} );
        return $ott;
    }
);

sub init {
    my ($self) = @_;
    $self->addAuthRoute( removeOther => 'removeOther', ['GET'] );

    # Build triggering rules from configuration
    $self->singleIPRule(
        $self->p->buildRule( $self->conf->{singleIP}, 'singleIP' ) );
    return 0 unless $self->singleIPRule;

    $self->singleSessionRule(
        $self->p->buildRule( $self->conf->{singleSession}, 'singleSession' ) );
    return 0 unless $self->singleSessionRule;

    $self->singleUserByIPRule(
        $self->p->buildRule( $self->conf->{singleUserByIP}, 'singleUserByIP' )
    );
    return 0 unless $self->singleUserByIPRule;

    return 1;
}

sub run {
    my ( $self, $req ) = @_;
    my ( $linkedSessionId, $token, $html ) = ( '', '', '' );
    my $deleted         = [];
    my $otherSessions   = [];
    my @otherSessionsId = ();

    my $moduleOptions = $self->conf->{globalStorageOptions} || {};
    $moduleOptions->{backend} = $self->conf->{globalStorage};

    my $singleSessionRuleMatched =
      $self->singleSessionRule->( $req, $req->sessionInfo );
    my $singleIPRuleMatched = $self->singleIPRule->( $req, $req->sessionInfo );
    my $singleUserByIPRuleMatched =
      $self->singleUserByIPRule->( $req, $req->sessionInfo );

    if (   $singleSessionRuleMatched
        or $singleIPRuleMatched
        or $self->conf->{notifyOther} )
    {
        my $sessions = $self->module->searchOn(
            $moduleOptions,
            $self->conf->{whatToTrace},
            $req->{sessionInfo}->{ $self->conf->{whatToTrace} }
        );

        if ( $self->conf->{securedCookie} == 2 ) {
            $self->logger->debug("Looking for double sessions...");
            $linkedSessionId = $sessions->{ $req->id }->{_httpSession};
            my $msg =
              $linkedSessionId
              ? "Linked session found -> $linkedSessionId / " . $req->id
              : "NO linked session found!";
            $self->logger->debug($msg);
        }

        foreach my $id ( keys %$sessions ) {
            next if ( $req->id eq $id );
            next if ( $linkedSessionId and $id eq $linkedSessionId );
            my $session = $self->p->getApacheSession($id) or next;
            if (
                $self->singleSessionRule->( $req, $req->sessionInfo )
                or (    $self->singleIPRule->( $req, $req->sessionInfo )
                    and $req->{sessionInfo}->{ipAddr} ne
                    $session->data->{ipAddr} )
              )
            {
                push @$deleted, $self->p->_sumUpSession( $session->data );
                $self->p->_deleteSession( $req, $session, 1 );
            }
            else {
                push @$otherSessions, $self->p->_sumUpSession( $session->data );
                push @otherSessionsId, $id;
            }
        }
    }

    $token = $self->ott->createToken( {
            user     => $req->{sessionInfo}->{ $self->conf->{whatToTrace} },
            sessions => to_json( \@otherSessionsId )
        }
    ) if @otherSessionsId;

    if ($singleUserByIPRuleMatched) {
        my $sessions =
          $self->module->searchOn( $moduleOptions, 'ipAddr',
            $req->sessionInfo->{ipAddr} );
        foreach my $id ( keys %$sessions ) {
            next if ( $req->id eq $id );
            my $session = $self->p->getApacheSession($id) or next;
            unless ( $req->{sessionInfo}->{ $self->conf->{whatToTrace} } eq
                $session->data->{ $self->conf->{whatToTrace} } )
            {
                push @$deleted, $self->p->_sumUpSession( $session->data );
                $self->p->_deleteSession( $req, $session, 1 );
            }
        }
    }

    $html = $self->p->mkSessionArray( $req, $deleted, 'sessionsDeleted', 1 )
      if ( $self->conf->{notifyDeleted} and @$deleted );
    $html .=
        $self->p->mkSessionArray( $req, $otherSessions, 'otherSessions', 1 )
      . $self->_mkRemoveOtherLink( $req, $token )
      if ( $self->conf->{notifyOther} and @$otherSessions );

    $req->info($html);
    return PE_OK;
}

sub removeOther {
    my ( $self, $req ) = @_;
    my $res   = PE_OK;
    my $count = 0;
    $req->{urldc} = decode_base64( $req->param('url') );

    if ( my $token = $req->param('token') ) {
        if ( $token = $self->ott->getToken($token) ) {

            # Read sessions from token
            my $sessions = eval { from_json( $token->{sessions} ) };
            if ($@) {
                $self->logger->error("Bad encoding in OTT: $@");
                $res = PE_ERROR;
            }
            my $as;
            foreach (@$sessions) {
                unless ( $as = $self->p->getApacheSession($_) ) {
                    $self->userLogger->info(
                        "SingleSession: session $_ expired");
                    next;
                }
                my $user = $token->{user};
                if ( $req->{userData}->{ $self->{conf}->{whatToTrace} } eq
                    $user )
                {
                    $self->userLogger->info("Remove \"$user\" session: $_");
                    $self->p->_deleteSession( $req, $as, 1 );
                    $count++;
                }
                else {
                    $self->userLogger->warn(
                        "SingleSession called with an invalid token");
                    $res = PE_TOKENEXPIRED;
                }
            }
        }
        else {
            $self->userLogger->error(
                "SingleSession called with an expired token");
            $res = PE_TOKENEXPIRED;
        }
    }
    else {
        $self->userLogger->error('SingleSession called without token');
        $res = PE_NOTOKEN;
    }

    return $self->p->do( $req, [ sub { $res } ] ) if $res;
    $self->userLogger->info("$count remaining session(s) removed");
    $req->mustRedirect(1);
    return $self->p->autoRedirect($req);
}

# Build the removeOther link
# Last part of URL is built trough javascript
# @return removeOther link in HTML code
sub _mkRemoveOtherLink {
    my ( $self, $req, $token ) = @_;

    return $self->loadTemplate(
        $req,
        'removeOther',
        params => {
            link => $self->conf->{portal} . "removeOther?token=$token"
        }
    );
}

1;
