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
use Crypt::OpenSSL::RSA;
use Convert::PEM;
use Digest::MD5 qw(md5_base64);

use URI::URL;
use Net::SSLeay;

extends qw(
  Lemonldap::NG::Manager::Plugin
  Lemonldap::NG::Common::Conf::RESTServer
);

our $VERSION = '2.0.14';

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => 'manager.html';

sub init {
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

    my ( $private, $cert ) = $self->_generateX509( $query->{password} );
    my $keys = {
        'private' => $private,
        'public'  => $cert,
        'hash'    => md5_base64($cert),
    };
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
    my $rsa = Crypt::OpenSSL::RSA->generate_key(2048);

    my $query = $req->jsonBodyToObj;
    my $keys  = {
        'private' => $rsa->get_private_key_string(),
        'public'  => $rsa->get_public_key_x509_string(),
        'hash'    => md5_base64( $rsa->get_public_key_string() ),
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

# This function does the dirty X509 work,
# mostly copied from IO::Socket::SSL::Utils
# and adapter to work on old platforms (CentOS7)

sub _generateX509 {
    my ( $self, $password ) = @_;
    Net::SSLeay::SSLeay_add_ssl_algorithms();
    my $conf = $self->confAcc->getConf();

    # Generate 2048 bits RSA key
    my $key = Net::SSLeay::EVP_PKEY_new();
    Net::SSLeay::EVP_PKEY_assign_RSA( $key,
        Net::SSLeay::RSA_generate_key( 2048, 0x10001 ) );

    my $cert = Net::SSLeay::X509_new();

    # Serial
    Net::SSLeay::ASN1_INTEGER_set(
        Net::SSLeay::X509_get_serialNumber($cert),
        rand( 2**32 ),
    );

    # Version
    Net::SSLeay::X509_set_version( $cert, 2 );

    # Make it last 20 years
    Net::SSLeay::ASN1_TIME_set( Net::SSLeay::X509_get_notBefore($cert),
        time() );
    Net::SSLeay::ASN1_TIME_set( Net::SSLeay::X509_get_notAfter($cert),
        time() + 20 * 365 * 86400 );

    # set subject
    my $portal_uri  = new URI::URL( $conf->{portal} || "http://localhost" );
    my $portal_host = $portal_uri->host;
    my $subj_e      = Net::SSLeay::X509_get_subject_name($cert);
    my $subj        = { commonName => $portal_host, };

    while ( my ( $k, $v ) = each %$subj ) {

        # Not everything we get is nice - try with MBSTRING_UTF8 first and if it
        # fails try V_ASN1_T61STRING and finally V_ASN1_OCTET_STRING
        Net::SSLeay::X509_NAME_add_entry_by_txt( $subj_e, $k, 0x1000, $v, -1,
            0 )
          or
          Net::SSLeay::X509_NAME_add_entry_by_txt( $subj_e, $k, 20, $v, -1, 0 )
          or
          Net::SSLeay::X509_NAME_add_entry_by_txt( $subj_e, $k, 4, $v, -1, 0 )
          or croak( "failed to add entry for $k - "
              . Net::SSLeay::ERR_error_string( Net::SSLeay::ERR_get_error() ) );
    }

    # Set to self-sign
    Net::SSLeay::X509_set_pubkey( $cert, $key );
    Net::SSLeay::X509_set_issuer_name( $cert,
        Net::SSLeay::X509_get_subject_name($cert) );

    # Sign with default alg
    Net::SSLeay::X509_sign( $cert, $key, 0 );

    my $strCert = Net::SSLeay::PEM_get_string_X509($cert);
    my $strPrivate;
    if ($password) {
        my $alg = Net::SSLeay::EVP_get_cipherbyname("AES-256-CBC")
          || Net::SSLeay::EVP_get_cipherbyname("DES-EDE3-CBC");
        $strPrivate =
          Net::SSLeay::PEM_get_string_PrivateKey( $key, $password, $alg );
    }
    else {
        $strPrivate = Net::SSLeay::PEM_get_string_PrivateKey($key);
    }

    # Free OpenSSL objects
    Net::SSLeay::X509_free($cert);
    Net::SSLeay::EVP_PKEY_free($key);

    return ( $strPrivate, $strCert );
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
        $res->{details}->{'__needConfirmation__'} = $parser->{needConfirmation}
          if ( @{ $parser->{needConfirmation} } && !$req->params('force') );
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
        my $s = CONFIG_WAS_CHANGED;
        $s = $self->confAcc->saveConf( $parser->newConf, %args )
          unless ( @{ $parser->{needConfirmation} } && !$args{force} );
        if ( $s > 0 ) {
            $self->userLogger->notice(
                'User ' . $self->p->userId($req) . " has stored conf $s" );
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
                  . $self->p->userId($req) );
            $res->{result} = 0;
            if ( $s == CONFIG_WAS_CHANGED ) {
                $res->{needConfirm} = 1;
                $res->{message} .= '__needConfirmation__'
                  unless @{ $parser->{needConfirmation} };
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

    my $res = {};

    # When uploading a new conf, always force it since cfgNum has a few
    # chances to be equal to last config cfgNum
    my $s = $self->confAcc->saveConf( $new, force => 1 );
    if ( $s > 0 ) {
        $self->userLogger->notice(
            'User ' . $self->p->userId($req) . " has stored (raw) conf $s" );
        $res->{result} = 1;
        $res->{cfgNum} = $s;
    }
    else {
        $self->userLogger->notice(
            'Raw saving attempt rejected, asking for confirmation to '
              . $self->p->userId($req) );
        $res->{result}      = 0;
        $res->{needConfirm} = 1 if ( $s == CONFIG_WAS_CHANGED );
        $res->{message} .= '__needConfirmation__';
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
