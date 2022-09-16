package Lemonldap::NG::Portal::Plugins::CheckDevOps;

use strict;
use Mouse;
use JSON qw(from_json);
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Portal::Main::Constants qw(
  URIRE
  PE_OK
  PE_BADURL
  PE_NOTOKEN
  PE_TOKENEXPIRED
  PE_FILENOTFOUND
  PE_BAD_DEVOPS_FILE
  PE_REGISTERFORMEMPTY
);

our $VERSION = '2.0.15';

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
    $self->addAuthRoute( checkdevops => 'parse', ['POST'] )
      ->addAuthRouteWithRedirect( checkdevops => 'display', ['GET'] );

    unless ( $self->conf->{useSafeJail} ) {
        $self->logger->warn('"CheckDevOps" plugin enabled WITHOUT SafeJail');
        return 0;
    }

    return 1;
}

# RUNNING METHOD

sub display {
    my ( $self, $req ) = @_;

    # Display form
    my $params = {
        DOWNLOAD => $self->conf->{checkDevOpsDownload},
        MSG      => 'checkDevOps',
        ALERTE   => 'alert-info',
        TOKEN    => (
              $self->ottRule->( $req, {} )
            ? $self->ott->createToken()
            : ''
        )
    };
    return $self->sendJSONresponse( $req, $params ) if $req->wantJSON;

    # Display form
    return $self->p->sendHtml( $req, 'checkdevops', params => $params, );
}

