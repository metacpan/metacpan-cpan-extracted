package Lemonldap::NG::Portal::Plugins::CheckDevOps;

use strict;
use Mouse;
use JSON qw(from_json);
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Portal::Main::Constants qw(
  URIRE
  PE_OK
  PE_ERROR
  PE_BADURL
  PE_NOTOKEN
  PE_TOKENEXPIRED
  PE_FILENOTFOUND
  PE_BAD_DEVOPS_FILE
);

our $VERSION = '2.0.12';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Lib::_tokenRule
);

# INITIALIZATION

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

has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
        $ua->env_proxy();
        return $ua;
    }
);

sub init {
    my ($self) = @_;
    $self->addAuthRoute( checkdevops => 'run', ['POST'] )
      ->addAuthRouteWithRedirect( checkdevops => 'display', ['GET'] );

    return 1;
}

# RUNNING METHOD

sub display {
    my ( $self, $req ) = @_;

    # Display form
    my $params = {
        PORTAL    => $self->conf->{portal},
        MAIN_LOGO => $self->conf->{portalMainLogo},
        SKIN      => $self->p->getSkin($req),
        LANGS     => $self->conf->{showLanguages},
        DOWNLOAD  => $self->conf->{checkDevOpsDownload},
        MSG       => 'checkDevOps',
        ALERTE    => 'alert-info',
        TOKEN     => (
              $self->ottRule->( $req, {} )
            ? $self->ott->createToken()
            : ''
        )
    };
    return $self->sendJSONresponse( $req, $params ) if $req->wantJSON;

    # Display form
    return $self->p->sendHtml( $req, 'checkdevops', params => $params, );
}

sub run {
    my ( $self,    $req )   = @_;
    my ( $headers, $rules ) = ( [], [] );
    my ( $msg, $json, $url );
    my $alert = 'alert-danger';

    # Check token
    if ( $self->ottRule->( $req, {} ) ) {
        my $token;
        $msg = PE_OK;
        if ( $token = $req->param('token') ) {
            unless ( $self->ott->getToken($token) ) {
                $self->userLogger->warn(
                    'CheckDevOps called with an expired/bad token');
                $msg   = PE_TOKENEXPIRED;
                $token = $self->ott->createToken();
            }
        }
        else {
            $self->userLogger->warn('CheckDevOps called without token');
            $msg   = PE_NOTOKEN;
            $token = $self->ott->createToken();
        }

        # Prepare form
        my $params = {
            PORTAL    => $self->conf->{portal},
            MAIN_LOGO => $self->conf->{portalMainLogo},
            SKIN      => $self->p->getSkin($req),
            LANGS     => $self->conf->{showLanguages},
            DOWNLOAD  => $self->conf->{checkDevOpsDownload},
            MSG       => "PE$msg",
            ALERTE    => 'alert-warning',
            TOKEN     => $token,
        };
        return $self->p->sendJSONresponse( $req, $params )
          if $req->wantJSON && $msg;

        # Display form
        return $self->p->sendHtml( $req, 'checkdevops', params => $params )
          if $msg;
    }

    # Check URL if allowed and exists
    if ( $self->conf->{checkDevOpsDownload} and $url = $req->param('url') ) {
        undef $url if $self->p->checkXSSAttack( 'CheckDevOps URL', $url );
        if ( $url && $url =~ URIRE ) {

            # Reformat url
            my ( $proto, $vhost, $appuri ) = ( $2, $3, $5 );
            $url = "$proto://$vhost/rules.json";
            my $resp = $self->ua->get( $url, 'Accept' => 'application/json' );
            $self->logger->debug( "Code/Message from $url: "
                  . $resp->code . '/'
                  . $resp->message );
            my $content = $resp->decoded_content;
            $self->logger->debug("Content received from $url: $content")
              if $content;

            if ( $resp->is_success ) {
                $json = eval { from_json( $content, { allow_nonref => 1 } ) };
                if ($@) {

                    # Prepare form params
                    undef $json;
                    $msg = 'PE' . PE_BAD_DEVOPS_FILE;
                    $self->userLogger->error(
"CheckDevOps: bad 'rules.json' file retrieved from $url ($@)"
                    );
                }
            }
            else {

                # Prepare form params
                $msg = 'PE' . PE_FILENOTFOUND;
                $self->userLogger->error(
"CheckDevOps: Unable to download 'rules.json' file from $url"
                );
            }
        }
        else {

            # Prepare form params
            $msg = 'PE' . PE_BADURL;
            $self->userLogger->error('CheckDevOps: bad URL provided');
        }
    }
    unless ( $json || $msg ) {
        $json = eval {
            from_json( $req->param('checkDevOpsFile'), { allow_nonref => 1 } );
        };
        if ($@) {

            # Prepare form params
            undef $json;
            $msg   = 'PE' . PE_BAD_DEVOPS_FILE;
            $alert = 'alert-danger';
            $self->userLogger->error(
                "CheckDevOps: bad provided 'rules.json' file ($@)");
        }
    }

    # Parse JSON
    if ($json) {
        my $handler = $self->p->HANDLER;
        my $vhost   = $handler->resolveAlias($req);

        # Removed forbidden session attributes
        foreach my $v ( split /\s+/, $self->conf->{hiddenAttributes} ) {
            foreach ( keys %{ $json->{headers} } ) {
                if ( $json->{headers}->{$_} eq '$' . $v ) {
                    delete $json->{headers}->{$_};
                    my $user = $req->userData->{ $self->conf->{whatToTrace} };
                    $self->userLogger->warn(
"CheckDevOps: $user tried to retrieve hidden attribute '$v'"
                    );
                }
            }
        }

        # Compile headers
        $handler->headersInit( undef, { $vhost => $json->{headers} } );
        $headers = $handler->checkHeaders( $req, $req->userData );
        my $headers_list = join ', ', map { "$_->{key}:$_->{value}" } @$headers;
        $self->logger->debug("CheckDevOps compiled headers: $headers_list");

        # Compile rules
        @$rules = map {
            my ( $sub, $flag ) = $handler->conditionSub( $json->{rules}->{$_} );
            {
                uri    => $_,
                access => $sub->( $req, $req->userData )
                ? 'allowed'
                : 'forbidden'
            }
        } sort keys %{ $json->{rules} };
        my $rules_list = join ', ', map { "$_->{uri}:$_->{access}" } @$rules;
        $self->logger->debug("CheckDevOps compiled rules: $rules_list");

        # Prepare form params
        $msg   = 'checkDevOps';
        $alert = 'alert-info';
        $json  = JSON->new->ascii->pretty->encode($json);    # Pretty print
    }

    # Prepare form
    my $params = {
        PORTAL    => $self->conf->{portal},
        MAIN_LOGO => $self->conf->{portalMainLogo},
        SKIN      => $self->p->getSkin($req),
        LANGS     => $self->conf->{showLanguages},
        DOWNLOAD  => $self->conf->{checkDevOpsDownload},
        MSG       => $msg,
        ALERTE    => $alert,
        FILE      => $json,
        HEADERS   => $headers,
        RULES     => $rules,
        URL       => $url,
        TOKEN     => (
              $self->ottRule->( $req, {} )
            ? $self->ott->createToken()
            : ''
        )
    };
    return $self->p->sendJSONresponse( $req, $params ) if $req->wantJSON;

    # Display form
    return $self->p->sendHtml( $req, 'checkdevops', params => $params, );
}

1;
