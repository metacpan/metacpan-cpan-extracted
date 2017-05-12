## @file
# LL::NG module for Safe jail

## @package
# LL::NG module for Safe jail
package Lemonldap::NG::Common::Safe;

use strict;
use base qw(Safe);
use constant SAFEWRAP => ( Safe->can("wrap_code_ref") ? 1 : 0 );
use Scalar::Util 'weaken';

our $VERSION = '1.9.1';

our $self;    # Safe cannot share a variable declared with my

## @constructor Lemonldap::NG::Common::Safe new(Lemonldap::NG::Portal::Simple portal)
# Build a new Safe object
# @param portal Lemonldap::NG::Portal::Simple object
# @return Lemonldap::NG::Common::Safe object
sub new {
    my ( $class, $portal ) = @_;
    my $self = {};

    unless ( $portal->{useSafeJail} ) {

        # Fake jail
        $portal->lmLog( "Creating a fake Safe jail", 'debug' );
        bless $self, $class;
    }
    else {

        # Safe jail
        $self = $class->SUPER::new();
        $portal->lmLog( "Creating a real Safe jail", 'debug' );
    }

    # Store portal object
    $self->{p} = $portal;
    weaken $self->{p};

    return $self;
}

## @method reval(string $e)
# Evaluate an expression, inside or outside jail
# @param e Expression to evaluate
sub reval {
    local $self = shift;
    my ($e) = @_;
    my $result;

    # Replace $date
    $e =~ s/\$date/&POSIX::strftime("%Y%m%d%H%M%S",localtime())/e;

    # Replace variables by session content
    # Manage subroutine not the same way as plain perl expressions
    if ( $e =~ /^sub\s*{/ ) {
        $e =~ s/\$(?!ENV)(?!self)(\w+)/\$self->{sessionInfo}->{$1}/g;
    }
    else {
        $e =~ s/\$(?!ENV)(\w+)/\$self->{p}->{sessionInfo}->{$1}/g;
    }

    $self->{p}->lmLog( "Evaluate expression: $e", 'debug' );

    if ( $self->{p}->{useSafeJail} ) {

        # Share $self to access sessionInfo HASH
        $self->SUPER::share('$self');

        # Test SAFEWRAP and run reval
        $result = (
            ( SAFEWRAP and ref($e) eq 'CODE' )
            ? $self->SUPER::wrap_code_ref( $self->SUPER::reval($e) )
            : $self->SUPER::reval($e)
        );
    }
    else {

        # Use a standard eval
        $result = eval $e;
    }

    # Catch errors
    if ($@) {
        $self->{p}
          ->lmLog( "Error while evaluating the expression: $@", 'warn' );
        return;
    }

    $self->{p}->lmLog( "Evaluation result: $result", 'debug' );

    return $result;
}

## @method share_from(string $pkg, arrayref $vars)
# Share variables into Safe jail
# @param pkg Package
# @param vars Varibales
sub share_from {
    local $self = shift;
    my ( $pkg, $vars ) = (@_);

    # If Safe jail, call parent
    if ( $self->{p}->{useSafeJail} ) {
        $self->SUPER::share_from( $pkg, $vars );
    }

    # Else register varibales into current package
    # Code copied from Safe.pm
    else {
        no strict 'refs';
        foreach my $arg (@$vars) {
            my ( $var, $type );
            $type = $1 if ( $var = $arg ) =~ s/^(\W)//;
            for ( 1 .. 2 ) {    # assign twice to avoid any 'used once' warnings
                *{$var} =
                    ( !$type )       ? \&{ $pkg . "::$var" }
                  : ( $type eq '&' ) ? \&{ $pkg . "::$var" }
                  : ( $type eq '$' ) ? \${ $pkg . "::$var" }
                  : ( $type eq '@' ) ? \@{ $pkg . "::$var" }
                  : ( $type eq '%' ) ? \%{ $pkg . "::$var" }
                  : ( $type eq '*' ) ? *{ $pkg . "::$var" }
                  :                    undef;
            }
        }

    }
}

1;
