# This file contains the OpenAPI specification for the Manager API

package Lemonldap::NG::Manager::Build::OpenApi;

our $VERSION = '2.19.0';

use Lemonldap::NG::Manager::Attributes;
use Lemonldap::NG::Manager::Api::Common qw/_listAttributes/;
use JSON;

my %TYPEMAP = (
    "bool"      => sub { { type => "boolean" } },
    "text"      => sub { { type => "string" } },
    "longtext"  => sub { { type => "string" } },
    "int"       => sub { { type => "integer" } },
    "intOrNull" => sub { { type => "integer" } },
    "trool"     => sub { { type => "integer", maximum => 1, minimum => -1 } },
    "select"    => \&handleSelect,
    "password"  => sub { { type => "string", format => "password" } },
    "file"      => sub { { type => "string" } },
    "url"       => sub { { type => "string", format => "url" } },
);

sub handleSelect {
    my ($attribute_desc) = @_;
    return {
        type => "string",
        enum => [ map { $_->{k} } @{ $attribute_desc->{select} } ],
      },
      ;
}

my @exceptions = qw(
  oidcRPMetaDataOptionsExtraClaims
);

sub getOptions {
    my ( $attributes, $prefix ) = @_;
    my $options = {};
    for my $option ( grep /^$prefix./, keys %$attributes ) {
        next if grep { $_ eq $option } @exceptions;
        my $attribute_desc = $attributes->{$option};
        my $api_option_name =
          Lemonldap::NG::Manager::Api->_translateOptionConfToApi($option);
        if ($api_option_name) {
            $options->{$api_option_name} = {};

            my $type          = $attribute_desc->{type};
            my $api_type_func = $TYPEMAP{$type};

            if ($api_type_func) {
                my $desc = $api_type_func->($attribute_desc);

                if ( Lemonldap::NG::Manager::Api->_mustArrayizeOption($option) )
                {
                    $options->{$api_option_name} = {
                        type  => "array",
                        items => $desc,
                    };
                }
                else {
                    $options->{$api_option_name} = $desc;
                }
            }
            else {
                warn("Could not translate API type $type for $option");
            }

            my $default = $attribute_desc->{default};
            if ($default) {
                $options->{$api_option_name}->{default} = $default;
            }
        }
        else {
            warn("Could not translate option name $option");
        }
    }
    return $options;
}

my $attributes = Lemonldap::NG::Manager::Attributes->attributes();

#getOptions( $attributes, "samlSPMetaDataOptions" );

