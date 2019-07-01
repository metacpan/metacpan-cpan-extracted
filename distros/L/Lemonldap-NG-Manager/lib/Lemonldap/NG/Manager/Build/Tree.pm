# This file describes the manager tree.
# You can only use the following keys:
#  * title: the name of the node
#  * nodes: the subnodes of the node
#  * group: grouped subnodes (see RSAKey form for example)
#  * form: only for nodes, the form to display when selected
#
# Conf parameters are just strings in the `nodes` array
#
# Important point: fields preceded by '*' are downloaded during manager
# initialization and available directly in $scope array. Example: '*portal'
# implies that portal value is available in $scope.portal
#
# All other ideas have to be set in Manager/Build/Attributes.pm !

# DON'T FORGET TO RUN "make json" AFTER EACH CHANGE

package Lemonldap::NG::Manager::Build::Tree;

our $VERSION = '2.0.3';

# TODO: Missing:
#  * activeTimer
#  * confirmFormMethod
#  * redirectFormMethod
sub tree {
    return [ {
            title => 'generalParameters',
            nodes => [ {
                    title => 'portalParams',
                    help  => 'portal.html',
                    nodes => [
                        '*portal',
                        {
                            title => 'portalMenu',
                            help  => 'portalmenu.html',
                            nodes => [ {
                                    title => 'portalModules',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalDisplayLogout',
                                        'portalDisplayChangePassword',
                                        'portalDisplayAppslist',
                                        'portalDisplayLoginHistory',
                                        'portalDisplayOidcConsents',
                                    ]
                                },
                                'applicationList'
                            ]
                        },
                        {
                            title => 'portalCustomization',
                            help  => 'portalcustom.html',
                            nodes => [
                                'portalMainLogo',
                                'showLanguages',
                                'portalSkin',
                                'portalSkinBackground',
                                'portalSkinRules',
                                {
                                    title => 'portalButtons',
                                    help  => 'portalcustom.html#buttons',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalCheckLogins',
                                        'portalDisplayResetPassword',
                                        'passwordResetAllowedRetries',
                                        'portalDisplayRegister'
                                    ]
                                },
                                {
                                    title => 'passwordManagement',
                                    help =>
                                      'portalcustom.html#password_management',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalRequireOldPassword',
                                        'hideOldPassword',
                                        'mailOnPasswordChange'
                                    ]
                                },
                                {
                                    title => 'portalOther',
                                    help =>
                                      'portalcustom.html#other_parameters',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalUserAttr',
                                        'portalOpenLinkInNewWindow',
                                        'portalAntiFrame',
                                        'portalPingInterval',
                                        'portalErrorOnExpiredSession',
                                        'portalErrorOnMailNotFound'
                                    ]
                                }
                            ]
                        },
                        {
                            title => 'portalCaptcha',
                            help  => 'captcha.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'captcha_login_enabled',
                                'captcha_mail_enabled',
                                'captcha_register_enabled',
                                'captcha_size',
                            ]
                        }
                    ]
                },
                {
                    title => 'authParams',
                    help =>
                      'start.html#authentication_users_and_password_databases',
                    form  => 'authParams',
                    nodes => [
                        'authentication', 'userDB', 'passwordDB', 'registerDB'
                    ],
                    nodes_cond => [ {
                            title => 'adParams',
                            help  => 'authad.html',
                            form  => 'simpleInputContainer',
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
                            title => 'casParams',
                            help  => 'authcas.html',
                            form  => 'simpleInputContainer',
                            nodes => ['casAuthnLevel']
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
                                    nodes => [ {
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
                                    nodes => [
                                        'dbiAuthPasswordHash',
                                        {
                                            title => 'dbiDynamicHash',
                                            help  => 'authdbi.html#password',
                                            form  => 'simpleInputContainer',
                                            nodes => [
                                                'dbiDynamicHashEnabled',
                                                'dbiDynamicHashValidSchemes',
'dbiDynamicHashValidSaltedSchemes',
'dbiDynamicHashNewPasswordScheme'
                                            ]
                                        }
                                    ]
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
                                'facebookAppId',      'facebookAppSecret',
                                'facebookUserField'
                            ]
                        },
                        {
                            title => 'kerberosParams',
                            form  => 'simpleInputContainer',
                            help  => 'authkerberos.html',
                            nodes => [
                                'krbAuthnLevel', 'krbKeytab',
                                'krbByJs',       'krbRemoveDomain'
                            ]
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
                                        'ldapGroupDecodeSearchedValue',
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
                            title => 'linkedinParams',
                            help  => 'authlinkedin.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'linkedInAuthnLevel',   'linkedInClientID',
                                'linkedInClientSecret', 'linkedInFields',
                                'linkedInUserField',    'linkedInScope'
                            ]
                        },
                        {
                            title => 'combinationParams',
                            help  => 'authcombination.html',
                            nodes => [ 'combination', 'combModules' ]
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
                            form  => 'simpleInputContainer',
                            nodes => [
                                'oidcAuthnLevel',
                                'oidcRPCallbackGetParam',
                                'oidcRPStateTimeout'
                            ]
                        },
                        {
                            title => 'gpgParams',
                            help  => 'authgpg.html',
                            form  => 'simpleInputContainer',
                            nodes => [ 'gpgAuthnLevel', 'gpgDb' ],
                        },
                        {
                            title => 'proxyParams',
                            help  => 'authproxy.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'proxyAuthnLevel',     'proxyAuthService',
                                'proxySessionService', 'remoteCookieName',
                                'proxyUseSoap'
                            ]
                        },
                        {
                            title => 'pamParams',
                            help  => 'authpam.html',
                            form  => 'simpleInputContainer',
                            nodes => [ 'pamAuthnLevel', 'pamService' ]
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
                            title => 'restParams',
                            help  => 'authrest.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'restAuthnLevel', 'restAuthUrl',
                                'restUserDBUrl',  'restPwdConfirmUrl',
                                'restPwdModifyUrl'
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
                            nodes => [
                                'SSLAuthnLevel', 'SSLVar',
                                'SSLVarIf',      'sslByAjax',
                                'sslHost',
                            ]
                        },
                        {
                            title => 'twitterParams',
                            help  => 'authtwitter.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'twitterAuthnLevel', 'twitterKey',
                                'twitterSecret',     'twitterAppName',
                                'twitterUserField'
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
                            title => 'customParams',
                            help  => 'authcustom.html',
                            nodes => [
                                'customAuth',     'customUserDB',
                                'customPassword', 'customRegister',
                                'customAddParams',
                            ]
                        },
                    ],
                    'nodes_filter' => 'authParams'
                },
                {
                    title => 'issuerParams',
                    help  => 'start.html#identity_provider',
                    nodes => [ {
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
                            help  => 'idpcas.html#enabling_cas',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'issuerDBCASActivation', 'issuerDBCASPath',
                                'issuerDBCASRule',
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
                            form  => 'simpleInputContainer',
                            nodes => [
                                'issuerDBOpenIDConnectActivation',
                                'issuerDBOpenIDConnectPath',
                                'issuerDBOpenIDConnectRule',
                            ]
                        },
                        {
                            title => 'issuerDBGet',
                            help  => 'issuerdbget.html',
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
                    nodes => [ 'whatToTrace', 'hiddenAttributes' ]
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
                {
                    title => 'reloadParams',
                    help  => 'configlocation.html#configuration_reload',
                    nodes => [ 'reloadUrls', 'reloadTimeout', ]
                },
                {
                    title => 'plugins',
                    help  => 'start.html#plugins',
                    nodes => [
                        'stayConnected',
                        'portalStatus',
                        'upgradeSession',
                        {
                            title => 'portalServers',
                            help  => 'portalservers.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'wsdlServer',           'restSessionServer',
                                'restExportSecretKeys', 'restConfigServer',
                                'soapSessionServer',    'soapConfigServer',
                                'exportedAttr',
                            ]
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
                                'notificationServer',
                                'oldNotifFormat',
                                'notificationStorage',
                                'notificationStorageOptions',
                                'notificationWildcard',
                                'notificationXSLTfile'
                            ]
                        },
                        {
                            title => 'passwordManagement',
                            help  => 'resetpassword.html',
                            nodes => [ {
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
                                        'mailUrl', 'mailTimeout',
                                        'randomPasswordRegexp',
                                    ]
                                }
                            ]
                        },
                        {
                            title => 'register',
                            help  => 'register.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'registerUrl',
                                'registerTimeout',
                                'registerConfirmSubject',
                                'registerDoneSubject'
                            ]
                        },
                        {
                            title => 'autoSignin',
                            help  => 'autosignin.html',
                            nodes => ['autoSigninRules'],
                        },
                        {
                            title => 'stateCheck',
                            help  => 'checkstate.html',
                            form  => 'simpleInputContainer',
                            nodes => [ 'checkState', 'checkStateSecret', ],
                        },
                        {
                            title => 'checkUsers',
                            help  => 'checkuser.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'checkUser',
                                'checkUserIdRule',
                                'checkUserHiddenAttributes',
                                'checkUserDisplayPersistentInfo',
                                'checkUserDisplayEmptyValues',
                            ]
                        },
                        {
                            title => 'impersonation',
                            help  => 'impersonation.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'impersonationRule',
                                'impersonationIdRule',
                                'impersonationPrefix',
                                'impersonationHiddenAttributes',
                                'impersonationSkipEmptyValues',
                                'impersonationMergeSSOgroups',
                            ]
                        },
                    ]
                },
                {
                    title => 'secondFactors',
                    help  => 'secondfactor.html',
                    nodes => [ {
                            title => 'utotp2f',
                            help  => 'utotp2f.html',
                            form  => 'simpleInputContainer',
                            nodes =>
                              [ 'utotp2fActivation', 'utotp2fAuthnLevel' ]
                        },
                        {
                            title => 'totp',
                            help  => 'totp2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'totp2fActivation',
                                'totp2fSelfRegistration',
                                'totp2fAuthnLevel',
                                'totp2fIssuer',
                                'totp2fInterval',
                                'totp2fRange',
                                'totp2fDigits',
                                'totp2fDisplayExistingSecret',
                                'totp2fUserCanChangeKey',
                                'totp2fUserCanRemoveKey',
                                'totp2fTTL',
                            ]
                        },
                        {
                            title => 'u2f',
                            help  => 'u2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'u2fActivation', 'u2fSelfRegistration',
                                'u2fAuthnLevel', 'u2fUserCanRemoveKey',
                                'u2fTTL',
                            ]
                        },
                        {
                            title => 'mail2f',
                            help  => 'mail2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'mail2fActivation', 'mail2fCodeRegex',
                                'mail2fTimeout',    'mail2fSubject',
                                'mail2fBody',       'mail2fAuthnLevel',
                                'mail2fLogo',
                            ]
                        },
                        {
                            title => 'external2f',
                            help  => 'external2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'ext2fActivation',  'ext2fCodeActivation',
                                'ext2FSendCommand', 'ext2FValidateCommand',
                                'ext2fAuthnLevel',  'ext2fLogo',
                            ]
                        },
                        {
                            title => 'rest2f',
                            help  => 'rest2f.html',
                            nodes => [
                                'rest2fActivation', 'rest2fInitUrl',
                                'rest2fInitArgs',   'rest2fVerifyUrl',
                                'rest2fVerifyArgs', 'rest2fAuthnLevel',
                                'rest2fLogo',
                            ]
                        },
                        {
                            title => 'yubikey2f',
                            help  => 'yubikey2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'yubikey2fActivation',
                                'yubikey2fSelfRegistration',
                                'yubikey2fAuthnLevel',
                                'yubikey2fClientID',
                                'yubikey2fSecretKey',
                                'yubikey2fNonce',
                                'yubikey2fUrl',
                                'yubikey2fPublicIDSize',
                                'yubikey2fUserCanRemoveKey',
                                'yubikey2fTTL',
                            ],
                        },
                        {
                            title => 'sfRemovedNotification',
                            help  => 'secondfactor.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'sfRemovedMsgRule',  'sfRemovedUseNotif',
                                'sfRemovedNotifRef', 'sfRemovedNotifTitle',
                                'sfRemovedNotifMsg',
                            ],
                        },
                        'sfRequired',
                    ]
                },
                {
                    title => 'advancedParams',
                    help  => 'start.html#advanced_features',
                    nodes => [
                        'customFunctions',
                        'multiValuesSeparator',
                        {
                            title => 'SMTP',
                            help  => 'smtp.html',
                            nodes => [
                                'mailSessionKey',
                                'SMTPServer',
                                'SMTPPort',
                                'SMTPAuthUser',
                                'SMTPAuthPass',
                                'SMTPTLS',
                                'SMTPTLSOpts',
                                {
                                    title => 'mailHeaders',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'mailFrom', 'mailReplyTo',
                                        'mailCharset'
                                    ]
                                },
                            ]
                        },
                        {
                            title => 'security',
                            help => 'security.html#configure_security_settings',
                            nodes => [
                                'userControl',
                                'portalForceAuthn',
                                'portalForceAuthnInterval',
                                'key',
                                'trustedDomains',
                                'useSafeJail',
                                'checkXSS',
                                'bruteForceProtection',
                                'requireToken',
                                'formTimeout',
                                'tokenUseGlobalStorage',
                                'lwpOpts',
                                'lwpSslOpts',
                                {
                                    title => 'contentSecurityPolicy',
                                    help  => 'security.html#portal',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'cspDefault', 'cspImg',
                                        'cspScript',  'cspStyle',
                                        'cspFont',    'cspFormAction',
                                        'cspConnect',
                                    ]
                                },
                                {
                                    title => 'crossOrigineResourceSharing',
                                    help  => 'security.html#portal',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'corsEnabled',
                                        'corsAllow_Credentials',
                                        'corsAllow_Headers',
                                        'corsAllow_Methods',
                                        'corsAllow_Origin',
                                        'corsExpose_Headers',
                                        'corsMax_Age',
                                    ]
                                },
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
                            nodes => [
                                'jsRedirect', 'noAjaxHook',
                                'skipRenewConfirmation',
                            ]
                        },
                        'nginxCustomHandlers',
                        'logoutServices',
                        {
                            title => 'forms',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'infoFormMethod',     'confirmFormMethod',
                                'redirectFormMethod', 'activeTimer',
                            ]
                        },
                    ]
                }
            ]
        },
        {
            title => 'variables',
            help  => 'variables.html',
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
                    nodes => [ {
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
                        'samlServiceUseCertificateInResponse',
                        'samlServiceSignatureMethod'
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
                    nodes => [ {
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
                        },
                        {
                            title => 'samlDiscoveryProtocol',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'samlDiscoveryProtocolActivation',
                                'samlDiscoveryProtocolURL',
                                'samlDiscoveryProtocolPolicy',
                                'samlDiscoveryProtocolIsPassive'
                            ]
                        },
                        'samlOverrideIDPEntityID',
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
                        'oidcServiceMetaDataFrontChannelURI',
                        'oidcServiceMetaDataBackChannelURI',
                    ]
                },
                'oidcServiceMetaDataAuthnContext',
                {
                    title => 'oidcServiceMetaDataSecurity',
                    nodes => [ {
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
        {
            title => 'casServiceMetadata',
            help  => 'idpcas.html#configuring_the_cas_service',
            nodes => [
                'casAttr',
                'casAccessControlPolicy',
                'casStorage',
                'casStorageOptions',
                'casAttributes',

            ]
        },
        'casSrvMetaDataNodes',
        'casAppMetaDataNodes',
    ];
}

1;
