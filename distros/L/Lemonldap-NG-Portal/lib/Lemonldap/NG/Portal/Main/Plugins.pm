# This module loads known enabled plugins. To add custom modules, just add them
# into "plugins" list in lemonldap-ng.ini, section "portal"
package Lemonldap::NG::Portal::Main::Plugins;

our $VERSION = '2.0.6';

package Lemonldap::NG::Portal::Main;

use strict;
use Mouse;

# Plugins enabled by a simple boolean value (ordered list)
#
# Developers: 2FA must be loaded before Notifications
our @pList = (
    portalDisplayResetPassword => '::Plugins::MailPasswordReset',
    portalStatus               => '::Plugins::Status',
    cda                        => '::Plugins::CDA',
    notification               => '::Plugins::Notifications',
    portalCheckLogins          => '::Plugins::History',
    stayConnected              => '::Plugins::StayConnected',
    bruteForceProtection       => '::Plugins::BruteForceProtection',
    grantSessionRules          => '::Plugins::GrantSession',
    upgradeSession             => '::Plugins::Upgrade',
    autoSigninRules            => '::Plugins::AutoSignin',
    checkState                 => '::Plugins::CheckState',
    portalForceAuthn           => '::Plugins::ForceAuthn',
    checkUser                  => '::Plugins::CheckUser',
    impersonationRule          => '::Plugins::Impersonation',
    contextSwitchingRule       => '::Plugins::ContextSwitching',
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

    # Load static plugin list
    for ( my $i = 0 ; $i < @pList ; $i += 2 ) {
        push @res, $pList[ $i + 1 ] if ( $conf->{ $pList[$i] } );
    }

    # Load single session
    push @res, '::Plugins::SingleSession'
      if ( $conf->{singleSession}
        or $conf->{singleIP}
        or $conf->{singleUserByIP}
        or $conf->{notifyOther} );

    # Check if SOAP is enabled
    push @res, '::Plugins::SOAPServer'
      if ( $conf->{soapSessionServer}
        or $conf->{soapConfigServer} );

    # Add REST (check is done by it)
    push @res, '::Plugins::RESTServer';

    if ( my $p = $conf->{passwordDB} ) {
        push @res, "::Password::$p" if ( $p ne 'Null' );
    }

    # Check if register is enabled
    push @res, '::Plugins::Register'
      if ( $conf->{registerDB} and $conf->{registerDB} ne 'Null' );

    # Check if custom plugins are required
    # TODO: change this name
    if ( $conf->{customPlugins} ) {
        $self->logger->debug( 'Custom plugins: ' . $conf->{customPlugins} );
        push @res, grep ( /\w+/, split( /,\s*/, $conf->{customPlugins} ) );
    }
    return @res;
}

1;
