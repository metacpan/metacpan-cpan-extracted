package Lemonldap::NG::Portal::Auth::Combination;

use strict;
use Mouse;
use Lemonldap::NG::Common::Combination::Parser;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_CONFIRM
  PE_ERROR
  PE_FIRSTACCESS
  PE_FORMEMPTY
  PE_PASSWORD_OK
  PE_OK
);
use Scalar::Util 'weaken';

our $VERSION = '2.0.14';

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

## Auth steps
#############
sub extractFormInfo {
    my $self = shift;
    return $self->try( 0, 'extractFormInfo', @_ );
}

sub authenticate {
    my $self = shift;
    return $self->try( 0, 'authenticate', @_ );
}

sub setAuthSessionInfo {
    my $self = shift;
    return $self->try( 0, 'setAuthSessionInfo', @_ );
}

sub getDisplayType {
    my $self = shift;
    my ($req) = @_;
    return $self->conf->{combinationForms}
      if ( $self->conf->{combinationForms} );

    my ( $nb, $stack ) = (
        $req->data->{dataKeep}->{combinationTry},
        $req->data->{combinationStack}
    );
    my $res = $stack->[$nb]->[0]->( 'getDisplayType', @_ );
    return $res;
}

sub authLogout {
    my $self = shift;
    my ($req) = @_;
    $self->getStack( $req, 'extractFormInfo' ) or return PE_ERROR;

    # Avoid warning msg at first access
    $req->userData->{_combinationTry} ||= 0;
    my $sub =
      $req->data->{combinationStack}->[ $req->userData->{_combinationTry} ]
      ->[0];
    unless ($sub) {
        $self->logger->warn(
                "Condition changed between login and logout for "
              . $req->user
              . ", unable to select good backend" );
        return PE_OK;
    }
    my ( $res, $name ) = $sub->( 'authLogout', @_ );
    $self->logger->debug(qq'User disconnected using scheme "$name"');
    return $res;
}

sub authFinish {
    return PE_OK;
}

sub authForce {
    return 0;
}

sub setSecurity {
    my $self = shift;
    my ($req) = @_;
    $self->getStack( $req, 'extractFormInfo' ) or return;
    eval {
        $req->data->{combinationStack}
          ->[ $req->data->{dataKeep}->{combinationTry} ]->[0]
          ->( 'setSecurity', @_ );
    };
    $self->logger->debug($@) if ($@);
}

## UserDB steps
###############
# Note that UserDB::Combination uses the same object.
sub getUser {
    my $self = shift;
    return $self->try( 1, 'getUser', @_ );
}

sub findUser {
    my $self = shift;
    return $self->try( 1, 'findUser', @_ );
}

sub setSessionInfo {
    my $self = shift;
    return $self->try( 1, 'setSessionInfo', @_ );
}

sub setGroups {
    my $self = shift;
    return $self->try( 1, 'setGroups', @_ );
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
    my ( $self, $type, $subname, $req, @args ) = @_;

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
    unless ( ref $stack->[$nb]->[$type] ) {
        $self->logger->error(
'Something went wrong in combination, unable to find any auth scheme (try == '
              . ( $nb + 1 )
              . ')' );
        return PE_ERROR;
    }

    my $stop = 0;
    if ( $nb < @$stack - 1 ) {

        # TODO: change logLevel for userLog()
        ( $res, $name ) = $stack->[$nb]->[$type]->( $subname, $req, @args );

        # On error, restart authentication with next scheme
        unless ( $stop = $self->stop( $stack->[$nb]->[$type], $res ) ) {
            $self->logger->info(qq'Scheme "$name" returned $res, trying next');
            $req->data->{dataKeep}->{combinationTry}++;
            $req->steps( [ @{ $req->data->{combinationSteps} } ] );
            $req->continue(1);
            return PE_OK;
        }
    }
    else {
        ( $res, $name ) = $stack->[$nb]->[$type]->( $subname, $req, @args );
    }
    $req->sessionInfo->{ [ '_auth', '_userDB' ]->[$type] } = $name;
    $req->sessionInfo->{_combinationTry} =
      $req->data->{dataKeep}->{combinationTry};
    if ( $res > 0 ) {
        if ($stop) {
            $self->userLogger->info(
                "Combination stopped by plugin $name (code $res)");
        }
        elsif ( $res != PE_FIRSTACCESS ) {
            $self->userLogger->warn( 'All schemes failed'
                  . ( $req->user ? ' for user ' . $req->user : '' ) . ' ('
                  . $req->address
                  . ')' );
        }
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

sub stop {
    my ( $self, $mod, $res ) = @_;
    return 1
      if (
        $res <= 0    # PE_OK
        or $res == PE_CONFIRM
        or $res == PE_PASSWORD_OK

        # TODO: adding this may generate behavior change
        #or $res == PE_FIRSTACCESS
        #or $res == PE_FORMEMPTY
      );
    my ( $ret, $name );
    $ret = $mod->( 'can', 'stop' );
    if ($ret) {
        eval { ( $ret, $name ) = $mod->( 'stop', $res ) };
        if ($@) {

            $self->logger->error(
                "Optional ${name}::stop() method failed: " . $@ );
            return 0;
        }
    }
    return $ret;
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
