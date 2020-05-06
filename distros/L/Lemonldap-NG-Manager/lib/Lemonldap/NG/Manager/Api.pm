# This module implements all the methods that responds to '/api/*' requests
package Lemonldap::NG::Manager::Api;

use 5.10.0;
use utf8;
use Mouse;

extends 'Lemonldap::NG::Manager::Plugin',
  'Lemonldap::NG::Common::Conf::RESTServer',
  'Lemonldap::NG::Common::Session::REST';

use Lemonldap::NG::Manager::Api::2F;
use Lemonldap::NG::Manager::Api::Providers::OidcRp;
use Lemonldap::NG::Manager::Api::Providers::SamlSp;

our $VERSION = '2.0.8';

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => 'api.html';

sub init {
    my ( $self, $conf ) = @_;

    # HTML template
    $self->addRoute( 'api.html', undef, ['GET'] )

      ->addRoute(
        api => {
            v1 => {
                providers => {
                    oidc => {
                        rp => {
                            findByConfKey => {
                                ':uPattern' => 'findOidcRpByConfKey'
                            },
                            findByClientId => {
                                ':uClientId' => 'findOidcRpByClientId'
                            },
                            ':confKey' => 'getOidcRpByConfKey'
                        },
                    },
                    saml => {
                        sp => {
                            findByConfKey => {
                                ':uPattern' => 'findSamlSpByConfKey'
                            },
                            findByEntityId => {
                                ':uEntityId' => 'findSamlSpByEntityId'
                            },
                            ':confKey' => 'getSamlSpByConfKey'
                        },
                    },
                },
                secondFactor => {
                    ':uid' => {
                        id => {
                            ':id' => 'getSecondFactorsById'
                        },
                        type => {
                            ':type' => 'getSecondFactorsByType'
                        },
                        '*' => 'getSecondFactors'
                    },
                },
            },
        },
        ['GET']
      )

      ->addRoute(
        api => {
            v1 => {
                providers => {
                    oidc => {
                        rp => 'addOidcRp'
                    },
                    saml => {
                        sp => 'addSamlSp'
                    },
                },
            },
        },
        ['POST']
      )

      ->addRoute(
        api => {
            v1 => {
                providers => {
                    oidc => {
                        rp => { ':confKey' => 'replaceOidcRp' }
                    },
                    saml => {
                        sp => { ':confKey' => 'replaceSamlSp' }
                    },
                },
            },
        },
        ['PUT']
      )

      ->addRoute(
        api => {
            v1 => {
                providers => {
                    oidc => {
                        rp => { ':confKey' => 'updateOidcRp' }
                    },
                    saml => {
                        sp => { ':confKey' => 'updateSamlSp' }
                    },
                },
            },
        },
        ['PATCH']
      )

      ->addRoute(
        api => {
            v1 => {
                providers => {
                    oidc => {
                        rp => { ':confKey' => 'deleteOidcRp' }
                    },
                    saml => {
                        sp => { ':confKey' => 'deleteSamlSp' }
                    },
                },
                secondFactor => {
                    ':uid' => {
                        id => {
                            ':id' => 'deleteSecondFactorsById'
                        },
                        type => {
                            ':type' => 'deleteSecondFactorsByType'
                        },
                        '*' => 'deleteSecondFactors'
                    },
                },
            },
        },
        ['DELETE']
      );

    $self->setTypes($conf);
    $self->{multiValuesSeparator} ||= '; ';
    $self->{hiddenAttributes} //= "_password";
    $self->{TOTPCheck} = $self->{U2FCheck} = $self->{UBKCheck} = '1';
    return 1;
}

1;
