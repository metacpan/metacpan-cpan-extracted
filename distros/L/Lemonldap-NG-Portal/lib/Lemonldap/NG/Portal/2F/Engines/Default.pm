# Default 2FA engine
#
# 2FA engine provides 3 functions and 1 interface:
#  - init()
#  - run($req): called during auth process after session populating
#  - display2fRegisters($req, $session): indicates if a 2F registration is
#                                        available for this user
#  - /2fregisters: the URL path that displays 2F registration menu

package Lemonldap::NG::Portal::2F::Engines::Default;

use strict;
use Mouse;
use JSON qw(from_json to_json);
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_ERROR
  PE_NOTOKEN
  PE_OK
  PE_SENDRESPONSE
  PE_TOKENEXPIRED
);

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

# INITIALIZATION

has sfModules => ( is => 'rw', default => sub { [] } );

has sfRModules => ( is => 'rw', default => sub { [] } );

has sfReq => ( is => 'rw' );

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->{conf}->{formTimeout} );
        return $ott;
    }
);

sub init {
    my ($self) = @_;

    # Load 2F modules
    for my $i ( 0 .. 1 ) {
        foreach (
            split /,\s*/,
            $self->conf->{
                $i
                ? 'available2FSelfRegistration'
                : 'available2F'
            }
          )
        {
            my $prefix = lc($_);
            $prefix =~ s/2f$//i;

            # Activation parameter
            my $ap = $prefix . ( $i ? '2fSelfRegistration' : '2fActivation' );
            $self->logger->debug("Checking $ap");

            # Unless $rule, skip loading
            if ( $self->conf->{$ap} ) {
                $self->logger->debug("Trying to load $_ 2F");
                my $m =
                  $self->p->loadPlugin( $i ? "::2F::Register::$_" : "::2F::$_" )
                  or return 0;

                # Rule and prefix may be modified by 2F module, reread them
                my $rule = $self->conf->{$ap};
                $prefix = $m->prefix;

                # Compile rule
                $rule = $self->p->HANDLER->substitute($rule);
                unless ( $rule = $self->p->HANDLER->buildSub($rule) ) {
                    $self->error( 'External 2F rule error: '
                          . $self->p->HANDLER->tsv->{jail}->error );
                    return 0;
                }

                # Store module
                push @{ $self->{ $i ? 'sfRModules' : 'sfModules' } },
                  { p => $prefix, m => $m, r => $rule };
            }
            else {
                $self->logger->debug(' -> not enabled');
            }
        }
    }

    unless (
        $self->sfReq(
            $self->p->HANDLER->buildSub(
                $self->p->HANDLER->substitute( $self->conf->{sfRequired} )
            )
        )
      )
    {
        $self->error( 'Error in sfRequired rule'
              . $self->p->HANDLER->tsv->{jail}->error );
        return 0;
    }

    # Enable REST request only if more than 1 2F module is enabled
    if ( @{ $self->{sfModules} } > 1 ) {
        $self->addUnauthRoute( '2fchoice' => '_choice',   ['POST'] );
        $self->addUnauthRoute( '2fchoice' => '_redirect', ['GET'] );
    }

    # Enable 2F registration URL only if at least 1 registration module
    # is enabled
    if ( @{ $self->{sfRModules} } ) {

        # Registration base
        $self->addAuthRoute( '2fregisters' => '_displayRegister', ['GET'] );
        $self->addAuthRoute( '2fregisters' => 'register',         ['POST'] );
        if ( $self->conf->{sfRequired} ) {
            $self->addUnauthRoute(
                '2fregisters' => 'restoreSession',
                [ 'GET', 'POST' ]
            );
        }
    }

    return 1;
}

# RUNNING METHODS

