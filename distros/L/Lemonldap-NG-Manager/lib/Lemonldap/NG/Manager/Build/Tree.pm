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
# All other ideas have to be set in Manager/Build/Attributes.pm!

# DO NOT FORGET TO RUN "make json" AFTER EACH CHANGE

package Lemonldap::NG::Manager::Build::Tree;

our $VERSION = '2.21.0';

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
                                    help  => 'portalmenu.html#menu-modules',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalDisplayAppslist',
                                        'portalDisplayLoginHistory',
                                        'portalDisplayChangePassword',
                                        'portalDisplayOidcConsents',
                                        'portalDisplayLogout',
                                        'portalDisplayOrder'
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
                                'portalFavicon',
                                'showLanguages',
                                'scrollTop',
                                'floatingCategoryName',
                                'portalCustomCss',
                                'portalCustomJs',
                                'portalSkin',
                                'portalSkinBackground',
                                'portalSkinRules',
                                {
                                    title => 'portalButtons',
                                    help  => 'portalcustom.html#buttons',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalCheckLogins',
                                        'portalDisplayRegister',
                                        'portalDisplayCertificateResetByMail',
                                        'portalDisplayResetPassword'
                                    ]
                                },
                                {
                                    title => 'passwordManagement',
                                    help  =>
                                      'portalcustom.html#password-management',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'portalRequireOldPassword',
                                        'portalEnablePasswordDisplay',
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
                                        'passwordPolicyMaxSize',
                                        'passwordPolicyMinLower',
                                        'passwordPolicyMinUpper',
                                        'passwordPolicyMinDigit',
                                        'passwordPolicyMinSpeChar',
                                        'passwordPolicySpecialChar',
                                    ]
                                },
                                {
                                    title => 'portalOther',
                                    help  =>
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
                                        'cacheTagSalt',
                                    ]
                                }
                            ]
                        },
                        {
                            title => 'portalCaptcha',
                            help  => 'captcha.html#configuration',
                            nodes => [
                                'captcha_login_enabled',
                                'captcha_mail_enabled',
                                'captcha_register_enabled',
                                'captcha_size',
                                {
                                    title => 'captchaCustom',
                                    help  => 'captcha.html#configuration',
                                    nodes => [ 'captcha', 'captchaOptions', ]
                                },
                            ]
                        }
                    ]
                },
                {
                    title => 'authParams',
                    help  =>
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
                                'authChoiceParam',     'authChoiceModules',
                                'authChoiceAuthBasic', 'authChoiceFindUser',
                                'authChoiceSelectOnly',
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
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'dbiAuthChain', 'dbiAuthUser',
                                        'dbiAuthPassword'
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
                            title => 'webauthnParams',
                            form  => 'simpleInputContainer',
                            help  => 'authwebauthn.html',
                            nodes => [ 'webauthnAuthnLevel', ]
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
                                        'groupLDAPFilter',
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
                            nodes => [
                                'proxyAuthnLevel',
                                'proxyUseSoap',
                                {
                                    title => 'proxyInternalPortal',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'proxyAuthService',
                                        'proxySessionService',
                                        'proxyAuthServiceChoiceParam',
                                        'proxyAuthServiceChoiceValue',
                                        'proxyCookieName',
                                        'proxyAuthServiceImpersonation',
                                    ]
                                }
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
                            nodes => [
                                'radiusAuthnLevel',
                                'radiusSecret',
                                'radiusServer',
                                'radiusTimeout',
                                'radiusMsgAuth',
                                'radiusExportedVars',
                                'radiusDictionaryFile',
                                'radiusRequestAttributes',
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
                                'SSLIssuerVar',  'SSLVarIf',
                                'sslByAjax',     'sslHost',
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
                            title => 'issuerDBCAS',
                            help  => 'idpcas.html#enabling-cas',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'issuerDBCASActivation', 'issuerDBCASPath',
                                'issuerDBCASRule',
                            ]
                        },
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
                            title => 'issuerDBJitsiMeetTokens',
                            help  => 'idpjitsimeettokens.html',
                            nodes => [
                                'issuerDBJitsiMeetTokensActivation',
                                'issuerDBJitsiMeetTokensPath',
                                'issuerDBJitsiMeetTokensRule',
                                {
                                    title => 'jitsiOptions',
                                    nodes => [
                                        'jitsiDefaultServer',
                                        'jitsiAppId',
                                        'jitsiAppSecret',
                                        'jitsiSigningAlg',
                                        'jitsiExpiration',
                                        {
                                            title => 'jitsiAttributes',
                                            form  => 'simpleInputContainer',
                                            nodes => [
                                                'jitsiIdAttribute',
                                                'jitsiNameAttribute',
                                                'jitsiMailAttribute',
                                            ]
                                        }
                                    ]
                                }
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
                        'cookieName',    '*domain',
                        'cda',           'httpOnly',
                        'securedCookie', 'sameSite',
                        'cookieExpiration',
                    ]
                },
                {
                    title => 'sessionParams',
                    help  => 'sessions.html',
                    nodes => [
                        'storePassword',
                        'storePasswordEncrypted',
                        'displaySessionId',
                        'timeout',
                        'timeoutActivity',
                        'timeoutActivityInterval',
                        'grantSessionRules',
                        'appAccessHistoryEnabled',
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
                    title => 'plugins',
                    help  => 'start.html#plugins',
                    nodes => [
                        'upgradeSession',
                        'refreshSessions',
                        'portalStatus',
                        {
                            title => 'stateCheck',
                            help  => 'checkstate.html',
                            form  => 'simpleInputContainer',
                            nodes => [ 'checkState', 'checkStateSecret', ],
                        },
                        {
                            title => 'portalServers',
                            help  => 'portalservers.html',
                            nodes => [
                                'exportedAttr',
                                {
                                    title => 'restServices',
                                    help  => 'portalservers.html#REST',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'restSessionServer',
                                        'restConfigServer',
                                        'restAuthServer',
                                        'restPasswordServer',
                                        'restExportSecretKeys',
                                        'restClockTolerance',
                                    ]
                                },
                                {
                                    title => 'soapServices',
                                    help  =>
                                      'portalservers.html#SOAP_(deprecated)',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'soapSessionServer',
                                        'soapConfigServer',
                                        'wsdlServer',
                                    ]
                                },
                            ]
                        },
                        {
                            title => 'register',
                            help  => 'register.html',
                            nodes => [ {
                                    title => 'mailContent',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'registerConfirmSubject',
                                        'registerConfirmBody',
                                        'registerDoneSubject',
                                        'registerDoneBody'
                                    ]
                                },
                                {
                                    title => 'mailOther',
                                    form  => 'simpleInputContainer',
                                    nodes =>
                                      [ 'registerUrl', 'registerTimeout' ]
                                }
                            ]
                        },
                        {
                            title => 'passwordResetByMailManagement',
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
                                        'passwordResetAllowedRetries',
                                        'portalDisplayGeneratePassword',
                                        'randomPasswordRegexp'
                                    ]
                                }
                            ]
                        },
                        {
                            title => 'certificateResetByMailManagement',
                            help  => 'resetcertificate.html',
                            nodes => [ {
                                    title => 'mailContent',
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
                        'adaptativeAuthenticationLevelRules',
                        'autoSigninRules',
                        {
                            title => 'stayConnect',
                            help  => 'trustedbrowser.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'trustedBrowserRule',
                                'stayConnected',
                                'stayConnectedBypassFG',
                                'stayConnectedTimeout',
                                'stayConnectedCookieName',
                                'stayConnectedSingleSession',
                                'trustedBrowserUseTotp',
                            ],
                        },
                        {
                            title => 'rememberAuthChoice',
                            help  => 'rememberauthchoice.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'rememberAuthChoiceRule',
                                'rememberCookieName',
                                'rememberCookieTimeout',
                                'rememberDefaultChecked',
                                'rememberTimer',
                                'rememberAuthChoiceForgetAtLogout',
                            ]
                        },
                        {
                            title => 'locationDetectPlugin',
                            help  => 'locationdetect.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'locationDetect',
                                'locationDetectGeoIpDatabase',
                                'locationDetectGeoIpLanguages',
                                'locationDetectIpDetail',
                                'locationDetectUaDetail'
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
                                'publicNotifications',
                                'notificationsExplorer',
                                'notificationWildcard',
                                'oldNotifFormat',
                                'notificationXSLTfile',
                                'notificationStorage',
                                'notificationStorageOptions',
                                {
                                    title => 'serverNotification',
                                    help  =>
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
                            title => 'checkUsers',
                            help  => 'checkuser.html',
                            nodes => [
                                'checkUser',
                                'checkUserIdRule',
                                'checkUserUnrestrictedUsersRule',
                                'checkUserSearchAttributes',
                                'checkUserHiddenAttributes',
                                'checkUserHiddenHeaders',
                                {
                                    title => 'checkUserDisplay',
                                    help  => 'checkuser.html#configuration',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'checkUserDisplayComputedSession',
                                        'checkUserDisplayPersistentInfo',
                                        'checkUserDisplayNormalizedHeaders',
                                        'checkUserDisplayEmptyHeaders',
                                        'checkUserDisplayEmptyValues',
                                        'checkUserDisplayHiddenAttributes',
                                        'checkUserDisplayHistory'
                                    ]
                                },
                            ]
                        },
                        {
                            title => 'devOpsCheck',
                            help  => 'checkdevops.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'checkDevOps',
                                'checkDevOpsDownload',
                                'checkDevOpsDisplayNormalizedHeaders',
                                'checkDevOpsCheckSessionAttributes'
                            ],
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
                                'impersonationMergeSSOgroups'
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
                            title => 'findUsers',
                            help  => 'finduser.html',
                            nodes => [
                                'findUser',
                                'findUserWildcard',
                                'findUserControl',
                                'restFindUserDBUrl',
                                'findUserSearchingAttributes',
                                'findUserExcludingAttributes'
                            ]
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
                            title => 'decryptValue',
                            help  => 'decryptvalue.html',
                            form  => 'simpleInputContainer',
                            nodes =>
                              [ 'decryptValueRule', 'decryptValueFunctions', ]
                        },
                        {
                            title => 'initializePasswordResetLabel',
                            help  => 'initializePasswordReset.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'initializePasswordReset',
                                'initializePasswordResetSecret',
                            ],
                        },
                        {
                            title => 'customPluginsNode',
                            help  => 'plugincustom.html#plugin-options',
                            nodes => [ 'customPlugins', 'customPluginsParams', 'disabledPlugins' ]
                        },
                    ]
                },
                {
                    title => 'secondFactors',
                    help  => 'secondfactor.html',
                    nodes => [ {
                            title => 'sfOptions',
                            help  => 'secondfactor.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'sfManagerRule',
                                'sfRequired',
                                'sfOnlyUpgrade',
                                'sfLoginTimeout',
                                'sfRegisterTimeout',
                                'sfRetries',
                                {
                                    title => 'sfRemovedNotification',
                                    help  => 'secondfactor.html',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'sfRemovedMsgRule',
                                        'sfRemovedUseNotif',
                                        'sfRemovedNotifRef',
                                        'sfRemovedNotifTitle',
                                        'sfRemovedNotifMsg'
                                    ],
                                }
                            ]
                        },
                        {
                            title => 'totp2f',
                            help  => 'totp2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'totp2fActivation',
                                'totp2fSelfRegistration',
                                'totp2fUserCanRemoveKey',
                                'totp2fIssuer',
                                'totp2fInterval',
                                'totp2fRange',
                                'totp2fDigits',
                                'totp2fEncryptSecret',
                                'totp2fAuthnLevel',
                                'totp2fLabel',
                                'totp2fLogo',
                                'totp2fTTL'
                            ]
                        },
                        {
                            title => 'webauthn2f',
                            help  => 'webauthn2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'webauthn2fActivation',
                                'webauthn2fSelfRegistration',
                                'webauthn2fUserCanRemoveKey',
                                'webauthn2fUserVerification',
                                'webauthn2fResidentKey',
                                'webauthn2fAttestation',
                                'webauthn2fAttestationTrust',
                                'webauthnRpName',
                                'webauthnRpId',
                                'webauthnAppId',
                                'webauthnDisplayNameAttr',
                                'webauthnDefaultTransports',
                                'webauthn2fAuthnLevel',
                                'webauthn2fLabel',
                                'webauthn2fLogo',
                            ]
                        },
                        {
                            title => 'yubikey2f',
                            help  => 'yubikey2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'yubikey2fActivation',
                                'yubikey2fSelfRegistration',
                                'yubikey2fUserCanRemoveKey',
                                'yubikey2fClientID',
                                'yubikey2fSecretKey',
                                'yubikey2fNonce',
                                'yubikey2fUrl',
                                'yubikey2fPublicIDSize',
                                'yubikey2fFromSessionAttribute',
                                'yubikey2fAuthnLevel',
                                'yubikey2fLabel',
                                'yubikey2fLogo',
                                'yubikey2fTTL'
                            ],
                        },
                        {
                            title => 'password2f',
                            help  => 'password2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'password2fActivation',
                                'password2fSelfRegistration',
                                'password2fAuthnLevel',
                                'password2fLabel',
                                'password2fLogo',
                                'password2fUserCanRemoveKey',
                                'password2fTTL',
                            ]
                        },
                        {
                            title => 'mail2f',
                            help  => 'mail2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'mail2fActivation',     'mail2fCodeRegex',
                                'mail2fTimeout',        'mail2fSubject',
                                'mail2fBody',           'mail2fSessionKey',
                                'mail2fResendInterval', 'mail2fAuthnLevel',
                                'mail2fLabel',          'mail2fLogo'
                            ]
                        },
                        {
                            title => 'ext2f',
                            help  => 'external2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'ext2fActivation',     'ext2fCodeActivation',
                                'ext2FSendCommand',    'ext2FValidateCommand',
                                'ext2fResendInterval', 'ext2fAuthnLevel',
                                'ext2fLabel',          'ext2fLogo',
                            ]
                        },
                        {
                            title => 'okta2f',
                            help  => 'okta2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'okta2fActivation', 'okta2fAdminURL',
                                'okta2fApiKey',     'okta2fLoginAttribute',
                                'okta2fAuthnLevel', 'okta2fLabel',
                                'okta2fLogo',
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
                                'radius2fMsgAuth',
                                'radius2fDictionaryFile',
                                'radius2fRequestAttributes',
                                'radius2fSendInitialRequest',
                                'radius2fAuthnLevel',
                                'radius2fLabel',
                                'radius2fLogo'
                            ]
                        },
                        {
                            title => 'rest2f',
                            help  => 'rest2f.html',
                            form  => 'simpleInputContainer',
                            nodes => [
                                'rest2fActivation',
                                'rest2fCodeActivation',
                                'rest2fInitUrl',
                                'rest2fInitArgs',
                                'rest2fVerifyUrl',
                                'rest2fVerifyArgs',
                                'rest2fResendInterval',
                                'rest2fAuthnLevel',
                                'rest2fLabel',
                                'rest2fLogo'
                            ]
                        },
                        'sfExtra',
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
                                'strictTransportSecurityMax_Age',
                                'hashedSessionStore',
                                {
                                    title => 'CrowdSecPlugin',
                                    help  => 'crowdsec.html',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'crowdsec',
                                        'crowdsecAction',
                                        'crowdsecUrl',
                                        'crowdsecKey',
                                        'crowdsecIgnoreFailures',
                                    ],
                                },
                                {
                                    title => 'HIBPcheck',
                                    help  => 'checkhibp.html',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'checkHIBP', 'checkHIBPURL',
                                        'checkHIBPRequired'
                                    ],
                                },
                                {
                                    title => 'Entropycheck',
                                    help  => 'checkentropy.html',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'checkEntropy',
                                        'checkEntropyRequired',
                                        'checkEntropyRequiredLevel'
                                    ],
                                },
                                {
                                    title => 'newLocationWarnings',
                                    help  => 'newlocationwarning.html',
                                    form  => 'simpleInputContainer',
                                    nodes => [
                                        'newLocationWarning',
                                        'newLocationWarningLocationAttribute',
'newLocationWarningLocationDisplayAttribute',
                                        'newLocationWarningMaxValues',
                                        'newLocationWarningMailAttribute',
                                        'newLocationWarningMailSubject',
                                        'newLocationWarningMailBody'
                                    ]
                                },
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
                                        'bruteForceProtectionMaxLockTime',
                                        'bruteForceProtectionMaxAge'
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
                                'useRedirectAjaxOnUnauthorized',
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
                        {
                            title => 'eventsManagement',
                            help  => 'eventsmanagement.html',
                            nodes => [
                                'messageBroker', 'messageBrokerOptions',
                                'reloadTimeout', 'reloadUrls',
                                'compactConf',   'eventQueueName',
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
            form  => 'displaySamlMetadata',
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
                        'samlAuthnContextMapKerberos',
                        'samlAuthnContextMapTLSClient',
                        'samlAuthnContextMapExtra'
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
                            title => 'samlFederation',
                            form  => 'simpleInputContainer',
                            nodes => [ 'samlFederationFiles', ]
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
            form  => 'displayOidcMetadata',
            help  => 'openidconnectservice.html#service-configuration',
            nodes => [
                'oidcServiceMetaDataIssuer',
                {
                    title => 'oidcServiceMetaDataEndPoints',
                    help  => 'openidconnectservice.html#endpoints',
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
                'oidcServiceMetaDataAmrRules',
                {
                    title => "oidcServiceDynamicRegistration",
                    help  => 'openidconnectservice.html#dynamic-registration',
                    nodes => [
                        'oidcServiceAllowDynamicRegistration',
                        'oidcServiceDynamicRegistrationExportedVars',
                        'oidcServiceDynamicRegistrationExtraClaims',
                    ],
                },
                {
                    title => 'oidcServiceMetaDataSecurity',
                    help  => 'openidconnectservice.html#security',
                    nodes => [ {
                            title => 'oidcServiceMetaDataKeys',
                            nodes => [ {
                                    title => 'oidcServiceMetaDataSigKeys',
                                    form  => 'OidcKey',
                                    group => [
                                        'oidcServicePrivateKeySig',
                                        'oidcServicePublicKeySig',
                                        'oidcServiceKeyIdSig',
                                        'oidcServiceKeyTypeSig',
                                        'oidcServiceOldPrivateKeySig',
                                        'oidcServiceOldPublicKeySig',
                                        'oidcServiceOldKeyIdSig',
                                        'oidcServiceOldKeyTypeSig',
                                        'oidcServiceNewPrivateKeySig',
                                        'oidcServiceNewPublicKeySig',
                                        'oidcServiceNewKeyIdSig',
                                        'oidcServiceNewKeyTypeSig',
                                    ],
                                },
                                {
                                    title => 'oidcServiceMetaDataEncKeys',
                                    form  => 'OidcKey',
                                    group => [
                                        'oidcServicePrivateKeyEnc',
                                        'oidcServicePublicKeyEnc',
                                        'oidcServiceKeyIdEnc',
                                        'oidcServiceKeyTypeEnc',
                                        'oidcServiceOldPrivateKeyEnc',
                                        'oidcServiceOldPublicKeyEnc',
                                        'oidcServiceOldKeyIdEnc',
                                        'oidcServiceOldKeyTypeEnc',
                                    ],
                                },
                            ],
                        },
                        'oidcServiceAllowAuthorizationCodeFlow',
                        'oidcServiceAllowImplicitFlow',
                        'oidcServiceAllowHybridFlow',
                        'oidcServiceIgnoreScopeForClaims',
                        'oidcServiceAllowOnlyDeclaredScopes',
                        'oidcDropCspHeaders',
                        'oidcServiceEncAlgorithmAlg',
                        'oidcServiceEncAlgorithmEnc',
                        'oidcServiceHideMetadata',
                        'oidcServiceMetaDataDisallowNoneAlg',
                    ],
                },
                {
                    title => 'oidcServiceMetaDataTimeouts',
                    help  => 'openidconnectservice.html#timeouts',
                    form  => 'simpleInputContainer',
                    nodes => [
                        'oidcServiceAuthorizationCodeExpiration',
                        'oidcServiceIDTokenExpiration',
                        'oidcServiceAccessTokenExpiration',
                        'oidcServiceOfflineSessionExpiration',
                        'oidcServiceMetadataTtl',
                    ]
                },
                {
                    title => "oidcServiceMetaDataSessions",
                    help  => 'openidconnectservice.html#sessions',
                    nodes => [ 'oidcStorage', 'oidcStorageOptions' ],
                },
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
                'casStrictMatching',
                'casTicketExpiration',
                'casBackChannelSingleLogout',
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
