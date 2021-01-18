package Lemonldap::NG::Manager::Api::Providers::SamlSp;

our $VERSION = '2.0.10';

package Lemonldap::NG::Manager::Api;

use strict;
use utf8;
use Mouse;

extends 'Lemonldap::NG::Manager::Api::Common';

sub getSamlSpByConfKey {
    my ( $self, $req ) = @_;

    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    $self->logger->debug("[API] SAML SP $confKey configuration requested");

    # Get latest configuration
    my $conf   = $self->_confAcc->getConf;
    my $samlSp = $self->_getSamlSpByConfKey( $conf, $confKey );

    # Check if confKey is defined
    return $self->sendError( $req,
        "SAML service Provider '$confKey' not found", 404 )
      unless ( defined $samlSp );

    return $self->sendJSONresponse( $req, $samlSp );
}

sub findSamlSpByConfKey {
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
        "[API] Find SAML SPs by confKey regexp $pattern requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf;
    my @samlSps =
      map { $_ =~ $pattern ? $self->_getSamlSpByConfKey( $conf, $_ ) : () }
      keys %{ $conf->{samlSPMetaDataXML} };

    return $self->sendJSONresponse( $req, [@samlSps] );
}

sub findSamlSpByEntityId {
    my ( $self, $req ) = @_;
    my $entityId = (
        defined $req->params('uEntityId') ? $req->params('uEntityId')
        : (
            defined $req->params('entityId') ? $req->params('entityId')
            : undef
        )
    );

    return $self->sendError( $req, 'entityId is missing', 400 )
      unless ( defined $entityId );

    $self->logger->debug("[API] Find SAML SPs by entityId $entityId requested");

    # Get latest configuration
    my $conf   = $self->_confAcc->getConf;
    my $samlSp = $self->_getSamlSpByEntityId( $conf, $entityId );

    return $self->sendError( $req,
        "SAML service Provider with entityID '$entityId' not found", 404 )
      unless ( defined $samlSp );
    return $self->sendJSONresponse( $req, $samlSp );
}

sub addSamlSp {
    my ( $self, $req ) = @_;
    my $add = $req->jsonBodyToObj;

    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ($add);

    return $self->sendError( $req, 'Invalid input: confKey is missing', 400 )
      unless ( defined $add->{confKey} );

    return $self->sendError( $req, 'Invalid input: metadata is missing', 400 )
      unless ( defined $add->{metadata} );

    return $self->sendError( $req, 'Invalid input: confKey is empty', 400 )
      unless ( $add->{confKey} );

    my $entityId = $self->_readSamlSpEntityId( $add->{metadata} );

    return $self->sendError( $req,
        'Invalid input: entityID is missing in metadata', 400 )
      unless ( defined $entityId );

    $self->logger->debug(
"[API] Add SAML SP with confKey $add->{confKey} and entityID $entityId requested"
    );

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    return $self->sendError(
        $req,
        "Invalid input: A SAML SP with confKey $add->{confKey} already exists",
        409
    ) if ( defined $self->_getSamlSpByConfKey( $conf, $add->{confKey} ) );

    return $self->sendError( $req,
        "Invalid input: A SAML SP with entityID $entityId already exists", 409 )
      if ( defined $self->_getSamlSpByEntityId( $conf, $entityId ) );

    my $res = $self->_pushSamlSp( $conf, $add->{confKey}, $add, 1 );

    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse(
        $req,
        { message => "Successful operation" },
        code => 201
    );
}

