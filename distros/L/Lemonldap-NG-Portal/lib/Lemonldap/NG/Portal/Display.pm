## @file
# Display functions for LemonLDAP::NG Portal

## @class
# Display functions for LemonLDAP::NG Portal
package Lemonldap::NG::Portal::Display;

use strict;
use Lemonldap::NG::Portal::Simple;
use utf8;

our $VERSION = '1.4.0';

## @method array display()
# Call portal process and set template parameters
# @return template name and template parameters
sub display {
    my $self = shift;

    my $skin_dir = $self->getApacheHtdocsPath() . "/skins";
    my ( $skinfile, %templateParams );
    my $http_error = $self->param('lmError');

    # 0. Display error page
    if ($http_error) {

        $skinfile = 'error.tpl';

        # Error code
        my $error500 = 1 if ( $http_error eq "500" );
        my $error403 = 1 if ( $http_error eq "403" );
        my $error503 = 1 if ( $http_error eq "503" );

        # Check URL
        $self->_sub('controlUrlOrigin');

        # Load session content
        $self->_sub('controlExistingSession');

        %templateParams = (
            PORTAL_URL => $self->{portal},
            LOGOUT_URL => $self->{portal} . "?logout=1",
            URL        => $self->{urldc},
            ERROR403   => $error403,
            ERROR500   => $error500,
            ERROR503   => $error503,
        );

    }

    # 1. Good authentication
    elsif ( $self->process() ) {

        # 1.1 Image mode
        if ( $self->{error} == PE_IMG_OK || $self->{error} == PE_IMG_NOK ) {
            $skinfile = "$skin_dir/common/"
              . (
                $self->{error} == PE_IMG_OK
                ? 'ok.png'
                : 'warning.png'
              );
            $self->printImage( $skinfile, 'image/png' );
            exit;
        }

        # 1.2 Case : there is a message to display
        elsif ( my $info = $self->info() ) {
            $skinfile       = 'info.tpl';
            %templateParams = (
                AUTH_ERROR_TYPE => $self->error_type,
                MSG             => $info,
                URL             => $self->{urldc},
                HIDDEN_INPUTS   => $self->buildHiddenForm(),
                ACTIVE_TIMER    => $self->{activeTimer},
                FORM_METHOD     => $self->{infoFormMethod},
            );
        }

        # 1.3 Redirection
        elsif ( $self->{error} == PE_REDIRECT ) {
            $skinfile       = "redirect.tpl";
            %templateParams = (
                URL           => $self->{urldc},
                HIDDEN_INPUTS => $self->buildHiddenForm(),
                FORM_METHOD   => $self->{redirectFormMethod},
            );
        }

        # 1.4 Case : display menu
        else {

            # Initialize menu elements
            $self->_sub('menuInit');

            $skinfile = 'menu.tpl';
            my $auth_user = $self->{sessionInfo}->{ $self->{portalUserAttr} };
            utf8::decode($auth_user);

            %templateParams = (
                AUTH_USER           => $auth_user,
                AUTOCOMPLETE        => $self->{portalAutocomplete},
                NEWWINDOW           => $self->{portalOpenLinkInNewWindow},
                AUTH_ERROR          => $self->error( $self->{menuError} ),
                AUTH_ERROR_TYPE     => $self->error_type( $self->{menuError} ),
                DISPLAY_TAB         => $self->{menuDisplayTab},
                LOGOUT_URL          => "$ENV{SCRIPT_NAME}?logout=1",
                REQUIRE_OLDPASSWORD => $self->{portalRequireOldPassword},
                HIDE_OLDPASSWORD =>
                  0,    # Do not hide old password if it is required
                DISPLAY_MODULES => $self->{menuDisplayModules},
                APPSLIST_MENU => $self->{menuAppslistMenu},  # For old templates
                APPSLIST_DESC => $self->{menuAppslistDesc},  # For old templates
                SCRIPT_NAME   => $ENV{SCRIPT_NAME},
                APPSLIST_ORDER => $self->{sessionInfo}->{'appsListOrder'},
                PING           => $self->{portalPingInterval},
            );

        }
    }

    # 2. Authentication not complete

 # 2.1 A notification has to be done (session is created but hidden and unusable
 #     until the user has accept the message)
    elsif ( my $notif = $self->notification ) {
        $skinfile       = 'notification.tpl';
        %templateParams = (
            AUTH_ERROR_TYPE => $self->error_type,
            NOTIFICATION    => $notif,
            HIDDEN_INPUTS   => $self->buildHiddenForm(),
            AUTH_URL        => $self->get_url,
            CHOICE_PARAM    => $self->{authChoiceParam},
            CHOICE_VALUE    => $self->{_authChoice},
        );
    }

    # 2.2 An authentication (or userDB) module needs to ask a question
    #     before processing to the request
    elsif ( $self->{error} == PE_CONFIRM ) {
        $skinfile       = 'confirm.tpl';
        %templateParams = (
            AUTH_ERROR      => $self->error,
            AUTH_ERROR_TYPE => $self->error_type,
            AUTH_URL        => $self->get_url,
            MSG             => $self->info(),
            HIDDEN_INPUTS   => $self->buildHiddenForm(),
            ACTIVE_TIMER    => $self->{activeTimer},
            FORM_METHOD     => $self->{confirmFormMethod},
            CHOICE_PARAM    => $self->{authChoiceParam},
            CHOICE_VALUE    => $self->{_authChoice},
            CHECK_LOGINS    => $self->{portalCheckLogins} && $self->{login},
            ASK_LOGINS      => $self->{checkLogins},
            CONFIRMKEY      => $self->stamp(),
            LIST            => $self->{list} || [],
        );
    }

    # 2.3 There is a message to display
    elsif ( my $info = $self->info() ) {
        $skinfile       = 'info.tpl';
        %templateParams = (
            AUTH_ERROR      => $self->error,
            AUTH_ERROR_TYPE => $self->error_type,
            MSG             => $info,
            URL             => $self->{urldc},
            HIDDEN_INPUTS   => $self->buildHiddenForm(),
            ACTIVE_TIMER    => $self->{activeTimer},
            FORM_METHOD     => $self->{infoFormMethod},
            CHOICE_PARAM    => $self->{authChoiceParam},
            CHOICE_VALUE    => $self->{_authChoice},
        );
    }

    # 2.4 OpenID menu page
    elsif ($self->{error} == PE_OPENID_EMPTY
        or $self->{error} == PE_OPENID_BADID )
    {
        $skinfile = 'openid.tpl';
        my $p = $self->{portal} . $self->{issuerDBOpenIDPath};
        $p =~ s#(?<!:)/\^?/#/#g;
        %templateParams = (
            AUTH_ERROR      => $self->error,
            AUTH_ERROR_TYPE => $self->error_type,
            PROVIDERURI     => $p,
            ID              => $self->{_openidPortal}
              . $self->{sessionInfo}
              ->{ $self->{openIdAttr} || $self->{whatToTrace} },
            PORTAL_URL => $self->{portal},
            MSG        => $self->info(),
        );
    }

    # 2.5 Authentication has been refused OR this is the first access
    else {
        $skinfile       = 'login.tpl';
        %templateParams = (
            AUTH_ERROR            => $self->error,
            AUTH_ERROR_TYPE       => $self->error_type,
            AUTH_URL              => $self->get_url,
            LOGIN                 => $self->get_user,
            AUTOCOMPLETE          => $self->{portalAutocomplete},
            CHECK_LOGINS          => $self->{portalCheckLogins},
            ASK_LOGINS            => $self->{checkLogins},
            DISPLAY_RESETPASSWORD => $self->{portalDisplayResetPassword},
            DISPLAY_REGISTER      => $self->{portalDisplayRegister},
            MAIL_URL              => $self->{mailUrl},
            REGISTER_URL          => $self->{registerUrl},
            HIDDEN_INPUTS         => $self->buildHiddenForm(),
            LOGIN_INFO            => $self->loginInfo(),
        );

        # Display captcha if it's enabled
        if ( $self->{captcha_login_enabled} ) {
            %templateParams = (
                %templateParams,
                CAPTCHA_IMG  => $self->{captcha_img},
                CAPTCHA_CODE => $self->{captcha_code},
                CAPTCHA_SIZE => $self->{captcha_size}
            );
        }

        # Show password form if password policy error
        if (

               $self->{error} == PE_PP_CHANGE_AFTER_RESET
            or $self->{error} == PE_PP_MUST_SUPPLY_OLD_PASSWORD
            or $self->{error} == PE_PP_INSUFFICIENT_PASSWORD_QUALITY
            or $self->{error} == PE_PP_PASSWORD_TOO_SHORT
            or $self->{error} == PE_PP_PASSWORD_TOO_YOUNG
            or $self->{error} == PE_PP_PASSWORD_IN_HISTORY
            or $self->{error} == PE_PASSWORD_MISMATCH
            or $self->{error} == PE_BADOLDPASSWORD
            or $self->{error} == PE_PASSWORDFORMEMPTY
          )
        {
            %templateParams = (
                %templateParams,
                REQUIRE_OLDPASSWORD =>
                  1,    # Old password is required to check user credentials
                DISPLAY_FORM          => 0,
                DISPLAY_OPENID_FORM   => 0,
                DISPLAY_YUBIKEY_FORM  => 0,
                DISPLAY_PASSWORD      => 1,
                DISPLAY_RESETPASSWORD => 0,
                AUTH_LOOP             => [],
                CHOICE_PARAM          => $self->{authChoiceParam},
                CHOICE_VALUE          => $self->{_authChoice},
                OLDPASSWORD =>
                  $self->checkXSSAttack( 'oldpassword', $self->{oldpassword} )
                ? ""
                : $self->{oldpassword},
                HIDE_OLDPASSWORD => $self->{hideOldPassword},
            );
        }

        # Disable all forms on:
        # * Logout message
        # * Bad URL error
        elsif ($self->{error} == PE_LOGOUT_OK
            or $self->{error} == PE_BADURL )
        {
            %templateParams = (
                %templateParams,
                DISPLAY_RESETPASSWORD => 0,
                DISPLAY_FORM          => 0,
                DISPLAY_OPENID_FORM   => 0,
                DISPLAY_YUBIKEY_FORM  => 0,
                AUTH_LOOP             => [],
                PORTAL_URL            => $self->{portal},
                MSG                   => $self->info(),
            );

        }

        # Display authentifcation form
        else {

            # Authentication loop
            if ( $self->{authLoop} ) {
                %templateParams = (
                    %templateParams,
                    AUTH_LOOP            => $self->{authLoop},
                    CHOICE_PARAM         => $self->{authChoiceParam},
                    CHOICE_VALUE         => $self->{_authChoice},
                    DISPLAY_FORM         => 0,
                    DISPLAY_OPENID_FORM  => 0,
                    DISPLAY_YUBIKEY_FORM => 0,
                );
            }

            # Choose what form to display if not in a loop
            else {

                my $displayType = $self->getDisplayType();

                $self->lmLog( "Display type $displayType ", 'debug' );

                %templateParams = (
                    %templateParams,
                    DISPLAY_FORM => $displayType eq "standardform" ? 1 : 0,
                    DISPLAY_OPENID_FORM => $displayType eq "openidform" ? 1 : 0,
                    DISPLAY_YUBIKEY_FORM => $displayType eq "yubikeyform" ? 1
                    : 0,
                    DISPLAY_LOGO_FORM => $displayType eq "logo" ? 1 : 0,
                    module => $displayType eq "logo" ? $self->get_module('auth')
                    : "",
                    AUTH_LOOP  => [],
                    PORTAL_URL => $displayType eq "logo" ? $self->{portal} : 0,
                    MSG        => $self->info(),
                );

            }

        }

    }

    ## Common template params
    my $skin       = $self->getSkin();
    my $portalPath = $self->{portal};
    $portalPath =~ s#^https?://[^/]+/?#/#;
    $portalPath =~ s#[^/]+\.pl$##;
    %templateParams = (
        %templateParams,
        SKIN_PATH => $portalPath . "skins",
        SKIN      => $skin,
        ANTIFRAME => $self->{portalAntiFrame},
    );

    ## Custom template params
    if ( my $customParams = $self->getCustomTemplateParameters() ) {
        %templateParams = ( %templateParams, %$customParams );
    }

    return ( "$skin_dir/$skin/$skinfile", %templateParams );

}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::Display - Display functions for LemonLDAP::NG Portal

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::SharedConf;
  use HTML::Template;

  my $portal = Lemonldap::NG::Portal::SharedConf->new();

  my($templateName,%templateParams) = $portal->display();

  my $template = HTML::Template->new(
    filename => $templateName,
    die_on_bad_params => 0,
    cache => 0,
    global_vars => 1,
    filter => sub { $portal->translate_template(@_) }
  );
  while ( my ( $k, $v ) = each %templateParams ) { $template->param( $k, $v ); }

  print $portal->header('text/html; charset=utf-8');
  print $template->output;

=head1 DESCRIPTION

This module is used to build all templates parameters to display
LemonLDAP::NG Portal

=head1 SEE ALSO

L<Lemonldap::NG::Portal>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2010, 2012 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012 by Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=item Copyright (C) 2012 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Copyright (C) 2010, 2011, 2012, 2013 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Copyright (C) 2011 by Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut

