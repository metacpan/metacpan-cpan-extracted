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

# DON'T FORGET TO RUN jsongenerator.pl AFTER EACH CHANGE

package Lemonldap::NG::Manager::Build::CTrees;

sub cTrees {
    return {
        virtualHost => [
            'locationRules',
            'exportedHeaders',
            'post',
            {
                title => 'vhostOptions',
                help  => 'configvhost.html#options',
                nodes => [
                    'vhostPort',        'vhostHttps',
                    'vhostMaintenance', 'vhostAliases'
                ],
            },
        ],
        samlIDPMetaDataNode => [
            'samlIDPMetaDataXML',
            'samlIDPMetaDataExportedAttributes',
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
                title => "samlIDPMetaDataOptionsSession",
                form  => 'simpleInputContainer',
                nodes => [
                    "samlIDPMetaDataOptionsAdaptSessionUtime",
                    "samlIDPMetaDataOptionsForceUTF8",
                    "samlIDPMetaDataOptionsStoreSAMLToken"
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
            }
        ],
        samlSPMetaDataNode => [
            "samlSPMetaDataXML",
            "samlSPMetaDataExportedAttributes",
            {
                title => "samlSPMetaDataOptions",
                help  => 'idpsaml.html#options',
                nodes => [
                    {
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
                            "samlSPMetaDataOptionsEnableIDPInitiatedURL"
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
                nodes => [
                    {
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
                    {
                        title => 'oidcOPMetaDataOptionsDisplayParams',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'oidcOPMetaDataOptionsDisplayName',
                            'oidcOPMetaDataOptionsIcon'
                        ]
                    },
                ]
            },
        ],
        oidcRPMetaDataNode => [
            'oidcRPMetaDataExportedVars',
            {
                title => 'oidcRPMetaDataOptions',
                nodes => [
                    {
                        title => 'oidcRPMetaDataOptionsAuthentication',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'oidcRPMetaDataOptionsClientID',
                            'oidcRPMetaDataOptionsClientSecret'
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
                    'oidcRPMetaDataOptionsUserIDAttr',
                    'oidcRPMetaDataOptionsIDTokenSignAlg',
                    'oidcRPMetaDataOptionsIDTokenExpiration',
                    'oidcRPMetaDataOptionsAccessTokenExpiration',
                    'oidcRPMetaDataOptionsRedirectUris',
                    'oidcRPMetaDataOptionsPostLogoutRedirectUris',
                    'oidcRPMetaDataOptionsBypassConsent',
                ]
            },
            'oidcRPMetaDataOptionsExtraClaims',
        ],
    };
}

1;
