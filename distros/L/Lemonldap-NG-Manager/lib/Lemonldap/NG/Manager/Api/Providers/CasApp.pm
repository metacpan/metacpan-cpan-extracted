package Lemonldap::NG::Manager::Api::Providers::CasApp;

our $VERSION = '2.0.14';

package Lemonldap::NG::Manager::Api;

use strict;
use utf8;
use Mouse;
use Lemonldap::NG::Manager::Conf::Parser;

extends 'Lemonldap::NG::Manager::Api::Common';

sub getCasAppByConfKey {
    my ( $self, $req ) = @_;

    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    $self->logger->debug("[API] CAS App $confKey configuration requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf;

    my $casApp = $self->_getCasAppByConfKey( $conf, $confKey );

    # Return 404 if not found
    return $self->sendError( $req, "CAS application '$confKey' not found", 404 )
      unless ( defined $casApp );

    return $self->sendJSONresponse( $req, $casApp );
}

sub findCasAppByConfKey {
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
        "[API] Find CAS Apps by confKey regexp $pattern requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf;

    my @casApps =
      map { $_ =~ $pattern ? $self->_getCasAppByConfKey( $conf, $_ ) : () }
      keys %{ $conf->{casAppMetaDataOptions} };

    return $self->sendJSONresponse( $req, [@casApps] );
}

sub findCasAppsByServiceUrl {
    my ( $self, $req ) = @_;

    my $serviceUrl = (
        defined $req->params('uServiceUrl') ? $req->params('uServiceUrl')
        : (
            defined $req->params('serviceUrl') ? $req->params('serviceUrl')
            : undef
        )
    );

    return $self->sendError( $req, 'Invalid input: serviceUrl is missing', 400 )
      unless ( defined $serviceUrl );

    $self->logger->debug(
        "[API] Find CAS Apps by service URL $serviceUrl requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf;

    my $casApp = $self->_getCasAppByServiceUrl( $conf, $serviceUrl );
    return $self->sendError( $req,
        "CAS application with service '$serviceUrl' not found", 404 )
      unless ( defined $casApp );

    return $self->sendJSONresponse( $req, $casApp );
}

sub addCasApp {
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

    return $self->sendError( $req, 'Invalid input: service is missing', 400 )
      unless ( defined $add->{options}->{service} );

    return $self->sendError( $req, 'Invalid input: service must be an array',
        400 )
      unless ( ref $add->{options}->{service} eq "ARRAY" );

    $self->logger->debug(
        "[API] Add CAS App with confKey $add->{confKey} requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    return $self->sendError(
        $req,
        "Invalid input: A CAS App with confKey $add->{confKey} already exists",
        409
    ) if ( defined $self->_getCasAppByConfKey( $conf, $add->{confKey} ) );

    for my $serviceUrl ( @{ $add->{options}->{service} } ) {
        my $res = $self->_getCasAppByServiceUrl( $conf, $serviceUrl );
        if ( defined $res ) {
            return $self->sendError(
                $req,
"Invalid input: A CAS application with service URL $serviceUrl already exists",
                409
            );
        }
    }

    my $res = $self->_pushCasApp( $conf, $add->{confKey}, $add, 1 );

    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse(
        $req,
        { message => "Successful operation" },
        code => 201
    );
}

sub updateCasApp {
    my ( $self, $req ) = @_;
    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    my $update = $req->jsonBodyToObj;

    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ($update);

    $self->logger->debug(
        "[API] CAS App $confKey configuration update requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    my $current = $self->_getCasAppByConfKey( $conf, $confKey );

    # Return 404 if not found

    return $self->sendError( $req, "CAS application '$confKey' not found", 404 )
      unless ( defined $current );

    # check if new clientID exists already
    my $res = $self->_isNewCasAppServiceUrlUnique( $conf, $confKey, $update );

    return $self->sendError( $req, $res->{msg}, 409 )
      unless ( $res->{res} eq 'ok' );

    $res = $self->_pushCasApp( $conf, $confKey, $update, 0 );

    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub replaceCasApp {
    my ( $self, $req ) = @_;
    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    my $replace = $req->jsonBodyToObj;

    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ($replace);

    $self->logger->debug(
        "[API] CAS App $confKey configuration replace requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    # Return 404 if not found

    return $self->sendError( $req, "CAS application '$confKey' not found", 404 )
      unless ( defined $self->_getCasAppByConfKey( $conf, $confKey ) );

    # check if new clientID exists already
    my $res = $self->_isNewCasAppServiceUrlUnique( $conf, $confKey, $replace );
    return $self->sendError( $req, $res->{msg}, 409 )
      unless ( $res->{res} eq 'ok' );

    $res = $self->_pushCasApp( $conf, $confKey, $replace, 1 );
    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub deleteCasApp {
    my ( $self, $req ) = @_;
    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    $self->logger->debug(
        "[API] CAS App $confKey configuration delete requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    my $delete = $self->_getCasAppByConfKey( $conf, $confKey );

    # Return 404 if not found

    return $self->sendError( $req, "CAS application '$confKey' not found", 404 )
      unless ( defined $delete );

    delete $conf->{casAppMetaDataOptions}->{$confKey};
    delete $conf->{casAppMetaDataExportedVars}->{$confKey};
    delete $conf->{casAppMetaDataMacros}->{$confKey};

    # Save configuration
    $self->_saveApplyConf($conf);

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub _getCasAppByConfKey {
    my ( $self, $conf, $confKey ) = @_;

    # Check if confKey is defined
    return undef unless ( defined $conf->{casAppMetaDataOptions}->{$confKey} );

    # Get exported vars
    my $exportedVars = $conf->{casAppMetaDataExportedVars}->{$confKey};

    # # Get extra claim
    # my $extraClaims = $conf->{casAppMetaDataOptionsExtraClaims}->{$confKey};

    # Get macros
    my $macros = $conf->{casAppMetaDataMacros}->{$confKey} || {};

    # Get options
    my $options = {};
    for
      my $configOption ( keys %{ $conf->{casAppMetaDataOptions}->{$confKey} } )
    {
        my $optionName  = $self->_translateOptionConfToApi($configOption);
        my $optionValue = $self->_translateValueConfToApi( $configOption,
            $conf->{casAppMetaDataOptions}->{$confKey}->{$configOption} );
        $options->{$optionName} = $optionValue;
    }

    return {
        confKey      => $confKey,
        exportedVars => $exportedVars,
        macros       => $macros,
        options      => $options
    };
}

sub _getCasAppByServiceUrl {
    my ( $self, $conf, $serviceUrl ) = @_;

    my ($serviceHost) = $serviceUrl =~ m#^(https?://[^/]+)(?:/.*)?$#;
    return undef unless $serviceHost;
    for my $confKey ( keys %{ $conf->{casAppMetaDataOptions} } ) {
        for my $url (
            split(
                /\s+/,
                $conf->{casAppMetaDataOptions}->{$confKey}
                  ->{casAppMetaDataOptionsService}
            )
          )
        {
            my ($curHost) = $url =~ m#^(https?://[^/]+)(?:/.*)?$#;
            if ( $serviceHost eq $curHost ) {
                return $self->_getCasAppByConfKey( $conf, $confKey );
            }
        }
    }

    return undef;
}

sub _isNewCasAppServiceUrlUnique {
    my ( $self, $conf, $confKey, $casApp ) = @_;
    my $curServiceUrl =
      $self->_getCasAppByConfKey( $conf, $confKey )->{options}->{service};

    # Check service paramater
    unless ( ref $casApp->{options}->{service} eq "ARRAY" ) {
        return {
            res => 'ko',
            msg => "The parameter 'service' must be an array",
        };
    }

    my $newService = $casApp->{options}->{service} || [];
    for my $newServiceUrl (@$newService) {
        if ( $newServiceUrl ne ''
            && !grep( /^$newServiceUrl$/, @$curServiceUrl ) )
        {
            return {
                res => 'ko',
                msg =>
"A CAS application with service URL '$newServiceUrl' already exists"
              }
              if (
                defined $self->_getCasAppByServiceUrl( $conf, $newServiceUrl )
              );
        }
    }

    return { res => 'ok' };
}

sub _pushCasApp {
    my ( $self, $conf, $confKey, $push, $replace ) = @_;

    my $translatedOptions = {};
    if ($replace) {
        $conf->{casAppMetaDataOptions}->{$confKey}      = {};
        $conf->{casAppMetaDataExportedVars}->{$confKey} = {};
        $conf->{casAppMetaDataMacros}->{$confKey}       = {};
        $translatedOptions = $self->_getDefaultValues('casAppMetaDataNodes');
    }

    if ( defined $push->{options} ) {

        foreach ( keys %{ $push->{options} } ) {
            my $optionName = $self->_translateOptionApiToConf( $_, 'casApp' );
            my $optionValue =
              $self->_translateValueApiToConf( $_, $push->{options}->{$_} );

            $translatedOptions->{$optionName} = $optionValue;
        }

        my $res = $self->_hasAllowedAttributes( $translatedOptions,
            'casAppMetaDataNode' );
        return $res unless ( $res->{res} eq 'ok' );

        foreach ( keys %{$translatedOptions} ) {
            $conf->{casAppMetaDataOptions}->{$confKey}->{$_} =
              $translatedOptions->{$_};
        }

    }

    if ( defined $push->{exportedVars} ) {
        if ( $self->_isSimpleKeyValueHash( $push->{exportedVars} ) ) {
            foreach ( keys %{ $push->{exportedVars} } ) {
                $conf->{casAppMetaDataExportedVars}->{$confKey}->{$_} =
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
                $conf->{casAppMetaDataMacros}->{$confKey}->{$_} =
                  $push->{macros}->{$_};
            }
        }
        else {
            return {
                res => 'ko',
                msg =>
"Invalid input: macros is not a hash object with \"key\":\"value\" attributes"
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
