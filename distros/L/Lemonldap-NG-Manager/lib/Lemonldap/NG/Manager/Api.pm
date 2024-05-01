# This module implements all the methods that responds to '/api/*' requests
package Lemonldap::NG::Manager::Api;

use strict;
use utf8;
use Mouse;

use Lemonldap::NG::Manager::Api::2F;
use Lemonldap::NG::Manager::Api::History;
use Lemonldap::NG::Manager::Api::Misc;
use Lemonldap::NG::Manager::Api::Providers::OidcRp;
use Lemonldap::NG::Manager::Api::Providers::SamlSp;
use Lemonldap::NG::Manager::Api::Providers::CasApp;
use Lemonldap::NG::Manager::Api::Menu::Cat;
use Lemonldap::NG::Manager::Api::Menu::App;
use Lemonldap::NG::Common::TOTP;

extends qw(
  Lemonldap::NG::Manager::Plugin
  Lemonldap::NG::Common::Conf::RESTServer
  Lemonldap::NG::Common::Session::REST
);

has totp_encrypt => ( is => "rw" );
our $VERSION = '2.19.0';

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => 'api.html';
use constant icon         => 'flash';

sub init {
    my ( $self, $conf ) = @_;

    $self->ua( Lemonldap::NG::Common::UserAgent->new($conf) );
    $self->totp_encrypt(
        Lemonldap::NG::Common::TOTP->new(
            key           => ( $conf->{totp2fKey} || $conf->{key} ),
            encryptSecret => $conf->{totp2fEncryptSecret}
        )
    );

    # HTML template
    $self->addRoute( 'api.html', undef, ['GET'] )

      ->addRoute(
        api => {
            v1 => {
                status    => 'status',
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
                    cas => {
                        app => {
                            findByConfKey => {
                                ':uPattern' => 'findCasAppByConfKey'
                            },
                            findByServiceUrl => {
                                ':uServiceUrl' => 'findCasAppsByServiceUrl'
                            },
                            ':confKey' => 'getCasAppByConfKey'
                        },
                    },
                },
                secondFactor => {
                    ':_uid' => {
                        id => {
                            ':id' => 'getSecondFactorsById'
                        },
                        type => {
                            ':type' => 'getSecondFactorsByType'
                        },
                        '*' => 'getSecondFactors'
                    },
                },
                menu => {
                    cat => {
                        findByConfKey => {
                            ':uPattern' => 'findMenuCatByConfKey'
                        },
                        ':confKey' => {
                            '*' => 'getMenuCatByConfKey'
                        }
                    },
                    app => {
                        ':confKey' => {
                            findByConfKey => {
                                ':uPattern' => 'findMenuAppByConfKey'
                            },
                            ':appConfKey' => 'getMenuApp'
                        }
                    },
                },
                history => {
                    ':uid' => 'getHistory',
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
                    cas => {
                        app => 'addCasApp'
                    },
                },
                menu => {
                    cat => 'addMenuCat',
                    app => {
                        ':confKey' => 'addMenuApp'
                    }
                },
                secondFactor => {
                    ':uid' => {
                        type => {
                            ':type' => 'addSecondFactorByType'
                        },
                        '*' => 'addSecondFactor'
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
                    cas => {
                        app => { ':confKey' => 'replaceCasApp' }
                    },
                },
                menu => {
                    cat => { ':confKey' => 'replaceMenuCat' },
                    app => {
                        ':confKey' => {
                            ':appConfKey' => 'replaceMenuApp'
                        }
                    }
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
                    cas => {
                        app => { ':confKey' => 'updateCasApp' }
                    },
                },
                menu => {
                    cat => { ':confKey' => 'updateMenuCat' },
                    app => {
                        ':confKey' => {
                            ':appConfKey' => 'updateMenuApp'
                        }
                    }
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
                    cas => {
                        app => { ':confKey' => 'deleteCasApp' }
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
                menu => {
                    cat => { ':confKey' => 'deleteMenuCat' },
                    app => {
                        ':confKey' => {
                            ':appConfKey' => 'deleteMenuApp'
                        }
                    }
                },
            },
        },
        ['DELETE']
      );

    $self->setTypes($conf);
    $self->{multiValuesSeparator} ||= '; ';
    $self->{hiddenAttributes} //= "_password";
    return 1;
}

1;
