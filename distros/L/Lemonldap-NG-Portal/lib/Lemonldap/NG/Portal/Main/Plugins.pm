# This module loads known enabled plugins. To add custom modules, just add them
# into "plugins" list in lemonldap-ng.ini, section "portal"
package Lemonldap::NG::Portal::Main::Plugins;

our $VERSION = '2.21.0';

package Lemonldap::NG::Portal::Main;

use strict;
use Mouse;

# Plugins enabled by a simple boolean value (ordered list)
#
# Developers: 2FA must be loaded before Notifications
# Developers: GlobalLogout must be the last loaded plugin
# Developers: Notifications must be loaded before PublicNotifications
our @pList = (
    portalDisplayResetPassword          => '::Plugins::MailPasswordReset',
    portalDisplayCertificateResetByMail => '::Plugins::CertificateResetByMail',
    cda                                 => '::Plugins::CDA',
    notification                        => '::Plugins::Notifications',
    publicNotifications                 => '::Plugins::PublicNotifications',
    rememberAuthChoiceRule              => '::Plugins::RememberAuthChoice',
    stayConnected                       => '::Plugins::StayConnected',
    portalCheckLogins                   => '::Plugins::History',
    bruteForceProtection                => '::Plugins::BruteForceProtection',
    grantSessionRules                   => '::Plugins::GrantSession',
    upgradeSession                      => '::Plugins::Upgrade',
    autoSigninRules                     => '::Plugins::AutoSignin',
    checkState                          => '::Plugins::CheckState',
    portalForceAuthn                    => '::Plugins::ForceAuthn',
    checkUser                           => '::Plugins::CheckUser',
    checkDevOps                         => '::Plugins::CheckDevOps',
    contextSwitchingRule                => '::Plugins::ContextSwitching',
    decryptValueRule                    => '::Plugins::DecryptValue',
    findUser                            => '::Plugins::FindUser',
    newLocationWarning                  => '::Plugins::NewLocationWarning',
    passwordPolicyActivation            => '::Plugins::BasePasswordPolicy',
    checkHIBP                           => '::Plugins::CheckHIBP',
    checkEntropy                        => '::Plugins::CheckEntropy',
    initializePasswordReset             => '::Plugins::InitializePasswordReset',
    adaptativeAuthenticationLevelRules  =>
      '::Plugins::AdaptativeAuthenticationLevel',
    refreshSessions     => '::Plugins::Refresh',
    crowdsec            => '::Plugins::CrowdSec',
    locationDetect      => '::Plugins::LocationDetect',
    globalLogoutRule    => '::Plugins::GlobalLogout',
    samlFederationFiles => '::Plugins::SamlFederation',
    'or::oidcRPMetaDataOptions/*/oidcRPMetaDataOptionsAllowNativeSso' =>
      '::Plugins::OIDCNativeSso',
    'or::oidcOPMetaDataOptions/*/oidcOPMetaDataOptionsRequirePkce' =>
      '::Plugins::AuthOidcPkce',
    'or::oidcRPMetaDataOptions/*/oidcRPMetaDataOptionsTokenXAuthorizedRP' =>
      '::Plugins::OIDCInternalTokenExchange',
);

##@method list enabledPlugins
#
#@return list of enabled plugins
#
# List can be:
#  * a plugin name
#  * an array ref containing:
#    - the property into which the plugin has to be linked
#    - the plugin name
#
# If plugin name starts with '::', the prefix Lemonldap::NG::Portal will be
# added

sub enabledServices {
    my ($self) = @_;
    my $conf = $self->conf;
    my @res;

    # Second factor
    push @res, [ secondFactor => $self->conf->{'sfEngine'} ];

    # Portal menu
    push @res, [ menu => "::Main::Menu" ];

    # Trusted browser
    if ( $self->conf->{trustedBrowserRule} or $self->conf->{stayConnected} ) {
        my $module =
          $self->conf->{'trustedBrowserEngine'} || '::Plugins::TrustedBrowser';
        $self->logger->debug("$module needed");
        push @res, [ trustedBrowser => $module ];
    }

    # Captcha
    if (   $self->conf->{captcha_mail_enabled}
        || $self->conf->{captcha_login_enabled}
        || $self->conf->{captcha_register_enabled} )
    {
        my $module = $self->conf->{'captcha'} || '::Captcha::SecurityImage';
        $self->logger->debug("$module needed");
        push @res, [ captcha => $module ];
    }
    return @res;
}

sub enabledPlugins {
    my ($self) = @_;
    my $conf = $self->conf;
    my @res;

    # Search for Issuer* modules enabled
    foreach my $key (qw(SAML OpenID CAS OpenIDConnect Get JitsiMeetTokens)) {
        if ( $conf->{"issuerDB${key}Activation"} ) {
            $self->logger->debug("Issuer${key} enabled");
            push @res, "::Issuer::$key";
        }
    }

    # Load single session
    push @res, '::Plugins::SingleSession'
      if ( $conf->{singleSession}
        or $conf->{singleIP}
        or $conf->{singleUserByIP}
        or $conf->{notifyOther} );

    # Load static plugin list
    for ( my $i = 0 ; $i < @pList ; $i += 2 ) {
        my $pluginConf;
        if ( $pList[$i] =~ /^(.*?)::(.*)$/ ) {
            $pluginConf = checkConf( $conf, $2, $1 );
        }
        else {
            my $c = $conf->{ $pList[$i] };
            $pluginConf = ( ref($c) && ref($c) eq 'HASH' ? scalar(%$c) : $c );
        }
        push @res, $pList[ $i + 1 ] if $pluginConf;
    }

    # Check if SOAP is enabled
    push @res, '::Plugins::SOAPServer'
      if ( $conf->{soapSessionServer}
        or $conf->{soapConfigServer} );

    # Add REST (check is done by plugin itself)
    push @res, '::Plugins::RESTServer';

    # Check if password is enabled
    if ( my $p = $conf->{passwordDB} ) {
        push @res, "::Password::$p";
    }

    # Check if register is enabled
    push @res, '::Plugins::Register'
      if ( $conf->{registerDB} and $conf->{registerDB} ne 'Null' );

    # Check if custom plugins are required
    if ( $conf->{customPlugins} ) {
        $self->logger->debug( 'Custom plugins: ' . $conf->{customPlugins} );
        push @res, grep ( /\w+/, split( /[,\s]+/, $conf->{customPlugins} ) );
    }

    # Impersonation overwrites req->step and pops 'afterData' EP.
    # Static and custom 'afterData' plugins will be never launched
    # if they are loaded after Impersonation.
    # This plugin must be the last 'afterData' loaded plugin. Fix #2655
    push @res, '::Plugins::Impersonation'
      if $conf->{impersonationRule};

    return @res;
}

sub checkConf {
    my ( $conf, $path, $type ) = @_;
    if ( $path =~ s#^(.*?)/## ) {
        my $w = $1;
        if ( $w eq '*' ) {
            my @res;
            foreach my $k ( keys %{ $conf || {} } ) {
                push @res, checkConf( $conf->{$k}, $path, $type );
            }
            if ( $type eq 'or' ) {
                my $res = 0;
                map { $res ||= $_ } @res;
                return $res;
            }
            else { die "Unkown type $type"; }
        }
        else {
            return checkConf( $conf->{$w}, $path, $type );
        }
    }
    else {
        return $conf->{$path};
    }
}

1;
