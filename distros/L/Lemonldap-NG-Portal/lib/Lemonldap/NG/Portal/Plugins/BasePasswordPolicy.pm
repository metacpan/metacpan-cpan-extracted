package Lemonldap::NG::Portal::Plugins::BasePasswordPolicy;

use strict;
use warnings;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_PP_PASSWORD_TOO_SHORT
  PE_PP_NOT_ALLOWED_CHARACTER
  PE_PP_NOT_ALLOWED_CHARACTERS
  PE_PP_INSUFFICIENT_PASSWORD_QUALITY
);

our $VERSION = '2.18.0';

extends 'Lemonldap::NG::Portal::Main::Plugin';

use constant hook => { passwordBeforeChange => 'checkPasswordQuality', };
has pwdPolicyRule => ( is => 'rw' );

sub init {
    my ($self) = @_;

    my $pwdPolicyRule = $self->p->buildRule(
        $self->conf->{passwordPolicyActivation},
        "Password policy activation rule"
    );
    $self->pwdPolicyRule($pwdPolicyRule);
    return 0 unless $pwdPolicyRule;

    $self->p->addPasswordPolicyDisplay(
        'ppolicy-minsize',
        {
            condition => $self->conf->{passwordPolicyMinSize},
            value     => $self->conf->{passwordPolicyMinSize},
            label     => "passwordPolicyMinSize",
            order => 101,
        }
    );

    $self->p->addPasswordPolicyDisplay(
        'ppolicy-minlower',
        {
            condition => $self->conf->{passwordPolicyMinLower},
            value     => $self->conf->{passwordPolicyMinLower},
            label     => "passwordPolicyMinLower",
            order => 102,
        }
    );
    $self->p->addPasswordPolicyDisplay(
        'ppolicy-minupper',
        {
            condition => $self->conf->{passwordPolicyMinUpper},
            value     => $self->conf->{passwordPolicyMinUpper},
            label     => "passwordPolicyMinUpper",
            order => 103,
        }
    );
    $self->p->addPasswordPolicyDisplay(
        'ppolicy-mindigit',
        {
            condition => $self->conf->{passwordPolicyMinDigit},
            value     => $self->conf->{passwordPolicyMinDigit},
            label     => "passwordPolicyMinDigit",
            order => 104,
        }
    );
    $self->p->addPasswordPolicyDisplay(
        'ppolicy-minspechar',
        {
            condition => (
                     $self->conf->{passwordPolicyMinSpeChar}
                  && $self->conf->{passwordPolicySpecialChar}
            ),
            value => $self->conf->{passwordPolicyMinSpeChar},
            label => "passwordPolicyMinSpeChar",
            order => 105,
        }
    );
    $self->p->addPasswordPolicyDisplay(
        'ppolicy-allowedspechar',
        {
            condition => (
                $self->conf->{passwordPolicyMinSpeChar} && $self->p->speChars()
            ),
            value => $self->p->speChars(),
            label => "passwordPolicySpecialChar",
            order => 106,
        }
    );

    return 1;
}

sub checkPasswordQuality {
    my ( $self, $req, $user, $password, $old ) = @_;
    if ( $self->pwdPolicyRule->( $req, $req->userData ) ) {
        $self->logger->debug("Checking basic password policy for $user");
        return $self->checkBasicPolicy($password);
    }
    else {
        $self->logger->debug("Skipping basic password policy for $user");
        return PE_OK;
    }
}

sub checkBasicPolicy {
    my ( $self, $password, $old ) = @_;

    # Min size
    if ( $self->conf->{passwordPolicyMinSize}
        and length($password) < $self->conf->{passwordPolicyMinSize} )
    {
        $self->logger->error("Password too short");
        return PE_PP_PASSWORD_TOO_SHORT;
    }

    # Min lower
    if ( $self->conf->{passwordPolicyMinLower} ) {
        my $lower = 0;
        $lower++ while ( $password =~ m/\p{lowercase}/g );
        if ( $lower < $self->conf->{passwordPolicyMinLower} ) {
            $self->logger->error("Password has not enough lower characters");
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
        }
    }

    # Min upper
    if ( $self->conf->{passwordPolicyMinUpper} ) {
        my $upper = 0;
        $upper++ while ( $password =~ m/\p{uppercase}/g );
        if ( $upper < $self->conf->{passwordPolicyMinUpper} ) {
            $self->logger->error("Password has not enough upper characters");
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
        }
    }

    # Min digit
    if ( $self->conf->{passwordPolicyMinDigit} ) {
        my $digit = 0;
        $digit++ while ( $password =~ m/\d/g );
        if ( $digit < $self->conf->{passwordPolicyMinDigit} ) {
            $self->logger->error("Password has not enough digit characters");
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
        }
    }

    ### Special characters policy
    my $speChars = $self->conf->{passwordPolicySpecialChar};

    ## Min special characters
    # Just number of special characters must be checked
    if ( $self->conf->{passwordPolicyMinSpeChar} && $speChars eq '__ALL__' ) {
        my $spe = $password =~ s/[\W_]//g;
        if ( $spe < $self->conf->{passwordPolicyMinSpeChar} ) {
            $self->logger->error("Password has not enough special characters");
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
        }
        return PE_OK;
    }

    # Check number of special characters
    if ( $self->conf->{passwordPolicyMinSpeChar} && $speChars ) {
        my $test = $password;
        my $spe  = $test =~ s/[\Q$speChars\E]//g;
        if ( $spe < $self->conf->{passwordPolicyMinSpeChar} ) {
            $self->logger->error("Password has not enough special characters");
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY;
        }
    }

    ## Fobidden special characters
    unless ( $speChars eq '__ALL__' ) {
        $password =~ s/[\Q$speChars\E\w]//g;
        if ($password) {
            $self->logger->error( 'Password contains '
                  . length($password)
                  . " forbidden character(s): $password" );
            return length($password) > 1
              ? PE_PP_NOT_ALLOWED_CHARACTERS
              : PE_PP_NOT_ALLOWED_CHARACTER;
        }
    }

    return PE_OK;
}

1;
