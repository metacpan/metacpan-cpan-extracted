# This module implements all the methods that responds to '/confs/*' requests
# It contains 2 sections:
#  - initialization methods
#  - upload method
#
# Read methods are inherited from Lemonldap::NG::Common::Conf::RESTServer
package Lemonldap::NG::Manager::Conf;

use 5.10.0;
use utf8;
use Mouse;
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::UserAgent;
use Crypt::OpenSSL::RSA;
use Convert::PEM;
use URI::URL;

use feature 'state';

extends 'Lemonldap::NG::Common::Conf::RESTServer';

our $VERSION = '2.0.0';

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => 'manager.html';

has ua => ( is => 'rw' );

sub addRoutes {
    my ( $self, $conf ) = @_;
    $self->ua( Lemonldap::NG::Common::UserAgent->new($conf) );

    # HTML template
    $self->addRoute( 'manager.html', undef, ['GET'] )

      # READ
      # Special keys
      ->addRoute(
        confs => {
            ':cfgNum' => [
                qw(virtualHosts samlIDPMetaDataNodes samlSPMetaDataNodes
                  applicationList oidcOPMetaDataNodes oidcRPMetaDataNodes
                  casSrvMetaDataNodes casAppMetaDataNodes
                  authChoiceModules grantSessionRules combModules
                  openIdIDPList)
            ]
        },
        ['GET']
      )

      # Other keys
      ->addRoute( confs => { ':cfgNum' => { '*' => 'getKey' } }, ['GET'] )

      # New key and conf save
      ->addRoute(
        confs =>
          { newRSAKey => 'newRSAKey', raw => 'newRawConf', '*' => 'newConf' },
        ['POST']
      )

      # Difference between confs
      ->addRoute( diff => { ':conf1' => { ':conf2' => 'diff' } } )
      ->addRoute( 'diff.html', undef, ['GET'] )

      # Url loader
      ->addRoute( 'prx', undef, ['POST'] );
}

# 35 - New RSA key pair on demand
#      --------------------------

##@method public PSGI-JSON-response newRSAKey($req)
# Return a hashref containing private and public keys
# The posted data must contain a JSON object containing
# {"password":"newpassword"}
#
#@param $req Lemonldap::NG::Common::PSGI::Request object
#@return PSGI JSON response
sub newRSAKey {
    my ( $self, $req, @others ) = @_;
    return $self->sendError( $req, 'There is no subkey for "newRSAKey"', 400 )
      if (@others);
    my $query = $req->jsonBodyToObj;
    my $rsa   = Crypt::OpenSSL::RSA->generate_key(2048);
    my $keys  = {
        'private' => $rsa->get_private_key_string(),
        'public'  => $rsa->get_public_key_x509_string(),
    };
    if ( $query->{password} ) {
        my $pem = Convert::PEM->new(
            Name => 'RSA PRIVATE KEY',
            ASN  => q(
                RSAPrivateKey SEQUENCE {
                    version INTEGER,
                    n INTEGER,
                    e INTEGER,
                    d INTEGER,
                    p INTEGER,
                    q INTEGER,
                    dp INTEGER,
                    dq INTEGER,
                    iqmp INTEGER
    }
               )
        );
        $keys->{private} = $pem->encode(
            Content  => $pem->decode( Content => $keys->{private} ),
            Password => $query->{password},
        );
    }
    return $self->sendJSONresponse( $req, $keys );
}

# 36 - URL File loader
#      ---------------

