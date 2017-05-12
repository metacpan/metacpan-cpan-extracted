##@file
# AD authentication backend file

##@class
# AD authentication backend class
package Lemonldap::NG::Portal::AuthAD;

use strict;

our $VERSION = '1.4.7';
use Lemonldap::NG::Portal::Simple;
use base qw(Lemonldap::NG::Portal::AuthLDAP);

*_formateFilter = *Lemonldap::NG::Portal::UserDBAD::formateFilter;
*getDisplayType = *Lemonldap::NG::Portal::AuthLDAP::getDisplayType;

## @apmethod int authInit()
# Add specific attributes for search
# @return Lemonldap::NG::Portal constant
sub authInit {
    my $self = shift;

    $self->{ldapExportedVars}->{_AD_pwdLastSet}         = 'pwdLastSet';
    $self->{ldapExportedVars}->{_AD_userAccountControl} = 'userAccountControl';
    $self->{ldapExportedVars}->{_AD_msDS_UACC} =
      'msDS-User-Account-Control-Computed';

    return $self->SUPER::authInit();
}

## @apmethod int authenticate()
# Authenticate user by LDAP mechanism.
# Check AD specific attribute to get password state.
# @return Lemonldap::NG::Portal constant
sub authenticate {
    my $self = shift;

    my $res = $self->SUPER::authenticate;

    unless ( $res == PE_OK ) {

        # Check specific AD attributes
        my $pls      = $self->{sessionInfo}->{_AD_pwdLastSet};
        my $computed = $self->{sessionInfo}->{_AD_msDS_UACC};
        my $mask = 0xf00000;    # mask to get the 8 at 6th position
        my $expired_flag =
          0x800000;   # 8 at 6th position for flag UF_PASSWORD_EXPIRED to be set
        if ( ( $computed & $mask ) == $expired_flag ) {
            $self->lmLog( "[AD] Password has expired", 'warn' );
            $res = PE_PP_PASSWORD_EXPIRED;
        }

        # Password must be changed if pwdLastSet 0
        if ( defined $pls and $pls == 0 ) {
            $self->lmLog( "[AD] Password reset. User must change his password",
                'warn' );
            $res = PE_PP_CHANGE_AFTER_RESET;
        }

    }
    else {

        # Getting password max age (delay)
        my $ADPwdMaxAge = $self->{ADPwdMaxAge} || 0;
        $ADPwdMaxAge *= 10000000; # padding with '0' to obtain 0.1 micro-seconds

        # Getting password expiration warning time (delay)
        my $ADPwdExpireWarning = $self->{ADPwdExpireWarning} || 0;
        $ADPwdExpireWarning *=
          10000000;               # padding with '0' to obtain 0.1 micro-seconds

        if ( $ADPwdExpireWarning > $ADPwdMaxAge ) {
            $ADPwdExpireWarning = $ADPwdMaxAge;
            $self->lmLog(
"Error: ADPwdExpireWarning > ADPwdMaxAge, this should not happen",
                'warn'
            );
        }

        # get userAccountControl to ckeck password expiration flags
        my $_adUac = $self->{sessionInfo}->{_AD_userAccountControl} || 0;

        # Compute current timestamp in AD format (date)
        my $time = time;    # unix timestamp (seconds since Jan 01 1970)
        my $a_time =
          $time + 11644473600;    # adding difference (in s) from Jan 01 1601
        my $timestamp =
          $a_time . '0000000';   # padding with '0' to obatin 0.1 micro-seconds

        # Compute password expiration time (date)
        my $_pwdExpire = $self->{sessionInfo}->{_AD_pwdLastSet} || $timestamp;
        $_pwdExpire += $ADPwdMaxAge;

# computing when the warning message is displayed on portal (date - delay = date)
        my $_pwdWarning = $_pwdExpire - $ADPwdExpireWarning;

        # display warning if account warning time before expiration is
        # reached and flag "password nevers expires" is not set
        if (   $timestamp > $_pwdWarning
            && $timestamp < $_pwdExpire
            && ( $_adUac & 0x10000 ) != 0x10000 )
        {

            # calculating remaining time before password expiration
            my $remainingTime = $_pwdExpire - $timestamp;
            $self->info(
                "<h3>"
                  . sprintf(
                    $self->msg(PM_PP_EXP_WARNING),
                    $self->convertSec(
                        substr( $remainingTime, 0, length($remainingTime) - 7 )
                    )
                  )
                  . "</h3>"
            );
        }

    }

    # Remember password if password reset needed
    $self->{oldpassword} = $self->{password}
      if ( $res == PE_PP_CHANGE_AFTER_RESET );

    return $res;
}

1;
