## @file
# Common functions for authentication choice

## @class
# Common functions for authentication choice

package Lemonldap::NG::Portal::_Choice;

use Lemonldap::NG::Portal::Simple;
use Scalar::Util 'weaken';

our $VERSION = '1.9.11';

## @cmethod Lemonldap::NG::Portal::_Choice new(Lemonldap::NG::Portal::Simple portal)
# Constructor
# @param $portal Lemonldap::NG::Portal::Simple object
# @return new Lemonldap::NG::Portal::_Choice object
sub new {
    my ( $class, $portal ) = @_;

    # Create object with portal parameter
    my $self = bless { p => $portal }, $class;
    weaken $self->{p};

    # Recover authChoice from session
    $portal->{_authChoice} ||= $portal->{sessionInfo}->{_authChoice};

    # Test authChoice
    unless ( $portal->{_authChoice}
        and exists $portal->{authChoiceModules}->{ $portal->{_authChoice} } )
    {
        $portal->lmLog( "No authentication choice done, or wrong choice",
            'debug' );
        $portal->{_authChoice} = "";
    }

    # Special workaround for Captcha
    # Init Captcha to have it displayed even if no choice already done
    if ( $portal->{captcha_login_enabled} ) {
        eval { $portal->initCaptcha(); };
        $portal->lmLog( "Can't init captcha: $@", "error" ) if $@;
    }

    # Special workaround for SAML
    # because we cannot easily set SSO return URL
    # and SLO URL with authChoice parameter

    # Test authForce to see if URL is an SAML URL
    unless ( $portal->{_authChoice} ) {
        my $samlModule = 'Lemonldap::NG::Portal::AuthSAML';
        my $samlForce  = 0;
        eval {
            $portal->loadModule( $samlModule, 1 );
            $authForce = $samlModule . '::authForce';
            $samlForce = $portal->$authForce;
        };

        if ($@) {
            $portal->lmLog( "SAML choice force not tested: $@", 'debug' );
        }

        # Select SAML choice if needed
        if ($samlForce) {
            $portal->lmLog( "Find SAML choice", 'debug' );
            foreach ( keys %{ $portal->{authChoiceModules} } ) {
                $portal->{_authChoice} = $_
                  if ( $portal->{authChoiceModules}->{$_} =~ /^SAML/ );
            }
            if ( $portal->{_authChoice} ) {
                $portal->lmLog(
                    "SAML Choice " . $portal->{_authChoice} . " found",
                    'debug' );
            }
            else {
                $portal->lmLog( "No SAML Choice found", 'error' );
            }
        }
    }

    return $self unless $portal->{_authChoice};

    # Find modules associated to authChoice
    my ( $auth, $userDB, $passwordDB ) =
      split( /[;\|]/,
        $portal->{authChoiceModules}->{ $portal->{_authChoice} } );

    if ( $auth and $userDB and $passwordDB ) {

        my $modulePrefix     = 'Lemonldap::NG::Portal::';
        my $authModule       = $modulePrefix . 'Auth' . $auth;
        my $userDBModule     = $modulePrefix . 'UserDB' . $userDB;
        my $passwordDBModule = $modulePrefix . 'PasswordDB' . $passwordDB;

        foreach my $module ( $authModule, $userDBModule, $passwordDBModule ) {
            $portal->abort( 'Bad configuration', "Unable to load $module" )
              unless $portal->loadModule($module);
        }

        $self->{modules} = [
            { m => $authModule,       n => $auth },
            { m => $userDBModule,     n => $userDB },
            { m => $passwordDBModule, n => $passwordDB }
        ];

        $portal->lmLog( "Authentication module $auth selected", 'debug' );
        $portal->lmLog( "User module $userDB selected",         'debug' );
        $portal->lmLog( "Password module $passwordDB selected", 'debug' );

    }

    else {
        $portal->abort( "Authentication choice "
              . $self->{_authChoice}
              . " value is invalid" );
    }

    return $self;
}

