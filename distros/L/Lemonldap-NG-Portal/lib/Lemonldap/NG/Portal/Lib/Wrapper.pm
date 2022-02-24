# Base class for auth modules that call other auth modules (Choice,...)
#
# It fakes portal object to catch entry points and load them only if underlying
# auth module is activated
package Lemonldap::NG::Portal::Lib::Wrapper;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);

our $VERSION = '2.0.0';

extends 'Lemonldap::NG::Portal::Main::Auth';

has availableModules => ( is => 'rw', default => sub { {} } );

# Wrappers for portal entry points: entry points are enabled only for active
# authentication module
#
# Note that "beforeAuth" can't be used here and must be wrapped in auth
# module
#
# Note also that auth module must store in $req->data->{enabledMods} a ref
# to each enabled underlying auth modules
sub betweenAuthAndData { '_betweenAuthAndData' }
sub afterData          { '_afterData' }
sub endAuth            { '_endAuth' }
sub forAuthUser        { '_forAuthUser' }
sub beforeLogout       { '_beforeLogout' }
sub authCancel         { '_authCancel' }

sub _betweenAuthAndData { _wrapEntryPoint( @_, 'betweenAuthAndData' ); }
sub _afterData          { _wrapEntryPoint( @_, 'afterData' ); }
sub _endAuth            { _wrapEntryPoint( @_, 'endAuth' ); }
sub _forAuthUser        { _wrapEntryPoint( @_, 'forAuthUser',  1 ); }
sub _beforeLogout       { _wrapEntryPoint( @_, 'beforeLogout', 1 ); }
sub _authCancel         { _wrapEntryPoint( @_, 'authCancel' ); }

sub _wrapEntryPoint {
    my ( $self, $req, $name, $connected ) = @_;
    my @t;
    if ($connected) {
        if ( my $mod = $req->userData->{ $self->sessionKey } ) {
            if ( $self->modules->{$mod} ) {
                @t = ( $self->modules->{$mod} );
            }
            else {
                $self->userLogger->error(
                    "Bad $self->{sessionKey} value in session ($name)");
            }
        }
        else {
            $self->userLogger->warn(
                "Missing $self->{sessionKey} key in session");
        }
    }
    elsif ( ref $req->data->{ "enabledMods" . $self->type } ) {
        @t = @{ $req->data->{ "enabledMods" . $self->type } };
    }
    else {
        $self->logger->debug(
            "Unable to find enabledMods$self->{type} in this context: $name");
    }
    foreach (@t) {
        if ( $_->can($name) ) {

            # Launch sub and break loop if result isn't PE_OK (==0)
            if ( my $sub = $_->$name() ) {
                my $res = $_->$sub($req);
                return $res if ($res);
            }
        }
    }
    return PE_OK;
}

sub AUTOLOAD {
    no strict;

    # Unknown methods are tried with real portal
    my $self = shift;
    my $sub  = $AUTOLOAD;
    $sub =~ s/.*:://;
    if ( $self->p->can($sub) ) {
        return $self->p->$sub(@_);
    }
    require Carp;
    Carp::confess "Unknown method $sub";
}

1;
