package Lemonldap::NG::Manager::Api::Menu::App;

our $VERSION = '2.0.10';

package Lemonldap::NG::Manager::Api;

use strict;
use utf8;
use Mouse;
use Lemonldap::NG::Manager::Conf::Parser;

extends 'Lemonldap::NG::Manager::Api::Common';

sub getMenuApp {
    my ( $self, $req ) = @_;

    my $catConfKey = $req->params('confKey')
      or return $self->sendError( $req, 'Category confKey is missing', 400 );

    my $appConfKey = $req->params('appConfKey');

    # Get latest configuration
    my $conf = $self->_confAcc->getConf;

    # Check if catConfKey is defined
    return $self->sendError( $req,
        "Menu category '$catConfKey' not found", 404 )
      unless ( defined $conf->{applicationList}->{$catConfKey} );

    if ( defined $appConfKey ) {

        # Return one application referenced with this appConfKey
        $self->logger->debug(
"[API] Menu application $appConfKey from category $catConfKey configuration requested"
        );

        my $menuApp =
          $self->_getMenuAppByConfKey( $conf, $catConfKey, $appConfKey );

        # Return 404 if not found
        return $self->sendError(
            $req,
"Menu application '$appConfKey' from category '$catConfKey' not found",
            404
        ) unless ( defined $menuApp );

        return $self->sendJSONresponse( $req, $menuApp );

    }
    else {

        # Return all applications for this category
        $self->logger->debug(
"[API] Menu applications from category $catConfKey configuration requested"
        );

        my $cat = $conf->{applicationList}->{$catConfKey};

        my @menuApps =
          map {
                $self->_isCatApp( $cat->{$_} )
              ? $self->_getMenuAppByConfKey( $conf, $catConfKey, $_ )
              : ()
          }
          keys %{$cat};

        return $self->sendJSONresponse( $req, [@menuApps] );

    }
}

sub findMenuAppByConfKey {
    my ( $self, $req ) = @_;

    my $catConfKey = $req->params('confKey')
      or return $self->sendError( $req, 'Category confKey is missing', 400 );

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
"[API] Find Menu Applications from category $catConfKey by confKey regexp $pattern requested"
    );

    # Get latest configuration
    my $conf = $self->_confAcc->getConf;

    # Check if catConfKey is defined
    return $self->sendError( $req,
        "Menu category '$catConfKey' not found", 404 )
      unless ( defined $conf->{applicationList}->{$catConfKey} );

    my $cat = $conf->{applicationList}->{$catConfKey};

    my @menuApps =
      map {
             $self->_isCatApp( $cat->{$_} )
          && $_ =~ $pattern
          ? $self->_getMenuAppByConfKey( $conf, $catConfKey, $_ )
          : ()
      }
      keys %{$cat};

    return $self->sendJSONresponse( $req, [@menuApps] );
}

sub addMenuApp {
    my ( $self, $req ) = @_;
    my $add = $req->jsonBodyToObj;

    my $catConfKey = $req->params('confKey')
      or return $self->sendError( $req, 'Category confKey is missing', 400 );

    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ($add);

    return $self->sendError( $req, 'Invalid input: confKey is missing', 400 )
      unless ( defined $add->{confKey} );

    return $self->sendError( $req, 'Invalid input: confKey is not a string',
        400 )
      if ( ref $add->{confKey} );

    return $self->sendError( $req,
        'Invalid input: confKey contains invalid characters', 400 )
      unless ( $add->{confKey} =~ '^\w[\w\.\-]*$' );

    return $self->sendError( $req, 'Invalid input: name is missing', 400 )
      unless ( defined $add->{options} && defined $add->{options}{name} );

    return $self->sendError( $req, 'Invalid input: name is not a string', 400 )
      if ( ref $add->{options}{name} );

    $self->logger->debug(
"[API] Add Menu Application from category $catConfKey with confKey $add->{confKey} requested"
    );

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    # Check if catConfKey is defined
    return $self->sendError( $req,
        "Menu category '$catConfKey' not found", 404 )
      unless ( defined $conf->{applicationList}->{$catConfKey} );

    return $self->sendError(
        $req,
"Invalid input: A Menu Application with confKey $add->{confKey} already exists in category $catConfKey",
        409
      )
      if (
        defined $self->_getMenuAppByConfKey( $conf, $catConfKey,
            $add->{confKey} ) );

    my $res =
      $self->_pushMenuApp( $conf, $catConfKey, $add->{confKey}, $add, 1 );

    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse(
        $req,
        { message => "Successful operation" },
        code => 201
    );
}

