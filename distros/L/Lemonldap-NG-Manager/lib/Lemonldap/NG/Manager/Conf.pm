# This module implements all the methods that responds to '/confs/*' requests
# It contains 2 sections:
#  - initialization methods
#  - upload method
#
# Read methods are inherited from Lemonldap::NG::Common::Conf::RESTServer
package Lemonldap::NG::Manager::Conf;

use strict;
use utf8;
use Mouse;
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Common::EmailTransport;
use Lemonldap::NG::Common::Util::Crypto;
use URI::URL;

extends qw(
  Lemonldap::NG::Manager::Plugin
  Lemonldap::NG::Common::Conf::RESTServer
);

our $VERSION = '2.19.0';

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => 'manager.html';
use constant icon         => 'cog';

has defaultNewKeySize => ( is => 'rw', default => 2048, );

sub init {
    my ( $self, $conf ) = @_;

    $self->defaultNewKeySize( $conf->{defaultNewKeySize} )
      if $conf->{defaultNewKeySize};

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
                  authChoiceModules grantSessionRules combModules sfExtra
                  openIdIDPList)
            ]
        },
        ['GET']
      )

      # Other keys
      ->addRoute( confs => { ':cfgNum' => { '*' => 'getKey' } }, ['GET'] )

      # New key and conf save
      ->addRoute(
        confs => {
            newRSAKey      => 'newRSAKey',
            newCertificate => 'newCertificate',
            newEcKeys      => 'newEcKeys',
            sendTestMail   => 'sendTestMail',
            raw            => 'newRawConf',
            '*'            => 'newConf'
        },
        ['POST']
      )

      # Difference between confs
      ->addRoute( diff => { ':conf1' => { ':conf2' => 'diff' } } )
      ->addRoute( 'diff.html', undef, ['GET'] )

      # Url loader
      ->addRoute( 'prx', undef, ['POST'] );
    return 1;
}

# 35 - New Certificate on demand
#      --------------------------

##@method public PSGI-JSON-response newRSAKey($req)
# Return a hashref containing private and public keys
# The posted data must contain a JSON object containing
# {"password":"newpassword"}
#
#@param $req Lemonldap::NG::Common::PSGI::Request object
#@return PSGI JSON response
sub newCertificate {
    my ( $self, $req, @others ) = @_;
    return $self->sendError( $req, 'There is no subkey for "newCertificate"',
        400 )
      if (@others);
    my $query = $req->jsonBodyToObj;

    my $keys = $self->_generateX509( $query->{password} );
    return $self->sendJSONresponse( $req, $keys );
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

    my $key_size = $self->defaultNewKeySize;
    my $query = $req->jsonBodyToObj;
    my $password = $query->{password};

    my $keys = Lemonldap::NG::Common::Util::Crypto::genRsaKey($key_size, $password);

    return $self->sendJSONresponse( $req, $keys );
}

# 35 - New EC key pair on demand
#      --------------------------

##@method public PSGI-JSON-response newEcKeys($req)
# Return a hashref containing private and public keys
#
#@param $req Lemonldap::NG::Common::PSGI::Request object
#@return PSGI JSON response
sub newEcKeys {
    my ( $self, $req, @others ) = @_;

    my $keys = Lemonldap::NG::Common::Util::Crypto::genEcKey('secp256r1');
    return $self->sendJSONresponse( $req, $keys );
}

# This function does the dirty X509 work,
# mostly copied from IO::Socket::SSL::Utils
# and adapter to work on old platforms (CentOS7)

sub _generateX509 {
    my ( $self, $password ) = @_;
    my $conf = $self->confAcc->getConf();
    my $key_size = $self->defaultNewKeySize;
    my $portal_uri  = new URI::URL( $conf->{portal} || "http://localhost" );
    my $portal_host = $portal_uri->host;

    return Lemonldap::NG::Common::Util::Crypto::genCertKey($key_size, $password, $portal_host);
}

#      Sending a test Email
#      --------------------

