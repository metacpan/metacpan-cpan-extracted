# This module loads known enabled plugins. To add custom modules, just add them
# into "plugins" list in lemonldap-ng.ini, section "portal"
package Lemonldap::NG::Portal::Main::Plugins;

our $VERSION = '2.0.14';

package Lemonldap::NG::Portal::Main;

use strict;
use Mouse;

# Plugins enabled by a simple boolean value (ordered list)
#
# Developers: 2FA must be loaded before Notifications
# Developers: GlobalLogout must be the last loaded plugin
our @pList = (
    portalDisplayResetPassword          => '::Plugins::MailPasswordReset',
    portalDisplayCertificateResetByMail => '::Plugins::CertificateResetByMail',
    portalStatus                        => '::Plugins::Status',
    cda                                 => '::Plugins::CDA',
    notification                        => '::Plugins::Notifications',
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
    adaptativeAuthenticationLevelRules  =>
      '::Plugins::AdaptativeAuthenticationLevel',
    refreshSessions  => '::Plugins::Refresh',
    crowdsec         => '::Plugins::CrowdSec',
    globalLogoutRule => '::Plugins::GlobalLogout',
);

##@method list enabledPlugins
#
#@return list of enabled plugins
sub enabledPlugins {
    my ($self) = @_;
    my $conf = $self->conf;
    my @res;

    # Search for Issuer* modules enabled
    foreach my $key (qw(SAML OpenID CAS OpenIDConnect Get)) {
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
        my $pluginConf = $conf->{ $pList[$i] };
        if ( ref($pluginConf) eq "HASH" ) {

            # Do not load plugin if config is an empty hash
            push @res, $pList[ $i + 1 ] if %{$pluginConf};
        }
        else {
            push @res, $pList[ $i + 1 ] if $pluginConf;
        }
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

1;