##@method public PSGI-JSON-response prx()
# Load file using posted URL and return its content
#
#@return PSGI JSON response
sub prx {
    my ( $self, $req, @others ) = @_;
    return $self->sendError( $req, 'There is no subkey for "prx"', 400 )
      if (@others);
    my $query = $req->jsonBodyToObj;
    return $self->sendError( $req, 'Missing parameter', 400 )
      unless ( $query->{url} );
    return $self->sendError( $req, 'Bad parameter', 400 )
      unless ( $query->{url} =~ m#^(?:f|ht)tps?://\w# );
    $self->ua->timeout(10);

    my $response = $self->ua->get( $query->{url} );
    unless ( $response->code == 200 ) {
        return $self->sendError( $req,
            $response->code . " (" . $response->message . ")", 400 );
    }
    unless ( $response->header('Content-Type') =~
        m#^(?:application/json|(?:application|text)/.*xml).*$# )
    {
        return $self->sendError( $req,
            'Content refused for security reason (neither XML or JSON)', 400 );
    }
    return $self->sendJSONresponse( $req, { content => $response->content } );
}

######################
# IV. Upload methods #
######################

# In this section, 4 methods:
#  - getConfByNum: override SUPER method to be able to use Zero
#  - newConf()
#  - newRawConf(): restore a saved conf
#  - applyConf(): called by the 2 previous to prevent other servers that a new
#                 configuration is available

sub getConfByNum {
    my ( $self, $cfgNum, @args ) = @_;
    unless ( %{ $self->currentConf }
        and $cfgNum == $self->currentConf->{cfgNum} )
    {
        my $tmp;
        if ( $cfgNum == 0 ) {
            require Lemonldap::NG::Manager::Conf::Zero;
            $tmp = Lemonldap::NG::Manager::Conf::Zero::zeroConf();
            $self->currentConf($tmp);
        }
        else {
            $tmp = $self->SUPER::getConfByNum( $cfgNum, @args );
            return undef unless ( defined $tmp );
        }
    }
    return $cfgNum;
}

## @method PSGI-JSON-response newConf($req)
# Call Lemonldap::NG::Manager::Conf::Parser to parse new configuration and store
# it
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@return PSGI JSON response
sub newConf {
    my ( $self, $req, @other ) = @_;
    return $self->sendError( $req, 'There is no subkey for "newConf"', 400 )
      if (@other);

    # Body must be json
    my $new = $req->jsonBodyToObj;
    unless ( defined($new) ) {
        return $self->sendError( $req, undef, 400 );
    }

    # Verify that cfgNum has been asked
    unless ( defined $req->params('cfgNum') ) {
        return $self->sendError( $req, "Missing configuration number", 400 );
    }

    # Set current conf to cfgNum
    unless ( defined $self->getConfByNum( $req->params('cfgNum') ) ) {
        return $self->sendError(
            $req,
            "Configuration "
              . $req->params('cfgNum')
              . " not available "
              . $Lemonldap::NG::Common::Conf::msg,
            400
        );
    }

    # Parse new conf
    require Lemonldap::NG::Manager::Conf::Parser;
    my $parser = Lemonldap::NG::Manager::Conf::Parser->new(
        { tree => $new, refConf => $self->currentConf, req => $req } );

    # If ref conf isn't last conf, consider conf changed
    my $cfgNum = $self->confAcc->lastCfg;
    unless ( defined $cfgNum ) {
        $req->error($Lemonldap::NG::Common::Conf::msg);
    }
    return $self->sendError( $req, undef, 400 ) if ( $req->error );

    if ( $cfgNum ne $req->params('cfgNum') ) { $parser->confChanged(1); }

    my $res = { result => $parser->check };

    # "message" fields: note that words enclosed by "__" (__word__) will be
    # translated
    $res->{message} = $parser->{message};
    foreach my $t (qw(errors warnings changes)) {
        $res->{details}->{ '__' . $t . '__' } = $parser->$t
          if ( @{ $parser->$t } );
    }
    if ( $res->{result} ) {
        if ( $self->{demoMode} ) {
            $res->{message} = '__demoModeOn__';
        }
        else {
            my %args;
            $args{force} = 1 if ( $req->params('force') );
            my $s = $self->confAcc->saveConf( $parser->newConf, %args );
            if ( $s > 0 ) {
                $self->userLogger->notice(
                    'User ' . $self->userId($req) . " has stored conf $s" );
                $res->{result} = 1;
                $res->{cfgNum} = $s;
                if ( my $status = $self->applyConf( $parser->newConf ) ) {
                    push @{ $res->{details}->{__applyResult__} },
                      { message => "$_: $status->{$_}" }
                      foreach ( keys %$status );
                }
            }
            else {
                $self->userLogger->notice(
                    'Saving attempt rejected, asking for confirmation to '
                      . $self->userId($req) );
                $res->{result} = 0;
                if ( $s == CONFIG_WAS_CHANGED ) {
                    $res->{needConfirm} = 1;
                    $res->{message} .= '__needConfirmation__';
                }
                else {
                    $res->{message} = $Lemonldap::NG::Common::Conf::msg;
                }
            }
        }
    }
    return $self->sendJSONresponse( $req, $res );
}

## @method PSGI-JSON-response newRawConf($req)
# Store directly raw configuration
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@return PSGI JSON response
sub newRawConf {
    my ( $self, $req, @other ) = @_;
    return $self->sendError( $req, 'There is no subkey for "newConf"', 400 )
      if (@other);

    # Body must be json
    my $new = $req->jsonBodyToObj;
    unless ( defined($new) ) {
        return $self->sendError( $req, undef, 400 );
    }

    my $res = {};
    if ( $self->{demoMode} ) {
        $res->{message} = '__demoModeOn__';
    }
    else {
        # When uploading a new conf, always force it since cfgNum has a few
        # chances to be equal to last config cfgNum
        my $s = $self->confAcc->saveConf( $new, force => 1 );
        if ( $s > 0 ) {
            $self->userLogger->notice(
                'User ' . $self->userId($req) . " has stored (raw) conf $s" );
            $res->{result} = 1;
            $res->{cfgNum} = $s;
        }
        else {
            $self->userLogger->notice(
                'Raw saving attempt rejected, asking for confirmation to '
                  . $self->userId($req) );
            $res->{result} = 0;
            $res->{needConfirm} = 1 if ( $s == CONFIG_WAS_CHANGED );
            $res->{message} .= '__needConfirmation__';
        }
    }
    return $self->sendJSONresponse( $req, $res );
}

## @method private applyConf()
# Try to prevent other servers declared in `reloadUrls` that a new
# configuration is available.
#
#@return reload status as boolean
sub applyConf {
    my ( $self, $newConf ) = @_;
    my $status;

    # 1 Apply conf locally
    $self->api->checkConf();

    # Get apply section values
    my %reloadUrls =
      %{ $self->confAcc->getLocalConf( APPLYSECTION, undef, 0 ) };
    if ( !%reloadUrls && $newConf->{reloadUrls} ) {
        %reloadUrls = %{ $newConf->{reloadUrls} };
    }
    return {} unless (%reloadUrls);

    $self->ua->timeout( $newConf->{reloadTimeout} );

    # Parse apply values
    while ( my ( $host, $request ) = each %reloadUrls ) {
        my $r = HTTP::Request->new( 'GET', "http://$host$request" );
        if ( $request =~ /^https?:\/\/[^\/]+.*$/ ) {
            my $url       = URI::URL->new($request);
            my $targetUrl = $url->scheme . "://" . $host;
            $targetUrl .= ":" . $url->port if defined( $url->port );
            $targetUrl .= $url->full_path;
            $r =
              HTTP::Request->new( 'GET', $targetUrl,
                HTTP::Headers->new( Host => $url->host ) );
            if ( defined $url->userinfo && $url->userinfo =~ /^([^:]+):(.*)$/ )
            {
                $r->authorization_basic( $1, $2 );
            }
        }

        my $response = $self->ua->request($r);
        if ( $response->code != 200 ) {
            $status->{$host} =
              "Error " . $response->code . " (" . $response->message . ")";
            $self->logger->error( "Apply configuration for $host: error "
                  . $response->code . " ("
                  . $response->message
                  . ")" );
        }
        else {
            $status->{$host} = "OK";
            $self->logger->notice("Apply configuration for $host: ok");
        }
    }

    return $status;
}

sub diff {
    my ( $self, $req, @path ) = @_;
    return $self->sendError( $req, 'to many arguments in path info', 400 )
      if (@path);
    my @cfgNum =
      ( scalar( $req->param('conf1') ), scalar( $req->param('conf2') ) );
    my @conf;
    $self->logger->debug(" Loading confs");

    # Load the 2 configurations
    for ( my $i = 0 ; $i < 2 ; $i++ ) {
        if ( %{ $self->currentConf }
            and $cfgNum[$i] == $self->currentConf->{cfgNum} )
        {
            $conf[$i] = $self->currentConf;
        }
        else {
            $conf[$i] = $self->confAcc->getConf(
                { cfgNum => $cfgNum[$i], raw => 1, noCache => 1 } );
            return $self->sendError(
                $req,
"Configuration $cfgNum[$i] not available $Lemonldap::NG::Common::Conf::msg",
                400
            ) unless ( $conf[$i] );
        }
    }
    require Lemonldap::NG::Manager::Conf::Diff;
    return $self->sendJSONresponse(
        $req,
        [
            $self->Lemonldap::NG::Manager::Conf::Diff::diff(
                $conf[0], $conf[1]
            )
        ]
    );
}

1;
