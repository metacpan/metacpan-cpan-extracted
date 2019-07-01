# This file contains the description of special subtrees of the manager
# interface.
# You can only use the following keys:
#  * title: the name of the node
#  * nodes: the subnodes of the node
#  * group: grouped subnodes (see RSAKey form for example)
#  * form: only for nodes, the form to display when selected
#
# Conf parameters are just strings in the `nodes` array
#
# All other ideas have to be set in Manager/Build/Attributes.pm !

# DON'T FORGET TO RUN "make json" AFTER EACH CHANGE

package Lemonldap::NG::Manager::Build::CTrees;

our $VERSION = '2.0.4';

sub cTrees {
    return {
        virtualHost => [
            'locationRules',
            'exportedHeaders',
            'post',
            {
                title => 'vhostOptions',
                help  => 'configvhost.html#options',
                form  => 'simpleInputContainer',
                nodes => [
                    'vhostPort',        'vhostHttps',
                    'vhostMaintenance', 'vhostAliases',
                    'vhostType',        'vhostAuthnLevel',
                    'vhostServiceTokenTTL'
                ],
            },
        ],
        samlIDPMetaDataNode => [
            'samlIDPMetaDataXML',
            'samlIDPMetaDataExportedAttributes',

            {
                title => "samlIDPMetaDataOptionsSession",
                form  => 'simpleInputContainer',
                nodes => [
                    "samlIDPMetaDataOptionsAdaptSessionUtime",
                    "samlIDPMetaDataOptionsForceUTF8",
                    "samlIDPMetaDataOptionsStoreSAMLToken",
                    "samlIDPMetaDataOptionsUserAttribute"
                ]
            },
            {
                title => "samlIDPMetaDataOptionsSignature",
                form  => 'simpleInputContainer',
                nodes => [
                    "samlIDPMetaDataOptionsSignSSOMessage",
                    "samlIDPMetaDataOptionsCheckSSOMessageSignature",
                    "samlIDPMetaDataOptionsSignSLOMessage",
                    "samlIDPMetaDataOptionsCheckSLOMessageSignature"
                ]
            },
            {
                title => "samlIDPMetaDataOptionsBinding",
                form  => 'simpleInputContainer',
                nodes => [
                    "samlIDPMetaDataOptionsSSOBinding",
                    "samlIDPMetaDataOptionsSLOBinding"
                ]
            },
            {
                title => "samlIDPMetaDataOptionsSecurity",
                form  => 'simpleInputContainer',
                nodes => [
                    "samlIDPMetaDataOptionsEncryptionMode",
                    "samlIDPMetaDataOptionsCheckTime",
                    "samlIDPMetaDataOptionsCheckAudience"
                ]
            },
            {
                title => 'samlIDPMetaDataOptions',
                help  => 'authsaml.html#options',
                form  => 'simpleInputContainer',
                nodes => [
                    'samlIDPMetaDataOptionsResolutionRule',
                    'samlIDPMetaDataOptionsNameIDFormat',
                    'samlIDPMetaDataOptionsForceAuthn',
                    'samlIDPMetaDataOptionsIsPassive',
                    'samlIDPMetaDataOptionsAllowProxiedAuthn',
                    'samlIDPMetaDataOptionsAllowLoginFromIDP',
                    'samlIDPMetaDataOptionsRequestedAuthnContext',
                    'samlIDPMetaDataOptionsRelayStateURL',
                ],
            },
            {
                title => "samlIDPMetaDataOptionsDisplay",
                form  => 'simpleInputContainer',
                nodes => [
                    "samlIDPMetaDataOptionsDisplayName",
                    "samlIDPMetaDataOptionsIcon",
                    "samlIDPMetaDataOptionsSortNumber"
                ]
            }
        ],
        samlSPMetaDataNode => [
            "samlSPMetaDataXML",
            "samlSPMetaDataExportedAttributes",
            {
                title => "samlSPMetaDataOptions",
                help  => 'idpsaml.html#options',
                nodes => [ {
                        title => "samlSPMetaDataOptionsAuthnResponse",
                        form  => 'simpleInputContainer',
                        nodes => [
                            "samlSPMetaDataOptionsNameIDFormat",
                            "samlSPMetaDataOptionsNameIDSessionKey",
                            "samlSPMetaDataOptionsOneTimeUse",
                            "samlSPMetaDataOptionsSessionNotOnOrAfterTimeout",
                            "samlSPMetaDataOptionsNotOnOrAfterTimeout",
                            "samlSPMetaDataOptionsForceUTF8"
                        ]
                    },
                    {
                        title => "samlSPMetaDataOptionsSignature",
                        form  => 'simpleInputContainer',
                        nodes => [
                            "samlSPMetaDataOptionsSignSSOMessage",
                            "samlSPMetaDataOptionsCheckSSOMessageSignature",
                            "samlSPMetaDataOptionsSignSLOMessage",
                            "samlSPMetaDataOptionsCheckSLOMessageSignature"
                        ]
                    },
                    {
                        title => "samlSPMetaDataOptionsSecurity",
                        form  => 'simpleInputContainer',
                        nodes => [
                            "samlSPMetaDataOptionsEncryptionMode",
                            "samlSPMetaDataOptionsEnableIDPInitiatedURL",
                            "samlSPMetaDataOptionsRule",
                        ]
                    }
                ]
            }
        ],
        oidcOPMetaDataNode => [
            'oidcOPMetaDataJSON',
            'oidcOPMetaDataJWKS',
            'oidcOPMetaDataExportedVars',
            {
                title => 'oidcOPMetaDataOptions',
                nodes => [ {
                        title => 'oidcOPMetaDataOptionsConfiguration',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'oidcOPMetaDataOptionsConfigurationURI',
                            'oidcOPMetaDataOptionsJWKSTimeout',
                            'oidcOPMetaDataOptionsClientID',
                            'oidcOPMetaDataOptionsClientSecret',
                            'oidcOPMetaDataOptionsStoreIDToken'
                        ]
                    },
                    {
                        title => 'oidcOPMetaDataOptionsProtocol',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'oidcOPMetaDataOptionsScope',
                            'oidcOPMetaDataOptionsDisplay',
                            'oidcOPMetaDataOptionsPrompt',
                            'oidcOPMetaDataOptionsMaxAge',
                            'oidcOPMetaDataOptionsUiLocales',
                            'oidcOPMetaDataOptionsAcrValues',
                            'oidcOPMetaDataOptionsTokenEndpointAuthMethod',
                            'oidcOPMetaDataOptionsCheckJWTSignature',
                            'oidcOPMetaDataOptionsIDTokenMaxAge',
                            'oidcOPMetaDataOptionsUseNonce'
                        ]
                    },
                ]
            },
            {
                title => 'oidcOPMetaDataOptionsDisplayParams',
                form  => 'simpleInputContainer',
                nodes => [
                    'oidcOPMetaDataOptionsDisplayName',
                    'oidcOPMetaDataOptionsIcon',
                    'oidcOPMetaDataOptionsSortNumber'
                ]
            },
        ],
        oidcRPMetaDataNode => [
            'oidcRPMetaDataExportedVars',
            'oidcRPMetaDataOptionsExtraClaims',
            {
                title => 'oidcRPMetaDataOptions',
                nodes => [ {
                        title => 'oidcRPMetaDataOptionsAuthentication',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'oidcRPMetaDataOptionsClientID',
                            'oidcRPMetaDataOptionsClientSecret',
                            'oidcRPMetaDataOptionsPublic',
                            'oidcRPMetaDataOptionsRequirePKCE',
                        ]
                    },
                    'oidcRPMetaDataOptionsUserIDAttr',
                    'oidcRPMetaDataOptionsIDTokenSignAlg',
                    'oidcRPMetaDataOptionsIDTokenExpiration',
                    'oidcRPMetaDataOptionsAccessTokenExpiration',
                    'oidcRPMetaDataOptionsRedirectUris',
                    'oidcRPMetaDataOptionsBypassConsent',
                    {
                        title => 'logout',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'oidcRPMetaDataOptionsPostLogoutRedirectUris',
                            'oidcRPMetaDataOptionsLogoutUrl',
                            'oidcRPMetaDataOptionsLogoutType',
                            'oidcRPMetaDataOptionsLogoutSessionRequired',
                        ]
                    },
                    'oidcRPMetaDataOptionsRule',
                ]
            },
            {
                title => 'oidcRPMetaDataOptionsDisplay',
                form  => 'simpleInputContainer',
                nodes => [
                    'oidcRPMetaDataOptionsDisplayName',
                    'oidcRPMetaDataOptionsIcon'
                ],
            },
        ],
        casSrvMetaDataNode => [
            'casSrvMetaDataExportedVars',
            'casSrvMetaDataOptionsProxiedServices',
            {
                title => 'casSrvMetaDataOptions',
                form  => 'simpleInputContainer',
                nodes => [
                    'casSrvMetaDataOptionsUrl',
                    'casSrvMetaDataOptionsRenew',
                    'casSrvMetaDataOptionsGateway',
                ]
            },
            {
                title => 'casSrvMetaDataOptionsDisplay',
                form  => 'simpleInputContainer',
                nodes => [
                    'casSrvMetaDataOptionsDisplayName',
                    'casSrvMetaDataOptionsIcon',
                    'casSrvMetaDataOptionsSortNumber',
                ]
            },
        ],
        casAppMetaDataNode => [ {
                title => 'casAppMetaDataOptions',
                form  => 'simpleInputContainer',
                nodes => [
                    'casAppMetaDataOptionsService',
                    'casAppMetaDataOptionsUserAttribute',
                    'casAppMetaDataOptionsRule'
                ]
            },
            'casAppMetaDataExportedVars',
        ],
    };
}

1;