sub parse {
    my ( $self,    $req ) = @_;
    my ( $headers, $rules, $unknown ) = ( [], [], [] );
    my ( $msg,     $json,  $url, $bad_json );
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
            DOWNLOAD => $self->conf->{checkDevOpsDownload},
            MSG      => "PE$msg",
            ALERTE   => 'alert-warning',
            TOKEN    => $token
        };
        return $self->p->sendJSONresponse( $req, $params )
          if ( $req->wantJSON && $msg );

        # Display form
        return $self->p->sendHtml( $req, 'checkdevops', params => $params )
          if $msg;
    }

    $msg = 'PE' . PE_REGISTERFORMEMPTY
      unless ( $req->param('url') || $req->param('checkDevOpsFile') );

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
        } if $req->param('checkDevOpsFile');
        if ( $@ || !$json->{rules} ) {

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

        # Removed hidden session attributes
        foreach my $v ( split /[,\s]+/, $self->conf->{hiddenAttributes} ) {
            foreach ( keys %{ $json->{headers} } ) {
                if ( $json->{headers}->{$_} =~ /\$$v/ ) {
                    delete $json->{headers}->{$_};
                    my $user = $req->userData->{ $self->conf->{whatToTrace} };
                    $self->userLogger->warn(
"CheckDevOps: $user tried to retrieve hidden attribute '$v'"
                    );
                }
            }
        }

        # Parse rules
        my $cpt = new Safe;
        $cpt->share_from( 'MIME::Base64', ['&encode_base64'] );
        $cpt->share_from(
            'Lemonldap::NG::Handler::Main::Jail',
            [
                '&encrypt', '&token',
                @Lemonldap::NG::Handler::Main::Jail::builtCustomFunctions
            ]
        );
        $cpt->share_from( 'Lemonldap::NG::Common::Safelib',
            $Lemonldap::NG::Common::Safelib::functions );

        foreach ( keys %{ $json->{rules} } ) {
            $cpt->reval("BEGIN { 'warnings'->unimport; } $json->{rules}->{$_}");
            my $err = join(
                '',
                grep(
                    { $_ =~
/(?:Undefined subroutine|Devel::StackTrace|trapped by operation mask)/
                          ? ()
                          : $_; }
                    split( /\n/, $@, 0 ) )
            );
            if ($err) {
                $self->userLogger->error(
                    "Bad rule: $json->{rules}->{$_} ($err)");
                $bad_json = 1;
            }
        }

        # Compile headers
        $handler->headersInit( undef, { $vhost => $json->{headers} } );
        $headers = $handler->checkHeaders( $req, $req->userData );

        # Check attributes if required
        if ( $self->conf->{checkDevOpsCheckSessionAttributes} ) {
            $unknown  = $self->_checkSessionAttrs($json);
            $bad_json = 1 if scalar @$unknown;
        }

        if ( $handler->tsv->{maintenance}->{$vhost} || $bad_json ) {

            # Prepare form params
            undef $json;
            $headers = [];
            $alert   = 'alert-danger';
            $msg     = 'PE' . PE_BAD_DEVOPS_FILE;
            $self->userLogger->error("CheckDevOps: bad 'rules.json' file");
            $handler->tsv->{maintenance}->{$vhost} = 0;
        }
        else {

            # Normalize headers name if required
            if ( $self->conf->{checkDevOpsDisplayNormalizedHeaders} ) {
                $self->logger->debug("Normalize headers...");
                @$headers = map {
                    ;    # Prevent compilation error with old Perl versions
                    no strict 'refs';
                    {
                        key   => &{ $handler . '::cgiName' }( $_->{key} ),
                        value => $_->{value}
                    }
                } @$headers;
            }

            my $headers_list = join ', ', map "$_->{key}:$_->{value}",
              @$headers;
            $self->logger->debug("CheckDevOps compiled headers: $headers_list");

            # Compile rules
            @$rules = map {
                my ( $sub, $flag ) =
                  $handler->conditionSub( $json->{rules}->{$_} );
                {
                    uri    => $_,
                    access => $sub->( $req, $req->userData )
                    ? 'allowed'
                    : 'forbidden'
                }
            } sort keys %{ $json->{rules} };
            my $rules_list = join ', ', map "$_->{uri}:$_->{access}", @$rules;
            $self->logger->debug("CheckDevOps compiled rules: $rules_list");

            # Prepare form params
            $msg   = 'checkDevOps';
            $alert = 'alert-info';
            foreach ( keys %$json ) {
                delete $json->{$_} unless $_ =~ /\b(?:rules|headers)\b/;
                delete $json->{$_} unless keys %{ $json->{$_} };
            }
            $json = JSON->new->ascii->pretty->encode($json);    # Pretty print
        }
    }

    # Prepare form
    my $params = {
        DOWNLOAD => $self->conf->{checkDevOpsDownload},
        MSG      => $msg,
        UNKNOWN  => join( $self->conf->{multiValuesSeparator}, @$unknown ),
        ALERTE   => $alert,
        FILE     => $json,
        HEADERS  => $headers,
        RULES    => $rules,
        URL      => $url,
        TOKEN    => (
              $self->ottRule->( $req, {} )
            ? $self->ott->createToken()
            : ''
        )
    };
    return $self->p->sendJSONresponse( $req, $params ) if $req->wantJSON;

    # Display form
    return $self->p->sendHtml( $req, 'checkdevops', params => $params );
}

sub _checkSessionAttrs {
    my ( $self, $json ) = @_;
    my $unknown;
    my %sessionAttrs = map { $_ => 1 } (
        keys %{ $self->conf->{ldapExportedVars} },
        keys %{ $self->conf->{exportedVars} },
        keys %{ $self->conf->{macros} }
    );
    $sessionAttrs{groups} = 1 if $self->conf->{groups};
    $self->logger->debug(
        "Existing session attributes: "
          . join $self->conf->{multiValuesSeparator},
        keys %sessionAttrs
    );

    my @varh = map { ( $json->{headers}->{$_} =~ /\$(\w+)\b/g ) }
      keys %{ $json->{headers} };
    my @varr = map { ( $json->{rules}->{$_} =~ /\$(\w+)\b/g ) }
      keys %{ $json->{rules} };
    my %usedAttrs = map { $_ => 1 } ( @varh, @varr );
    $self->logger->debug(
        "Used attributs: " . join $self->conf->{multiValuesSeparator},
        keys %usedAttrs );

    @$unknown = map { $sessionAttrs{$_} ? () : $_ } sort keys %usedAttrs;
    $self->logger->debug(
        "Unknown attributes: " . join $self->conf->{multiValuesSeparator},
        @$unknown )
      if scalar @$unknown;

    return $unknown;
}

1;