##@method public PSGI-JSON-response sendTestMail($req)
# Sends a test email to the provided address
# The posted data must contain a JSON object containing
# {"dest":"target@example.com"}
#
#@param $req Lemonldap::NG::Common::PSGI::Request object
#@return PSGI JSON response
sub sendTestMail {
    my ( $self, $req, @others ) = @_;
    return $self->sendError( $req, 'There is no subkey for "sendTestMail"',
        400 )
      if (@others);
    my $dest = $req->jsonBodyToObj->{dest};
    unless ($dest) {
        $self->logger->debug("Missing dest parameter for sending test mail");
        return $self->sendJSONresponse(
            $req,
            {
                success => \0,
                error   => "You must provide an email address"
            }
        );
    }
    my $conf = $self->confAcc->getConf();

    # Try to send test Email
    $self->logger->info("Sending test email to $dest");
    eval {
        Lemonldap::NG::Common::EmailTransport::sendTestMail( $conf, $dest );
    };
    my $error   = $@;
    my $success = ( $error ? 0 : 1 );

    $self->logger->debug("Email was sent") unless $error;
    return $self->sendJSONresponse(
        $req,
        {
            success => \$success,
            ( $error ? ( error => $error ) : () )
        }
    );
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

# In this section, 3 methods:
#  - getConfByNum: override SUPER method to be able to use Zero
#  - newConf(), load a new configuration and invokes reloadUrls
#  - newRawConf(): restore a saved conf

sub getConfByNum {
    my ( $self, $cfgNum, @args ) = @_;
    unless ($self->currentConf
        and %{ $self->currentConf }
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
    return $self->sendError( $req, undef, 400 ) unless ( defined $new );

    # Verify that cfgNum has been sent
    return $self->sendError( $req, "Missing configuration number", 400 )
      unless ( defined $req->params('cfgNum') );

    # # Verify that cfgDate has been sent
    # return $self->sendError( $req, "Missing configuration date", 400 )
    #   unless ( defined $req->params('cfgDate') );

    # Set current conf to cfgNum
    return $self->sendError(
        $req,
        "Configuration "
          . $req->params('cfgNum')
          . " not available "
          . $Lemonldap::NG::Common::Conf::msg,
        400
    ) unless ( defined $self->getConfByNum( $req->params('cfgNum') ) );

    # Parse new conf
    require Lemonldap::NG::Manager::Conf::Parser;
    my $parser = Lemonldap::NG::Manager::Conf::Parser->new(
        { tree => $new, refConf => $self->currentConf, req => $req } );

    # If ref conf isn't last conf, consider conf changed
    my $currentCfgNum = $self->confAcc->lastCfg;
    $req->error($Lemonldap::NG::Common::Conf::msg)
      unless ( defined $currentCfgNum );
    return $self->sendError( $req, undef, 400 ) if ( $req->error );
    my $currentConf =
      $self->confAcc->getConf(
        { CfgNum => $currentCfgNum, raw => 1, noCache => 1 } );
    my $currentCfgDate = $currentConf->{cfgDate};
    $self->logger->debug(
        "Current CfgNum/cfgDate: $currentCfgNum/$currentCfgDate");
    $parser->confChanged(1)
      if ( $currentCfgNum ne $req->params('cfgNum')
        || $req->params('cfgDate')
        && $req->params('cfgDate') ne $currentCfgDate );

    my $res = { result => $parser->check( $self->p ) };

    # "message" fields: note that words enclosed by "__" (__word__) will be
    # translated
    $res->{details}->{'__errors__'} = $parser->{errors}
      if ( @{ $parser->{errors} } );
    unless ( @{ $parser->{errors} } ) {
        if ( @{ $parser->{needConfirmation} } && !$req->params('force') ) {
            $res->{needConfirm} = 1;
            $res->{details}->{'__needConfirmation__'} =
              $parser->{needConfirmation};
        }
        $res->{message} = $parser->{message};
        foreach my $t (qw(warnings changes)) {
            $res->{details}->{ '__' . $t . '__' } = $parser->$t
              if ( @{ $parser->$t } );
        }
    }
    if ( $res->{result} ) {
        my %args;
        $args{force} = 1 if ( $req->params('force') );
        if ( $req->params('cfgDate') ) {
            $args{cfgDate}        = $req->params('cfgDate');
            $args{currentCfgDate} = $currentCfgDate;
        }
        my $s = UNKNOWN_ERROR;
        $s = $self->confAcc->saveConf( $parser->newConf, %args )
          unless ( @{ $parser->{needConfirmation} } && !$args{force} );
        if ( $s > 0 ) {
            $self->auditLog(
                $req,
                message => (
                    'User ' . $self->p->userId($req) . " has stored conf $s"
                ),
                code   => "CONF_STORED",
                user   => $self->p->userId($req),
                cfgNum => $s,
            );

            $res->{result} = 1;
            $res->{cfgNum} = $s;
            if ( my $status = $self->applyConf( $parser->newConf ) ) {
                push @{ $res->{details}->{__applyResult__} },
                  { message => "$_: $status->{$_}" }
                  foreach ( keys %$status );
            }
        }
        else {
            $self->auditLog(
                $req,
                message => (
                    'Saving attempt rejected, asking for confirmation to '
                      . $self->p->userId($req)
                ),
                code => "CONF_REJECTED",
                user => $self->p->userId($req),
            );

            $res->{result} = 0;
            if ( $s == CONFIG_WAS_CHANGED ) {
                $res->{needConfirm} = 1;
                $res->{details}->{'__needConfirmation__'} ||= [];
                push @{ $res->{details}->{'__needConfirmation__'} },
                  { message => '__newCfgAvailableWarning__' };
            }
            else {
                $res->{message} = $Lemonldap::NG::Common::Conf::msg;
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

    require Lemonldap::NG::Manager::Conf::Parser;
    my $parser = Lemonldap::NG::Manager::Conf::Parser->new( {
            refConf => $self->currentConf,
            newConf => $new,
            req     => $req,
        }
    );

    $parser->confChanged(1);

    my $res = { result => $parser->check( $self->p ) };

    # "message" fields: note that words enclosed by "__" (__word__) will be
    # translated
    $res->{details}->{'__errors__'} = $parser->{errors}
      if ( @{ $parser->{errors} } );
    unless ( @{ $parser->{errors} } ) {
        if ( @{ $parser->{needConfirmation} } && !$req->params('force') ) {
            $res->{needConfirm} = 1;
            $res->{details}->{'__needConfirmation__'} =
              $parser->{needConfirmation};
        }
        $res->{message} = $parser->{message};
        foreach my $t (qw(warnings changes)) {
            $res->{details}->{ '__' . $t . '__' } = $parser->$t
              if ( @{ $parser->$t } );
        }
    }
    if ( $res->{result} ) {

        # When uploading a new conf, always force it since cfgNum has a few
        # chances to be equal to last config cfgNum
        my $s = $self->confAcc->saveConf( $new, force => 1 );
        if ( $s > 0 ) {
            $self->auditLog(
                $req,
                message => (
                    'User ' . $self->p->userId($req) . " has stored (raw) conf $s"
                ),
                code   => "CONF_STORED_RAW",
                user   => $self->p->userId($req),
                cfgNum => $s,
            );
            $res->{result} = 1;
            $res->{cfgNum} = $s;
        }
        else {
            $self->auditLog(
                $req,
                message => (
                    'Raw saving attempt rejected, asking for confirmation to '
                      . $self->p->userId($req)
                ),
                code => "CONF_REJECTED_RAW",
                user => $self->p->userId($req),
            );
            $res->{result}      = 0;
            $res->{needConfirm} = 1 if ( $s == CONFIG_WAS_CHANGED );
            $res->{message} .= '__needConfirmation__';
        }
    }
    return $self->sendJSONresponse( $req, $res );
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
