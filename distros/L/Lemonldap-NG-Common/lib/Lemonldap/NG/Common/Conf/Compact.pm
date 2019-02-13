package Lemonldap::NG::Common::Conf::Compact;

use strict;
use Mouse;
use Lemonldap::NG::Common::Conf::ReConstants;

our $VERSION = '2.0.0';

sub compactConf {
    my ( $self, $conf ) = @_;

    # Remove unused auth parameters
    my %keep;
    foreach my $type (qw(authentication userDB passwordDB registerDB)) {
        my $mod = $conf->{$type} || 'Null';
        $mod =~ s/OpenIDConnect/oidc/i;
        $mod = lc($mod);
        $keep{$mod} = 1;
        if ( $mod eq "ad" ) { $keep{'ldap'} = 1; }
    }
    if ( $keep{combination} ) {
        foreach my $md ( keys %{ $conf->{combModules} } ) {
            $_ = $conf->{combModules}->{$md}->{type};
            s/^(\w+).*$/lc($1)/e;
            s/OpenIDConnect/oidc/i;
            $keep{$_} = 1;
        }
    }
    if ( $keep{choice} ) {
        foreach my $key ( values %{ $conf->{authChoiceModules} } ) {
            my @tmp = split /[;|\|]/, $key;
            foreach (@tmp) {
                s/^(\w+).*$/lc($1)/e;
                s/OpenIDConnect/oidc/i;
                $keep{$_} = 1;
            }
        }
    }
    foreach my $key ( keys %$authParameters ) {
        my $mod = $key;
        $mod =~ s/Params$//;
        unless ( $keep{$mod} ) {
            delete $conf->{$_} foreach ( @{ $authParameters->{$key} } );
        }
    }

    # Disabled for now:

    # Remove unused issuerDB parameters
    foreach my $k ( keys %$issuerParameters ) {
        unless ( $conf->{ $k . "Activation" } ) {
            delete $conf->{$_} foreach ( @{ $issuerParameters->{$k} } );
        }
    }

    # Remove SAML service unless used
    unless ( $keep{saml} or $conf->{issuerDBSAMLActivation} ) {
        delete $conf->{$_} foreach (@$samlServiceParameters);
    }

    # Remove OpenID-Connect service unless used
    unless ( $keep{oidc} or $conf->{issuerDBOpenIDConnectActivation} ) {
        delete $conf->{$_} foreach (@$oidcServiceParameters);
    }
    return $conf;
}

1;
