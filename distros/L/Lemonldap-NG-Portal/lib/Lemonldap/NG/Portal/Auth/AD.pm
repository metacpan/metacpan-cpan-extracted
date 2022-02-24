# Auth::AD inherits from Auth::LDAP. It defines some additional configuration
# parameters and manage AD password expiration

package Lemonldap::NG::Portal::Auth::AD;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_PP_PASSWORD_EXPIRED
  PE_PP_CHANGE_AFTER_RESET
  PE_BADCREDENTIALS
);

our $VERSION = '2.0.14';

extends 'Lemonldap::NG::Portal::Auth::LDAP';

# PROPERTIES

has adPwdMaxAge => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $conf = $_[0]->{conf};
        my $res  = $conf->{ADPwdMaxAge} || 0;
        return $res * 10000000;   # padding with '0' to obtain 0.1 micro-seconds
    }
);

has adPwdExpireWarning => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $conf = $_[0]->{conf};
        my $res  = $conf->{ADPwdExpireWarning} || 0;
        return $res * 10000000;   # padding with '0' to obtain 0.1 micro-seconds
    }
);

# AD timestamp starts from Jan 01 1601 and is defined in 0.1 micro seconds.
# This method converts Unix timestamp into AD timestamp.
sub adTime {
    return ( time + 11644473600 ) * 10000000;
}

# INITIALIZATION
# update LDAP configuration
sub init {
    my ($self) = @_;

    $self->conf->{ldapExportedVars}->{_AD_pwdLastSet} = 'pwdLastSet';
    $self->conf->{ldapExportedVars}->{_AD_userAccountControl} =
      'userAccountControl';
    $self->conf->{ldapExportedVars}->{_AD_msDS_UACC} =
      'msDS-User-Account-Control-Computed';

    if ( $self->adPwdExpireWarning > $self->adPwdMaxAge ) {
        $self->adPwdExpireWarning( $self->adPwdMaxAge );
        $self->logger->warn(
            "Error: ADPwdExpireWarning > ADPwdMaxAge, this should not happen",
        );
    }
    return $self->SUPER::init();
}

# RUNNING METHODS

sub authenticate {
    my ( $self, $req ) = @_;
    my $res = $self->SUPER::authenticate($req);

    my $pls =
      $self->ldap->getLdapValue( $req->data->{ldapentry}, 'pwdLastSet' );
    my $computed = $self->ldap->getLdapValue( $req->data->{ldapentry},
        'msDS-User-Account-Control-Computed' );
    my $_adUac =
      $self->ldap->getLdapValue( $req->data->{ldapentry}, 'userAccountControl' )
      || 0;

    unless ( $res == PE_OK ) {

        # Explicit bad credentials message
        if (    $req->data->{ldapError}
            and $req->data->{ldapError} =~ /LdapErr: .* data ([^,]+),.*/ )
        {
            if ( $1 eq '52e' ) {
                return PE_BADCREDENTIALS;
            }
        }

        # Check specific AD attributes
        my $mask = 0xf00000;    # mask to get the 8 at 6th position
        my $expired_flag =
          0x800000;   # 8 at 6th position for flag UF_PASSWORD_EXPIRED to be set
        if ( ( $computed & $mask ) == $expired_flag ) {
            $self->userLogger->warn("[AD] Password has expired");
            $res = PE_PP_PASSWORD_EXPIRED;
        }

        # Password must be changed if pwdLastSet 0
        if ( defined $pls and $pls == 0 ) {
            $self->userLogger->warn(
                "[AD] Password reset. User must change his password");
            $res = PE_PP_CHANGE_AFTER_RESET;
        }

    }
    else {
        my $timestamp = $self->adTime;

        # Compute password expiration time (date)
        my $_pwdExpire = $pls || $timestamp;
        $_pwdExpire += $self->adPwdMaxAge;

        # computing when the warning message is displayed on portal
        # (date - delay = date)
        my $_pwdWarning = $_pwdExpire - $self->adPwdExpireWarning;

        # display warning if account warning time before expiration is
        # reached and flag "password nevers expires" is not set
        if (   $timestamp > $_pwdWarning
            && $timestamp < $_pwdExpire
            && ( $_adUac & 0x10000 ) != 0x10000 )
        {

            # calculating remaining time before password expiration
            my $remainingTime = $_pwdExpire - $timestamp;
            $req->info(
                $self->loadTemplate(
                    $req,
                    'pwdWillExpire',
                    params => {
                        time => join(
                            ',',
                            $self->ldap->convertSec(
                                substr(
                                    $remainingTime, 0,
                                    length($remainingTime) - 7
                                )
                            )
                        )
                    }
                )
            );
        }

    }

    # Remember password if password reset needed
    if (
        $res == PE_PP_CHANGE_AFTER_RESET
        or (    $res == PE_PP_PASSWORD_EXPIRED
            and $self->conf->{ldapAllowResetExpiredPassword} )
      )
    {
        $req->data->{oldpassword} = $req->data->{password};    # Fix 2377
        $req->data->{noerror}     = 1;
        $self->setSecurity($req);
    }

    return $res;
}

# Define which error codes will stop Combination process
# @param res error code
# @return result 1 if stop is needed
sub stop {
    my ( $self, $res ) = @_;

    return 1
      if ( $res == PE_PP_PASSWORD_EXPIRED
        or $res == PE_PP_CHANGE_AFTER_RESET );
    return 0;
}

1;
