## @file
# Authentication and UserDB chaining mechanism

## @class
# Authentication and UserDB chaining mechanism.
# To use it set your authentication module like this :
#    authentication => 'Multi CAS;LDAP'
#
# If CAS failed, LDAP will be used. You can also add a condition. Example:
#    authentication => 'Multi Remote $ENV{REMOTE_ADDR}=~/^192/;LDAP $ENV{REMOTE_ADDR}!~/^192/'
package Lemonldap::NG::Portal::_Multi;

use Lemonldap::NG::Portal::Simple;
use Scalar::Util 'weaken';

our $VERSION = '1.4.8';

## @cmethod Lemonldap::NG::Portal::_Multi new(Lemonldap::NG::Portal::Simple portal)
# Constructor
# @param $portal Lemonldap::NG::Portal::Simple object
# @return new Lemonldap::NG::Portal::_Multi object
sub new {
    my ( $class, $portal ) = @_;
    my $self = bless { p => $portal, res => PE_NOSCHEME }, $class;
    weaken $self->{p};

    # Browse authentication and userDB configuration
    my @stack = ( $portal->{authentication}, $portal->{userDB} );
    for ( my $i = 0 ; $i < 2 ; $i++ ) {
        $stack[$i] =~ s/^Multi\s*//;
        foreach my $l ( split /;/, $stack[$i] ) {
            $l =~ s/^\s+//;    # Remove first space
            $l =~ /^([\w#]+)(?:\s+(.*))?$/
              or $portal->abort( 'Bad configuration', "Unable to read $l" );
            my ( $mod, $cond ) = ( $1, $2 );
            my $name = $mod;
            $mod =~ s/#(.*)$//;
            my $shortname = $mod;
            $cond = 1 unless ( defined $cond );
            $mod = "Lemonldap::NG::Portal::" . [ 'Auth', 'UserDB' ]->[$i] . $mod
              unless ( $mod =~ /::/ );

            $portal->abort( 'Bad configuration', "Unable to load $mod" )
              unless $self->{p}->loadModule($mod);
            push @{ $self->{stack}->[$i] },
              { m => $mod, c => $cond, n => $name, s => $shortname };
        }

        # Override portal settings
        %{ $self->{p} } = (
            %{ $self->{p} },
            %{ $self->{p}->{multi}->{ $self->{stack}->[$i]->[0]->{n} } }
        ) if ( $self->{p}->{multi}->{ $self->{stack}->[$i]->[0]->{n} } );

    }

    # Return _Multi object
    return $self;
}

## @method int try(string sub,int type)
# Main method: try to call $sub method in the current authentication or
# userDB module. If it fails, call next() and replay()
# @param sub name of the method to launch
# @param type 0 for authentication, 1 for userDB
# @return Lemonldap::NG::Portal error code returned by method $sub
sub try {
    my ( $self, $sub, $type ) = @_;
    my $res;
    my $s   = $self->{stack}->[$type]->[0]->{m} . "::$sub";
    my $old = $self->{stack}->[$type]->[0]->{n};
    my $ci;

    # Store last module used
    $self->{last}->[$type] = $self->{stack}->[$type]->[0]->{m};

    if ( $ci = $self->{p}->safe->reval( $self->{stack}->[$type]->[0]->{c} ) ) {

        # Log used module
        $self->{p}
          ->lmLog( "Multi (type $type): trying $sub for module $old", 'debug' );

        # Run subroutine
        $res = $self->{p}->$s();

        # Stop if no error, or if confirmation needed, or if form not filled
        return $res
          if ( $res <= 0
            or $res == PE_CONFIRM
            or $res == PE_FIRSTACCESS
            or $res == PE_FORMEMPTY );
    }
    unless ( $self->next($type) ) {
        return ( $ci ? $res : $self->{res} );
    }
    $self->{res} = $res if ( defined($res) );
    $self->{p}->lmLog(
        [ 'Authentication', 'Retriving user' ]->[$type]
          . " with $old failed, trying next",
        'info'
    ) if ($ci);
    $res = $self->replay( $sub, $type );
    return $res;
}

## @method protected boolean next(int type)
# Set the next authentication or userDB module as current. If both
# authentication and userDB module have the same name, both are changed if
# possible.
# @param type 0 for authentication, 1 for userDB
# return true if an other module is available
sub next {
    my ( $self, $type ) = @_;

    if ( $self->{stack}->[$type]->[0]->{n} eq
            $self->{stack}->[ 1 - $type ]->[0]->{n}
        and $self->{stack}->[ 1 - $type ]->[1] )
    {
        shift @{ $self->{stack}->[ 1 - $type ] };
    }
    shift @{ $self->{stack}->[$type] };

    # Manage end of the stack
    return 0 unless ( @{ $self->{stack}->[$type] } );

    %{ $self->{p} } = (
        %{ $self->{p} },
        %{ $self->{p}->{multi}->{ $self->{stack}->[$type]->[0]->{n} } }
    ) if ( $self->{p}->{multi}->{ $self->{stack}->[$type]->[0]->{n} } );
    return 1;
}

## @method protected int replay(string sub)
# replay all methods since authInit() until method $sub with the new module.
# @param $sub name of the method who has failed
# @return Lemonldap::NG::Portal error code
sub replay {
    my ( $self, $sub ) = @_;
    my @subs = ();
    $self->{p}->lmLog( "Replay all methods until sub $sub", 'debug' );

    foreach (
        qw(authInit extractFormInfo userDBInit getUser setAuthSessionInfo
        setSessionInfo setMacros setGroups setPersistentSessionInfo
        setLocalGroups authenticate authFinish)
      )
    {
        push @subs, $_;
        last if ( $_ eq $sub );
    }
    return $self->{p}->_subProcess(@subs);
}

package Lemonldap::NG::Portal::Simple;

## @method private Lemonldap::NG::Portal::_Multi _multi()
# Return Lemonldap::NG::Portal::_Multi object and builds it if it was not build
# before. This method is used if authentication is set to "Multi".
# @return Lemonldap::NG::Portal::_Multi object
sub _multi {
    my $self = shift;
    return $self->{_multi} if ( $self->{_multi} );
    return $self->{_multi} = Lemonldap::NG::Portal::_Multi->new($self);
}

1;