sub openapi {
    return {
        'openapi' => '3.0.1',
        'info'    => {
            'title'       => 'LemonLDAP::NG Manager API',
            'description' =>
'The Manager API allows an administrator to modify the LemonLDAP::NG configuration programmatically. It is not meant to be accessed by end users. The client libraries mentionned in examples can be generated from doc/sources/manager-api/openapi-spec.yaml',
            'version' => '2.17'
        },
        'servers' => [ {
                'url' => 'https://manager-api.example.com'
            }
        ],
        'tags' => [ {
                'name'        => 'samlsp',
                'description' => 'SAML Service Providers'
            },
            {
                'name'        => 'oidcrp',
                'description' => 'OpenID Connect Relying Parties'
            },
            {
                'name'        => '2fa',
                'description' => 'negistered Second Factors'
            },
            {
                'name'        => 'history',
                'description' => 'Login history'
            }
        ],
        'paths' => {
            '/api/v1/status' => {
                'get' => {
                    'summary'     => 'Check the status of the API',
                    'operationId' => 'status',
                    'responses'   => {
                        '200' => {
                            '$ref' => '#/components/responses/StatusResponse'
                        },
                        '503' => {
                            '$ref' => '#/components/responses/StatusResponse'
                        }
                    }
                }
            },
            '/api/v1/history/{uid}' => {
                'get' => {
                    'summary'     => 'Get the login history for a user',
                    'operationId' => 'getHistory',
                    'tags'        => ['history'],
                    'parameters'  => [ {
                            'name'     => 'uid',
                            'in'       => 'path',
                            'required' => JSON::true,
                            'schema'   => {
                                'type' => 'string'
                            }
                        },
                        {
                            'name'     => 'result',
                            'in'       => 'query',
                            'required' => JSON::false,
                            'schema'   => {
                                'type' => 'string',
                                'enum' => [ 'success', 'failed', 'any' ]
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/HistoryList'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },
            '/api/v1/history/{uid}/last' => {
                'get' => {
                    'summary'     => 'Get the last history event for a user',
                    'operationId' => 'getHistoryLast',
                    'tags'        => ['history'],
                    'parameters'  => [ {
                            'name'     => 'uid',
                            'in'       => 'path',
                            'required' => JSON::true,
                            'schema'   => {
                                'type' => 'string'
                            }
                        },
                        {
                            'name'     => 'result',
                            'in'       => 'query',
                            'required' => JSON::false,
                            'schema'   => {
                                'type' => 'string',
                                'enum' => [ 'success', 'failed', 'any' ]
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/HistoryItem'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },
            '/api/v1/providers/saml/sp' => {
                'post' => {
                    'tags'        => ['samlsp'],
                    'summary'     => 'Create a new SAML Service provider',
                    'operationId' => 'addsamlsp',
                    'requestBody' => {
                        'description' => 'SAML Service provider to add',
                        'content'     => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' => '#/components/schemas/SamlSp'
                                }
                            }
                        },
                        'required' => JSON::true
                    },
                    'responses' => {
                        '201' => {
                            '$ref' => '#/components/responses/Created'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                }
            },
            '/api/v1/providers/saml/sp/findByConfKey' => {
                'get' => {
                    'tags'    => ['samlsp'],
                    'summary' =>
                      'Finds SAML Service providers by configuration key',
                    'description' =>
'Takes a search pattern to be tested against existing service providers',
                    'operationId' => 'findSamlSpByConfKey',
                    'parameters'  => [ {
                            'name'        => 'pattern',
                            'in'          => 'query',
                            'description' => 'Search pattern',
                            'required'    => JSON::true,
                            'schema'      => {
                                'type' => 'string'
                            },
                            'examples' => {
                                'any' => {
                                    'summary' => 'Any value',
                                    'value'   => '*'
                                },
                                'prefix' => {
                                    'summary' => 'Given prefix',
                                    'value'   => 'zone1-*'
                                },
                                'anywhere' => {
                                    'summary' => 'Substring',
                                    'value'   => 'something'
                                }
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/ManySamlSp'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        }
                    }
                }
            },
            '/api/v1/providers/saml/sp/findByEntityId' => {
                'get' => {
                    'tags'        => ['samlsp'],
                    'summary'     => 'Finds SAML Service Provider by Entity ID',
                    'operationId' => 'findSamlSpByEntityId',
                    'parameters'  => [ {
                            'name'        => 'entityId',
                            'in'          => 'query',
                            'description' => 'Entity ID to search',
                            'required'    => JSON::true,
                            'schema'      => {
                                'type' => 'string'
                            },
                            'example' => 'http://mysp.example.com/saml/metadata'
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/OneSamlSp'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },
            '/api/v1/providers/saml/sp/{confKey}' => {
                'get' => {
                    'tags'    => ['samlsp'],
                    'summary' =>
                      'Get SAML Service Provider by configuration key',
                    'description' => 'Returns a single Service Provider',
                    'operationId' => 'getSamlSpByConfKey',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of SAML Service Provider',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/OneSamlSp'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                },
                'put' => {
                    'tags'        => ['samlsp'],
                    'summary'     => 'Replaces a SAML Service',
                    'operationId' => 'replaceSamlSp',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of SAML Service Provider that needs to be replaced',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'requestBody' => {
                        'content' => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' =>
                                      '#/components/schemas/SamlSpReplace'
                                }
                            }
                        }
                    },
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                },
                'patch' => {
                    'tags'        => ['samlsp'],
                    'summary'     => 'Updates a SAML Service.',
                    'operationId' => 'updateSamlSp',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of SAML Service Provider that needs to be updated',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'requestBody' => {
                        'content' => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' =>
                                      '#/components/schemas/SamlSpUpdate'
                                }
                            }
                        }
                    },
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                },
                'delete' => {
                    'tags'        => ['samlsp'],
                    'summary'     => 'Deletes a SAML Service Provider',
                    'operationId' => 'deleteSamlSp',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of SAML Service Provider to delete',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },
            '/api/v1/providers/oidc/rp' => {
                'post' => {
                    'tags'    => ['oidcrp'],
                    'summary' => 'Create a new OpenID Connect Relying Party',
                    'operationId' => 'addoidcrp',
                    'requestBody' => {
                        'description' => 'OpenID Connect Relying Party to add',
                        'content'     => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' => '#/components/schemas/OidcRp'
                                }
                            }
                        },
                        'required' => JSON::true
                    },
                    'responses' => {
                        '201' => {
                            '$ref' => '#/components/responses/Created'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                }
            },
            '/api/v1/providers/oidc/rp/findByConfKey' => {
                'get' => {
                    'tags'    => ['oidcrp'],
                    'summary' =>
'Finds OpenID Connect Relying Partys by configuration key',
                    'description' =>
'Takes a search pattern to be tested against existing service providers',
                    'operationId' => 'findOidcRpByConfKey',
                    'parameters'  => [ {
                            'name'        => 'pattern',
                            'in'          => 'query',
                            'description' => 'Search pattern',
                            'required'    => JSON::true,
                            'schema'      => {
                                '$ref' => '#/components/schemas/confKey'
                            },
                            'examples' => {
                                'any' => {
                                    'summary' => 'Any value',
                                    'value'   => '*'
                                },
                                'prefix' => {
                                    'summary' => 'Given prefix',
                                    'value'   => 'zone1-*'
                                },
                                'anywhere' => {
                                    'summary' => 'Substring',
                                    'value'   => 'something'
                                }
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/ManyOidcRp'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        }
                    }
                }
            },
            '/api/v1/providers/oidc/rp/findByClientId' => {
                'get' => {
                    'tags'    => ['oidcrp'],
                    'summary' =>
                      'Finds OpenID Connect Relying Party by Client ID',
                    'operationId' => 'findOidcRpByClientId',
                    'parameters'  => [ {
                            'name'        => 'clientId',
                            'in'          => 'query',
                            'description' => 'Client ID to search',
                            'required'    => JSON::true,
                            'schema'      => {
                                'type' => 'string'
                            },
                            'example' => 'my_client_id'
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/OneOidcRp'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },
            '/api/v1/providers/oidc/rp/{confKey}' => {
                'get' => {
                    'tags'    => ['oidcrp'],
                    'summary' =>
                      'Get OpenID Connect Relying Party by configuration key',
                    'description' => 'Returns a single Service Provider',
                    'operationId' => 'getOidcRpByConfKey',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of OpenID Connect Relying Party',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/OneOidcRp'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                },
                'patch' => {
                    'tags'        => ['oidcrp'],
                    'summary'     => 'Updates an OpenID Connect Relying Party',
                    'operationId' => 'updateOidcRp',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of OpenID Connect Relying Party that needs to be updated',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'requestBody' => {
                        'content' => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' =>
                                      '#/components/schemas/OidcRpUpdate'
                                }
                            }
                        }
                    },
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                },
                'put' => {
                    'tags'    => ['oidcrp'],
                    'summary' => 'Replaces an OpenID Connect Relying Party',
                    'operationId' => 'replaceOidcRp',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of OpenID Connect Relying Party that needs to be replaced',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'requestBody' => {
                        'content' => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' =>
                                      '#/components/schemas/OidcRpReplace'
                                }
                            }
                        }
                    },
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                },
                'delete' => {
                    'tags'        => ['oidcrp'],
                    'summary'     => 'Deletes a OpenID Connect Relying Party',
                    'operationId' => 'deleteOidcRp',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of OpenID Connect Relying Party to delete',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },
            '/api/v1/providers/cas/app' => {
                'post' => {
                    'tags'        => ['casapp'],
                    'summary'     => 'Create a new CAS Application',
                    'operationId' => 'addcasapp',
                    'requestBody' => {
                        'description' => 'CAS Application to add',
                        'content'     => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' => '#/components/schemas/CasApp'
                                }
                            }
                        },
                        'required' => JSON::true
                    },
                    'responses' => {
                        '201' => {
                            '$ref' => '#/components/responses/Created'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                }
            },
            '/api/v1/providers/cas/app/findByConfKey' => {
                'get' => {
                    'tags'    => ['casapp'],
                    'summary' => 'Finds CAS applications by configuration key',
                    'description' =>
'Takes a search pattern to be tested against existing applications',
                    'operationId' => 'findCasAppByConfKey',
                    'parameters'  => [ {
                            'name'        => 'pattern',
                            'in'          => 'query',
                            'description' => 'Search pattern',
                            'required'    => JSON::true,
                            'schema'      => {
                                'type' => 'string'
                            },
                            'examples' => {
                                'any' => {
                                    'summary' => 'Any value',
                                    'value'   => '*'
                                },
                                'prefix' => {
                                    'summary' => 'Given prefix',
                                    'value'   => 'zone1-*'
                                },
                                'anywhere' => {
                                    'summary' => 'Substring',
                                    'value'   => 'something'
                                }
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/ManyCasApp'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        }
                    }
                }
            },
            '/api/v1/providers/cas/app/findByServiceUrl' => {
                'get' => {
                    'tags'        => ['casapp'],
                    'summary'     => 'Get CAS Application by Service URL',
                    'operationId' => 'findCasAppByServiceUrl',
                    'parameters'  => [ {
                            'name'        => 'serviceUrl',
                            'in'          => 'query',
                            'description' => 'Service URL to search',
                            'required'    => JSON::true,
                            'schema'      => {
                                'type' => 'string'
                            },
                            'example' => 'http://mycasapp.example.com/'
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/OneCasApp'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },
            '/api/v1/providers/cas/app/{confKey}' => {
                'get' => {
                    'tags'        => ['casapp'],
                    'summary'     => 'Get CAS Application by configuration key',
                    'description' => 'Returns a single Application',
                    'operationId' => 'getCasAppByConfKey',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of CAS Application',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/OneCasApp'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                },
                'put' => {
                    'tags'        => ['casapp'],
                    'summary'     => 'Replaces a CAS Application',
                    'operationId' => 'replaceCasApp',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of CAS Application that needs to be replaced',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'requestBody' => {
                        'content' => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' =>
                                      '#/components/schemas/CasAppReplace'
                                }
                            }
                        }
                    },
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                },
                'patch' => {
                    'tags'        => ['casapp'],
                    'summary'     => 'Updates a CAS Application.',
                    'operationId' => 'updateCasApp',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of CAS Application that needs to be updated',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'requestBody' => {
                        'content' => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' =>
                                      '#/components/schemas/CasAppUpdate'
                                }
                            }
                        }
                    },
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                },
                'delete' => {
                    'tags'        => ['casapp'],
                    'summary'     => 'Deletes a CAS Application',
                    'operationId' => 'deleteCasApp',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of CAS Application to delete',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },

            '/api/v1/secondFactor/' => {
                description => "Registered second factors",
                get         => {
                    summary    => "Search for second factors",
                    parameters => [ {
                            name        => "uid",
                            in          => "query",
                            description =>
"The user id to filter on. Can contain wildcards.",
                            example  => "dw*",
                            required => "false",
                            schema   => {
                                type => "string",
                            },
                        },
                        {
                            name        => "type",
                            in          => "query",
                            description =>
"The second factor type to filter on. Can be specified multiple times.",
                            example  => "TOTP",
                            required => "false",
                            schema   => {
                                type => "string",
                            },
                        },
                    ],
                    tags        => ['2fa'],
                    operationId => "searchSecondFactors",
                    responses   => {
                        200 => {
                            '$ref' =>
                              '#/components/responses/SecondFactorSearch'
                        },
                    }
                },
            },
            '/api/v1/secondFactor/{uid}' => {
                'description' => 'Second factors for a particular user',
                'parameters'  => [ {
                        'name'     => 'uid',
                        'in'       => 'path',
                        'required' => JSON::true,
                        'schema'   => {
                            'type' => 'string'
                        }
                    }
                ],
                'get' => {
                    'summary'     => 'List second factors for a user',
                    'description' => '',
                    'tags'        => ['2fa'],
                    'operationId' => 'getSecondFactors',
                    'responses'   => {
                        '200' => {
                            '$ref' => '#/components/responses/SecondFactors'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                },
                'delete' => {
                    'summary'     => 'Delete all second factors for a user',
                    'description' => '',
                    'tags'        => ['2fa'],
                    'operationId' => 'deleteSecondFactors',
                    'responses'   => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                },
                'post' => {
                    'summary'     => 'Register a new second factor for a user',
                    'description' => '',
                    'tags'        => ['2fa'],
                    'operationId' => 'addSecondFactor',
                    'parameters'  => [ {
                            'name'        => 'create',
                            'in'          => 'query',
                            'required'    => JSON::false,
                            'description' =>
"Should the persistent session be created if it does not exist yet",
                            'schema' => {
                                'type'    => 'bool',
                                'default' => JSON::false
                            }
                        }
                    ],
                    'requestBody' => {
                        'description' =>
'Second factor to add, additional properties depend on the 2FA type',
                        'content' => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' =>
                                      '#/components/schemas/NewSecondFactor'
                                }
                            }
                        },
                        'required' => JSON::true
                    },
                    'responses' => {
                        '201' => {
                            '$ref' => '#/components/responses/Created'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },
            '/api/v1/secondFactor/{uid}/type/{type}' => {
                'description' =>
                  'Second factors of a given type for a particular user',
                'parameters' => [ {
                        'name'     => 'uid',
                        'in'       => 'path',
                        'required' => JSON::true,
                        'schema'   => {
                            'type' => 'string'
                        }
                    },
                    {
                        'name'     => 'type',
                        'in'       => 'path',
                        'required' => JSON::true,
                        'schema'   => {
                            'type' => 'string'
                        }
                    }
                ],
                'get' => {
                    'summary' =>
                      'List second factors for a user given its type',
                    'description' => '',
                    'tags'        => ['2fa'],
                    'operationId' => 'getSecondFactorsByType',
                    'responses'   => {
                        '200' => {
                            '$ref' => '#/components/responses/SecondFactors'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                },
                'delete' => {
                    'summary' =>
                      'Delete all second factors of a given type for a user',
                    'description' => '',
                    'tags'        => ['2fa'],
                    'operationId' => 'deleteSecondFactorsByType',
                    'responses'   => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },
            '/api/v1/secondFactor/{uid}/type/TOTP' => {
                'description' => 'Specialized API for TOTP',
                'parameters'  => [ {
                        'name'     => 'uid',
                        'in'       => 'path',
                        'required' => JSON::true,
                        'schema'   => {
                            'type' => 'string'
                        }
                    }
                ],
                'post' => {
                    'summary' => 'Register a new TOTP device factor for a user',
                    'description' =>
'The secret must be passed as cleartext and will be encrypted by the server if needed',
                    'tags'        => ['2fa'],
                    'operationId' => 'addSecondFactorTotp',
                    'parameters'  => [ {
                            'name'        => 'create',
                            'in'          => 'query',
                            'required'    => JSON::false,
                            'description' =>
"Should the persistent session be created if it does not exist yet",
                            'schema' => {
                                'type'    => 'bool',
                                'default' => JSON::false
                            }
                        }
                    ],
                    'requestBody' => {
                        'description' => 'Second factor to add',
                        'content'     => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' =>
                                      '#/components/schemas/NewSecondFactorTotp'
                                }
                            }
                        },
                        'required' => JSON::true
                    },
                    'responses' => {
                        '201' => {
                            '$ref' => '#/components/responses/Created'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },
            '/api/v1/secondFactor/{uid}/id/{id}' => {
                'description' =>
                  'Second factors of a given id for a particular user',
                'parameters' => [ {
                        'name'     => 'uid',
                        'in'       => 'path',
                        'required' => JSON::true,
                        'schema'   => {
                            'type' => 'string'
                        }
                    },
                    {
                        'name'     => 'id',
                        'in'       => 'path',
                        'required' => JSON::true,
                        'schema'   => {
                            'type' => 'string'
                        }
                    }
                ],
                'get' => {
                    'summary' => 'Get second factors for a user given its ID',
                    'description' => '',
                    'tags'        => ['2fa'],
                    'operationId' => 'getSecondFactorsById',
                    'responses'   => {
                        '200' => {
                            '$ref' => '#/components/responses/SecondFactors'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                },
                'delete' => {
                    'summary'     => 'Delete a second factors for a user',
                    'description' => '',
                    'tags'        => ['2fa'],
                    'operationId' => 'deleteSecondFactorsById',
                    'responses'   => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },
            '/api/v1/menu/cat' => {
                'post' => {
                    'tags'        => ['menucat'],
                    'summary'     => 'Create a new Menu Category',
                    'operationId' => 'addMenuCat',
                    'requestBody' => {
                        'description' => 'Menu Category to add',
                        'content'     => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' => '#/components/schemas/MenuCat'
                                }
                            }
                        },
                        'required' => JSON::true
                    },
                    'responses' => {
                        '201' => {
                            '$ref' => '#/components/responses/Created'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                }
            },
            '/api/v1/menu/cat/findByConfKey' => {
                'get' => {
                    'tags'    => ['menucat'],
                    'summary' => 'Finds Menu Categories by configuration key',
                    'description' =>
'Takes a search pattern to be tested against existing categories',
                    'operationId' => 'findMenuCatByConfKey',
                    'parameters'  => [ {
                            'name'        => 'pattern',
                            'in'          => 'query',
                            'description' => 'Search pattern',
                            'required'    => JSON::true,
                            'schema'      => {
                                'type' => 'string'
                            },
                            'examples' => {
                                'any' => {
                                    'summary' => 'Any value',
                                    'value'   => '*'
                                },
                                'prefix' => {
                                    'summary' => 'Given prefix',
                                    'value'   => 'zone1-*'
                                },
                                'anywhere' => {
                                    'summary' => 'Substring',
                                    'value'   => 'something'
                                }
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/ManyMenuCat'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        }
                    }
                }
            },
            '/api/v1/menu/cat/{confKey}' => {
                'get' => {
                    'tags'        => ['menucat'],
                    'summary'     => 'Get Menu Category by configuration key',
                    'description' => 'Returns a single Category',
                    'operationId' => 'getMenuCatByConfKey',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of Menu Category',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/OneMenuCat'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                },
                'put' => {
                    'tags'        => ['menucat'],
                    'summary'     => 'Replaces a Menu Category',
                    'operationId' => 'replaceMenuCat',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of Menu Category that needs to be replaced',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'requestBody' => {
                        'content' => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' => '#/components/schemas/MenuCat'
                                }
                            }
                        }
                    },
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                },
                'patch' => {
                    'tags'        => ['menucat'],
                    'summary'     => 'Updates a Menu Category',
                    'operationId' => 'updateMenuCat',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of Menu Category that needs to be updated',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'requestBody' => {
                        'content' => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' =>
                                      '#/components/schemas/MenuCatUpdate'
                                }
                            }
                        }
                    },
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                },
                'delete' => {
                    'tags'        => ['menucat'],
                    'summary'     => 'Deletes a Menu Category',
                    'operationId' => 'deleteMenuCat',
                    'parameters'  => [ {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of Menu Category to delete',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            },
            '/api/v1/menu/app/{cat}' => {
                'get' => {
                    'tags'    => ['menuapp'],
                    'summary' => 'Get Menu Applications within a Menu Category',
                    'description' =>
                      'Return existing applications within a menu category',
                    'operationId' => 'getMenuApps',
                    'parameters'  => [ {
                            'name'        => 'cat',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of Menu Category to work with',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/menuCatConfKey'
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/ManyMenuApp'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                },
                'post' => {
                    'tags'    => ['menuapp'],
                    'summary' =>
                      'Create a new Menu Application within a Menu Category',
                    'operationId' => 'addMenuApp',
                    'parameters'  => [ {
                            'name'        => 'cat',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of Menu Category to work with',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/menuCatConfKey'
                            }
                        }
                    ],
                    'requestBody' => {
                        'description' => 'Menu Application to add',
                        'content'     => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' => '#/components/schemas/MenuApp'
                                }
                            }
                        },
                        'required' => JSON::true
                    },
                    'responses' => {
                        '201' => {
                            '$ref' => '#/components/responses/Created'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                }
            },
            '/api/v1/menu/app/{cat}/findByConfKey' => {
                'get' => {
                    'tags'    => ['menuapp'],
                    'summary' =>
'Finds Menu Applications by configuration key within a Menu Category',
                    'description' =>
'Takes a search pattern to be tested against existing applications within a menu category',
                    'operationId' => 'findMenuAppByConfKey',
                    'parameters'  => [ {
                            'name'        => 'cat',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of Menu Category to work with',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/menuCatConfKey'
                            }
                        },
                        {
                            'name'        => 'pattern',
                            'in'          => 'query',
                            'description' => 'Search pattern',
                            'required'    => JSON::true,
                            'schema'      => {
                                'type' => 'string'
                            },
                            'examples' => {
                                'any' => {
                                    'summary' => 'Any value',
                                    'value'   => '*'
                                },
                                'prefix' => {
                                    'summary' => 'Given prefix',
                                    'value'   => 'zone1-*'
                                },
                                'anywhere' => {
                                    'summary' => 'Substring',
                                    'value'   => 'something'
                                }
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/ManyMenuApp'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        }
                    }
                }
            },
            '/api/v1/menu/app/{cat}/{confKey}' => {
                'get' => {
                    'tags'    => ['menuapp'],
                    'summary' =>
'Get Menu Application within a Menu Category by configuration key',
                    'description' => 'Returns a single application',
                    'operationId' => 'getMenuAppByConfKey',
                    'parameters'  => [ {
                            'name'        => 'cat',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of Menu Category to work with',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/menuCatConfKey'
                            }
                        },
                        {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of Menu Application',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'responses' => {
                        '200' => {
                            '$ref' => '#/components/responses/OneMenuApp'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                },
                'put' => {
                    'tags'        => ['menuapp'],
                    'summary'     => 'Replaces a Menu Application',
                    'operationId' => 'replaceMenuApp',
                    'parameters'  => [ {
                            'name'        => 'cat',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of Menu Category to work with',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/menuCatConfKey'
                            }
                        },
                        {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of Menu Application that needs to be replaced',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'requestBody' => {
                        'content' => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' => '#/components/schemas/MenuApp'
                                }
                            }
                        }
                    },
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                },
                'patch' => {
                    'tags'        => ['menuapp'],
                    'summary'     => 'Updates a Menu Application',
                    'operationId' => 'updateMenuApp',
                    'parameters'  => [ {
                            'name'        => 'cat',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of Menu Category to work with',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/menuCatConfKey'
                            }
                        },
                        {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
'Configuration key of Menu Application that needs to be updated',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'requestBody' => {
                        'content' => {
                            'application/json' => {
                                'schema' => {
                                    '$ref' =>
                                      '#/components/schemas/MenuAppUpdate'
                                }
                            }
                        }
                    },
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        },
                        '409' => {
                            '$ref' => '#/components/responses/Conflict'
                        }
                    }
                },
                'delete' => {
                    'tags'        => ['menuapp'],
                    'summary'     => 'Deletes a Menu Application',
                    'operationId' => 'deleteMenuApp',
                    'parameters'  => [ {
                            'name'        => 'cat',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of Menu Category to work with',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/menuCatConfKey'
                            }
                        },
                        {
                            'name'        => 'confKey',
                            'in'          => 'path',
                            'description' =>
                              'Configuration key of Menu Application to delete',
                            'required' => JSON::true,
                            'schema'   => {
                                '$ref' => '#/components/schemas/confKey'
                            }
                        }
                    ],
                    'responses' => {
                        '204' => {
                            '$ref' => '#/components/responses/NoContent'
                        },
                        '400' => {
                            '$ref' => '#/components/responses/Error'
                        },
                        '404' => {
                            '$ref' => '#/components/responses/NotFound'
                        }
                    }
                }
            }
        },
        'components' => {
            'schemas' => {
                'Status' => {
                    'type'       => 'object',
                    'properties' => {
                        'name' => {
                            'type'        => 'string',
                            'description' => 'Descriptive name of the software'
                        },
                        'version' => {
                            'type'        => 'string',
                            'description' =>
                              'Version of the LemonLDAP::NG software'
                        },
                        'status_sessions' => {
                            'type'        => 'string',
                            'description' => 'Status of the sessions database',
                            'enum'        => [ 'ok', 'ko', 'unknown' ]
                        },
                        'status_psessions' => {
                            'type'        => 'string',
                            'description' => 'Status of the psessions database',
                            'enum'        => [ 'ok', 'ko', 'unknown' ]
                        },
                        'status_config' => {
                            'type'        => 'string',
                            'description' =>
                              'Status of the configuration database',
                            'enum' => [ 'ok', 'ko' ]
                        },
                        'status' => {
                            'type'        => 'string',
                            'description' => 'Global status',
                            'enum'        => [ 'ok', 'ko' ]
                        }
                    }
                },
                'HistoryItem' => {
                    'type'       => 'object',
                    'required'   => [ 'date', 'result' ],
                    'properties' => {
                        'date' => {
                            'type'        => 'string',
                            'description' => 'Unix timestamp of the event'
                        },
                        'ipAddr' => {
                            'type'        => 'string',
                            'description' =>
                              'String representation of the IP address'
                        },
                        'result' => {
                            'type'        => 'string',
                            'description' => 'Result of authentication attempt',
                            'enum'        => [ 'success', 'failed' ]
                        },
                        'error' => {
                            'type'        => 'integer',
                            'description' => 'LemonLDAP::NG error code'
                        }
                    }
                },
                'confKey' => {
                    'type'    => 'string',
                    'pattern' => '^\\w[\\w\\.\\-]*$'
                },
                'Error' => {
                    'type'       => 'object',
                    'properties' => {
                        'error' => {
                            'type' => 'string'
                        }
                    },
                    'required' => ['error']
                },
                'SamlSp' => {
                    'required'   => [ 'confKey', 'metadata' ],
                    'type'       => 'object',
                    'properties' => {
                        'confKey' => {
                            '$ref' => '#/components/schemas/confKey'
                        },
                        'metadata' => {
                            'type'    => 'string',
                            'example' =>
                              '<?xml version="1.0"?><EntityDescriptor...'
                        },
                        'exportedAttributes' => {
                            'type'  => 'object',
                            'items' => {
                                '$ref' => '#/components/schemas/samlAttribute'
                            }
                        },
                        'macros' => {
                            'type'    => 'object',
                            'example' => {
                                'myMacroName' => '$macro(rule)'
                            }
                        },
                        'options' => {
                            '$ref' => '#/components/schemas/samlOptions'
                        }
                    }
                },
                'SamlSpUpdate' => {
                    'type'       => 'object',
                    'properties' => {
                        'metadata' => {
                            'type'    => 'string',
                            'example' =>
                              '<?xml version="1.0"?><EntityDescriptor...'
                        },
                        'macros' => {
                            'type'    => 'object',
                            'example' => {
                                'myMacroName' => '$macro(rule)'
                            }
                        },
                        'exportedAttributes' => {
                            'type'  => 'object',
                            'items' => {
                                '$ref' => '#/components/schemas/samlAttribute'
                            }
                        },
                        'options' => {
                            '$ref' => '#/components/schemas/samlOptions'
                        }
                    }
                },
                'SamlSpReplace' => {
                    'type'       => 'object',
                    'required'   => ['metadata'],
                    'properties' => {
                        'metadata' => {
                            'type'    => 'string',
                            'example' =>
                              '<?xml version="1.0"?><EntityDescriptor...'
                        },
                        'macros' => {
                            'type'    => 'object',
                            'example' => {
                                'myMacroName' => '$macro(rule)'
                            }
                        },
                        'exportedAttributes' => {
                            'type'  => 'object',
                            'items' => {
                                '$ref' => '#/components/schemas/samlAttribute'
                            }
                        },
                        'options' => {
                            '$ref' => '#/components/schemas/samlOptions'
                        }
                    }
                },
                'samlOptions' => {
                    'type'       => 'object',
                    'properties' =>
                      getOptions( $attributes, 'samlSPMetaDataOptions' ),
                },
                'samlAttribute' => {
                    'type'       => 'object',
                    'properties' => {
                        'name' => {
                            'type' => 'string'
                        },
                        'mandatory' => {
                            'type' => 'boolean'
                        },
                        'friendlyName' => {
                            'type' => 'string'
                        },
                        'format' => {
                            'type'    => 'string',
                            'example' =>
'urn:oasis:names:tc:SAML:2.0:attrname-format:basic'
                        }
                    }
                },
                'OidcRp' => {
                    'required'   => [ 'confKey', 'clientId', 'redirectUris' ],
                    'type'       => 'object',
                    'properties' => {
                        'confKey' => {
                            '$ref' => '#/components/schemas/confKey'
                        },
                        'clientId' => {
                            'type' => 'string'
                        },
                        'redirectUris' => {
                            'type'  => 'array',
                            'items' => {
                                'type'     => 'string',
                                'minItems' => '1',
                                'format'   => 'uri'
                            }
                        },
                        'exportedVars' => {
                            'type'    => 'object',
                            'example' => {
                                'email'       => 'mail',
                                'family_name' => 'sn',
                                'name'        => 'cn'
                            }
                        },
                        'extraClaims' => {
                            'type'    => 'object',
                            'example' => {
                                'myscope' => 'myattr1 myattr2 myattr3'
                            }
                        },
                        'macros' => {
                            'type'    => 'object',
                            'example' => {
                                'myMacroName' => '$macro(rule)'
                            }
                        },
                        'options' => {
                            '$ref' => '#/components/schemas/OidcOptions'
                        },
                        'scopeRules' => {
                            'type'    => 'object',
                            'example' => {
                                'write' => 'requested and inGroup(\'writers\')'
                            }
                        }
                    }
                },
                'OidcOptions' => {
                    'type'       => 'object',
                    'properties' =>
                      getOptions( $attributes, 'oidcRPMetaDataOptions' ),
                },
                'OidcRpUpdate' => {
                    'type'       => 'object',
                    'properties' => {
                        'clientId' => {
                            'type' => 'string'
                        },
                        'exportedVars' => {
                            'type'    => 'object',
                            'example' => {
                                'email'       => 'mail',
                                'family_name' => 'sn',
                                'name'        => 'cn'
                            }
                        },
                        'extraClaims' => {
                            'type'    => 'object',
                            'example' => {
                                'myscope' => 'myattr1 myattr2 myattr3'
                            }
                        },
                        'macros' => {
                            'type'    => 'object',
                            'example' => {
                                'myMacroName' => '$macro(rule)'
                            }
                        },
                        'options' => {
                            '$ref' => '#/components/schemas/OidcOptions'
                        },
                        'scopeRules' => {
                            'type'    => 'object',
                            'example' => {
                                'write' => 'requested and inGroup(\'writers\')'
                            }
                        }
                    }
                },
                'OidcRpReplace' => {
                    'type'       => 'object',
                    'required'   => [ 'clientId', 'redirectUris' ],
                    'properties' => {
                        'clientId' => {
                            'type' => 'string'
                        },
                        'exportedVars' => {
                            'type'    => 'object',
                            'example' => {
                                'email'       => 'mail',
                                'family_name' => 'sn',
                                'name'        => 'cn'
                            }
                        },
                        'extraClaims' => {
                            'type'    => 'object',
                            'example' => {
                                'myscope' => 'myattr1 myattr2 myattr3'
                            }
                        },
                        'macros' => {
                            'type'    => 'object',
                            'example' => {
                                'myMacroName' => '$macro(rule)'
                            }
                        },
                        'options' => {
                            '$ref' => '#/components/schemas/OidcOptions'
                        },
                        'scopeRules' => {
                            'type'    => 'object',
                            'example' => {
                                'write' => 'requested and inGroup(\'writers\')'
                            }
                        }
                    }
                },
                'CasApp' => {
                    'required'   => ['confKey'],
                    'type'       => 'object',
                    'properties' => {
                        'confKey' => {
                            '$ref' => '#/components/schemas/confKey'
                        },
                        'exportedVars' => {
                            'type'    => 'object',
                            'default' => {
                                'cn'   => 'cn',
                                'mail' => 'mail',
                                'uid'  => 'uid'
                            }
                        },
                        'macros' => {
                            'type'    => 'object',
                            'example' => {
                                'myMacroName' => '$macro(rule)'
                            }
                        },
                        'options' => {
                            '$ref' => '#/components/schemas/casOptions'
                        }
                    }
                },
                'CasAppUpdate' => {
                    'type'       => 'object',
                    'properties' => {
                        'macros' => {
                            'type'    => 'object',
                            'example' => {
                                'myMacroName' => '$macro(rule)'
                            }
                        },
                        'exportedVars' => {
                            'type'    => 'object',
                            'default' => {
                                'cn'   => 'cn',
                                'mail' => 'mail',
                                'uid'  => 'uid'
                            }
                        },
                        'options' => {
                            '$ref' => '#/components/schemas/casOptions'
                        }
                    }
                },
                'CasAppReplace' => {
                    'type'       => 'object',
                    'properties' => {
                        'macros' => {
                            'type'    => 'object',
                            'example' => {
                                'myMacroName' => '$macro(rule)'
                            }
                        },
                        'exportedVars' => {
                            'type'    => 'object',
                            'default' => {
                                'cn'   => 'cn',
                                'mail' => 'mail',
                                'uid'  => 'uid'
                            }
                        },
                        'options' => {
                            '$ref' => '#/components/schemas/casOptions'
                        }
                    }
                },
                'casOptions' => {
                    'required'   => ['service'],
                    'type'       => 'object',
                    'properties' =>
                      getOptions( $attributes, 'casAppMetaDataOptions' ),
                },
                'NewSecondFactor' => {
                    'type'       => 'object',
                    'required'   => ['type'],
                    'properties' => {
                        'type' => {
                            'type'        => 'string',
                            'description' =>
                              'The type of second factor to create',
                            'example' => 'TOTP, U2F, UBK (Yubikey), WebAuthn'
                        },
                        'name' => {
                            'type'        => 'string',
                            'description' => 'A description of the device'
                        }
                    },
                    'additionalProperties' => {
                        'type' => 'string'
                    }
                },
                'NewSecondFactorTotp' => {
                    'type'       => 'object',
                    'required'   => ['key'],
                    'properties' => {
                        'key' => {
                            'type'        => 'string',
                            'description' => 'The BASE32 encoded shared secret',
                        },
                        'name' => {
                            'type'        => 'string',
                            'description' => 'A description of the device'
                        }
                    },
                },
                'SecondFactor' => {
                    'type'       => 'object',
                    'required'   => [ 'type', 'id' ],
                    'properties' => {
                        'id' => {
                            'type'        => 'string',
                            'description' =>
                              'An opaque idenfifier for this particular device'
                        },
                        'type' => {
                            'type'        => 'string',
                            'description' => 'The type of device in use',
                            'example' => 'TOTP, U2F, UBK (Yubikey), WebAuthn'
                        },
                        'name' => {
                            'type'        => 'string',
                            'description' =>
                              'A user-set description of the device'
                        }
                    }
                },
                'SecondFactors' => {
                    'type'  => 'array',
                    'items' => {
                        '$ref' => '#/components/schemas/SecondFactor'
                    }
                },
                'SecondFactorSearchResult' => {
                    'type'       => 'object',
                    'required'   => [ 'uid', 'secondFactors' ],
                    'properties' => {
                        'uid' => {
                            'type'        => 'string',
                            'description' => 'The user identifier',
                        },
                        'secondFactors' => {
                            description =>
"The list of second factors matching the request's type",
                            '$ref' => '#/components/schemas/SecondFactors'
                        },
                    }
                },
                'menuCatConfKey' => {
                    'type'    => 'string',
                    'pattern' => '^\\w[\\w\\.\\-]*$'
                },
                'MenuCat' => {
                    'required'   => [ 'confKey', 'catname' ],
                    'type'       => 'object',
                    'properties' => {
                        'confKey' => {
                            '$ref' => '#/components/schemas/confKey'
                        },
                        'catname' => {
                            'type' => 'string'
                        },
                        'order' => {
                            'type' => 'integer'
                        }
                    }
                },
                'MenuCatUpdate' => {
                    'type'       => 'object',
                    'properties' => {
                        'catname' => {
                            'type' => 'string'
                        },
                        'order' => {
                            'type' => 'integer'
                        }
                    }
                },
                'MenuApp' => {
                    'required'   => ['confKey'],
                    'type'       => 'object',
                    'properties' => {
                        'confKey' => {
                            '$ref' => '#/components/schemas/confKey'
                        },
                        'order' => {
                            'type' => 'integer'
                        },
                        'options' => {
                            '$ref' => '#/components/schemas/MenuAppOptions'
                        }
                    }
                },
                'MenuAppOptions' => {
                    'required'   => ['name'],
                    'type'       => 'object',
                    'properties' => {
                        'name' => {
                            'type' => 'string'
                        },
                        'tooltip' => {
                            'type' => 'string'
                        },
                        'description' => {
                            'type' => 'string'
                        },
                        'uri' => {
                            'type' => 'string'
                        },
                        'logo' => {
                            'type'    => 'string',
                            'default' => 'network.png',
                            'enum'    => [
                                'attach.png',
                                'bell.png',
                                'bookmark.png',
                                'configure.png',
                                'database.png',
                                'demo.png',
                                'folder.png',
                                'gear.png',
                                'help.png',
                                'llng.png',
                                'mailappt.png',
                                'money.png',
                                'network.png',
                                'terminal.png',
                                'thumbnail.png',
                                'tux.png',
                                'web.png',
'(Any reference to an available image in app logo folder)'
                            ]
                        },
                        'display' => {
                            'type'    => 'string',
                            'default' => 'auto',
                            'enum'    => [
                                'on',
                                'off',
                                'auto',
'(Any special rule to apply for example "$uid eq \'dwho\'")'
                            ]
                        }
                    }
                },
                'MenuAppUpdate' => {
                    'type'       => 'object',
                    'properties' => {
                        'order' => {
                            'type' => 'integer'
                        },
                        'options' => {
                            '$ref' => '#/components/schemas/MenuAppOptions'
                        }
                    }
                }
            },
            'responses' => {
                'StatusResponse' => {
                    'description' => 'Response to API health check',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                '$ref' => '#/components/schemas/Status'
                            }
                        }
                    }
                },
                'HistoryList' => {
                    'description' =>
'List of history entries, sorted by date, from most recent to least recent',
                    'content' => {
                        'application/json' => {
                            'schema' => {
                                'type'  => 'array',
                                'items' => {
                                    '$ref' => '#/components/schemas/HistoryItem'
                                }
                            }
                        }
                    }
                },
                'HistoryItem' => {
                    'description' => 'History entry',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                '$ref' => '#/components/schemas/HistoryItem'
                            }
                        }
                    }
                },
                'NoContent' => {
                    'description' => 'Successful modification'
                },
                'Created' => {
                    'description' => 'Successful creation'
                },
                'OneOidcRp' => {
                    'description' => 'Return an OpenID Connect Provider',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                '$ref' => '#/components/schemas/OidcRp'
                            }
                        }
                    }
                },
                'OneSamlSp' => {
                    'description' => 'Return a SAML Provider',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                '$ref' => '#/components/schemas/SamlSp'
                            }
                        }
                    }
                },
                'OneCasApp' => {
                    'description' => 'Return a CAS Provider',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                '$ref' => '#/components/schemas/CasApp'
                            }
                        }
                    }
                },
                'ManyOidcRp' => {
                    'description' =>
                      'Return a list of OpenID Connect Providers',
                    'content' => {
                        'application/json' => {
                            'schema' => {
                                'type'  => 'array',
                                'items' => {
                                    '$ref' => '#/components/schemas/OidcRp'
                                }
                            }
                        }
                    }
                },
                'ManySamlSp' => {
                    'description' => 'Return a list of SAML Providers',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                'type'  => 'array',
                                'items' => {
                                    '$ref' => '#/components/schemas/SamlSp'
                                }
                            }
                        }
                    }
                },
                'ManyCasApp' => {
                    'description' => 'Return a list of CAS Providers',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                'type'  => 'array',
                                'items' => {
                                    '$ref' => '#/components/schemas/CasApp'
                                }
                            }
                        }
                    }
                },
                'NotFound' => {
                    'description' => 'The specified resource was not found',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                '$ref' => '#/components/schemas/Error'
                            }
                        }
                    }
                },
                'Conflict' => {
                    'description' =>
'The specified object could not be created because its configuration key, client_id or entityID already exists',
                    'content' => {
                        'application/json' => {
                            'schema' => {
                                '$ref' => '#/components/schemas/Error'
                            }
                        }
                    }
                },
                'Error' => {
                    'description' =>
                      'An error was encountered when processing the request',
                    'content' => {
                        'application/json' => {
                            'schema' => {
                                '$ref' => '#/components/schemas/Error'
                            }
                        }
                    }
                },
                'SecondFactor' => {
                    'description' => 'Return a second factor',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                '$ref' => '#/components/schemas/SecondFactor'
                            }
                        }
                    }
                },
                'SecondFactors' => {
                    'description' => 'Return a list of second factors',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                '$ref' => '#/components/schemas/SecondFactors'
                            }
                        }
                    }
                },
                'SecondFactorSearch' => {
                    'description' => 'A list of search results',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                'type'  => 'array',
                                'items' => {
                                    '$ref' =>
'#/components/schemas/SecondFactorSearchResult'
                                }
                            }
                        }
                    }
                },
                'OneMenuCat' => {
                    'description' => 'Return a Menu Category',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                '$ref' => '#/components/schemas/MenuCat'
                            }
                        }
                    }
                },
                'ManyMenuCat' => {
                    'description' => 'Return a list of Menu Categories',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                'type'  => 'array',
                                'items' => {
                                    '$ref' => '#/components/schemas/MenuCat'
                                }
                            }
                        }
                    }
                },
                'OneMenuApp' => {
                    'description' => 'Return a Menu Application',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                '$ref' => '#/components/schemas/MenuApp'
                            }
                        }
                    }
                },
                'ManyMenuApp' => {
                    'description' => 'Return a list of Menu Applications',
                    'content'     => {
                        'application/json' => {
                            'schema' => {
                                'type'  => 'array',
                                'items' => {
                                    '$ref' => '#/components/schemas/MenuApp'
                                }
                            }
                        }
                    }
                }
            }
        }
    };
}
1;