# public PE_CODE run($req)
#
# run() is called at each authentication, just after sessionInfo populated
sub run {
    my ( $self, $req ) = @_;

    my $checkLogins = $req->param('checkLogins');
    $self->logger->debug("2F checkLogins set") if ($checkLogins);

    # Skip 2F unless a module has been registered
    return PE_OK unless ( @{ $self->sfModules } );

    # Search for authorized modules for this user
    my @am;
    foreach my $m ( @{ $self->sfModules } ) {
        $self->logger->debug(
            'Looking if ' . $m->{m}->prefix . '2F is available' );
        if ( $m->{r}->( $req, $req->sessionInfo ) ) {
            $self->logger->debug(' -> OK');
            push @am, $m->{m};
        }
    }

    # If no 2F module is authorized, skipping 2F
    # Note that a rule may forbid access after (GrantSession plugin)
    unless (@am) {

        # Except if 2FA is required, move to registration
        if ( $self->sfReq->( $req, $req->sessionInfo ) ) {
            $self->logger->debug("2F is required...");
            $self->logger->debug(" -> Register 2F");
            $req->pdata->{sfRegToken} =
              $self->ott->createToken( $req->sessionInfo );
            $self->logger->debug("Just one 2F is enabled");
            $self->logger->debug(" -> Redirect to /2fregisters/");
            $req->response(
                [
                    302,
                    [ Location => $self->conf->{portal} . '/2fregisters/' ], []
                ]
            );
            return PE_SENDRESPONSE;
        }
        else {
            return PE_OK;
        }
    }

    $self->userLogger->info( 'Second factor required for '
          . $req->sessionInfo->{ $self->conf->{whatToTrace} } );

    # Store user data in a token
    $req->sessionInfo->{_2fRealSession} = $req->id;
    $req->sessionInfo->{_2fUrldc}       = $req->urldc;
    $req->sessionInfo->{_2fUtime}       = $req->{sessionInfo}->{_utime};
    my $token = $self->ott->createToken( $req->sessionInfo );
    delete $req->{authResult};

    # If only one 2F is authorized, display it
    unless ($#am) {
        my $res = $am[0]->run( $req, $token );
        $req->authResult($res);
        return $res;
    }

    # More than 1 2F has been found, display choice
    $self->logger->debug("Prepare 2F choice");
    my $tpl = $self->p->sendHtml(
        $req,
        '2fchoice',
        params => {
            MAIN_LOGO => $self->conf->{portalMainLogo},
            SKIN      => $self->conf->{portalSkin},
            TOKEN     => $token,
            MODULES => [ map { { CODE => $_->prefix, LOGO => $_->logo } } @am ],
            CHECKLOGINS => $checkLogins
        }
    );
    $req->response($tpl);
    return PE_SENDRESPONSE;
}

# bool public display2fRegisters($req, $session)
#
# Return true if at least 1 register module is available for this user. Used
# by Menu to display or not /2fregisters page
sub display2fRegisters {
    my ( $self, $req, $session ) = @_;
    foreach my $m ( @{ $self->sfRModules } ) {
        return 1 if ( $m->{r}->( $req, $session ) );
    }
    return 0;
}

sub _choice {
    my ( $self, $req ) = @_;
    my $token;

    # Restore session
    unless ( $token = $req->param('token') ) {
        $self->userLogger->error( $self->prefix . ' 2F access without token' );
        $req->mustRedirect(1);
        return $self->p->do( $req, [ sub { PE_NOTOKEN } ] );
    }

    my $session;
    unless ( $session = $self->ott->getToken($token) ) {
        $self->userLogger->info('Token expired');
        return $self->p->do( $req, [ sub { PE_TOKENEXPIRED } ] );
    }

    $req->sessionInfo($session);

    # New token
    $token = $self->ott->createToken($session);

    my $ch = $req->param('sf');
    foreach my $m ( @{ $self->sfModules } ) {
        if ( $m->{m}->prefix eq $ch ) {
            my $res = $m->{m}->run( $req, $token );
            $req->authResult($res);
            return $self->p->do(
                $req,
                [
                    sub { $res }, 'controlUrl',
                    'buildCookie', @{ $self->p->endAuth },
                ]
            );
        }
    }
    $self->userLogger->error('Bad 2F choice');
    return $self->p->lmError( $req, 500 );
}

