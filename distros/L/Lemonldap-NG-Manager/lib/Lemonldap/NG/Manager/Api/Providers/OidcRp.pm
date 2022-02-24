package Lemonldap::NG::Manager::Api::Providers::OidcRp;

our $VERSION = '2.0.12';

package Lemonldap::NG::Manager::Api;

use strict;
use utf8;
use Mouse;
use Lemonldap::NG::Manager::Conf::Parser;

extends 'Lemonldap::NG::Manager::Api::Common';

sub getOidcRpByConfKey {
    my ( $self, $req ) = @_;

    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    $self->logger->debug("[API] OIDC RP $confKey configuration requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf;

    my $oidcRp = $self->_getOidcRpByConfKey( $conf, $confKey );

    # Return 404 if not found
    return $self->sendError( $req,
        "OIDC relying party '$confKey' not found", 404 )
      unless ( defined $oidcRp );

    return $self->sendJSONresponse( $req, $oidcRp );
}

sub findOidcRpByConfKey {
    my ( $self, $req ) = @_;

    my $pattern = (
        defined $req->params('uPattern')
        ? $req->params('uPattern')
        : ( defined $req->params('pattern') ? $req->params('pattern') : undef )
    );

    return $self->sendError( $req, 'Invalid input: pattern is missing', 400 )
      unless ( defined $pattern );

    unless ( $pattern = $self->_getRegexpFromPattern($pattern) ) {
        return $self->sendError( $req, 'Invalid input: pattern is invalid',
            400 );
    }

    $self->logger->debug(
        "[API] Find OIDC RPs by confKey regexp $pattern requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf;

    my @oidcRps =
      map { $_ =~ $pattern ? $self->_getOidcRpByConfKey( $conf, $_ ) : () }
      keys %{ $conf->{oidcRPMetaDataOptions} };

    return $self->sendJSONresponse( $req, [@oidcRps] );
}

sub findOidcRpByClientId {
    my ( $self, $req ) = @_;

    my $clientId = (
        defined $req->params('uClientId') ? $req->params('uClientId')
        : (
            defined $req->params('clientId') ? $req->params('clientId')
            : undef
        )
    );

    return $self->sendError( $req, 'Invalid input: clientId is missing', 400 )
      unless ( defined $clientId );

    $self->logger->debug("[API] Find OIDC RPs by clientId $clientId requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf;

    my $oidcRp = $self->_getOidcRpByClientId( $conf, $clientId );
    return $self->sendError( $req,
        "OIDC relying party with clientId '$clientId' not found", 404 )
      unless ( defined $oidcRp );

    return $self->sendJSONresponse( $req, $oidcRp );
}

sub addOidcRp {
    my ( $self, $req ) = @_;
    my $add = $req->jsonBodyToObj;

    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ($add);

    return $self->sendError( $req, 'Invalid input: confKey is missing', 400 )
      unless ( defined $add->{confKey} );

    return $self->sendError( $req, 'Invalid input: confKey is not a string',
        400 )
      if ( ref $add->{confKey} );

    return $self->sendError( $req, 'Invalid input: confKey is empty', 400 )
      unless ( $add->{confKey} );

    return $self->sendError( $req, 'Invalid input: clientId is missing', 400 )
      unless ( defined $add->{clientId} );

    return $self->sendError( $req, 'Invalid input: clientId is not a string',
        400 )
      if ( ref $add->{clientId} );

    return $self->sendError( $req, 'Invalid input: redirectUris is missing',
        400 )
      unless ( defined $add->{redirectUris} );

    return $self->sendError( $req,
        'Invalid input: redirectUris must be an array', 400 )
      unless ( ref( $add->{redirectUris} ) eq "ARRAY" );

    $self->logger->debug(
"[API] Add OIDC RP with confKey $add->{confKey} and clientId $add->{clientId} requested"
    );

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    return $self->sendError(
        $req,
        "Invalid input: An OIDC RP with confKey $add->{confKey} already exists",
        409
    ) if ( defined $self->_getOidcRpByConfKey( $conf, $add->{confKey} ) );

    return $self->sendError(
        $req,
"Invalid input: An OIDC RP with clientId $add->{clientId} already exists",
        409
    ) if ( defined $self->_getOidcRpByClientId( $conf, $add->{clientId} ) );

    $add->{options}                 = {} unless ( defined $add->{options} );
    $add->{options}->{clientId}     = $add->{clientId};
    $add->{options}->{redirectUris} = $add->{redirectUris};

    my $res = $self->_pushOidcRp( $conf, $add->{confKey}, $add, 1 );

    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse(
        $req,
        { message => "Successful operation" },
        code => 201
    );
}

sub updateOidcRp {
    my ( $self, $req ) = @_;
    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    my $update = $req->jsonBodyToObj;

    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ($update);

    if ( $update->{redirectUris} ) {
        if ( ref( $update->{redirectUris} ) eq "ARRAY" ) {
            $update->{options}->{redirectUris} = $update->{redirectUris};
        }
        else {
            return $self->sendError( $req,
                'Invalid input: redirectUris must be an array', 400 );
        }
    }

    $self->logger->debug(
        "[API] OIDC RP $confKey configuration update requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    my $current = $self->_getOidcRpByConfKey( $conf, $confKey );

    # Return 404 if not found

    return $self->sendError( $req,
        "OIDC relying party '$confKey' not found", 404 )
      unless ( defined $current );

    # check if new clientID exists already
    my $res = $self->_isNewOidcRpClientIdUnique( $conf, $confKey, $update );

    return $self->sendError( $req, $res->{msg}, 409 )
      unless ( $res->{res} eq 'ok' );

    $res = $self->_pushOidcRp( $conf, $confKey, $update, 0 );

    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub replaceOidcRp {
    my ( $self, $req ) = @_;
    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    my $replace = $req->jsonBodyToObj;

    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ($replace);

    return $self->sendError( $req, 'Invalid input: clientId is missing', 400 )
      unless ( defined $replace->{clientId} );

    return $self->sendError( $req, 'Invalid input: clientId is not a string',
        400 )
      if ( ref $replace->{clientId} );

    return $self->sendError( $req, 'Invalid input: redirectUris is missing',
        400 )
      unless ( defined $replace->{redirectUris} );

    return $self->sendError( $req,
        'Invalid input: redirectUris must be an array', 400 )
      unless ( ref( $replace->{redirectUris} ) eq "ARRAY" );

    $self->logger->debug(
        "[API] OIDC RP $confKey configuration replace requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    # Return 404 if not found

    return $self->sendError( $req,
        "OIDC relying party '$confKey' not found", 404 )
      unless ( defined $self->_getOidcRpByConfKey( $conf, $confKey ) );

    # check if new clientID exists already
    my $res = $self->_isNewOidcRpClientIdUnique( $conf, $confKey, $replace );
    return $self->sendError( $req, $res->{msg}, 409 )
      unless ( $res->{res} eq 'ok' );

    $replace->{options}             = {} unless ( defined $replace->{options} );
    $replace->{options}->{clientId} = $replace->{clientId};
    $replace->{options}->{redirectUris} = $replace->{redirectUris};

    $res = $self->_pushOidcRp( $conf, $confKey, $replace, 1 );
    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub deleteOidcRp {
    my ( $self, $req ) = @_;
    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    my $delete = $self->_getOidcRpByConfKey( $conf, $confKey );

    # Return 404 if not found

    return $self->sendError( $req,
        "OIDC relying party '$confKey' not found", 404 )
      unless ( defined $delete );

    delete $conf->{oidcRPMetaDataOptions}->{$confKey};
    delete $conf->{oidcRPMetaDataExportedVars}->{$confKey};
    delete $conf->{oidcRPMetaDataOptionsExtraClaims}->{$confKey};
    delete $conf->{oidcRPMetaDataMacros}->{$confKey};
    delete $conf->{oidcRPMetaDataScopeRules}->{$confKey};

    # Save configuration
    $self->_saveApplyConf($conf);

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub _getOidcRpByConfKey {
    my ( $self, $conf, $confKey ) = @_;

    # Check if confKey is defined
    return undef unless ( defined $conf->{oidcRPMetaDataOptions}->{$confKey} );

    # Get Client ID
    my $clientId = $conf->{oidcRPMetaDataOptions}->{$confKey}
      ->{oidcRPMetaDataOptionsClientID};

    # Get exported vars
    my $exportedVars = $conf->{oidcRPMetaDataExportedVars}->{$confKey};

    # Get extra claim
    my $extraClaims = $conf->{oidcRPMetaDataOptionsExtraClaims}->{$confKey};

    # Get macros
    my $macros = $conf->{oidcRPMetaDataMacros}->{$confKey} || {};

    # Get scope rules
    my $scopeRules = $conf->{oidcRPMetaDataScopeRules}->{$confKey} || {};

    # Redirect URIs, filled later
    my $redirectUris = $self->_translateValueConfToApi(
        'oidcRPMetaDataOptionsRedirectUris',
        $conf->{oidcRPMetaDataOptions}->{$confKey}
          ->{oidcRPMetaDataOptionsRedirectUris}
    );

    # Get options
    my $options = {};
    for
      my $configOption ( keys %{ $conf->{oidcRPMetaDataOptions}->{$confKey} } )
    {
        my $apiName  = $self->_translateOptionConfToApi($configOption);
        my $apiValue = $self->_translateValueConfToApi( $configOption,
            $conf->{oidcRPMetaDataOptions}->{$confKey}->{$configOption} );
        $options->{$apiName} = $apiValue;
    }

    return {
        confKey      => $confKey,
        clientId     => $clientId,
        redirectUris => $redirectUris,
        exportedVars => $exportedVars,
        extraClaims  => $extraClaims,
        macros       => $macros,
        scopeRules   => $scopeRules,
        options      => $options
    };
}

sub _getOidcRpByClientId {
    my ( $self, $conf, $clientId ) = @_;

    foreach ( keys %{ $conf->{oidcRPMetaDataOptions} } ) {
        return $self->_getOidcRpByConfKey( $conf, $_ )
          if ( $conf->{oidcRPMetaDataOptions}->{$_}
            ->{oidcRPMetaDataOptionsClientID} eq $clientId );
    }

    return undef;
}

sub _isNewOidcRpClientIdUnique {
    my ( $self, $conf, $confKey, $oidcRp ) = @_;
    my $curClientId = $self->_getOidcRpByConfKey( $conf, $confKey )->{clientId};
    my $newClientId =
         $oidcRp->{clientId}
      || $oidcRp->{options}->{clientId}
      || "";
    if ( $newClientId ne '' && $newClientId ne $curClientId ) {
        return {
            res => 'ko',
            msg =>
"An OIDC relying party with clientId '$newClientId' already exists"
          }
          if ( defined $self->_getOidcRpByClientId( $conf, $newClientId ) );
    }

    return { res => 'ok' };
}

sub _pushOidcRp {
    my ( $self, $conf, $confKey, $push, $replace ) = @_;

    my $translatedOptions = {};
    if ($replace) {
        $conf->{oidcRPMetaDataOptions}->{$confKey}            = {};
        $conf->{oidcRPMetaDataExportedVars}->{$confKey}       = {};
        $conf->{oidcRPMetaDataOptionsExtraClaims}->{$confKey} = {};
        $conf->{oidcRPMetaDataMacros}->{$confKey}             = {};
        $translatedOptions = $self->_getDefaultValues('oidcRPMetaDataNode');
    }

    if ( defined $push->{options} ) {

        foreach ( keys %{ $push->{options} } ) {

            my $optionName = $self->_translateOptionApiToConf( $_, 'oidcRP' );
            eval {
                my $optionValue =
                  $self->_translateValueApiToConf( $_, $push->{options}->{$_} );
                $translatedOptions->{$optionName} = $optionValue;
            };
            if ($@) {
                return {
                    res => 'ko',
                    msg => "Invalid input: $@",
                };
            }
        }

        my $res = $self->_hasAllowedAttributes( $translatedOptions,
            'oidcRPMetaDataNode' );
        return $res unless ( $res->{res} eq 'ok' );

        foreach ( keys %{$translatedOptions} ) {
            $conf->{oidcRPMetaDataOptions}->{$confKey}->{$_} =
              $translatedOptions->{$_};
        }

    }

    $conf->{oidcRPMetaDataOptions}->{$confKey}->{oidcRPMetaDataOptionsClientID}
      = $push->{clientId}
      if ( defined $push->{clientId} );

    if ( defined $push->{exportedVars} ) {
        if ( $self->_isSimpleKeyValueHash( $push->{exportedVars} ) ) {
            foreach ( keys %{ $push->{exportedVars} } ) {
                $conf->{oidcRPMetaDataExportedVars}->{$confKey}->{$_} =
                  $push->{exportedVars}->{$_};
            }
        }
        else {
            return {
                res => 'ko',
                msg =>
"Invalid input: exportedVars is not a hash object with \"key\":\"value\" attributes"
            };
        }
    }

    if ( defined $push->{macros} ) {
        if ( $self->_isSimpleKeyValueHash( $push->{macros} ) ) {
            foreach ( keys %{ $push->{macros} } ) {
                $conf->{oidcRPMetaDataMacros}->{$confKey}->{$_} =
                  $push->{macros}->{$_};
            }
        }
        else {
            return {
                res => 'ko',
                msg => "Invalid input: macros is not a hash object"
                  . " with \"key\":\"value\" attributes"
            };
        }
    }

    if ( defined $push->{scopeRules} ) {
        if ( $self->_isSimpleKeyValueHash( $push->{scopeRules} ) ) {
            foreach ( keys %{ $push->{scopeRules} } ) {
                $conf->{oidcRPMetaDataScopeRules}->{$confKey}->{$_} =
                  $push->{scopeRules}->{$_};
            }
        }
        else {
            return {
                res => 'ko',
                msg => "Invalid input: scopeRules is not a hash object"
                  . " with \"key\":\"value\" attributes"
            };
        }
    }

    if ( defined $push->{extraClaims} ) {
        if ( $self->_isSimpleKeyValueHash( $push->{extraClaims} ) ) {
            foreach ( keys %{ $push->{extraClaims} } ) {
                $conf->{oidcRPMetaDataOptionsExtraClaims}->{$confKey}->{$_} =
                  $push->{extraClaims}->{$_};
            }
        }
        else {
            return {
                res => 'ko',
                msg => "Invalid input: extraClaims is not a hash object"
                  . " with \"key\":\"value\" attributes"
            };
        }
    }

    # Test new configuration
    my $parser = Lemonldap::NG::Manager::Conf::Parser->new( {
            refConf => $self->_confAcc->getConf,
            newConf => $conf,
            req     => {},
        }
    );
    unless ( $parser->testNewConf( $self->p ) ) {
        return {
            res  => 'ko',
            code => 400,
            msg  => "Configuration error: "
              . join( ". ", map { $_->{message} } @{ $parser->errors } ),
        };
    }

    # Save configuration
    $self->_saveApplyConf($conf);

    return { res => 'ok' };
}

1;
