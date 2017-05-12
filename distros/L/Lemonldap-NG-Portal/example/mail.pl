#!/usr/bin/perl

use Lemonldap::NG::Portal::MailReset;
use HTML::Template;
use strict;

# Load portal module
my $portal = Lemonldap::NG::Portal::MailReset->new();

my $skin_dir   = $portal->getApacheHtdocsPath() . "/skins";
my $portal_url = $portal->{portal};
my $portalPath = $portal->{portal};
$portalPath =~ s#^https?://[^/]+/?#/#;
$portalPath =~ s#[^/]+\.pl$##;

# Process
$portal->process();

my $skin = $portal->getSkin();

# Template creation
my $template = HTML::Template->new(
    filename          => "$skin_dir/$skin/mail.tpl",
    die_on_bad_params => 0,
    cache             => 0,
    filter            => [
        sub { $portal->translate_template(@_) },
        sub { $portal->session_template(@_) }
    ],
);

$template->param(
    PORTAL_URL      => $portal_url,
    SKIN_PATH       => $portalPath . "skins",
    SKIN            => $skin,
    AUTH_ERROR      => $portal->error,
    AUTH_ERROR_TYPE => $portal->error_type,
    CHOICE_PARAM    => $portal->{authChoiceParam},
    CHOICE_VALUE    => $portal->{_authChoice},
    EXPMAILDATE     => $portal->{expMailDate},
    EXPMAILTIME     => $portal->{expMailTime},
    STARTMAILDATE   => $portal->{startMailDate},
    STARTMAILTIME   => $portal->{startMailTime},
    MAILALREADYSENT => $portal->{mail_already_sent},
    MAIL            => $portal->checkXSSAttack( 'mail', $portal->{mail} ) ? ""
    : $portal->{mail},
    MAIL_TOKEN => $portal->checkXSSAttack( 'mail_token', $portal->{mail_token} )
    ? ""
    : $portal->{mail_token},
);

# Display form the first time
if (
    (
           $portal->{error} == PE_MAILFORMEMPTY
        or $portal->{error} == PE_MAILFIRSTACCESS
        or $portal->{error} == PE_MAILNOTFOUND
        or $portal->{error} == PE_CAPTCHAERROR
        or $portal->{error} == PE_CAPTCHAEMPTY
    )
    and !$portal->{mail_token}
  )
{
    $template->param(
        DISPLAY_FORM            => 1,
        DISPLAY_RESEND_FORM     => 0,
        DISPLAY_CONFIRMMAILSENT => 0,
        DISPLAY_MAILSENT        => 0,
        DISPLAY_PASSWORD_FORM   => 0,
    );
}

# Display captcha if it's enabled
if ( $portal->{captcha_mail_enabled} ) {
    $template->param(
        CAPTCHA_IMG  => $portal->{captcha_img},
        CAPTCHA_CODE => $portal->{captcha_code},
        CAPTCHA_SIZE => $portal->{captcha_size}
    );
}

# Display mail confirmation resent form
if ( $portal->{error} == PE_MAILCONFIRMATION_ALREADY_SENT ) {
    $template->param(
        DISPLAY_FORM            => 0,
        DISPLAY_RESEND_FORM     => 1,
        DISPLAY_CONFIRMMAILSENT => 0,
        DISPLAY_MAILSENT        => 0,
        DISPLAY_PASSWORD_FORM   => 0,
    );
}

# Display confirmation mail sent
if ( $portal->{error} == PE_MAILCONFIRMOK ) {
    $template->param(
        DISPLAY_FORM            => 0,
        DISPLAY_RESEND_FORM     => 0,
        DISPLAY_CONFIRMMAILSENT => 1,
        DISPLAY_MAILSENT        => 0,
        DISPLAY_PASSWORD_FORM   => 0,
    );
}

# Display mail sent
if ( $portal->{error} == PE_MAILOK ) {
    $template->param(
        DISPLAY_FORM            => 0,
        DISPLAY_RESEND_FORM     => 0,
        DISPLAY_CONFIRMMAILSENT => 0,
        DISPLAY_MAILSENT        => 1,
        DISPLAY_PASSWORD_FORM   => 0,
    );
}

# Display password change form
if (    $portal->{mail_token}
    and $portal->{error} != PE_MAILERROR
    and $portal->{error} != PE_BADMAILTOKEN
    and $portal->{error} != PE_MAILOK )
{
    $template->param(
        DISPLAY_FORM            => 0,
        DISPLAY_RESEND_FORM     => 0,
        DISPLAY_CONFIRMMAILSENT => 0,
        DISPLAY_MAILSENT        => 0,
        DISPLAY_PASSWORD_FORM   => 1,
    );
}

# Custom template parameters
if ( my $customParams = $portal->getCustomTemplateParameters() ) {
    foreach ( keys %$customParams ) {
        $template->param( $_, $customParams->{$_} );
    }
}

print $portal->header('text/html; charset=utf-8');
print $template->output;