sub updateMenuApp {
    my ( $self, $req ) = @_;

    my $catConfKey = $req->params('confKey')
      or return $self->sendError( $req, 'Category confKey is missing', 400 );

    my $appConfKey = $req->params('appConfKey')
      or return $self->sendError( $req, 'Application confKey is missing', 400 );

    my $update = $req->jsonBodyToObj;

    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ($update);

    $self->logger->debug(
"[API] Menu application $appConfKey from category $catConfKey configuration update requested"
    );

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    # Return 404 if not found

    return $self->sendError( $req,
        "Menu category '$catConfKey' not found", 404 )
      unless ( defined $self->_getMenuCatByConfKey( $conf, $catConfKey ) );

    return $self->sendError(
        $req,
        "Menu application '$appConfKey' from category '$catConfKey' not found",
        404
      )
      unless (
        defined $self->_getMenuAppByConfKey( $conf, $catConfKey, $appConfKey )
      );

    my $res =
      $self->_pushMenuApp( $conf, $catConfKey, $appConfKey, $update, 0 );

    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub replaceMenuApp {
    my ( $self, $req ) = @_;
    my $catConfKey = $req->params('confKey')
      or return $self->sendError( $req, 'Category confKey is missing', 400 );

    my $appConfKey = $req->params('appConfKey')
      or return $self->sendError( $req, 'Application confKey is missing', 400 );

    my $replace = $req->jsonBodyToObj;

    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ($replace);

    return $self->sendError( $req, 'Invalid input: confKey is missing', 400 )
      unless ( defined $replace->{confKey} );

    return $self->sendError( $req, 'Invalid input: confKey is not a string',
        400 )
      if ( ref $replace->{confKey} );

    return $self->sendError( $req,
        'Invalid input: confKey contains invalid characters', 400 )
      unless ( $replace->{confKey} =~ '^\w[\w\.\-]*$' );

    return $self->sendError( $req, 'Invalid input: name is missing', 400 )
      unless ( defined $replace->{options}
        && defined $replace->{options}{name} );

    return $self->sendError( $req, 'Invalid input: name is not a string', 400 )
      if ( ref $replace->{options}{name} );

    $self->logger->debug(
"[API] Menu application $appConfKey from category $catConfKey configuration replace requested"
    );

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    # Return 404 if not found

    return $self->sendError( $req,
        "Menu category '$catConfKey' not found", 404 )
      unless ( defined $self->_getMenuCatByConfKey( $conf, $catConfKey ) );

    return $self->sendError(
        $req,
        "Menu application '$appConfKey' from category '$catConfKey' not found",
        404
      )
      unless (
        defined $self->_getMenuAppByConfKey( $conf, $catConfKey, $appConfKey )
      );

    my $res =
      $self->_pushMenuApp( $conf, $catConfKey, $appConfKey, $replace, 1 );
    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub deleteMenuApp {
    my ( $self, $req ) = @_;

    my $catConfKey = $req->params('confKey')
      or return $self->sendError( $req, 'Category confKey is missing', 400 );

    my $appConfKey = $req->params('appConfKey')
      or return $self->sendError( $req, 'Application confKey is missing', 400 );

    $self->logger->debug(
"[API] Menu Application $appConfKey from category $catConfKey configuration delete requested"
    );

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    return $self->sendError( $req,
        "Menu category '$catConfKey' not found", 404 )
      unless ( defined $self->_getMenuCatByConfKey( $conf, $catConfKey ) );

    my $delete = $self->_getMenuAppByConfKey( $conf, $catConfKey, $appConfKey );

    # Return 404 if not found

    return $self->sendError( $req,
        "Menu category '$appConfKey' not found", 404 )
      unless ( defined $delete );

    delete $conf->{applicationList}->{$catConfKey}->{$appConfKey};

    # Save configuration
    $self->_saveApplyConf($conf);

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub _isCatApp {
    my ( $self, $candidate ) = @_;

# Check if candidate is a hash, has "type" defined and if "type" equals "application".
    return
         ref $candidate eq ref {}
      && defined $candidate->{type}
      && $candidate->{type} eq 'application';
}

sub _getMenuAppByConfKey {
    my ( $self, $conf, $catConfKey, $appConfKey ) = @_;

    # Check if catConfKey is defined
    return undef unless ( defined $conf->{applicationList}->{$catConfKey} );

    # Check if appConfKey is defined
    return undef
      unless ( defined $conf->{applicationList}->{$catConfKey}->{$appConfKey} );

    my $cat = $conf->{applicationList}->{$catConfKey};

    my $menuApp = { confKey => $appConfKey };

    $menuApp->{order} = $cat->{$appConfKey}->{order}
      if ( defined $cat->{$appConfKey}->{order} );

    # Get options
    my $options = {};
    for my $configOption ( keys %{ $cat->{$appConfKey}->{options} } ) {
        $options->{ $self->_translateOptionConfToApi($configOption) } =
          $cat->{$appConfKey}->{options}->{$configOption};
    }

    $menuApp->{options} = $options;

    return $menuApp;
}

sub _pushMenuApp {
    my ( $self, $conf, $catConfKey, $appConfKey, $push, $replace ) = @_;

    if ($replace) {
        $conf->{applicationList}->{$catConfKey}->{$appConfKey} = {};
        $conf->{applicationList}->{$catConfKey}->{$appConfKey}->{type} =
          "application";
        $conf->{applicationList}->{$catConfKey}->{$appConfKey}->{options} = {};
        $conf->{applicationList}->{$catConfKey}->{$appConfKey}->{options}
          ->{display} = "auto";
        $conf->{applicationList}->{$catConfKey}->{$appConfKey}->{options}
          ->{logo} = "network.png";
    }

    $conf->{applicationList}->{$catConfKey}->{$appConfKey}->{order} =
      $push->{order}
      if ( defined $push->{order} );

    if ( defined $push->{options} ) {
        foreach ( keys %{ $push->{options} } ) {
            $conf->{applicationList}->{$catConfKey}->{$appConfKey}->{options}
              ->{$_} = $push->{options}->{$_};
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
