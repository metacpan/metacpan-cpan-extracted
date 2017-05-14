##@file
# Web form authentication backend file

##@class
# Web form authentication backend class
package Lemonldap::NG::Portal::_WebForm;

use Lemonldap::NG::Portal::Simple qw(:all);
use strict;

our $VERSION = '1.9.1';

## @apmethod int authInit()
# Does nothing.
# @return Lemonldap::NG::Portal constant
sub authInit {
    PE_OK;
}

## @apmethod int extractFormInfo()
# Read username and password from POST datas
# @return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;

    # Init captcha
    if ( $self->{captcha_login_enabled} ) {
        eval { $self->initCaptcha(); };
        $self->lmLog( "Can't init captcha: $@", "error" ) if $@;
    }

    # Detect first access and empty forms
    my $defUser        = defined $self->param('user');
    my $defPassword    = defined $self->param('password');
    my $defOldPassword = defined $self->param('oldpassword');

    # 1. No user defined at all -> first access
    return PE_FIRSTACCESS unless $defUser;

    # 2. If user and password defined -> login form
    if ( $defUser && $defPassword ) {
        return PE_FORMEMPTY
          unless ( ( $self->{user} = $self->param('user') )
            && ( $self->{password} = $self->param('password') ) );
    }

    # 3. If user and oldpassword defined -> password form
    if ( $defUser && $defOldPassword ) {
        return PE_PASSWORDFORMEMPTY
          unless ( ( $self->{user} = $self->param('user') )
            && ( $self->{oldpassword}     = $self->param('oldpassword') )
            && ( $self->{newpassword}     = $self->param('newpassword') )
            && ( $self->{confirmpassword} = $self->param('confirmpassword') ) );
    }

    # 4. Captcha for login form
    if ( $self->{captcha_login_enabled} && $defUser && $defPassword ) {
        $self->{captcha_user_code}  = $self->param('captcha_user_code');
        $self->{captcha_check_code} = $self->param('captcha_code');

        unless ( $self->{captcha_user_code} && $self->{captcha_check_code} ) {
            $self->lmLog( "Captcha not filled", 'warn' );
            return PE_CAPTCHAEMPTY;
        }

        $self->lmLog(
            "Captcha data received: "
              . $self->{captcha_user_code} . " and "
              . $self->{captcha_check_code},
            'debug'
        );

        # Check captcha
        my $captcha_result = $self->checkCaptcha( $self->{captcha_user_code},
            $self->{captcha_check_code} );

        if ( $captcha_result != 1 ) {
            if (   $captcha_result == -3
                or $captcha_result == -2 )
            {
                $self->lmLog( "Captcha failed: wrong code", 'warn' );
                return PE_CAPTCHAERROR;
            }
            elsif ( $captcha_result == 0 ) {
                $self->lmLog( "Captcha failed: code not checked (file error)",
                    'warn' );
                return PE_CAPTCHAERROR;
            }
            elsif ( $captcha_result == -1 ) {
                $self->lmLog( "Captcha failed: code has expired", 'warn' );
                return PE_CAPTCHAERROR;
            }
        }
        $self->lmLog( "Captcha code verified", 'debug' );
    }

    # Other parameters
    $self->{timezone} = $self->param('timezone');

    # Check user
    return PE_MALFORMEDUSER unless $self->get_user;

    PE_OK;
}

## @apmethod int setAuthSessionInfo()
# Set password in session datas if wanted.
# @return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    # authenticationLevel
    # +1 for user/password with HTTPS
    $self->{_authnLevel} ||= 0;
    $self->{_authnLevel} += 1 if $self->https();

    $self->{sessionInfo}->{authenticationLevel} = $self->{_authnLevel};

    # Store user submitted login for basic rules
    $self->{sessionInfo}->{'_user'} = $self->{'user'};

    # Store submitted password if set in configuration
    # WARNING: it can be a security hole
    if ( $self->{storePassword} ) {
        $self->{sessionInfo}->{'_password'} = $self->{'newpassword'}
          || $self->{'password'};
    }

    # Store user timezone
    $self->{sessionInfo}->{'_timezone'} = $self->{'timezone'};

    PE_OK;
}

1;