sub _redirect {
    my ( $self, $req ) = @_;
    my $arg = $req->env->{QUERY_STRING};
    $self->logger->debug('Call sfEngine _redirect method');
    return [
        302,
        [
            Location => $self->conf->{portal} . ( $arg ? "?$arg" : '' )
        ],
        []
    ];
}

sub _displayRegister {
    my ( $self, $req, $tpl ) = @_;

    # After verifying rule:
    #  - display template if $tpl
    #  - else display choice template
    if ($tpl) {
        my ($m) =
          grep { $_->{m}->prefix eq $tpl } @{ $self->sfRModules };
        unless ($m) {
            return $self->p->sendError( $req,
                'Inexistent register module', 400 );
        }
        unless ( $m->{r}->( $req, $req->userData ) ) {
            return $self->p->sendError( $req,
                'Registration not authorized', 403 );
        }
        return $self->p->sendHtml( $req, $m->{m}->template,
            params => { MAIN_LOGO => $self->conf->{portalMainLogo} } );
    }

    # If only one 2F is available, redirect to it
    my @am;
    foreach my $m ( @{ $self->sfRModules } ) {
        $self->logger->debug(
            'Looking if ' . $m->{m}->prefix . '2F register is available' );
        if ( $m->{r}->( $req, $req->userData ) ) {
            push @am,
              {
                CODE => $m->{m}->prefix,
                URL  => '/2fregisters/' . $m->{m}->prefix,
                LOGO => $m->{m}->logo,
              };
        }
    }
    if (
        @am == 1
        and not( $req->userData->{_2fDevices}
            or $req->data->{sfRegRequired} )
      )
    {
        return [ 302, [ Location => $self->conf->{portal} . $am[0]->{URL} ],
            [] ];
    }

    my $_2fDevices =
      $req->userData->{_2fDevices}
      ? eval { from_json( $req->userData->{_2fDevices},
            { allow_nonref => 1 } ); }
      : undef;

    unless ($_2fDevices) {
        $self->logger->debug("No 2F Device found");
        $_2fDevices = [];
    }

    return $self->p->sendHtml(
        $req,
        '2fregisters',
        params => {
            MAIN_LOGO    => $self->conf->{portalMainLogo},
            SKIN         => $self->conf->{portalSkin},
            MODULES      => \@am,
            SFDEVICES    => $_2fDevices,
            REG_REQUIRED => $req->data->{sfRegRequired},
        }
    );
}

# Check rule and display
sub register {
    my ( $self, $req, $tpl, @args ) = @_;

    # After verifying rule:
    #   - call register run method if $tpl
    #   - else give JSON list of available registers for this user
    if ($tpl) {
        my ($m) =
          grep { $_->{m}->prefix eq $tpl } @{ $self->sfRModules };
        unless ($m) {
            return $self->p->sendError( $req,
                'Inexistent register module', 400 );
        }
        unless ( $m->{r}->( $req, $req->userData ) ) {
            $self->userLogger->error("$tpl 2F registration refused");
            return $self->p->sendError( $req, 'Registration refused', 403 );
        }
        return $m->{m}->run( $req, @args );
    }
    my @am;
    foreach my $m ( @{ $self->sfRModules } ) {
        $self->logger->debug(
            'Looking if ' . $m->{m}->prefix . '2F register is available' );
        if ( $m->{r}->( $req, $req->userData ) ) {
            $self->logger->debug(' -> OK');
            my $name = $m->{m}->prefix;
            push @am,
              {
                name => $name,
                logo => $m->{m}->logo,
                url  => "/2fregisters/$name"
              };
        }
    }
    return $self->p->sendJSONresponse( $req, \@am );
}

sub restoreSession {
    my ( $self, $req, @path ) = @_;
    my $token = $req->pdata->{sfRegToken}
      or return [ 302, [ Location => $self->conf->{portal} ], [] ];
    $req->userData( $self->ott->getToken( $token, 1 ) );
    $req->data->{sfRegRequired} = 1;
    return $req->method eq 'POST'
      ? $self->register( $req, @path )
      : $self->_displayRegister( $req, @path );
}

1;
