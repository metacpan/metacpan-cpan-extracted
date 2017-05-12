# This file describes the manager tree.
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

package Lemonldap::NG::Manager::Build::Tree;

our $VERSION = '1.9.6';

# TODO: Missing:
#  * activeTimer
#  * confirmFormMethod
#  * redirectFormMethod
sub tree {
    return [
        {
            title => 'generalParameters',
            nodes => [
                {
                    title => 'portalParams',
                    help  => 'portal.html',
                    nodes => [
                        '*portal',
                        {
                            title => 'portalMenu',
                            help  => 'portalmenu.html',
                            nodes => [
                                {
                                    title => 'portalModules',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalDisplayLogout',
                                        'portalDisplayChangePassword',
                                        'portalDisplayAppslist',
                                        'portalDisplayLoginHistory'
                                    ]
                                },
                                'applicationList'
                            ]
                        },
                        {
                            title => 'portalCustomization',
                            help  => 'portalcustom.html',
                            nodes => [
                                'portalSkin',
                                'portalSkinBackground',
                                'portalSkinRules',
                                {
                                    title => 'portalButtons',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalCheckLogins',
                                        'portalDisplayResetPassword',
                                        'portalDisplayRegister'
                                    ]
                                },
                                {
                                    title => 'passwordManagement',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalRequireOldPassword',
                                        'hideOldPassword',
                                        'mailOnPasswordChange'
                                    ]
                                },
                                {
                                    title => 'portalOther',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalUserAttr',
                                        'portalOpenLinkInNewWindow',
                                        'portalAntiFrame',
                                        'portalPingInterval'
                                    ]
                                }
                            ]
                        },
                        {
                            title => 'portalCaptcha',
                            help  => 'captcha.html',
                            nodes => [
                                'captcha_login_enabled',
                                'captcha_mail_enabled',
                                'captcha_register_enabled',
                                'captcha_size',
                                'captchaStorage',
                                'captchaStorageOptions'
                            ]
                        }
                    ]
                },
                {
                    title => 'authParams',
                    help =>
                      'start.html#authentication_users_and_password_databases',
                    form       => 'authParams',
                    nodes      => [ 'authentication', 'userDB', 'passwordDB' ],
                    nodes_cond => [
                        {
                            title => 'adParams',
                            help  => 'authad.html',
                            nodes => [ 'ADPwdMaxAge', 'ADPwdExpireWarning' ]
                        },
                        {
                            title => 'choiceParams',
                            help  => 'authchoice.html',
                            nodes => [ 'authChoiceParam', 'authChoiceModules' ]
                        },
                        {
                            title => 'apacheParams',
                            help  => 'authapache.html',
                            form  => 'simpleInputContainer',
                            nodes => ['apacheAuthnLevel']
                        },
                        {
                            title => 'browseridParams',
                            help  => 'authbrowserid.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'browserIdAuthnLevel',
                                'browserIdAutoLogin',
                                'browserIdVerificationURL',
                                'browserIdSiteName',
                                'browserIdSiteLogo',
                                'browserIdBackgroundColor'
                            ]
                        },
                        {
                            title => 'casParams',
                            help  => 'authcas.html',
                            nodes => [
                                'CAS_authnLevel', 'CAS_url',
                                'CAS_CAFile',     'CAS_renew',
                                'CAS_gateway',    'CAS_pgtFile',
                                'CAS_proxiedServices'
                            ]
                        },
                        {
                            title => 'dbiParams',
                            help  => 'authdbi.html',
                            nodes => [
                                'dbiAuthnLevel',
                                'dbiExportedVars',
                                {
                                    title => 'dbiConnection',
                                    help  => 'authdbi.html#connection',
                                    nodes => [
                                        {
                                            title => 'dbiConnectionAuth',
                                            form  => 'simpleInputContainer',
                                            nodes => [
                                                'dbiAuthChain',
                                                'dbiAuthUser',
                                                'dbiAuthPassword'
                                            ]
                                        },
                                        {
                                            title => 'dbiConnectionUser',
                                            form  => 'simpleInputContainer',
                                            nodes => [
                                                'dbiUserChain',
                                                'dbiUserUser',
                                                'dbiUserPassword'
                                            ]
                                        }
                                    ]
                                },
                                {
                                    title => 'dbiSchema',
                                    help  => 'authdbi.html#schema',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'dbiAuthTable',
                                        'dbiUserTable',
                                        'dbiAuthLoginCol',
                                        'dbiAuthPasswordCol',
                                        'dbiPasswordMailCol',
                                        'userPivot'
                                    ]
                                },
                                {
                                    title => 'dbiPassword',
                                    help  => 'authdbi.html#password',
                                    form  => 'simpleInputContainer',
                                    nodes => ['dbiAuthPasswordHash']
                                }
                            ]
                        },
                        {
                            title => 'demoParams',
                            help  => 'authdemo.html',
                            nodes => ['demoExportedVars']
                        },
                        {
                            title => 'facebookParams',
                            help  => 'authfacebook.html',
                            nodes => [
                                'facebookAuthnLevel', 'facebookExportedVars',
                                'facebookAppId',      'facebookAppSecret'
                            ]
                        },
                        {
                            title => 'googleParams',
                            help  => 'authgoogle.html',
                            nodes =>
                              [ 'googleAuthnLevel', 'googleExportedVars' ]
                        },
                        {
                            title => 'ldapParams',
                            help  => 'authldap.html',
                            nodes => [
                                'ldapAuthnLevel',
                                'ldapExportedVars',
                                {
                                    title => 'ldapConnection',
                                    help  => 'authldap.html#connection',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'ldapServer',      'ldapPort',
                                        'ldapBase',        'managerDn',
                                        'managerPassword', 'ldapTimeout',
                                        'ldapVersion',     'ldapRaw'
                                    ]
                                },
                                {
                                    title => 'ldapFilters',
                                    help  => 'authldap.html#filters',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'LDAPFilter',     'AuthLDAPFilter',
                                        'mailLDAPFilter', 'ldapSearchDeref',
                                    ]
                                },
                                {
                                    title => 'ldapGroups',
                                    help  => 'authldap.html#groups',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'ldapGroupBase',
                                        'ldapGroupObjectClass',
                                        'ldapGroupAttributeName',
                                        'ldapGroupAttributeNameUser',
                                        'ldapGroupAttributeNameSearch',
                                        'ldapGroupRecursive',
                                        'ldapGroupAttributeNameGroup'
                                    ]
                                },
                                {
                                    title => 'ldapPassword',
                                    help  => 'authldap.html#password',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'ldapPpolicyControl',
                                        'ldapSetPassword',
                                        'ldapChangePasswordAsUser',
                                        'ldapPwdEnc',
                                        'ldapUsePasswordResetAttribute',
                                        'ldapPasswordResetAttribute',
                                        'ldapPasswordResetAttributeValue',
                                        'ldapAllowResetExpiredPassword'
                                    ]
                                },
                            ]
                        },
                        {
                            title => 'multiParams',
                            help  => 'authmulti.html',
                            form  => 'authParamsTextContainer',
                            nodes => [ 'multiAuthStack', 'multiUserDBStack' ]
                        },
                        {
                            title => 'nullParams',
                            help  => 'authnull.html',
                            form  => 'simpleInputContainer',
                            nodes => ['nullAuthnLevel']
                        },
                        {
                            title => 'openidParams',
                            help  => 'authopenid.html',
                            nodes => [
                                'openIdAuthnLevel', 'openIdExportedVars',
                                'openIdSecret',     'openIdIDPList'
                            ]
                        },
                        {
                            title => 'oidcParams',
                            help  => 'authopenidconnect.html',
                            nodes => [
                                'oidcAuthnLevel',
                                'oidcRPCallbackGetParam',
                                'oidcRPStateTimeout'
                            ]
                        },
                        {
                            title => 'proxyParams',
                            help  => 'authproxy.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'soapAuthService', 'remoteCookieName',
                                'soapSessionService'
                            ]
                        },
                        {
                            title => 'radiusParams',
                            help  => 'authradius.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'radiusAuthnLevel', 'radiusSecret',
                                'radiusServer'
                            ]
                        },
                        {
                            title => 'remoteParams',
                            help  => 'authremote.html',
                            nodes => [
                                'remotePortal',
                                'remoteCookieName',
                                'remoteGlobalStorage',
                                'remoteGlobalStorageOptions'
                            ]
                        },
                        {
                            title => 'slaveParams',
                            help  => 'authslave.html',
                            nodes => [
                                'slaveAuthnLevel', 'slaveExportedVars',
                                'slaveUserHeader', 'slaveMasterIP',
                                'slaveHeaderName', 'slaveHeaderContent'
                            ]
                        },
                        {
                            title => 'sslParams',
                            help  => 'authssl.html',
                            form  => 'simpleInputContainer',
                            nodes => [ 'SSLAuthnLevel', 'SSLVar' ]
                        },
                        {
                            title => 'twitterParams',
                            help  => 'authtwitter.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'twitterAuthnLevel', 'twitterKey',
                                'twitterSecret',     'twitterAppName'
                            ]
                        },
                        {
                            title => 'webidParams',
                            help  => 'authwebid.html',
                            nodes => [
                                'webIDAuthnLevel', 'webIDExportedVars',
                                'webIDWhitelist'
                            ]
                        },
                        {
                            title => 'yubikeyParams',
                            help  => 'authyubikey.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'yubikeyAuthnLevel', 'yubikeyClientID',
                                'yubikeySecretKey',  'yubikeyPublicIDSize'
                            ]
                        },
                    ],
                    'nodes_filter' => 'authParams'
                },
                {
                    title => 'issuerParams',
                    help  => 'start.html#identity_provider',
                    nodes => [
                        {
                            title => 'issuerDBSAML',
                            help  => 'idpsaml.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'issuerDBSAMLActivation', 'issuerDBSAMLPath',
                                'issuerDBSAMLRule'
                            ]
                        },
                        {
                            title => 'issuerDBCAS',
                            help  => 'idpcas.html',
                            nodes => [
                                'issuerDBCASActivation',
                                'issuerDBCASPath',
                                'issuerDBCASRule',
                                {
                                    title => 'issuerDBCASOptions',
                                    nodes => [
                                        'casAttr',
                                        'casAttributes',
                                        'casAccessControlPolicy',
                                        'casStorage',
                                        'casStorageOptions'
                                    ]
                                }
                            ]
                        },
                        {
                            title => 'issuerDBOpenID',
                            help  => 'idpopenid.html',
                            nodes => [
                                'issuerDBOpenIDActivation',
                                'issuerDBOpenIDPath',
                                'issuerDBOpenIDRule',
                                {
                                    title => 'issuerDBOpenIDOptions',
                                    nodes => [
                                        'openIdIssuerSecret',
                                        'openIdAttr',
                                        'openIdSPList',
                                        {
                                            title => 'openIdSreg',
                                            form  => 'simpleInputContainer',
                                            nodes => [
                                                'openIdSreg_fullname',
                                                'openIdSreg_nickname',
                                                'openIdSreg_language',
                                                'openIdSreg_postcode',
                                                'openIdSreg_timezone',
                                                'openIdSreg_country',
                                                'openIdSreg_gender',
                                                'openIdSreg_email',
                                                'openIdSreg_dob'
                                            ]
                                        }
                                    ]
                                }
                            ]
                        },
                        {
                            title => 'issuerDBOpenIDConnect',
                            help  => 'idpopenidconnect.html',
                            nodes => [
                                'issuerDBOpenIDConnectActivation',
                                'issuerDBOpenIDConnectPath',
                                'issuerDBOpenIDConnectRule',
                            ]
                        },
                        {
                            title => 'issuerDBGet',
                            nodes => [
                                'issuerDBGetActivation',
                                'issuerDBGetPath',
                                'issuerDBGetRule',
                                'issuerDBGetParameters'
                            ]
                        },
                    ]
                },
                {
                    title => 'logParams',
                    help  => 'logs.html',
                    form  => 'simpleInputContainer',
                    nodes => [
                        'syslog',      'trustedProxies',
                        'whatToTrace', 'hiddenAttributes'
                    ]
                },
                {
                    title => 'cookieParams',
                    help  => 'ssocookie.html',
                    form  => 'simpleInputContainer',
                    nodes => [
                        'cookieName', '*domain',
                        'cda',        'securedCookie',
                        'httpOnly',   'cookieExpiration'
                    ]
                },
                {
                    title => 'sessionParams',
                    help  => 'sessions.html',
                    nodes => [
                        'storePassword',
                        'timeout',
                        'timeoutActivity',
                        'timeoutActivityInterval',
                        'grantSessionRules',
                        {
                            title => 'sessionStorage',
                            help  => 'start.html#sessions_database',
                            nodes => [
                                'globalStorage',
                                'globalStorageOptions',
                                'localSessionStorage',
                                'localSessionStorageOptions'
                            ]
                        },
                        {
                            title => 'multipleSessions',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'singleSession',  'singleIP',
                                'singleUserByIP', 'singleSessionUserByIP',
                                'notifyDeleted',  'notifyOther'
                            ]
                        },
                        {
                            title => 'persistentSessions',
                            nodes => [
                                'persistentStorage', 'persistentStorageOptions'
                            ]
                        }
                    ]
                },
                'reloadUrls',
                {
                    title => 'advancedParams',
                    help  => 'start.html#advanced_features',
                    nodes => [
                        'customFunctions',
                        {
                            title => 'soap',
                            form  => 'simpleInputContainer',
                            nodes => [ 'Soap', 'exportedAttr' ]
                        },
                        {
                            title => 'loginHistory',
                            help  => 'loginhistory.html',
                            nodes => [
                                'loginHistoryEnabled',
                                'successLoginNumber',
                                'failedLoginNumber',
                                'sessionDataToRemember'
                            ]
                        },
                        {
                            title => 'notifications',
                            help  => 'notifications.html',
                            nodes => [
                                'notification',
                                'notificationStorage',
                                'notificationStorageOptions',
                                'notificationWildcard',
                                'notificationXSLTfile'
                            ]
                        },
                        {
                            title => 'passwordManagement',
                            help  => 'resetpassword.html',
                            nodes => [
                                {
                                    title => 'SMTP',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'SMTPServer', 'SMTPAuthUser',
                                        'SMTPAuthPass'
                                    ]
                                },
                                {
                                    title => 'mailHeaders',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'mailFrom', 'mailReplyTo',
                                        'mailCharset'
                                    ]
                                },
                                {
                                    title => 'mailContent',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'mailSubject',
                                        'mailBody',
                                        'mailConfirmSubject',
                                        'mailConfirmBody'
                                    ]
                                },
                                {
                                    title => 'mailOther',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'mailUrl',     'randomPasswordRegexp',
                                        'mailTimeout', 'mailSessionKey'
                                    ]
                                }
                            ]
                        },
                        {
                            title => 'register',
                            help  => 'register.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'registerDB',
                                'registerUrl',
                                'registerTimeout',
                                'registerConfirmSubject',
                                'registerDoneSubject'
                            ]
                        },
                        {
                            title => 'security',
                            help => 'security.html#configure_security_settings',
                            form => 'simpleInputContainer',
                            nodes => [
                                'userControl',
                                'portalForceAuthn',
                                'portalForceAuthnInterval',
                                'key',
                                'trustedDomains',
                                'useSafeJail',
                                'checkXSS',
                                'lwpSslOpts'
                            ]
                        },
                        {
                            title => 'redirection',
                            help  => 'redirections.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'https',
                                'port',
                                'useRedirectOnForbidden',
                                'useRedirectOnError',
                                'maintenance'
                            ]
                        },
                        {
                            title => 'portalRedirection',
                            help  => 'redirections.html#portal_redirections',
                            form  => 'simpleInputContainer',
                            nodes => [ 'jsRedirect', 'noAjaxHook' ]
                        },
                        {
                            title => 'specialHandlers',
                            nodes => [
                                {
                                    title => 'zimbraHandler',
                                    help  => 'applications/zimbra.html',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'zimbraPreAuthKey',
                                        'zimbraAccountKey',
                                        'zimbraBy',
                                        'zimbraUrl',
                                        'zimbraSsoUrl'
                                    ]
                                },
                                {
                                    title => 'sympaHandler',
                                    help  => 'applications/sympa.html',
                                    form  => 'simpleInputContainer',
                                    nodes => [ 'sympaSecret', 'sympaMailKey' ]
                                },
                                {
                                    title => 'secureTokenHandler',
                                    help  => 'securetoken.html',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'secureTokenMemcachedServers',
                                        'secureTokenExpiration',
                                        'secureTokenAttribute',
                                        'secureTokenUrls',
                                        'secureTokenHeader',
                                        'secureTokenAllowOnError'
                                    ]
                                }
                            ]
                        },
                        'nginxCustomHandlers',
                        'logoutServices',
                        'multiValuesSeparator',
                        {
                            title => 'forms',
                            nodes => [
                                'infoFormMethod',     'confirmFormMethod',
                                'redirectFormMethod', 'activeTimer',
                            ]
                        }
                    ]
                }
            ]
        },
        {
            title => 'variables',
            nodes => [ 'exportedVars', 'macros', 'groups' ]
        },
        'virtualHosts',
        {
            title => 'samlServiceMetaData',
            help  => 'samlservice.html',
            nodes => [
                'samlEntityID',
                {
                    title => 'samlServiceSecurity',
                    help  => 'samlservice.html#security_parameters',
                    nodes => [
                        {
                            title => 'samlServiceSecuritySig',
                            form  => 'RSAKey',
                            group => [
                                'samlServicePrivateKeySig',
                                'samlServicePrivateKeySigPwd',
                                'samlServicePublicKeySig'
                            ]
                        },
                        {
                            title => 'samlServiceSecurityEnc',
                            form  => 'RSAKey',
                            group => [
                                'samlServicePrivateKeyEnc',
                                'samlServicePrivateKeyEncPwd',
                                'samlServicePublicKeyEnc'
                            ]
                        },
                        'samlServiceUseCertificateInResponse'
                    ]
                },
                {
                    title => 'samlNameIDFormatMap',
                    help  => 'samlservice.html#nameid_formats',
                    form  => 'simpleInputContainer',
                    nodes => [
                        'samlNameIDFormatMapEmail',
                        'samlNameIDFormatMapX509',
                        'samlNameIDFormatMapWindows',
                        'samlNameIDFormatMapKerberos'
                    ]
                },
                {
                    title => 'samlAuthnContextMap',
                    help  => 'samlservice.html#authentication_contexts',
                    form  => 'simpleInputContainer',
                    nodes => [
                        'samlAuthnContextMapPassword',
                        'samlAuthnContextMapPasswordProtectedTransport',
                        'samlAuthnContextMapTLSClient',
                        'samlAuthnContextMapKerberos'
                    ]
                },
                {
                    title => 'samlOrganization',
                    help  => 'samlservice.html#organization',
                    form  => 'simpleInputContainer',
                    nodes => [
                        'samlOrganizationDisplayName', 'samlOrganizationName',
                        'samlOrganizationURL'
                    ]
                },
                {
                    title => 'samlSPSSODescriptor',
                    help  => 'samlservice.html#service_provider',
                    nodes => [
                        'samlSPSSODescriptorAuthnRequestsSigned',
                        'samlSPSSODescriptorWantAssertionsSigned',
                        {
                            title => 'samlSPSSODescriptorSingleLogoutService',
                            nodes => [
'samlSPSSODescriptorSingleLogoutServiceHTTPRedirect',
'samlSPSSODescriptorSingleLogoutServiceHTTPPost',
                                'samlSPSSODescriptorSingleLogoutServiceSOAP'
                            ]
                        },
                        {
                            title =>
                              'samlSPSSODescriptorAssertionConsumerService',
                            nodes => [
'samlSPSSODescriptorAssertionConsumerServiceHTTPArtifact',
'samlSPSSODescriptorAssertionConsumerServiceHTTPPost'
                            ]
                        },
                        {
                            title =>
                              'samlSPSSODescriptorArtifactResolutionService',
                            nodes => [
'samlSPSSODescriptorArtifactResolutionServiceArtifact'
                            ]
                        }
                    ]
                },
                {
                    title => 'samlIDPSSODescriptor',
                    help  => 'samlservice.html#identity_provider',
                    nodes => [
                        'samlIDPSSODescriptorWantAuthnRequestsSigned',
                        {
                            title => 'samlIDPSSODescriptorSingleSignOnService',
                            nodes => [
'samlIDPSSODescriptorSingleSignOnServiceHTTPRedirect',
'samlIDPSSODescriptorSingleSignOnServiceHTTPPost',
'samlIDPSSODescriptorSingleSignOnServiceHTTPArtifact',
                                'samlIDPSSODescriptorSingleSignOnServiceSOAP'
                            ]
                        },
                        {
                            title => 'samlIDPSSODescriptorSingleLogoutService',
                            nodes => [
'samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect',
'samlIDPSSODescriptorSingleLogoutServiceHTTPPost',
                                'samlIDPSSODescriptorSingleLogoutServiceSOAP'
                            ]
                        },
                        {
                            title =>
                              'samlIDPSSODescriptorArtifactResolutionService',
                            nodes => [
'samlIDPSSODescriptorArtifactResolutionServiceArtifact'
                            ]
                        }
                    ]
                },
                {
                    title => 'samlAttributeAuthorityDescriptor',
                    help  => 'samlservice.html#attribute_authority',
                    nodes => [
                        {
                            title =>
'samlAttributeAuthorityDescriptorAttributeService',
                            nodes => [
'samlAttributeAuthorityDescriptorAttributeServiceSOAP'
                            ]
                        }
                    ]
                },
                {
                    title => 'samlAdvanced',
                    help  => 'samlservice.html#advanced',
                    nodes => [
                        'samlIdPResolveCookie',
                        'samlMetadataForceUTF8',
                        'samlStorage',
                        'samlStorageOptions',
                        'samlRelayStateTimeout',
                        'samlUseQueryStringSpecific',
                        {
                            title => 'samlCommonDomainCookie',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'samlCommonDomainCookieActivation',
                                'samlCommonDomainCookieDomain',
                                'samlCommonDomainCookieReader',
                                'samlCommonDomainCookieWriter'
                            ]
                        }
                    ]
                }
            ]
        },
        'samlIDPMetaDataNodes',
        'samlSPMetaDataNodes',
        {
            title => 'oidcServiceMetaData',
            help  => 'openidconnectservice.html#service_configuration',
            nodes => [
                'oidcServiceMetaDataIssuer',
                {
                    title => 'oidcServiceMetaDataEndPoints',
                    form  => 'simpleInputContainer',
                    nodes => [
                        'oidcServiceMetaDataAuthorizeURI',
                        'oidcServiceMetaDataTokenURI',
                        'oidcServiceMetaDataUserInfoURI',
                        'oidcServiceMetaDataJWKSURI',
                        'oidcServiceMetaDataRegistrationURI',
                        'oidcServiceMetaDataEndSessionURI',
                        'oidcServiceMetaDataCheckSessionURI',
                    ]
                },
                'oidcServiceMetaDataAuthnContext',
                {
                    title => 'oidcServiceMetaDataSecurity',
                    nodes => [
                        {
                            title => 'oidcServiceMetaDataKeys',
                            form  => 'RSAKeyNoPassword',
                            group => [
                                'oidcServicePrivateKeySig',
                                'oidcServicePublicKeySig',
                            ],
                        },
                        'oidcServiceKeyIdSig',
                        'oidcServiceAllowDynamicRegistration',
                        'oidcServiceAllowAuthorizationCodeFlow',
                        'oidcServiceAllowImplicitFlow',
                        'oidcServiceAllowHybridFlow',
                    ],
                },
                {
                    title => "oidcServiceMetaDataSessions",
                    nodes => [ 'oidcStorage', 'oidcStorageOptions', ],
                },
            ]
        },
        'oidcOPMetaDataNodes',
        'oidcRPMetaDataNodes',
    ];
}

1;
