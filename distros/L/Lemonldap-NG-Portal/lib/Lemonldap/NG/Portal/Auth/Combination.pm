package Lemonldap::NG::Portal::Auth::Combination;

use strict;
use Mouse;
use Lemonldap::NG::Common::Combination::Parser;
use Lemonldap::NG::Portal::Main::Constants qw(PE_OK PE_ERROR PE_FIRSTACCESS);
use Scalar::Util 'weaken';

our $VERSION = '2.0.5';

# TODO: See Lib::Wrapper
extends 'Lemonldap::NG::Portal::Main::Auth';
with 'Lemonldap::NG::Portal::Lib::OverConf';

# PROPERTIES

has stackSub => ( is => 'rw' );

has wrapUserLogger => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        Lemonldap::NG::Portal::Lib::Combination::UserLogger->new(
            $_[0]->userLogger );
    }
);

# INITIALIZATION

sub init {
    my $self = shift;

    # Check if expression exists
    unless ( $self->conf->{combination} ) {
        $self->error('No combination found');
        return 0;
    }

    # Load all declared modules
    my %mods;
    foreach my $key ( keys %{ $self->conf->{combModules} } ) {
        my @tmp = ( undef, undef );
        my $mod = $self->conf->{combModules}->{$key};

        unless ( $mod->{type} and defined $mod->{for} ) {
            $self->error("Malformed combination module $key");
            return 0;
        }

        # Override parameters

        # "for" key can have 3 values:
        # 0: this module will be used for Auth and UserDB
        # 1: this module will be used for Auth only
        # 2: this module will be used for UserDB only

        # Load Auth module
        if ( $mod->{for} < 2 ) {
            $tmp[0] = $self->loadPlugin( "::Auth::$mod->{type}", $mod->{over} );
            unless ( $tmp[0] ) {
                $self->error("Unable to load Auth::$mod->{type}");
                return 0;
            }
            $tmp[0]->{userLogger} = $self->wrapUserLogger;
            weaken $tmp[0]->{userLogger};
        }

        # Load UserDB module
        unless ( $mod->{for} == 1 ) {
            $tmp[1] =
              $self->loadPlugin( "::UserDB::$mod->{type}", $mod->{over} );
            unless ( $tmp[1] ) {
                $self->error("Unable to load UserDB::$mod->{type}");
                return 0;
            }
            $tmp[1]->{userLogger} = $self->wrapUserLogger;
            weaken $tmp[1]->{userLogger};
        }

        # Store modules as array
        $mods{$key} = \@tmp;
    }

    # Compile expression
    eval {
        $self->stackSub(
            Lemonldap::NG::Common::Combination::Parser->parse(
                \%mods, $self->conf->{combination}
            )
        );
    };
    if ($@) {
        $self->error("Bad combination: $@");
        return 0;
    }
    return 1;
}

# Each first method must call getStack() to get the auth scheme available for
# the current user
sub extractFormInfo {
    my ( $self, $req ) = @_;
    return $self->try( 0, 'extractFormInfo', $req );
}

# Note that UserDB::Combination uses the same object.
sub getUser {
    return $_[0]->try( 1, 'getUser', $_[1] );
}

sub authenticate {
    return $_[0]->try( 0, 'authenticate', $_[1] );
}

sub setAuthSessionInfo {
    return $_[0]->try( 0, 'setAuthSessionInfo', $_[1] );
}

sub setSessionInfo {
    return $_[0]->try( 1, 'setSessionInfo', $_[1] );
}

sub setGroups {
    return $_[0]->try( 1, 'setGroups', $_[1] );
}

sub getDisplayType {
    my ( $self, $req ) = @_;
    return $self->conf->{combinationForms}
      if ( $self->conf->{combinationForms} );
    my ( $nb, $stack ) = (
        $req->data->{dataKeep}->{combinationTry},
        $req->data->{combinationStack}
    );
    my ( $res, $name ) = $stack->[$nb]->[0]->( 'getDisplayType', $req );
    return $res;
}

sub authLogout {
    my ( $self, $req ) = @_;
    $self->getStack( $req, 'extractFormInfo' ) or return PE_ERROR;

    # Avoid warning msg at first access
    $req->userData->{_combinationTry} ||= '';
    my ( $res, $name ) =
      $req->data->{combinationStack}->[ $req->userData->{_combinationTry} ]
      ->[0]->( 'authLogout', $req );
    $self->logger->debug(qq'User disconnected using scheme "$name"');
    return $res;
}

sub getStack {
    my ( $self, $req, @steps ) = @_;
    return $req->data->{combinationStack}
      if ( $req->data->{combinationStack} );
    my $stack = $req->data->{combinationStack} = $self->stackSub->( $req->env );
    unless ($stack) {
        $self->logger->error('No authentication scheme for this user');
    }
    @{ $req->data->{combinationSteps} } = ( @steps, @{ $req->steps } );
    $req->data->{dataKeep}->{combinationTry} ||= 0;
    return $stack;
}

# Main running method: launch the next scheme if the current fails
sub try {
    my ( $self, $type, $subname, $req ) = @_;

    # Get available authentication schemes for this user if not done
    unless ( defined $req->data->{combinationStack} ) {
        $self->getStack( $req, $subname ) or return PE_ERROR;
    }
    my ( $nb, $stack ) = (
        $req->data->{dataKeep}->{combinationTry},
        $req->data->{combinationStack}
    );

    # If more than 1 scheme is available
    my ( $res, $name );
    if ( $nb < @$stack - 1 ) {

        # TODO: change logLevel for userLog()
        ( $res, $name ) = $stack->[$nb]->[$type]->( $subname, $req );

        # On error, restart authentication with next scheme
        if ( $res > PE_OK ) {
            $self->logger->info(qq'Scheme "$name" returned $res, trying next');
            $req->data->{dataKeep}->{combinationTry}++;
            $req->steps( [ @{ $req->data->{combinationSteps} } ] );
            $req->continue(1);
            return PE_OK;
        }
    }
    else {
        ( $res, $name ) = $stack->[$nb]->[$type]->( $subname, $req );
    }
    $req->sessionInfo->{ [ '_auth', '_userDB' ]->[$type] } = $name;
    $req->sessionInfo->{_combinationTry} =
      $req->data->{dataKeep}->{combinationTry};
    if ( $res > 0 and $res != PE_FIRSTACCESS ) {
        $self->userLogger->warn( 'All schemes failed'
              . ( $req->user ? ' for user ' . $req->user : '' ) );
    }
    return $res;
}

# try() stores real Auth/UserDB module in sessionInfo
# This method reads them. It is called by getModule()
# (see Main::Run)
sub name {
    my ( $self, $req, $type ) = @_;
    return $req->sessionInfo->{ ( $type eq 'auth' ? '_auth' : '_userDB' ) }
      || 'Combination';
}

package Lemonldap::NG::Portal::Lib::Combination::UserLogger;

# This logger rewrite "warn" to "notice"

sub new {
    my ( $class, $realLogger ) = @_;
    return bless { logger => $realLogger }, $class;
}

sub warn {
    my ($auth) = caller(0);
    $_[0]->{logger}->notice("Combination ($auth): $_[1]");
}

sub AUTOLOAD {
    no strict;
    return $_[0]->{logger}->$AUTOLOAD( $_[1] )
      if ( $AUTOLOAD =~ /^(?:notice|debug|error|info)$/ );
}

1;
