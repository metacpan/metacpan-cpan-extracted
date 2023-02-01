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

# DON'T FORGET TO RUN 'make json' AFTER EACH CHANGE

package Lemonldap::NG::Manager::Build::CTrees;

our $VERSION = '2.0.15';

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
                    'vhostPort',            'vhostHttps',
                    'vhostMaintenance',     'vhostAliases',
                    'vhostAccessToTrace',   'vhostAuthnLevel',
                    'vhostType',            'vhostDevOpsRulesUrl',
                    'vhostServiceTokenTTL', 'vhostComment'
                ],
            },
        ],
        samlIDPMetaDataNode => [
            'samlIDPMetaDataXML',
            'samlIDPMetaDataExportedAttributes',

            {
                title => 'samlIDPMetaDataOptionsSession',
                form  => 'simpleInputContainer',
                nodes => [
                    'samlIDPMetaDataOptionsAdaptSessionUtime',
                    'samlIDPMetaDataOptionsForceUTF8',
                    'samlIDPMetaDataOptionsStoreSAMLToken',
                    'samlIDPMetaDataOptionsUserAttribute'
                ]
            },
            {
                title => 'samlIDPMetaDataOptionsSignature',
                form  => 'simpleInputContainer',
                nodes => [
                    'samlIDPMetaDataOptionsSignatureMethod',
                    'samlIDPMetaDataOptionsSignSSOMessage',
                    'samlIDPMetaDataOptionsCheckSSOMessageSignature',
                    'samlIDPMetaDataOptionsSignSLOMessage',
                    'samlIDPMetaDataOptionsCheckSLOMessageSignature'
                ]
            },
            {
                title => 'samlIDPMetaDataOptionsBinding',
                form  => 'simpleInputContainer',
                nodes => [
                    'samlIDPMetaDataOptionsSSOBinding',
                    'samlIDPMetaDataOptionsSLOBinding'
                ]
            },
            {
                title => 'samlIDPMetaDataOptionsSecurity',
                form  => 'simpleInputContainer',
                nodes => [
                    'samlIDPMetaDataOptionsEncryptionMode',
                    'samlIDPMetaDataOptionsCheckTime',
                    'samlIDPMetaDataOptionsCheckAudience'
                ]
            },
            {
                title => 'samlIDPMetaDataOptions',
                help  => 'authsaml.html#options',
                form  => 'simpleInputContainer',
                nodes => [
                    'samlIDPMetaDataOptionsNameIDFormat',
                    'samlIDPMetaDataOptionsForceAuthn',
                    'samlIDPMetaDataOptionsIsPassive',
                    'samlIDPMetaDataOptionsAllowLoginFromIDP',
                    'samlIDPMetaDataOptionsRequestedAuthnContext',
                    'samlIDPMetaDataOptionsRelayStateURL',
                    {
                        title => 'samlIDPMetaDataOptionsFederation',
                        form  => 'simpleInputContainer',
                        nodes => [ 'samlIDPMetaDataOptionsFederationEntityID', ]
                    },
                    'samlIDPMetaDataOptionsComment'
                ],
            },
            {
                title => 'samlIDPMetaDataOptionsDisplay',
                form  => 'simpleInputContainer',
                nodes => [
                    'samlIDPMetaDataOptionsDisplayName',
                    'samlIDPMetaDataOptionsIcon',
                    'samlIDPMetaDataOptionsTooltip',
                    'samlIDPMetaDataOptionsResolutionRule',
                    'samlIDPMetaDataOptionsSortNumber'
                ]
            }
        ],
        samlSPMetaDataNode => [
            'samlSPMetaDataXML',
            'samlSPMetaDataExportedAttributes',
            {
                title => 'samlSPMetaDataOptions',
                help  => 'idpsaml.html#options',
                nodes => [ {
                        title => 'samlSPMetaDataOptionsAuthnResponse',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'samlSPMetaDataOptionsNameIDFormat',
                            'samlSPMetaDataOptionsNameIDSessionKey',
                            'samlSPMetaDataOptionsOneTimeUse',
                            'samlSPMetaDataOptionsSessionNotOnOrAfterTimeout',
                            'samlSPMetaDataOptionsNotOnOrAfterTimeout',
                            'samlSPMetaDataOptionsForceUTF8'
                        ]
                    },
                    {
                        title => 'samlSPMetaDataOptionsSignature',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'samlSPMetaDataOptionsSignatureMethod',
                            'samlSPMetaDataOptionsSignSSOMessage',
                            'samlSPMetaDataOptionsCheckSSOMessageSignature',
                            'samlSPMetaDataOptionsSignSLOMessage',
                            'samlSPMetaDataOptionsCheckSLOMessageSignature',
                        ]
                    },
                    {
                        title => 'samlSPMetaDataOptionsSecurity',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'samlSPMetaDataOptionsEncryptionMode',
                            'samlSPMetaDataOptionsEnableIDPInitiatedURL',
                            'samlSPMetaDataOptionsAuthnLevel',
                            'samlSPMetaDataOptionsRule',
                        ]
                    },
                    {
                        title => 'samlSPMetaDataOptionsFederation',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'samlSPMetaDataOptionsFederationEntityID',
                            'samlSPMetaDataOptionsFederationOptionalAttributes',
                            'samlSPMetaDataOptionsFederationRequiredAttributes',
                        ]
                    },
                    'samlSPMetaDataOptionsComment'
                ]
            },
            'samlSPMetaDataMacros',
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
                    'oidcOPMetaDataOptionsComment'
                ]
            },
            {
                title => 'oidcOPMetaDataOptionsDisplayParams',
                form  => 'simpleInputContainer',
                nodes => [
                    'oidcOPMetaDataOptionsDisplayName',
                    'oidcOPMetaDataOptionsIcon',
                    'oidcOPMetaDataOptionsTooltip',
                    'oidcOPMetaDataOptionsResolutionRule',
                    'oidcOPMetaDataOptionsSortNumber'
                ]
            },
        ],
        oidcRPMetaDataNode => [ {
                title => 'oidcRPMetaDataOptionsBasic',
                help  => 'idpopenidconnect.html#basic-options',
                form  => 'simpleInputContainer',
                nodes => [
                    'oidcRPMetaDataOptionsPublic',
                    'oidcRPMetaDataOptionsClientID',
                    'oidcRPMetaDataOptionsClientSecret',
                    'oidcRPMetaDataOptionsRedirectUris'
                ]
            },
            'oidcRPMetaDataExportedVars',
            {
                title => 'oidcRPMetaDataOptions',
                help  => 'idpopenidconnect.html#options',
                nodes => [ {
                        title => 'oidcRPMetaDataOptionsAdvanced',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'oidcRPMetaDataOptionsBypassConsent',
                            'oidcRPMetaDataOptionsIDTokenForceClaims',
                            'oidcRPMetaDataOptionsAccessTokenJWT',
                            'oidcRPMetaDataOptionsAccessTokenClaims',
                            'oidcRPMetaDataOptionsRefreshToken',
                            'oidcRPMetaDataOptionsUserIDAttr',
                            'oidcRPMetaDataOptionsAdditionalAudiences',
                        ]
                    },
                    {
                        title => 'oidcRPMetaDataOptionsScopes',
                        nodes => [
                            'oidcRPMetaDataOptionsExtraClaims',
                            'oidcRPMetaDataScopeRules',
                        ]
                    },
                    {
                        title => 'security',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'oidcRPMetaDataOptionsIDTokenSignAlg',
                            'oidcRPMetaDataOptionsAccessTokenSignAlg',
                            'oidcRPMetaDataOptionsUserInfoSignAlg',
                            'oidcRPMetaDataOptionsRequirePKCE',
                            'oidcRPMetaDataOptionsAllowOffline',
                            'oidcRPMetaDataOptionsAllowPasswordGrant',
                            'oidcRPMetaDataOptionsAllowClientCredentialsGrant',
                            'oidcRPMetaDataOptionsAuthnLevel',
                            'oidcRPMetaDataOptionsRule',
                        ]
                    },
                    {
                        title => 'oidcRPMetaDataOptionsTimeouts',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'oidcRPMetaDataOptionsAuthorizationCodeExpiration',
                            'oidcRPMetaDataOptionsIDTokenExpiration',
                            'oidcRPMetaDataOptionsAccessTokenExpiration',
                            'oidcRPMetaDataOptionsOfflineSessionExpiration',
                        ]
                    },
                    {
                        title => 'logout',
                        form  => 'simpleInputContainer',
                        nodes => [
                            'oidcRPMetaDataOptionsLogoutBypassConfirm',
                            'oidcRPMetaDataOptionsLogoutSessionRequired',
                            'oidcRPMetaDataOptionsLogoutType',
                            'oidcRPMetaDataOptionsLogoutUrl',
                            'oidcRPMetaDataOptionsPostLogoutRedirectUris',
                        ]
                    },
                    'oidcRPMetaDataOptionsComment'
                ]
            },
            'oidcRPMetaDataMacros',
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
                    'casSrvMetaDataOptionsComment'
                ]
            },
            {
                title => 'casSrvMetaDataOptionsDisplay',
                form  => 'simpleInputContainer',
                nodes => [
                    'casSrvMetaDataOptionsDisplayName',
                    'casSrvMetaDataOptionsIcon',
                    'casSrvMetaDataOptionsTooltip',
                    'casSrvMetaDataOptionsResolutionRule',
                    'casSrvMetaDataOptionsSortNumber'
                ]
            },
        ],
        casAppMetaDataNode => [
            'casAppMetaDataExportedVars',
            {
                title => 'casAppMetaDataOptions',
                form  => 'simpleInputContainer',
                nodes => [
                    'casAppMetaDataOptionsService',
                    'casAppMetaDataOptionsUserAttribute',
                    'casAppMetaDataOptionsAuthnLevel',
                    'casAppMetaDataOptionsRule',
                    'casAppMetaDataOptionsComment',
                ]
            },
            'casAppMetaDataMacros',
        ],
    };
}

1;