sub replaceSamlSp {
    my ( $self, $req ) = @_;

    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    my $replace = $req->jsonBodyToObj;

    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ($replace);

    return $self->sendError( $req, 'Invalid input: metadata is missing', 400 )
      unless ( defined $replace->{metadata} );

    $self->logger->debug(
        "[API] SAML SP $confKey configuration replace requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    # Return 404 if not found

    return $self->sendError( $req,
        "SAML service provider '$confKey' not found", 404 )
      unless ( defined $self->_getSamlSpByConfKey( $conf, $confKey ) );

    # check if new entityId exists already
    my $res = $self->_isNewSamlSpEntityIdUnique( $conf, $confKey, $replace );

    return $self->sendError( $req, $res->{msg}, 409 )
      unless ( $res->{res} eq 'ok' );

    $res = $self->_pushSamlSp( $conf, $confKey, $replace, 1 );

    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub updateSamlSp {
    my ( $self, $req ) = @_;
    my $res;
    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    my $update = $req->jsonBodyToObj;

    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ($update);

    $self->logger->debug(
        "[API] SAML SP $confKey configuration update requested");

    # Get latest configuration
    my $conf    = $self->_confAcc->getConf( { noCache => 1 } );
    my $current = $self->_getSamlSpByConfKey( $conf, $confKey );

    # Return 404 if not found
    return $self->sendError( $req,
        "SAML service provider '$confKey' not found", 404 )
      unless ( defined $current );

    if ( defined $update->{metadata} ) {

        # check if new entityId exists already
        $res = $self->_isNewSamlSpEntityIdUnique( $conf, $confKey, $update );

        return $self->sendError( $req, $res->{msg}, 409 )
          unless ( $res->{res} eq 'ok' );

    }

    $res = $self->_pushSamlSp( $conf, $confKey, $update, 0 );
    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub deleteSamlSp {
    my ( $self, $req ) = @_;

    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    my $delete = $self->_getSamlSpByConfKey( $conf, $confKey );

    # Return 404 if not found

    return $self->sendError( $req,
        "SAML service provider '$confKey' not found", 404 )
      unless ( defined $delete );

    delete $conf->{samlSPMetaDataXML}->{$confKey};
    delete $conf->{samlSPMetaDataOptions}->{$confKey};
    delete $conf->{samlSPMetaDataExportedAttributes}->{$confKey};
    delete $conf->{samlSPMetaDataMacros}->{$confKey};

    # Save configuration
    $self->_saveApplyConf($conf);

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub _getSamlSpByConfKey {
    my ( $self, $conf, $confKey ) = @_;

    # Check if confKey is defined
    return undef unless ( defined $conf->{samlSPMetaDataXML}->{$confKey} );

    # Get metadata
    my $metadata = $conf->{samlSPMetaDataXML}->{$confKey}->{samlSPMetaDataXML};

    # Get options
    my $options = {};
    for my $confOption ( keys %{ $conf->{samlSPMetaDataOptions}->{$confKey} } )
    {
        my $optionName  = $self->_translateOptionConfToApi($confOption);
        my $optionValue = $self->_translateValueConfToApi( $confOption,
            $conf->{samlSPMetaDataOptions}->{$confKey}->{$confOption} );

        $options->{$optionName} = $optionValue;
    }

    # Get macros
    my $macros = $conf->{samlSPMetaDataMacros}->{$confKey} || {};

    my $samlSp = {
        confKey            => $confKey,
        metadata           => $metadata,
        exportedAttributes => {},
        macros             => $macros,
        options            => $options
    };

    # Get exported attributes
    foreach ( keys %{ $conf->{samlSPMetaDataExportedAttributes}->{$confKey} } )
    {
        # Extract fields from exportedAttr value
        my ( $mandatory, $name, $format, $friendly_name ) =
          split( /;/,
            $conf->{samlSPMetaDataExportedAttributes}->{$confKey}->{$_} );

        $mandatory = !!$mandatory ? 'true' : 'false';    # ????????????

        $samlSp->{exportedAttributes}->{$_} = {
            name      => $name,
            mandatory => $mandatory
        };

        $samlSp->{exportedAttributes}->{$_}->{friendlyName} = $friendly_name
          if ( defined $friendly_name && $friendly_name ne '' );

        $samlSp->{exportedAttributes}->{$_}->{format} = $format
          if ( defined $format && $format ne '' );
    }

    return $samlSp;
}

sub _getSamlSpByEntityId {
    my ( $self, $conf, $entityId ) = @_;

    foreach ( keys %{ $conf->{samlSPMetaDataXML} } ) {
        return $self->_getSamlSpByConfKey( $conf, $_ )
          if (
            $self->_readSamlSpEntityId(
                $conf->{samlSPMetaDataXML}->{$_}->{samlSPMetaDataXML}
            ) eq $entityId
          );
    }

    return undef;
}

sub _readSamlSpEntityId {
    my ( $self, $metadata ) = @_;

    return ( $metadata =~ /entityID=['"](.+?)['"]/ ) ? $1 : undef;
}

sub _readSamlSpExportedAttributes {
    my ( $self, $attrs, $mergeWith ) = @_;
    my $allowedFormats = [
        "urn:oasis:names:tc:SAML:2.0:attrname-format:unspecified",
        "urn:oasis:names:tc:SAML:2.0:attrname-format:uri",
        "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
    ];
    foreach ( keys %{$attrs} ) {
        return { res => "ko", msg => "Exported attribute $_ has no name" }
          unless ( defined $attrs->{$_}->{name} );
        my $mandatory    = 0;
        my $name         = $attrs->{$_}->{name};
        my $format       = '';
        my $friendlyName = '';

        ( $mandatory, $name, $format, $friendlyName ) =
          split( /;/, $mergeWith->{$_} )
          if ( defined $mergeWith->{$_} );

        if ( defined $attrs->{$_}->{mandatory} ) {
            $mandatory = (
                     $attrs->{$_}->{mandatory} eq '1'
                  or $attrs->{$_}->{mandatory} eq 'true'
            ) ? 1 : 0;
        }

        if ( defined $attrs->{$_}->{format} ) {
            $format = $attrs->{$_}->{format};
            return {
                res => "ko",
                msg => "Exported attribute $_ format does not exist."
              }
              unless ( length( grep { /^$format$/ } @{$allowedFormats} ) );
        }

        $friendlyName = $attrs->{$_}->{friendlyName}
          if ( defined $attrs->{$_}->{friendlyName} );
        $mergeWith->{$_} = "$mandatory;$name;$format;$friendlyName";
    }

    return { res => "ok", exportedAttributes => $mergeWith };
}

sub _pushSamlSp {
    my ( $self, $conf, $confKey, $push, $replace ) = @_;

    my $translatedOptions = {};
    if ($replace) {
        $conf->{samlSPMetaDataXML}->{$confKey}                = {};
        $conf->{samlSPMetaDataOptions}->{$confKey}            = {};
        $conf->{samlSPMetaDataMacros}->{$confKey}             = {};
        $conf->{samlSPMetaDataExportedAttributes}->{$confKey} = {};
        $translatedOptions = $self->_getDefaultValues('samlSPMetaDataNode');
    }

    $conf->{samlSPMetaDataXML}->{$confKey}->{samlSPMetaDataXML} =
      $push->{metadata}
      if defined $push->{metadata};

    if ( defined $push->{options} ) {

        foreach ( keys %{ $push->{options} } ) {
            my $optionName = $self->_translateOptionApiToConf( $_, 'samlSP' );
            my $optionValue =
              $self->_translateValueApiToConf( $_, $push->{options}->{$_} );
            $translatedOptions->{$optionName} = $optionValue;
        }

        my $res = $self->_hasAllowedAttributes( $translatedOptions,
            'samlSPMetaDataNode' );
        return $res unless ( $res->{res} eq 'ok' );
        foreach ( keys %{$translatedOptions} ) {
            $conf->{samlSPMetaDataOptions}->{$confKey}->{$_} =
              $translatedOptions->{$_};
        }

    }

    if ( defined $push->{macros} ) {
        if ( $self->_isSimpleKeyValueHash( $push->{macros} ) ) {
            foreach ( keys %{ $push->{macros} } ) {
                $conf->{samlSPMetaDataMacros}->{$confKey}->{$_} =
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

    if ( defined $push->{exportedAttributes} ) {
        my $res =
          $self->_readSamlSpExportedAttributes( $push->{exportedAttributes},
            $conf->{samlSPMetaDataExportedAttributes}->{$confKey} );
        return $res unless ( $res->{res} eq 'ok' );

        $conf->{samlSPMetaDataExportedAttributes}->{$confKey} =
          $res->{exportedAttributes};
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

sub _isNewSamlSpEntityIdUnique {
    my ( $self, $conf, $confKey, $newSp ) = @_;
    my $newEntityId = $self->_readSamlSpEntityId( $newSp->{metadata} );
    my $curEntityId =
      $self->_readSamlSpEntityId(
        $self->_getSamlSpByConfKey( $conf, $confKey )->{metadata} );
    if ( $newEntityId ne $curEntityId ) {
        return {
            res => 'ko',
            msg =>
"An SAML service provide with entityId '$newEntityId' already exists"
          }
          if ( defined $self->_getSamlSpByEntityId( $conf, $newEntityId ) );
    }

    return { res => 'ok' };
}

1;
