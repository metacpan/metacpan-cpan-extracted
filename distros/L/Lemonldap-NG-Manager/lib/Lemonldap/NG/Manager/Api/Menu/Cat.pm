package Lemonldap::NG::Manager::Api::Menu::Cat;

our $VERSION = '2.0.10';

package Lemonldap::NG::Manager::Api;

use strict;
use utf8;
use Mouse;
use Lemonldap::NG::Manager::Conf::Parser;

extends 'Lemonldap::NG::Manager::Api::Common';

sub getMenuCatByConfKey {
    my ( $self, $req ) = @_;

    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    $self->logger->debug(
        "[API] Menu Category $confKey configuration requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf;

    my $menuCat = $self->_getMenuCatByConfKey( $conf, $confKey );

    # Return 404 if not found
    return $self->sendError( $req, "Menu category '$confKey' not found", 404 )
      unless ( defined $menuCat );

    return $self->sendJSONresponse( $req, $menuCat );
}

sub findMenuCatByConfKey {
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
        "[API] Find Menu Categories by confKey regexp $pattern requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf;

    my @menuCats =
      map { $_ =~ $pattern ? $self->_getMenuCatByConfKey( $conf, $_ ) : () }
      keys %{ $conf->{applicationList} };

    return $self->sendJSONresponse( $req, [@menuCats] );
}

sub addMenuCat {
    my ( $self, $req ) = @_;
    my $add = $req->jsonBodyToObj;

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

    return $self->sendError( $req, 'Invalid input: catname is missing', 400 )
      unless ( defined $add->{catname} );

    return $self->sendError( $req, 'Invalid input: catname is not a string',
        400 )
      if ( ref $add->{catname} );

    $self->logger->debug(
        "[API] Add Menu Category with confKey $add->{confKey} requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    return $self->sendError(
        $req,
"Invalid input: A Menu Category with confKey $add->{confKey} already exists",
        409
    ) if ( defined $self->_getMenuCatByConfKey( $conf, $add->{confKey} ) );

    my $res = $self->_pushMenuCat( $conf, $add->{confKey}, $add, 1 );

    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse(
        $req,
        { message => "Successful operation" },
        code => 201
    );
}

sub updateMenuCat {
    my ( $self, $req ) = @_;
    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    my $update = $req->jsonBodyToObj;

    return $self->sendError( $req, "Invalid input: " . $req->error, 400 )
      unless ($update);

    $self->logger->debug(
        "[API] Menu Category $confKey configuration update requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    my $current = $self->_getMenuCatByConfKey( $conf, $confKey );

    # Return 404 if not found

    return $self->sendError( $req, "Menu category '$confKey' not found", 404 )
      unless ( defined $current );

    my $res = $self->_pushMenuCat( $conf, $confKey, $update, 0 );

    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub replaceMenuCat {
    my ( $self, $req ) = @_;
    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

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

    return $self->sendError( $req, 'Invalid input: catname is missing', 400 )
      unless ( defined $replace->{catname} );

    return $self->sendError( $req, 'Invalid input: catname is not a string',
        400 )
      if ( ref $replace->{catname} );

    $self->logger->debug(
        "[API] Menu Category $confKey configuration replace requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    # Return 404 if not found

    return $self->sendError( $req, "Menu category '$confKey' not found", 404 )
      unless ( defined $self->_getMenuCatByConfKey( $conf, $confKey ) );

    my $res = $self->_pushMenuCat( $conf, $confKey, $replace, 1 );
    return $self->sendError( $req, $res->{msg}, 400 )
      unless ( $res->{res} eq 'ok' );

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub deleteMenuCat {
    my ( $self, $req ) = @_;
    my $confKey = $req->params('confKey')
      or return $self->sendError( $req, 'confKey is missing', 400 );

    $self->logger->debug(
        "[API] Menu Category $confKey configuration delete requested");

    # Get latest configuration
    my $conf = $self->_confAcc->getConf( { noCache => 1 } );

    my $delete = $self->_getMenuCatByConfKey( $conf, $confKey );

    # Return 404 if not found

    return $self->sendError( $req, "Menu category '$confKey' not found", 404 )
      unless ( defined $delete );

    delete $conf->{applicationList}->{$confKey};

    # Save configuration
    $self->_saveApplyConf($conf);

    return $self->sendJSONresponse( $req, undef, code => 204 );
}

sub _getMenuCatByConfKey {
    my ( $self, $conf, $confKey ) = @_;

    # Check if confKey is defined
    return undef unless ( defined $conf->{applicationList}->{$confKey} );

    my $menuCat = {
        confKey => $confKey,
        catname => $conf->{applicationList}->{$confKey}->{catname}
    };

    $menuCat->{order} = $conf->{applicationList}->{$confKey}->{order}
      if ( defined $conf->{applicationList}->{$confKey}->{order} );

    return $menuCat;
}

sub _pushMenuCat {
    my ( $self, $conf, $confKey, $push, $replace ) = @_;

    if ($replace) {
        $conf->{applicationList}->{$confKey} = {};
        $conf->{applicationList}->{$confKey}->{type} = "category";
    }

    $conf->{applicationList}->{$confKey}->{order} = $push->{order}
      if ( defined $push->{order} );

    $conf->{applicationList}->{$confKey}->{catname} = $push->{catname}
      if ( defined $push->{catname} );

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
