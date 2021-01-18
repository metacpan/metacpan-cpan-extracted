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

our $VERSION = '2.0.10';

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
                                'portalCustomCss',
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
                                        'portalDisplayRegister',
                                        'portalDisplayCertificateResetByMail'
                                    ]
                                },
                                {
                                    title => 'passwordManagement',
                                    help =>
                                      'portalcustom.html#password-management',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalRequireOldPassword',
                                        'hideOldPassword',
                                        'mailOnPasswordChange',
                                    ]
                                },
                                {
                                    title => 'passwordPolicy',
                                    help => 'portalcustom.html#password-policy',
                                    form => 'simpleInputContainer',
                                    nodes => [
                                        'passwordPolicyActivation',
                                        'portalDisplayPasswordPolicy',
                                        'passwordPolicyMinSize',
                                        'passwordPolicyMinLower',
                                        'passwordPolicyMinUpper',
                                        'passwordPolicyMinDigit',
                                        'passwordPolicyMinSpeChar',
                                        'passwordPolicySpecialChar',
                                    ]
                                },
                                {
                                    title => 'portalOther',
                                    help =>
                                      'portalcustom.html#other-parameters',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalUserAttr',
                                        'portalOpenLinkInNewWindow',
                                        'portalAntiFrame',
                                        'portalPingInterval',
                                        'portalErrorOnExpiredSession',
                                        'portalErrorOnMailNotFound',
                                        'portalDisplayRefreshMyRights',
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
                      'start.html#authentication-users-and-password-databases',
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
                            nodes => [
                                'authChoiceParam', 'authChoiceModules',
                                'authChoiceAuthBasic'
                            ]
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
                                'krbByJs',       'krbRemoveDomain',
                                'krbAllowedDomains',
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
                                        'ldapServer',  'ldapPort',
                                        'ldapVerify',  'ldapBase',
                                        'managerDn',   'managerPassword',
                                        'ldapTimeout', 'ldapIOTimeout',
                                        'ldapVersion', 'ldapRaw',
                                        'ldapCAFile',  'ldapCAPath',
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
                                        'ldapAllowResetExpiredPassword',
                                        'ldapGetUserBeforePasswordChange',
                                        'ldapITDS'
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
                            title => 'githubParams',
                            help  => 'authgithub.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'githubAuthnLevel',   'githubClientID',
                                'githubClientSecret', 'githubUserField',
                                'githubScope'
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
                                'slaveAuthnLevel',    'slaveUserHeader',
                                'slaveMasterIP',      'slaveHeaderName',
                                'slaveHeaderContent', 'slaveDisplayLogo',
                                'slaveExportedVars',
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
                                'customAuth',            'customUserDB',
                                'customPassword',        'customRegister',
                                'customResetCertByMail', 'customAddParams',
                            ]
                        },
                    ],
                    'nodes_filter' => 'authParams'
                },
                {
                    title => 'issuerParams',
                    help  => 'start.html#identity-provider',
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
                            help  => 'idpcas.html#enabling-cas',
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
                        {
                            title => 'issuerOptions',
                            help  => 'start.html#options',
                            form  => 'simpleInputContainer',
                            nodes => ['issuersTimeout']
                        },
                    ]
                },
                {
                    title => 'logParams',
                    help  => 'logs.html',
                    form  => 'simpleInputContainer',
                    nodes =>
                      [ 'whatToTrace', 'customToTrace', 'hiddenAttributes' ]
                },
                {
                    title => 'cookieParams',
                    help  => 'ssocookie.html',
                    form  => 'simpleInputContainer',
                    nodes => [
                        'cookieName', '*domain',
                        'cda',        'securedCookie',
                        'httpOnly',   'cookieExpiration',
                        'sameSite',
                    ]
                },
                {
                    title => 'sessionParams',
                    help  => 'sessions.html',
                    nodes => [
                        'storePassword',
                        'displaySessionId',
                        'timeout',
                        'timeoutActivity',
                        'timeoutActivityInterval',
                        'grantSessionRules',
                        {
                            title => 'sessionStorage',
                            help  => 'start.html#sessions-database',
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
                                'singleUserByIP', 'notifyDeleted',
                                'notifyOther'
                            ]
                        },
                        {
                            title => 'persistentSessions',
                            nodes => [
                                'disablePersistentStorage',
                                'persistentStorage',
                                'persistentStorageOptions'
                            ]
                        },
                    ]
                },
                {
                    title => 'reloadParams',
                    help  => 'configlocation.html#configuration-reload',
                    nodes => [ 'reloadTimeout', 'compactConf', 'reloadUrls' ]
                },
                {
                    title => 'plugins',
                    help  => 'start.html#plugins',
                    nodes => [
                        'portalStatus',
                        'upgradeSession',
                        'refreshSessions',
                        'adaptativeAuthenticationLevelRules',
                        {
                            title => 'stayConnect',
                            help  => 'stayconnected.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'stayConnected',
                                'stayConnectedTimeout',
                                'stayConnectedCookieName'
                            ],
                        },
                        {
                            title => 'portalServers',
                            help  => 'portalservers.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'wsdlServer',         'restExportSecretKeys',
                                'restClockTolerance', 'restSessionServer',
                                'restConfigServer',   'restAuthServer',
                                'restPasswordServer', 'soapSessionServer',
                                'soapConfigServer',   'exportedAttr',
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
                                'notificationsExplorer',
                                'notificationWildcard',
                                'oldNotifFormat',
                                'notificationXSLTfile',
                                'notificationStorage',
                                'notificationStorageOptions',
                                {
                                    title => 'serverNotification',
                                    help =>
                                      'notifications.html#notification-server',
                                    nodes => [
                                        'notificationServer',
                                        'notificationDefaultCond',
                                        'notificationServerSentAttributes',
                                        {
                                            title =>
                                              'notificationServerMethods',
                                            form  => 'simpleInputContainer',
                                            nodes => [
                                                'notificationServerPOST',
                                                'notificationServerGET',
                                                'notificationServerDELETE',
                                            ]
                                        },
                                    ]
                                },
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
                                        'mailUrl',
                                        'mailTimeout',
                                        'portalDisplayGeneratePassword',
                                        'randomPasswordRegexp',
                                    ]
                                }
                            ]
                        },
                        {
                            title => 'certificateResetByMailManagement',
                            help  => 'resetcertificate.html',
                            nodes => [ {
                                    title => 'certificateMailContent',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'certificateResetByMailStep1Subject',
                                        'certificateResetByMailStep1Body',
                                        'certificateResetByMailStep2Subject',
                                        'certificateResetByMailStep2Body'
                                    ]
                                },

                                {
                                    title => 'mailOther',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'certificateResetByMailURL',
                                        'certificateResetByMailCeaAttribute',
'certificateResetByMailCertificateAttribute',
                                        'certificateResetByMailValidityDelay'
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
                            title => 'globalLogout',
                            help  => 'globallogout.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'globalLogoutRule',
                                'globalLogoutTimer',
                                'globalLogoutCustomParam'
                            ],
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
                            nodes => [
                                'checkUser',
                                'checkUserIdRule',
                                'checkUserUnrestrictedUsersRule',
                                'checkUserHiddenAttributes',
                                'checkUserSearchAttributes',
                                'checkUserDisplayComputedSession',
                                'checkUserDisplayEmptyHeaders',
                                'checkUserDisplayEmptyValues',
                                'checkUserDisplayPersistentInfo',
                                'checkUserHiddenHeaders'
                            ]
                        },
                        {
                            title => 'impersonation',
                            help  => 'impersonation.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'impersonationRule',
                                'impersonationIdRule',
                                'impersonationUnrestrictedUsersRule',
                                'impersonationHiddenAttributes',
                                'impersonationSkipEmptyValues',
                                'impersonationMergeSSOgroups',
                            ]
                        },
                        {
                            title => 'contextSwitching',
                            help  => 'contextswitching.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'contextSwitchingRule',
                                'contextSwitchingIdRule',
                                'contextSwitchingUnrestrictedUsersRule',
                                'contextSwitchingAllowed2fModifications',
                                'contextSwitchingStopWithLogout',
                            ]
                        },
                        {
                            title => 'decryptValue',
                            help  => 'decryptvalue.html',
                            form  => 'simpleInputContainer',
                            nodes =>
                              [ 'decryptValueRule', 'decryptValueFunctions', ]
                        },
                        {
                            title => 'customPluginsNode',
                            help  => 'plugincustom.html',
                            nodes => [ 'customPlugins', 'customPluginsParams' ]
                        },
                    ]
                },
                {
                    title => 'secondFactors',
                    help  => 'secondfactor.html',
                    nodes => [
                        'sfManagerRule',
                        'sfRequired',
                        'sfOnlyUpgrade',
                        {
                            title => 'utotp2f',
                            help  => 'utotp2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'utotp2fActivation', 'utotp2fAuthnLevel',
                                'utotp2fLabel',      'utotp2fLogo'
                            ]
                        },
                        {
                            title => 'totp2f',
                            help  => 'totp2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'totp2fActivation',
                                'totp2fSelfRegistration',
                                'totp2fIssuer',
                                'totp2fInterval',
                                'totp2fRange',
                                'totp2fDigits',
                                'totp2fDisplayExistingSecret',
                                'totp2fUserCanChangeKey',
                                'totp2fUserCanRemoveKey',
                                'totp2fTTL',
                                'totp2fAuthnLevel',
                                'totp2fLabel',
                                'totp2fLogo',
                            ]
                        },
                        {
                            title => 'u2f',
                            help  => 'u2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'u2fActivation',       'u2fSelfRegistration',
                                'u2fUserCanRemoveKey', 'u2fTTL',
                                'u2fAuthnLevel',       'u2fLabel',
                                'u2fLogo',
                            ]
                        },
                        {
                            title => 'yubikey2f',
                            help  => 'yubikey2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'yubikey2fActivation',
                                'yubikey2fSelfRegistration',
                                'yubikey2fClientID',
                                'yubikey2fSecretKey',
                                'yubikey2fNonce',
                                'yubikey2fUrl',
                                'yubikey2fPublicIDSize',
                                'yubikey2fUserCanRemoveKey',
                                'yubikey2fFromSessionAttribute',
                                'yubikey2fTTL',
                                'yubikey2fAuthnLevel',
                                'yubikey2fLabel',
                                'yubikey2fLogo',
                            ],
                        },
                        {
                            title => 'mail2f',
                            help  => 'mail2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'mail2fActivation', 'mail2fCodeRegex',
                                'mail2fTimeout',    'mail2fSubject',
                                'mail2fBody',       'mail2fAuthnLevel',
                                'mail2fLabel',      'mail2fLogo',
                                'mail2fSessionKey',
                            ]
                        },
                        {
                            title => 'ext2f',
                            help  => 'external2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'ext2fActivation',  'ext2fCodeActivation',
                                'ext2FSendCommand', 'ext2FValidateCommand',
                                'ext2fAuthnLevel',  'ext2fLabel',
                                'ext2fLogo',
                            ]
                        },
                        {
                            title => 'radius2f',
                            help  => 'radius2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'radius2fActivation',
                                'radius2fServer',
                                'radius2fSecret',
                                'radius2fUsernameSessionKey',
                                'radius2fTimeout',
                                'radius2fAuthnLevel',
                                'radius2fLogo',
                                'radius2fLabel',
                            ]
                        },
                        {
                            title => 'rest2f',
                            help  => 'rest2f.html',
                            nodes => [
                                'rest2fActivation', 'rest2fInitUrl',
                                'rest2fInitArgs',   'rest2fVerifyUrl',
                                'rest2fVerifyArgs', 'rest2fAuthnLevel',
                                'rest2fLabel',      'rest2fLogo',
                            ]
                        },
                        'sfExtra',
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
                    ]
                },
                {
                    title => 'advancedParams',
                    help  => 'start.html#advanced-features',
                    nodes => [
                        'customFunctions',
                        'multiValuesSeparator',
                        'groupsBeforeMacros',
                        {
                            title => 'SMTP',
                            help  => 'smtp.html',
                            form  => 'SMTP',
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
                            help => 'security.html#configure-security-settings',
                            nodes => [
                                'userControl',
                                'browsersDontStorePassword',
                                'portalForceAuthn',
                                'portalForceAuthnInterval',
                                'key',
                                'trustedDomains',
                                'useSafeJail',
                                'avoidAssignment',
                                'checkXSS',
                                'requireToken',
                                'formTimeout',
                                'tokenUseGlobalStorage',
                                {
                                    title => 'bruteForceAttackProtection',
                                    help  => 'bruteforceprotection.html',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'bruteForceProtection',
                                        'bruteForceProtectionTempo',
                                        'bruteForceProtectionMaxFailed',
                                        'bruteForceProtectionIncrementalTempo',
                                        'bruteForceProtectionLockTimes',
                                    ]
                                },
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
                                        'cspConnect', 'cspFrameAncestors'
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
                            help  => 'redirections.html#portal-redirections',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'jsRedirect',
                                'noAjaxHook',
                                'skipRenewConfirmation',
                                'skipUpgradeConfirmation',
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
                    help  => 'samlservice.html#security-parameters',
                    nodes => [ {
                            title => 'samlServiceSecuritySig',
                            form  => 'RSACertKey',
                            group => [
                                'samlServicePrivateKeySig',
                                'samlServicePrivateKeySigPwd',
                                'samlServicePublicKeySig'
                            ]
                        },
                        {
                            title => 'samlServiceSecurityEnc',
                            form  => 'RSACertKey',
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
                    help  => 'samlservice.html#nameid-formats',
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
                    help  => 'samlservice.html#authentication-contexts',
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
                        'samlOrganizationDisplayName',
                        'samlOrganizationName',
                        'samlOrganizationURL'
                    ]
                },
                {
                    title => 'samlSPSSODescriptor',
                    help  => 'samlservice.html#service-provider',
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
                    help  => 'samlservice.html#identity-provider',
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
                    help  => 'samlservice.html#attribute-authority',
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
                        'samlMetadataForceUTF8',
                        'samlRelayStateTimeout',
                        'samlUseQueryStringSpecific',
                        'samlOverrideIDPEntityID',
                        'samlStorage',
                        'samlStorageOptions',
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
                    ]
                }
            ]
        },
        'samlIDPMetaDataNodes',
        'samlSPMetaDataNodes',
        {
            title => 'oidcServiceMetaData',
            help  => 'openidconnectservice.html#service-configuration',
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
                        'oidcServiceMetaDataIntrospectionURI',
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
                        'oidcServiceAuthorizationCodeExpiration',
                        'oidcServiceAccessTokenExpiration',
                        'oidcServiceIDTokenExpiration',
                        'oidcServiceOfflineSessionExpiration',
                    ],
                },
                {
                    title => "oidcServiceMetaDataSessions",
                    nodes => [ 'oidcStorage', 'oidcStorageOptions', ],
                },
                'oidcServiceDynamicRegistrationExportedVars',
                'oidcServiceDynamicRegistrationExtraClaims',
            ]
        },
        'oidcOPMetaDataNodes',
        'oidcRPMetaDataNodes',
        {
            title => 'casServiceMetadata',
            help  => 'idpcas.html#configuring-the-cas-service',
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