## @method int try(string sub,int type)
# Main method: try to call $sub method in the choosen module.
# If no choice, return default behavior
# @param sub name of the method to launch
# @param type 0 for authentication, 1 for userDB, 2 for passworDB
# @return Lemonldap::NG::Portal error code returned by method $sub
sub try {
    my ( $self, $sub, $type ) = @_;

    # Default behavior in no choice
    unless ( defined $self->{modules} ) {
        return PE_FIRSTACCESS if ( $sub eq 'extractFormInfo' );
        return PE_OK;
    }

    # Launch wanted subroutine
    my $s    = $self->{modules}->[$type]->{m} . "::$sub";
    my $name = $self->{modules}->[$type]->{n};

    $self->{p}
      ->lmLog( "Try to launch $sub on module $name (type $type)", 'debug' );

    return $self->{p}->$s();
}

package Lemonldap::NG::Portal::Simple;

## @method private Lemonldap::NG::Portal::_Choice _choice()
# Return Lemonldap::NG::Portal::_Choice object and builds it if it was not build
# before. This method is used if authentication is set to "Choice".
# @return Lemonldap::NG::Portal::_Choice object
sub _choice {
    my $self = shift;

    # Check if choice is already built
    return $self->{_choice} if ( $self->{_choice} );

    # Get authentication choice
    $self->{_authChoice} = $self->param( $self->{authChoiceParam} );

    # Check XSS Attack
    $self->{_authChoice} = ""
      if (  $self->{_authChoice}
        and
        $self->checkXSSAttack( $self->{authChoiceParam}, $self->{_authChoice} )
      );

    $self->lmLog( "Authentication choice found: " . $self->{_authChoice},
        'debug' )
      if $self->{_authChoice};

    return $self->{_choice} = Lemonldap::NG::Portal::_Choice->new($self);
}

## @method private Lemonldap::NG::Portal::_Choice _buildAuthLoop()
# Build authentication loop displayed in template
# @return authLoop rarray reference
sub _buildAuthLoop {
    my $self = shift;
    my @authLoop;

    # Test authentication choices
    unless ( ref $self->{authChoiceModules} eq 'HASH' ) {
        $self->lmLog( "No authentication choices defined", 'warn' );
        return [];
    }

    foreach ( sort keys %{ $self->{authChoiceModules} } ) {

        my $name = $_;

        # Name can have a digit as first character
        # for sorting purpose
        # Remove it in displayed name
        $name =~ s/^(\d*)?(\s*)?//;

        # Replace also _ by space for a nice display
        $name =~ s/\_/ /g;

        # Find modules associated to authChoice
        my ( $auth, $userDB, $passwordDB, $url ) =
          split( /[;\|]/, $self->{authChoiceModules}->{$_} );

        if ( $auth and $userDB and $passwordDB ) {

            # Default URL
            $url = ( defined $url ? $url .= $ENV{'REQUEST_URI'} : '#' );
            $self->lmLog( "Use URL $url", 'debug' );

            # Options to store in the loop
            my $optionsLoop =
              { name => $name, key => $_, module => $auth, url => $url };

            # Get displayType for this module
            my $modulePrefix = 'Lemonldap::NG::Portal::';
            my $authModule   = $modulePrefix . 'Auth' . $auth;
            $self->loadModule($authModule);
            my $displayType = &{ $authModule . '::getDisplayType' };

            $self->lmLog( "Display type $displayType for module $auth",
                'debug' );
            $optionsLoop->{$displayType} = 1;

            # If displayType is logo, check if key.png is available
            if (
                -e $self->getApacheHtdocsPath . "/skins/common/" . $_ . ".png" )
            {
                $optionsLoop->{logoFile} = $_ . ".png";
            }
            else { $optionsLoop->{logoFile} = $auth . ".png"; }

            # Register item in loop
            push @authLoop, $optionsLoop;

            $self->lmLog( "Authentication choice $name will be displayed",
                'debug' );
        }

        else {
            $self->abort("Authentication choice $_ value is invalid");
        }

    }

    return \@authLoop;

}

1;

