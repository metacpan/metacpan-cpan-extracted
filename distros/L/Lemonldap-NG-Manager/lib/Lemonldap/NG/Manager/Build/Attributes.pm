# This file contains the description of all configuration parameters
# It may be included only by batch files, never in portal or handler chain
# for performances reasons

# DON'T FORGET TO RUN jsongenerator.pl AFTER EACH CHANGE

package Lemonldap::NG::Manager::Build::Attributes;

our $VERSION = '1.9.11';
use strict;
use Regexp::Common qw/URI/;

my $perlExpr = sub {
    my ( $val, $conf ) = @_;
    my $s  = '';
    my @cf = qw(
      encode_base64 checkLogonHours date checkDate basic unicode2iso
      iso2unicode groupMatch encrypt
    );
    push @cf,
      defined $conf->{customFunctions}
      ? map { my $f = $_; $f =~ s/\w+:://g; ( $f, $_ ) }
      split( /\s+/, $conf->{customFunctions} )
      : ();
    foreach my $f (@cf) {
        $s = "sub $f {1} $s";
    }
    no warnings( 'redefine', 'uninitialized' );
    eval "$s $val";
    return $@ ? ( 1, "__badExpression__: $@" ) : (1);
};

my $url = $RE{URI}{HTTP}{ -scheme => "https?" };
$url =~ s/(?<=[^\\])\$/\\\$/g;
$url = qr/$url/;

sub types {
    return {

        # Simple text types
        text => {
            test    => sub { 1 },
            msgFail => '__malformedValue__',
        },
        password => {
            test    => sub { 1 },
            msgFail => '__malformedValue__',
        },
        longtext => {
            test => sub { 1 }
        },
        url => {
            form    => 'text',
            test    => $url,
            msgFail => '__badUrl__',
        },
        PerlModule => {
            form    => 'text',
            test    => qr/^[a-zA-Z][a-zA-Z0-9]*(?:::[a-zA-Z][a-zA-Z0-9]*)*$/,
            msgFail => '__badPerlPackageName__',
        },
        hostname => {
            form    => 'text',
            test    => qr/^(?:$Regexp::Common::URI::RFC2396::host)?$/,
            msgFail => '__badHostname__',
        },
        pcre => {
            form => 'text',
            test => sub {
                eval { qr/$_[0]/ };
                return $@ ? ( 0, "__badRegexp__: $@" ) : (1);
            },
        },
        lmAttrOrMacro => {
            form => 'text',
            test => sub {
                my ( $val, $conf ) = @_;
                return 1
                  if ( defined $conf->{macros}->{$val} or $val eq '_timezone' );
                foreach ( keys %$conf ) {
                    return 1
                      if ( $_ =~ /exportedvars$/i
                        and defined $conf->{$_}->{$val} );
                }
                return ( 1, "__unknownAttrOrMacro__: $val" );
            },
        },

        # Other types
        int => {
            test    => qr/^\-?\d+$/,
            msgFail => '__notAnInteger__',
        },
        bool => {
            test    => qr/^[01]$/,
            msgFail => '__notABoolean__',
        },
        trool => {
            test    => qr/^(?:-1|0|1)$/,
            msgFail => '__authorizedValues__: -1, 0, 1',
        },
        boolOrExpr => {
            test    => $perlExpr,
            msgFail => '__notAValidPerlExpression__',
        },
        keyTextContainer => {
            test       => qr/./,
            msgFail    => '__emptyValueNotAllowed__',
            keyTest    => qr/^\w[\w\.\-]*$/,
            keyMsgFail => '__badKeyName__',
        },
        subContainer => {
            keyTest => qr/\w/,
            test    => sub { 1 },
        },
        select => {
            test => sub {
                my $test =
                  grep (
                    { $_ eq $_[0] } map ( { $_->{k} } @{ $_[2]->{select} } ) );
                return $test
                  ? 1
                  : ( 0, "Invalid value '$_[0]' for this select" );
            },
        },

        # Files type (long text)
        file => {
            test => sub { 1 }
        },
        RSAPublicKey => {
            test => sub {
                return (
                    $_[0] =~
/^(?:(?:\-+\s*BEGIN\s+PUBLIC\s+KEY\s*\-+\r?\n)?[a-zA-Z0-9\/\+\r\n]+={0,2}(?:\r?\n\-+\s*END\s+PUBLIC\s+KEY\s*\-+)?[\r\n]*)?$/s
                    ? (1)
                    : ( 1, '__badPemEncoding__' )
                );
            },
        },
        'RSAPublicKeyOrCertificate' => {
            'test' => sub {
                return (
                    $_[0] =~
/^(?:(?:\-+\s*BEGIN\s+(?:PUBLIC\s+KEY|CERTIFICATE)\s*\-+\r?\n)?[a-zA-Z0-9\/\+\r\n]+={0,2}(?:\r?\n\-+\s*END\s+(?:PUBLIC\s+KEY|CERTIFICATE)\s*\-+)?[\r\n]*)?$/s
                    ? (1)
                    : ( 1, '__badPemEncoding__' )
                );
            },
        },
        RSAPrivateKey => {
            test => sub {
                return (
                    $_[0] =~
/^(?:(?:\-+\s*BEGIN\s+(?:RSA\s+)?PRIVATE\s+KEY\s*\-+\r?\n)?[a-zA-Z0-9\/\+\r\n]+={0,2}(?:\r?\n\-+\s*END\s+(?:RSA\s+)PRIVATE\s+KEY\s*\-+)?[\r\n]*)?$/s
                    ? (1)
                    : ( 1, '__badPemEncoding__' )
                );
            },
        },

        authParamsText => {
            test => sub { 1 }
        },
        blackWhiteList => {
            test => sub { 1 }
        },
        catAndAppList => {
            test => sub { 1 }
        },
        keyText => {
            keyTest => qr/^[a-zA-Z0-9_]+$/,
            test    => qr/^.*$/,
            msgFail => '__badValue__',
        },
        menuApp => {
            test => sub { 1 }
        },
        menuCat => {
            test => sub { 1 }
        },
        oidcOPMetaDataNode => {
            test => sub { 1 }
        },
        oidcRPMetaDataNode => {
            test => sub { 1 }
        },
        oidcmetadatajson => {
            test => sub { 1 }
        },
        oidcmetadatajwks => {
            test => sub { 1 }
        },
        portalskin => {
            test => sub { 1 }
        },
        portalskinbackground => {
            test => sub { 1 }
        },
        post => {
            test => sub { 1 }
        },
        rule => {
            test => sub { 1 }
        },
        samlAssertion => {
            test => sub { 1 }
        },
        samlAttribute => {
            test => sub { 1 }
        },
        samlIDPMetaDataNode => {
            test => sub { 1 }
        },
        samlSPMetaDataNode => {
            test => sub { 1 }
        },
        samlService => {
            test => sub { 1 }
        },
    };
}

sub attributes {
    return {

        # Other
        cfgNum => {
            type          => 'int',
            default       => 0,
            documentation => 'Enable Cross Domain Authentication',
        },
        cfgAuthor => {
            type          => 'text',
            documentation => 'Name of the author of the current configuration',
        },
        cfgAuthorIP => {
            type          => 'text',
            documentation => 'Uploader IP address of the current configuration',
        },
        cfgDate => {
            type          => 'int',
            documentation => 'Timestamp of the current configuration',
        },
        cfgLog => {
            type          => 'longtext',
            documentation => 'Configuration update log',
        },
        confirmFormMethod => {
            type => "select",
            select =>
              [ { k => 'get', v => 'GET' }, { k => 'post', v => 'POST' }, ],
            default       => 'post',
            documentation => 'HTTP method for confirm page form',
        },
        customFunctions => {
            type          => 'text',
            test          => qr/^(?:\w+(?:::\w+)*(?:\s+\w+(?:::\w+)*)*)?$/,
            msgFail       => "__badCustomFuncName__",
            documentation => 'List of custom functions'
        },
        https => {
            default       => 0,
            type          => 'bool',
            documentation => 'Use HTTPS for redirection from portal',
        },
        infoFormMethod => {
            type => "select",
            select =>
              [ { k => 'get', v => 'GET' }, { k => 'post', v => 'POST' }, ],
            default       => 'get',
            documentation => 'HTTP method for info page form',
        },
        port       => { type => 'int', },
        jsRedirect => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Use javascript for redirections',
        },
        logoutServices => {
            type          => 'keyTextContainer',
            help          => 'logoutforward.html',
            default       => {},
            documentation => 'Send logout trough GET request to these services',
        },
        maintenance => {
            default       => 0,
            type          => 'bool',
            documentation => 'Maintenance mode for all virtual hosts',
        },
        nginxCustomHandlers => {
            type    => 'keyTextContainer',
            keyTest => qr/^\w+$/,
            test    => qr/^[a-zA-Z][a-zA-Z0-9]*(?:::[a-zA-Z][a-zA-Z0-9]*)*$/,
            msgFail => '__badPerlPackageName__',
        },
        noAjaxHook => {
            default       => 0,
            type          => 'bool',
            documentation => 'Avoid replacing 302 by 401 for Ajax responses',
        },
        portal => {
            type          => 'url',
            default       => 'http://auth.example.com/',
            documentation => 'Portal URL',
        },
        portalUserAttr => {
            type    => 'text',
            default => '_user',
            documentation =>
              'Session parameter to display connected user in portal',
        },
        redirectFormMethod => {
            type => "select",
            select =>
              [ { k => 'get', v => 'GET' }, { k => 'post', v => 'POST' }, ],
            default       => 'get',
            documentation => 'HTTP method for redirect page form',
        },
        reloadUrls => {
            type    => 'keyTextContainer',
            help    => 'configlocation.html#configuration_reload',
            keyTest => qr/^$Regexp::Common::URI::RFC2396::host(?::\d+)?$/,
            test    => $url,
            msgFail => '__badUrl__'
        },
        staticPrefix => {
            type          => 'text',
            documentation => 'Prefix of static files for HTML templates',
        },
        syslog => {
            type => 'text',
            test => qr/^(?:auth|authpriv|daemon|local\d|user)?$/,
            msgFail =>
              '__authorizedValues__: auth, authpriv, daemon, local0-7, user',
            default       => '',
            documentation => 'Syslog facility',
        },

        # Manager
        protection => {
            type          => 'text',
            test          => qr/^(?:none|authenticate|manager|)$/,
            msgFail       => '__authorizedValues__: none authenticate manager',
            default       => 'none',
            documentation => 'Manager protection method',
        },

        # Menu
        activeTimer => {
            type          => 'bool',
            default       => 1,
            documentation => 'Enable timers on portal pages',
        },
        applicationList => {
            type    => 'catAndAppList',
            keyTest => qr/\w/,
            help    => 'portalmenu.html#categories_and_applications',
            default => {
                default => { catname => 'Default category', type => "category" }
            },
            documentation => 'Applications list',
        },
        portalErrorOnExpiredSession => {
            type          => 'bool',
            default       => 1,
            documentation => 'Show error if session is expired',
        },
        portalErrorOnMailNotFound => {
            type    => 'bool',
            default => 0,
            documentation =>
              'Show error if mail is not found in password reset process',
        },
        portalOpenLinkInNewWindow => {
            type          => 'bool',
            default       => 0,
            documentation => 'Open applications in new windows',
        },
        portalPingInterval => {
            type          => 'int',
            default       => 60000,
            documentation => 'Interval in ms between portal Ajax pings ',
        },
        portalSkin => {
            type          => 'portalskin',
            default       => 'bootstrap',
            documentation => 'Name of portal skin',
            select        => [
                { k => 'bootstrap', v => 'Bootstrap' },
                { k => 'pastel',    v => 'Pastel' },
                { k => 'impact',    v => 'Impact' },
                { k => 'dark',      v => 'Dark' },
            ],
        },
        portalSkinBackground => {
            type          => 'portalskinbackground',
            documentation => 'Background image of portal skin',
            select        => [
                { k => "", v => 'None' },
                {
                    k => "1280px-Anse_Source_d'Argent_2-La_Digue.jpg",
                    v => 'Anse'
                },
                {
                    k =>
"1280px-Autumn-clear-water-waterfall-landscape_-_Virginia_-_ForestWander.jpg",
                    v => 'Waterfall'
                },
                { k => "1280px-BrockenSnowedTrees.jpg", v => 'Snowed Trees' },
                {
                    k => "1280px-Cedar_Breaks_National_Monument_partially.jpg",
                    v => 'National Monument'
                },
                {
                    k => "1280px-Parry_Peak_from_Winter_Park.jpg",
                    v => 'Winter'
                },
                { k => "Aletschgletscher_mit_Pinus_cembra1.jpg", v => 'Pinus' },
            ],
        },
        portalSkinRules => {
            type       => 'keyTextContainer',
            help       => 'portalcustom.html',
            keyTest    => $perlExpr,
            keyMsgFail => '__badSkinRule__',
            test       => qr/^\w+$/,
            msgFail    => '__badValue__',
        },

        # Security
        cda => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable Cross Domain Authentication',
        },
        checkXSS => {
            default       => 1,
            type          => 'bool',
            documentation => 'Check XSS',
        },
        grantSessionRules => {
            type    => 'grantContainer',
            keyTest => $perlExpr,
            test    => sub { 1 },
        },
        hiddenAttributes => {
            type          => 'text',
            default       => '_password',
            documentation => 'Name of attributes to hide in logs',
        },
        key => {
            type          => 'password',
            documentation => 'Secret key',
        },
        portalAntiFrame => {
            default       => 1,
            type          => 'bool',
            documentation => 'Avoid portal to be displayed inside frames',
        },
        portalCheckLogins => {
            default       => 1,
            type          => 'bool',
            documentation => 'Display login history checkbox in portal',
        },
        portalForceAuthn => {
            default       => 0,
            type          => 'bool',
            documentation => 'Force to authenticate when displaying portal',
        },
        portalForceAuthnInterval => {
            type    => 'int',
            default => 5,
            documentation =>
'Minimum number of seconds since last authentifcation to force reauthentication',
        },
        randomPasswordRegexp => {
            type          => 'pcre',
            default       => '[A-Z]{3}[a-z]{5}.\d{2}',
            documentation => 'Regular expression to create a random password',
        },
        trustedDomains => { type => 'text', },
        storePassword  => {
            default       => 0,
            type          => 'bool',
            documentation => 'Store password in session',
        },
        timeout => {
            type          => 'int',
            test          => sub { $_[0] > 0 },
            default       => 72000,
            documentation => 'Session timeout on server side',
        },
        timeoutActivity => {
            type          => 'int',
            test          => sub { $_[0] >= 0 },
            default       => 0,
            documentation => 'Session activity timeout on server side',
        },
        timeoutActivityInterval => {
            type          => 'int',
            test          => sub { $_[0] >= 0 },
            default       => 60,
            documentation => 'Update session timeout interval on server side',
        },
        trustedProxies => {
            type          => 'text',
            default       => '',
            documentation => 'Trusted proxies',
        },
        userControl => {
            type          => 'pcre',
            default       => '^[\w\.\-@]+$',
            documentation => 'Regular expression to validate login',
        },
        useRedirectOnError => {
            type          => 'bool',
            default       => 1,
            documentation => 'Use 302 redirect code for error (500)',
        },
        useRedirectOnForbidden => {
            default       => 0,
            type          => 'bool',
            documentation => 'Use 302 redirect code for forbidden (403)',
        },
        useSafeJail => {
            default       => 1,
            type          => 'bool',
            documentation => 'Activate Safe jail',
        },
        whatToTrace => {
            type          => 'lmAttrOrMacro',
            default       => 'uid',
            documentation => 'Session parameter used to fill REMOTE_USER',
        },
        lwpSslOpts => {
            type          => 'keyTextContainer',
            documentation => 'Options given to LWP::UserAgent',
        },

        # History
        failedLoginNumber => {
            default       => 5,
            type          => 'int',
            documentation => 'Number of failures stored in login history',
        },
        loginHistoryEnabled => {
            default       => 0,
            type          => 'bool',
            default       => 1,
            documentation => 'Enable login history',
        },
        portalDisplayLoginHistory => {
            type          => 'boolOrExpr',
            default       => 1,
            documentation => 'Display login history tab in portal',
        },
        successLoginNumber => {
            default       => 5,
            type          => 'int',
            documentation => 'Number of success stored in login history',
        },

        # Other displays
        portalDisplayAppslist => {
            type          => 'boolOrExpr',
            default       => 1,
            documentation => 'Display applications tab in portal',
        },
        portalDisplayChangePassword => {
            type          => 'boolOrExpr',
            default       => '$_auth =~ /^(LDAP|DBI|Demo)$/',
            documentation => 'Display password tab in portal',
        },
        portalDisplayLogout => {
            default       => 1,
            type          => 'boolOrExpr',
            documentation => 'Display logout tab in portal',
        },
        portalDisplayRegister => {
            default       => 1,
            type          => 'bool',
            documentation => 'Display register button in portal',
        },
        portalDisplayResetPassword => {
            default       => 1,
            type          => 'bool',
            documentation => 'Display reset password button in portal',
        },

        # Cookies
        cookieExpiration => { type => 'text', },
        cookieName       => {
            type          => 'text',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_-]*$/,
            msgFail       => '__badCookieName__',
            default       => 'lemonldap',
            documentation => 'Name of the main cookie',
        },
        domain => {
            type          => 'text',
            test          => qr/^(?:$Regexp::Common::URI::RFC2396::hostname)?/,
            msgFail       => '__badDomainName__',
            default       => 'example.com',
            documentation => 'DNS domain',
        },
        httpOnly => {
            default       => 1,
            type          => 'bool',
            documentation => 'Enable httpOnly flag in cookie',
        },
        securedCookie => {
            type   => 'select',
            select => [
                { k => '0', v => 'unsecuredCookie' },
                { k => '1', v => 'securedCookie' },
                { k => '2', v => 'doubleCookie' },
                { k => '3', v => 'doubleCookieForSingleSession' },
            ],
            default       => 0,
            documentation => 'Cookie securisation method',
        },

        # Notification
        notificationWildcard => {
            type          => 'text',
            default       => 'allusers',
            documentation => 'Notification string to match all users',
        },
        notificationXSLTfile => { type => 'text', },
        notification         => {
            default       => 0,
            type          => 'bool',
            documentation => 'Notification activation',
        },
        notificationStorage => {
            type          => 'PerlModule',
            default       => 'File',
            documentation => 'Notification backend',
        },
        notificationStorageOptions => {
            type    => 'keyTextContainer',
            default => { dirName => '/var/lib/lemonldap-ng/notifications', },
            documentation => 'Notification backend options',
        },

        # Captcha
        captcha_login_enabled => {
            default       => 0,
            type          => 'bool',
            documentation => 'Captcha on login page',
        },
        captcha_mail_enabled => {
            default       => 0,
            type          => 'bool',
            documentation => 'Captcha on password reset page',
        },
        captcha_register_enabled => {
            default       => 1,
            type          => 'bool',
            documentation => 'Captcha on account creation page',
        },
        captcha_size => {
            type          => 'int',
            default       => 6,
            documentation => 'Captcha size',
        },

        #captcha_data
        #captcha_output
        captchaStorage => {
            type          => 'PerlModule',
            default       => 'Apache::Session::File',
            documentation => 'Captcha backend module',
        },
        captchaStorageOptions => {
            type    => 'keyTextContainer',
            default => { 'Directory' => '/var/lib/lemonldap-ng/captcha/', },
            documentation => 'Captcha backend module options',
        },

        # Variables
        exportedVars => {
            type          => 'keyTextContainer',
            help          => 'exportedvars.html',
            keyTest       => qr/^!?[_a-zA-Z][a-zA-Z0-9_]*$/,
            keyMsgFail    => '__badVariableName__',
            test          => qr/^[_a-zA-Z][a-zA-Z0-9_:\-]*$/,
            msgFail       => '__badValue__',
            default       => { 'UA' => 'HTTP_USER_AGENT' },
            documentation => 'Main exported variables',
        },
        groups => {
            type => 'keyTextContainer',
            help =>
              'exportedvars.html#extend_variables_using_macros_and_groups',
            test          => $perlExpr,
            default       => {},
            documentation => 'Groups',
        },
        macros => {
            type => 'keyTextContainer',
            help =>
              'exportedvars.html#extend_variables_using_macros_and_groups',
            keyTest       => qr/^[_a-zA-Z][a-zA-Z0-9_]*$/,
            keyMsgFail    => '__badMacroName__',
            test          => $perlExpr,
            default       => {},
            documentation => 'Macros',
        },

        # Storage
        globalStorage => {
            type          => 'PerlModule',
            default       => 'Apache::Session::File',
            documentation => 'Session backend module',
        },
        globalStorageOptions => {
            type    => 'keyTextContainer',
            default => {
                'Directory'     => '/var/lib/lemonldap-ng/sessions/',
                'LockDirectory' => '/var/lib/lemonldap-ng/sessions/lock/',
                'generateModule' =>
                  'Lemonldap::NG::Common::Apache::Session::Generate::SHA256',
            },
            documentation => 'Session backend module options',
        },
        localSessionStorage => {
            type    => 'PerlModule',
            default => 'Cache::FileCache',
            , documentation => 'Sessions cache module',
        },
        localSessionStorageOptions => {
            type    => 'keyTextContainer',
            default => {
                'namespace'          => 'lemonldap-ng-sessions',
                'default_expires_in' => 600,
                'directory_umask'    => '007',
                'cache_root'         => '/tmp',
                'cache_depth'        => 3,
            },
            documentation => 'Sessions cache module options',
        },

        # Persistent storage
        persistentStorage        => { type => 'PerlModule', },
        persistentStorageOptions => { type => 'keyTextContainer', },
        sessionDataToRemember    => {
            type       => 'keyTextContainer',
            keyTest    => qr/^[_a-zA-Z][a-zA-Z0-9_]*$/,
            keyMsgFail => '__invalidSessionData__',
        },

        # SAML issuer
        issuerDBSAMLActivation => {
            default       => 0,
            type          => 'bool',
            documentation => 'SAML IDP activation',
        },
        issuerDBSAMLPath => {
            type          => 'pcre',
            default       => '^/saml/',
            documentation => 'SAML IDP request path',
        },
        issuerDBSAMLRule => {
            type          => 'boolOrExpr',
            default       => 1,
            documentation => 'SAML IDP rule',
        },

        # OpenID-Connect issuer
        issuerDBOpenIDConnectActivation => {
            type          => 'bool',
            default       => '0',
            documentation => 'OpenID Connect server activation',
        },
        issuerDBOpenIDConnectPath => {
            type          => 'text',
            default       => '^/oauth2/',
            documentation => 'OpenID Connect server request path',
        },
        issuerDBOpenIDConnectRule => {
            type          => 'boolOrExpr',
            default       => 1,
            documentation => 'OpenID Connect server rule',
        },

        # GET issuer
        issuerDBGetActivation => {
            type          => 'bool',
            default       => '0',
            documentation => 'Get issuer activation',
        },
        issuerDBGetPath => {
            type          => 'text',
            default       => '^/get/',
            documentation => 'Get issuer request path',
        },
        issuerDBGetRule => {
            type          => 'boolOrExpr',
            default       => 1,
            documentation => 'Get issuer rule',
        },
        issuerDBGetParameters => {
            type       => 'doubleHash',
            default    => {},
            keyTest    => qr/^$Regexp::Common::URI::RFC2396::hostname$/,
            keyMsgFail => '__badHostname__',
            test       => {
                keyTest    => qr/^(?=[^\-])[\w\-]+(?<=[^-])$/,
                keyMsgFail => '__badKeyName__',
                test       => sub {
                    my ( $val, $conf ) = @_;
                    return 1
                      if ( defined $conf->{macros}->{$val}
                        or $val eq '_timezone' );
                    foreach ( keys %$conf ) {
                        return 1
                          if ( $_ =~ /exportedvars$/i
                            and defined $conf->{$_}->{$val} );
                    }
                    return ( 1, "__unknownAttrOrMacro__: $val" );
                },
            },
            documentation => 'List of virtualHosts with their get parameters',
        },

        # Password
        mailOnPasswordChange => {
            default       => 0,
            type          => 'bool',
            documentation => 'Send a mail when password is changed',
        },
        portalRequireOldPassword => {
            default       => 1,
            type          => 'bool',
            documentation => 'Old password is required to change the password',
        },
        hideOldPassword => {
            default       => 0,
            type          => 'bool',
            documentation => 'Hide old password in portal',
        },

        # Mails
        mailBody    => { type => 'longtext', },
        mailCharset => {
            type          => 'text',
            default       => 'utf-8',
            documentation => 'Mail charset',
        },
        mailConfirmBody    => { type => 'longtext', },
        mailConfirmSubject => {
            type          => 'text',
            default       => '[LemonLDAP::NG] Password reset confirmation',
            documentation => 'Mail subject for reset confirmation',
        },
        mailFrom => {
            type          => 'text',
            default       => 'noreply@example.com',
            documentation => 'Sender email',
        },
        mailReplyTo    => { type => 'text', },
        mailSessionKey => {
            type          => 'text',
            default       => 'mail',
            documentation => 'Session parameter where mail is stored',
        },
        mailSubject => {
            type          => 'text',
            default       => '[LemonLDAP::NG] Your new password',
            documentation => 'Mail subject for new password email',
        },
        mailTimeout => {
            type          => 'int',
            default       => 0,
            documentation => 'Mail session timeout',
        },
        mailUrl => {
            type          => 'url',
            default       => 'http://auth.example.com/mail.pl',
            documentation => 'URL of password reset page',
        },
        SMTPServer => {
            type    => 'text',
            default => '',
            test    => qr/^(?:$Regexp::Common::URI::RFC2396::host(?::\d+)?)?$/,
            documentation => 'SMTP Server',
        },
        SMTPAuthUser => { type => 'text', },
        SMTPAuthPass => { type => 'password', },

        # Registration
        registerConfirmSubject => {
            type          => 'text',
            default       => '[LemonLDAP::NG] Account register confirmation',
            documentation => 'Mail subject for register confirmation',
        },
        registerDB => {
            type   => 'select',
            select => [
                { k => 'AD',   v => 'Active Directory' },
                { k => 'Demo', v => 'Demonstration' },
                { k => 'LDAP', v => 'LDAP' },
                { k => 'Null', v => 'None' },
            ],
            default       => 'Demo',
            documentation => 'Register module',
        },
        registerDoneSubject => {
            type          => 'text',
            default       => '[LemonLDAP::NG] Your new account',
            documentation => 'Mail subject when register is done',
        },
        registerTimeout => {
            default       => 0,
            type          => 'int',
            documentation => 'Register session timeout',
        },
        registerUrl => {
            type          => 'text',
            default       => 'http://auth.example.com/register.pl',
            documentation => 'URL of register page',
        },

        # Single session
        notifyDeleted => {
            default       => 1,
            type          => 'bool',
            documentation => 'Show deleted sessions in portal',
        },
        notifyOther => {
            default       => 0,
            type          => 'bool',
            documentation => 'Show other sessions in portal',
        },
        singleSession => {
            default       => 0,
            type          => 'bool',
            documentation => 'Allow only one session per user',
        },
        singleIP => {
            default       => 0,
            type          => 'bool',
            documentation => 'Allow only one session per IP',
        },
        singleUserByIP => {
            default => 0,
            type    => 'bool',
        },
        singleSessionUserByIP => {
            default       => 0,
            type          => 'bool',
            documentation => 'Allow only one session per user on an IP',
        },

        # SOAP server
        Soap => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable SOAP services',
        },
        exportedAttr => { type => 'text', },

        ## Virtualhosts

        # Fake attribute: used by manager REST API to agglomerate all other
        # nodes
        virtualHosts => {
            type     => 'virtualHostContainer',
            help     => 'configvhost.html',
            template => 'virtualHost',
        },

        locationRules => {
            type => 'ruleContainer',
            help => 'writingrulesand_headers.html#rules',
            test => {
                keyTest => sub {
                    eval { qr/$_[0]/ };
                    return $@ ? 0 : 1;
                },
                keyMsgFail => '__badRegexp__',
                test       => sub {
                    my ( $val, $conf ) = @_;
                    my $s = $val;
                    if ( $s =~ s/^logout(?:_(?:sso|app(?:_sso)?))?\s*// ) {
                        return $s =~ m{^(?:https?://.*)?$}
                          ? (1)
                          : ( 0, '__badUrl__' );
                    }
                    $s =~ s/\b(accept|deny|unprotect|skip)\b/1/g;
                    my @cf =
                      qw(encode_base64 checkLogonHours date checkDate basic unicode2iso iso2unicode groupMatch encrypt);
                    push @cf,
                      defined $conf->{customFunctions}
                      ? map { my $f = $_; $f =~ s/\w+:://g; ( $f, $_ ) }
                      split( /\s+/, $conf->{customFunctions} )
                      : ();
                    foreach my $f (@cf) {
                        $s = "sub $f {1} $s";
                    }
                    no warnings( 'redefine', 'uninitialized' );
                    eval $s;
                    return $@ ? ( 1, "__badExpression__: $@" ) : (1);
                },
                msgFail => '__badExpression__',
            },
            keyTest    => qr/^$Regexp::Common::URI::RFC2396::hostname$/,
            keyMsgFail => '__badHostname__',
            default    => {
                default => 'deny',
            },
            documentation => 'Virtualhost rules',
        },
        exportedHeaders => {
            type       => 'keyTextContainer',
            help       => 'writingrulesand_headers.html#headers',
            keyTest    => qr/^$Regexp::Common::URI::RFC2396::hostname$/,
            keyMsgFail => '__badHostname__',
            test       => {
                keyTest    => qr/^(?=[^\-])[\w\-]+(?<=[^-])$/,
                keyMsgFail => '__badHeaderName__',
                test       => sub {
                    my ( $val, $conf ) = @_;
                    my $s = $val;
                    my @cf =
                      qw(encode_base64 checkLogonHours date checkDate basic unicode2iso iso2unicode groupMatch encrypt);
                    push @cf,
                      defined $conf->{customFunctions}
                      ? map { my $f = $_; $f =~ s/\w+:://g; ( $f, $_ ) }
                      split( /\s+/, $conf->{customFunctions} )
                      : ();
                    foreach my $f (@cf) {
                        $s = "sub $f {1} $s";
                    }
                    no warnings( 'redefine', 'uninitialized' );
                    eval $s;
                    return $@ ? ( 1, "__badExpression__: $@" ) : (1);
                  }
            },
            documentation => 'Virtualhost headers',
        },
        post => {
            type          => 'postContainer',
            help          => 'formreplay.html',
            test          => sub { 1 },
            keyTest       => qr/^$Regexp::Common::URI::RFC2396::hostname$/,
            keyMsgFail    => '__badHostname__',
            documentation => 'Virtualhost urls/Datas to post',
        },

        vhostOptions => {
            type => 'subContainer',
        },
        vhostPort => {
            type    => 'int',
            default => -1,
        },
        vhostHttps => {
            type    => 'trool',
            default => -1,
        },
        vhostMaintenance => {
            type    => 'bool',
            default => 0,
        },
        vhostAliases => {
            type => 'text',
        },

        # CAS IDP
        casAttr                => { type => 'text', },
        casAttributes          => { type => 'keyTextContainer', },
        casAccessControlPolicy => {
            type   => 'select',
            select => [
                { k => 'none',       v => 'None' },
                { k => 'error',      v => 'Display error on portal' },
                { k => 'faketicket', v => 'Send a fake service ticket' },
            ],
            default       => 'none',
            documentation => 'CAS access control policy',
        },
        casStorage        => { type => 'PerlModule', },
        casStorageOptions => {
            type => 'keyTextContainer',
        },
        issuerDBCASActivation => {
            default       => 0,
            type          => 'bool',
            documentation => 'CAS server activation',
        },
        issuerDBCASPath => {
            type          => 'pcre',
            default       => '^/cas/',
            documentation => 'CAS server request path',
        },
        issuerDBCASRule => {
            type          => 'boolOrExpr',
            default       => 1,
            documentation => 'CAS server rule',
        },

        # OpenID Issuer
        issuerDBOpenIDActivation => {
            default       => 0,
            type          => 'bool',
            documentation => 'OpenID server activation',
        },
        issuerDBOpenIDPath => {
            type          => 'pcre',
            default       => '^/openidserver/',
            documentation => 'OpenID server request path',
        },
        issuerDBOpenIDRule => {
            type          => 'boolOrExpr',
            default       => 1,
            documentation => 'OpenID server rule',
        },

        openIdIssuerSecret  => { type => 'text', },
        openIdAttr          => { type => 'text', },
        openIdSreg_fullname => {
            type          => 'lmAttrOrMacro',
            default       => 'cn',
            documentation => 'OpenID SREG fullname session parameter',
        },
        openIdSreg_nickname => {
            type          => 'lmAttrOrMacro',
            default       => 'uid',
            documentation => 'OpenID SREG nickname session parameter',
        },
        openIdSreg_language => { type => 'lmAttrOrMacro', },
        openIdSreg_postcode => { type => 'lmAttrOrMacro', },
        openIdSreg_timezone => {
            type          => 'lmAttrOrMacro',
            default       => '_timezone',
            documentation => 'OpenID SREG timezone session parameter',
        },
        openIdSreg_country => { type => 'lmAttrOrMacro', },
        openIdSreg_gender  => { type => 'lmAttrOrMacro', },
        openIdSreg_email   => {
            type          => 'lmAttrOrMacro',
            default       => 'mail',
            documentation => 'OpenID SREG email session parameter',
        },
        openIdSreg_dob => { type => 'lmAttrOrMacro', },
        openIdSPList   => { type => 'blackWhiteList', default => '0;' },

        # Zimbra
        zimbraPreAuthKey => { type => 'text', },
        zimbraAccountKey => { type => 'text', },
        zimbraBy         => {
            type   => 'select',
            select => [
                { k => '',                 v => '' },
                { k => 'name',             v => 'User name' },
                { k => 'id',               v => 'User id' },
                { k => 'foreignPrincipal', v => 'Foreign principal' },
            ],
            default => '',
        },
        zimbraUrl    => { type => 'text', },
        zimbraSsoUrl => { type => 'text', },

        # Sympa
        sympaSecret  => { type => 'text', },
        sympaMailKey => { type => 'text', },

        # Secure Token
        secureTokenMemcachedServers => {
            type          => 'text',
            default       => '127.0.0.1:11211',
            documentation => 'Secure Token Handler memcached servers',
        },
        secureTokenExpiration => {
            type          => 'int',
            default       => 60,
            documentation => 'Secure Token Handler token expiration',
        },
        secureTokenAttribute => {
            type          => 'text',
            default       => 'uid',
            documentation => 'Secure Token Handler attribute to store',
        },
        secureTokenUrls => {
            type    => 'pcre',
            default => '.*',
            documentation =>
              'Secure Token Handler regular expression to match protected URL',
        },
        secureTokenHeader => {
            type          => 'text',
            default       => 'Auth-Token',
            documentation => 'Secure Token Handler header name',
        },
        secureTokenAllowOnError => {
            default       => 1,
            type          => 'bool',
            documentation => 'Secure Token Handler allow request on error',
        },
        #########
        ## SAML #
        #########
        samlEntityID => {
            type          => 'text',
            default       => '#PORTAL#/saml/metadata',
            documentation => 'SAML service entityID',
        },
        samlOrganizationDisplayName => {
            type          => 'text',
            default       => 'Example',
            documentation => 'SAML service organization display name',
        },
        samlOrganizationName => {
            type          => 'text',
            default       => 'Example',
            documentation => 'SAML service organization name',
        },
        samlOrganizationURL => {
            type          => 'text',
            default       => 'http://www.example.com',
            documentation => 'SAML service organization URL',
        },
        samlNameIDFormatMapEmail => {
            type          => 'text',
            default       => 'mail',
            documentation => 'SAML session parameter for NameID email',
        },
        samlNameIDFormatMapX509 => {
            type          => 'text',
            default       => 'mail',
            documentation => 'SAML session parameter for NameID x509',
        },
        samlNameIDFormatMapWindows => {
            type          => 'text',
            default       => 'uid',
            documentation => 'SAML session parameter for NameID windows',
        },
        samlNameIDFormatMapKerberos => {
            type          => 'text',
            default       => 'uid',
            documentation => 'SAML session parameter for NameID kerberos',
        },
        samlAttributeAuthorityDescriptorAttributeServiceSOAP => {
            type    => 'samlService',
            default => 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP;'
              . '#PORTAL#/saml/AA/SOAP;',
            documentation => 'SAML Attribute Authority SOAP',
        },
        samlServicePrivateKeySig => {
            type          => 'RSAPrivateKey',
            default       => '',
            documentation => 'SAML signature private key',
        },
        samlServicePrivateKeySigPwd => {
            type          => 'password',
            default       => '',
            documentation => 'SAML signature private key password',
        },
        samlServicePublicKeySig => {
            type          => 'RSAPublicKeyOrCertificate',
            default       => '',
            documentation => 'SAML signature public key',
        },
        samlServicePrivateKeyEnc => {
            type          => 'RSAPrivateKey',
            default       => '',
            documentation => 'SAML encryption private key',
        },
        samlServicePrivateKeyEncPwd => { type => 'password', },
        samlServicePublicKeyEnc     => {
            type          => 'RSAPublicKeyOrCertificate',
            default       => '',
            documentation => 'SAML encryption public key',
        },
        samlServiceUseCertificateInResponse => {
            type    => 'bool',
            default => 0,
            documentation =>
              'Use certificate instead of public key in SAML responses',
        },
        samlIdPResolveCookie => {
            type          => 'text',
            default       => 'lemonldapidp',
            documentation => 'SAML IDP resolution cookie',
        },
        samlMetadataForceUTF8 => {
            default       => 1,
            type          => 'bool',
            documentation => 'SAML force metadata UTF8 conversion',
        },
        samlStorage                 => { type => 'PerlModule', },
        samlStorageOptions          => { type => 'keyTextContainer', },
        samlAuthnContextMapPassword => {
            type          => 'int',
            default       => 2,
            documentation => 'SAML authn context password level',
        },
        samlAuthnContextMapPasswordProtectedTransport => {
            type    => 'int',
            default => 3,
            documentation =>
              'SAML authn context password protected transport level',
        },
        samlAuthnContextMapTLSClient => {
            type          => 'int',
            default       => 5,
            documentation => 'SAML authn context TLS client level',
        },
        samlAuthnContextMapKerberos => {
            type          => 'int',
            default       => 4,
            documentation => 'SAML authn context kerberos level',
        },
        samlCommonDomainCookieActivation => {
            default       => 0,
            type          => 'bool',
            documentation => 'SAML CDC activation',
        },
        samlCommonDomainCookieDomain => {
            type    => 'text',
            test    => qr/^$Regexp::Common::URI::RFC2396::hostname$/,
            msgFail => '__badDomainName__',
        },
        samlCommonDomainCookieReader => {
            type    => 'text',
            test    => $url,
            msgFail => '__badUrl__',
        },
        samlCommonDomainCookieWriter => {
            type    => 'text',
            test    => $url,
            msgFail => '__badUrl__',
        },
        samlRelayStateTimeout => {
            type          => 'int',
            default       => 600,
            documentation => 'SAML timeout of relay state',
        },
        samlUseQueryStringSpecific => {
            default       => 0,
            type          => 'bool',
            documentation => 'SAML use specific method for query_string',
        },
        samlIDPSSODescriptorWantAuthnRequestsSigned => {
            type          => 'bool',
            default       => 1,
            documentation => 'SAML IDP want authn request signed',
        },
        samlIDPSSODescriptorSingleSignOnServiceHTTPRedirect => {
            type    => 'samlService',
            default => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect;'
              . '#PORTAL#/saml/singleSignOn;',
            documentation => 'SAML IDP SSO HTTP Redirect',
        },
        samlIDPSSODescriptorSingleSignOnServiceHTTPPost => {
            type    => 'samlService',
            default => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST;'
              . '#PORTAL#/saml/singleSignOn;',
            documentation => 'SAML IDP SSO HTTP POST',
        },
        samlIDPSSODescriptorSingleSignOnServiceHTTPArtifact => {
            type    => 'samlService',
            default => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact;'
              . '#PORTAL#/saml/singleSignOnArtifact;',
            documentation => 'SAML IDP SSO HTTP Artifact',
        },
        samlIDPSSODescriptorSingleSignOnServiceSOAP => {
            type    => 'samlService',
            default => 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP;'
              . '#PORTAL#/saml/singleSignOnSOAP;',
            documentation => 'SAML IDP SSO SOAP',
        },
        samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect => {
            type    => 'samlService',
            default => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect;'
              . '#PORTAL#/saml/singleLogout;'
              . '#PORTAL#/saml/singleLogoutReturn',
            documentation => 'SAML IDP SLO HTTP Redirect',
        },
        samlIDPSSODescriptorSingleLogoutServiceHTTPPost => {
            type    => 'samlService',
            default => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST;'
              . '#PORTAL#/saml/singleLogout;'
              . '#PORTAL#/saml/singleLogoutReturn',
            documentation => 'SAML IDP SLO HTTP POST',
        },
        samlIDPSSODescriptorSingleLogoutServiceSOAP => {
            type    => 'samlService',
            default => 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP;'
              . '#PORTAL#/saml/singleLogoutSOAP;',
            documentation => 'SAML IDP SLO SOAP',
        },
        samlIDPSSODescriptorArtifactResolutionServiceArtifact => {
            type    => 'samlAssertion',
            default => '1;0;urn:oasis:names:tc:SAML:2.0:bindings:SOAP;'
              . '#PORTAL#/saml/artifact',
            documentation => 'SAML IDP artifact resolution service',
        },

        # Fake attribute: used by manager REST API to agglomerate all nodes
        # related to a SAML IDP partner
        samlIDPMetaDataNodes => {
            type     => 'samlIDPMetaDataNodeContainer',
            template => 'samlIDPMetaDataNode',
        },

        # Fake attribute: used by manager REST API to agglomerate all nodes
        # related to a SAML SP partner
        samlSPMetaDataNodes => {
            type     => 'samlSPMetaDataNodeContainer',
            help     => 'authsaml.html',
            template => 'samlSPMetaDataNode',
        },

        # TODO: split that
        # IDP Keys
        samlIDPMetaDataExportedAttributes => {
            type       => 'samlAttributeContainer',
            help       => 'authsaml.html#exported_attributes',
            keyTest    => qr/^[a-zA-Z](?:[a-zA-Z0-9_\-\.]*\w)?$/,
            keyMsgFail => '__badMetadataName__',
            test       => qr/\w/,
            msgFail    => '__badValue__',
            default    => {},
        },
        samlIDPMetaDataXML => {
            type => 'file',
        },
        samlIDPMetaDataOptions => {
            type       => 'keyTextContainer',
            keyTest    => qr/^[a-zA-Z](?:[a-zA-Z0-9_\-\.]*\w)?$/,
            keyMsgFail => '__badMetadataName__',
        },
        samlIDPMetaDataOptionsNameIDFormat => {
            type   => 'select',
            select => [
                { k => '',            v => '' },
                { k => 'unspecified', v => 'Unspecified' },
                { k => 'email',       v => 'Email' },
                { k => 'x509',        v => 'X509 certificate' },
                { k => 'windows',     v => 'Windows' },
                { k => 'kerberos',    v => 'Kerberos' },
                { k => 'entity',      v => 'Entity' },
                { k => 'persistent',  v => 'Persistent' },
                { k => 'transient',   v => 'Transient' },
                { k => 'encrypted',   v => 'Encrypted' },
            ],
            default => '',
        },
        samlIDPMetaDataOptionsForceAuthn => {
            type    => 'bool',
            default => 0,
        },
        samlIDPMetaDataOptionsIsPassive => {
            type    => 'bool',
            default => 0,
        },
        samlIDPMetaDataOptionsAllowProxiedAuthn => {
            type    => 'bool',
            default => 0,
        },
        samlIDPMetaDataOptionsAllowLoginFromIDP => {
            type    => 'bool',
            default => 0,
        },
        samlIDPMetaDataOptionsRequestedAuthnContext => {
            type   => 'select',
            select => [
                { k => '',         v => '' },
                { k => 'kerberos', v => 'Kerberos' },
                {
                    k => 'password-protected-transport',
                    v => 'Password protected transport'
                },
                { k => 'password',   v => 'Password' },
                { k => 'tls-client', v => 'TLS client certificate' },
            ],
            default => '',
        },
        samlIDPMetaDataOptionsAdaptSessionUtime => {
            type    => 'bool',
            default => 0,
        },
        samlIDPMetaDataOptionsForceUTF8 => {
            type    => 'bool',
            default => 0,
        },
        samlIDPMetaDataOptionsSignSSOMessage => {
            type    => 'trool',
            default => -1,
        },
        samlIDPMetaDataOptionsCheckSSOMessageSignature => {
            type    => 'bool',
            default => 1,
        },
        samlIDPMetaDataOptionsSignSLOMessage => {
            type    => 'trool',
            default => -1,
        },
        samlIDPMetaDataOptionsCheckSLOMessageSignature => {
            type    => 'bool',
            default => 1,
        },
        samlIDPMetaDataOptionsSSOBinding => {
            type   => 'select',
            select => [
                { k => '',              v => '' },
                { k => 'http-post',     v => 'POST' },
                { k => 'http-redirect', v => 'Redirect' },
                { k => 'http-soap',     v => 'SOAP' },
                { k => 'artifact-get',  v => 'Artifact GET' },
                { k => 'artifact-post', v => 'Artifact POST' },
            ],
            default => '',
        },
        samlIDPMetaDataOptionsSLOBinding => {
            type   => 'select',
            select => [
                { k => '',              v => '' },
                { k => 'http-post',     v => 'POST' },
                { k => 'http-redirect', v => 'Redirect' },
                { k => 'http-soap',     v => 'SOAP' },
                { k => 'artifact-get',  v => 'Artifact GET' },
                { k => 'artifact-post', v => 'Artifact POST' },
            ],
            default => '',
        },
        samlIDPMetaDataOptionsEncryptionMode => {
            type   => 'select',
            select => [
                { k => 'none',      v => 'None' },
                { k => 'nameid',    v => 'Name ID' },
                { k => 'assertion', v => 'Assertion' },
            ],
            default => 'none',
        },
        samlIDPMetaDataOptionsCheckTime => {
            type    => 'bool',
            default => 1,
        },
        samlIDPMetaDataOptionsCheckAudience => {
            type    => 'bool',
            default => 1,
        },
        samlIDPMetaDataOptionsResolutionRule => {
            type    => 'longtext',
            default => '',
        },
        samlIDPMetaDataOptionsStoreSAMLToken => {
            type    => 'bool',
            default => 0,
        },
        samlIDPMetaDataOptionsRelayStateURL => {
            type    => 'bool',
            default => 0,
        },

        # SP keys
        samlSPMetaDataExportedAttributes => {
            type       => 'samlAttributeContainer',
            help       => 'idpsaml.html#exported_attributes',
            keyTest    => qr/^[a-zA-Z](?:[a-zA-Z0-9_\-\.]*\w)?$/,
            keyMsgFail => '__badMetadataName__',
            test       => qr/\w/,
            msgFail    => '__badValue__',
            default    => {},
        },
        samlSPMetaDataXML => {
            type => 'file',
        },
        samlSPMetaDataOptions => {
            type       => 'keyTextContainer',
            keyTest    => qr/^[a-zA-Z](?:[a-zA-Z0-9_\-\.]*\w)?$/,
            keyMsgFail => '__badMetadataName__',
        },
        samlSPSSODescriptorAuthnRequestsSigned => {
            default       => 1,
            type          => 'bool',
            documentation => 'SAML SP AuthnRequestsSigned',
        },
        samlSPSSODescriptorWantAssertionsSigned => {
            default       => 1,
            type          => 'bool',
            documentation => 'SAML SP WantAssertionsSigned',
        },
        samlSPSSODescriptorSingleLogoutServiceHTTPRedirect => {
            type    => 'samlService',
            default => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect;'
              . '#PORTAL#/saml/proxySingleLogout;'
              . '#PORTAL#/saml/proxySingleLogoutReturn',
            documentation => 'SAML SP SLO HTTP Redirect',
        },
        samlSPSSODescriptorSingleLogoutServiceHTTPPost => {
            type    => 'samlService',
            default => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST;'
              . '#PORTAL#/saml/proxySingleLogout;'
              . '#PORTAL#/saml/proxySingleLogoutReturn',
            documentation => 'SAML SP SLO HTTP POST',
        },
        samlSPSSODescriptorSingleLogoutServiceSOAP => {
            type    => 'samlService',
            default => 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP;'
              . '#PORTAL#/saml/proxySingleLogoutSOAP;',
            documentation => 'SAML SP SLO SOAP',
        },
        samlSPSSODescriptorAssertionConsumerServiceHTTPArtifact => {
            type => 'samlAssertion',
            default =>
              '1;0;urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact;'
              . '#PORTAL#/saml/proxySingleSignOnArtifact',
            documentation => 'SAML SP ACS HTTP artifact',
        },
        samlSPSSODescriptorAssertionConsumerServiceHTTPPost => {
            type    => 'samlAssertion',
            default => '0;1;urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST;'
              . '#PORTAL#/saml/proxySingleSignOnPost',
            documentation => 'SAML SP ACS HTTP POST',
        },
        samlSPSSODescriptorArtifactResolutionServiceArtifact => {
            type    => 'samlAssertion',
            default => '1;0;urn:oasis:names:tc:SAML:2.0:bindings:SOAP;'
              . '#PORTAL#/saml/artifact',
            documentation => 'SAML SP artifact resolution service ',
        },
        samlSPMetaDataOptionsNameIDFormat => {
            type   => 'select',
            select => [
                { k => '',            v => '' },
                { k => 'unspecified', v => 'Unspecified' },
                { k => 'email',       v => 'Email' },
                { k => 'x509',        v => 'X509 certificate' },
                { k => 'windows',     v => 'Windows' },
                { k => 'kerberos',    v => 'Kerberos' },
                { k => 'entity',      v => 'Entity' },
                { k => 'persistent',  v => 'Persistent' },
                { k => 'transient',   v => 'Transient' },
                { k => 'encrypted',   v => 'Encrypted' },
            ],
            default => '',
        },
        samlSPMetaDataOptionsNameIDSessionKey => {
            type => 'text',
        },
        samlSPMetaDataOptionsOneTimeUse => {
            type    => 'bool',
            default => 0,
        },
        samlSPMetaDataOptionsSessionNotOnOrAfterTimeout => {
            type    => 'int',
            default => 72000,
        },
        samlSPMetaDataOptionsNotOnOrAfterTimeout => {
            type    => 'int',
            default => 72000,
        },
        samlSPMetaDataOptionsSignSSOMessage => {
            type    => 'trool',
            default => -1,
        },
        samlSPMetaDataOptionsCheckSSOMessageSignature => {
            type    => 'bool',
            default => 1,
        },
        samlSPMetaDataOptionsSignSLOMessage => {
            type    => 'trool',
            default => -1,
        },
        samlSPMetaDataOptionsCheckSLOMessageSignature => {
            type    => 'bool',
            default => 1,
        },
        samlSPMetaDataOptionsEncryptionMode => {
            type   => 'select',
            select => [
                { k => 'none',      v => 'None' },
                { k => 'nameid',    v => 'Name ID' },
                { k => 'assertion', v => 'Assertion' },
            ],
            default => 'none',
        },
        samlSPMetaDataOptionsEnableIDPInitiatedURL => {
            type    => 'bool',
            default => 0,
        },
        samlSPMetaDataOptionsForceUTF8 => {
            type    => 'bool',
            default => 1,
        },

        # AUTH, USERDB and PASSWORD MODULES
        authentication => {
            type   => 'select',
            select => [
                { k => 'Apache',    v => 'Apache' },
                { k => 'AD',        v => 'Active Directory' },
                { k => 'BrowserID', v => 'BrowserID (Mozilla Persona)' },
                { k => 'Choice',    v => 'authChoice' },
                { k => 'CAS',  v => 'Central Authentication Service (CAS)' },
                { k => 'DBI',  v => 'Database (DBI)' },
                { k => 'Demo', v => 'Demonstration' },
                { k => 'Facebook',      v => 'Facebook' },
                { k => 'Google',        v => 'Google' },
                { k => 'LDAP',          v => 'LDAP' },
                { k => 'LinkedIn',      v => 'LinkedIn' },
                { k => 'Multi',         v => 'Multiple' },
                { k => 'Null',          v => 'None' },
                { k => 'OpenID',        v => 'OpenID' },
                { k => 'OpenIDConnect', v => 'OpenID Connect' },
                { k => 'Proxy',         v => 'Proxy' },
                { k => 'Radius',        v => 'Radius' },
                { k => 'Remote',        v => 'Remote' },
                { k => 'SAML',          v => 'SAML v2' },
                { k => 'Slave',         v => 'Slave' },
                { k => 'SSL',           v => 'SSL' },
                { k => 'Twitter',       v => 'Twitter' },
                { k => 'WebID',         v => 'WebID' },
                { k => 'Yubikey',       v => 'Yubikey' },
            ],
            default       => 'Demo',
            documentation => 'Authentication module',
        },
        userDB => {
            type   => 'select',
            select => [
                { k => 'AD',            v => 'Active Directory' },
                { k => 'DBI',           v => 'Database (DBI)' },
                { k => 'Choice',        v => 'authChoice' },
                { k => 'Demo',          v => 'Demonstration' },
                { k => 'Facebook',      v => 'Facebook' },
                { k => 'Google',        v => 'Google' },
                { k => 'LDAP',          v => 'LDAP' },
                { k => 'Multi',         v => 'Multiple' },
                { k => 'Null',          v => 'None' },
                { k => 'OpenID',        v => 'OpenID' },
                { k => 'OpenIDConnect', v => 'OpenID Connect' },
                { k => 'Proxy',         v => 'Proxy' },
                { k => 'Remote',        v => 'Remote' },
                { k => 'SAML',          v => 'SAML v2' },
                { k => 'Slave',         v => 'Slave' },
                { k => 'WebID',         v => 'WebID' },
            ],
            default       => 'Demo',
            documentation => 'User module',
        },
        passwordDB => {
            type   => 'select',
            select => [
                { k => 'AD',     v => 'Active Directory' },
                { k => 'Choice', v => 'authChoice' },
                { k => 'DBI',    v => 'Database (DBI)' },
                { k => 'Demo',   v => 'Demonstration' },
                { k => 'LDAP',   v => 'LDAP' },
                { k => 'Null',   v => 'None' },
            ],
            default       => 'Demo',
            documentation => 'Password module',
        },

        # DEMO
        demoExportedVars => {
            type          => 'keyTextContainer',
            keyTest       => qr/^!?[a-zA-Z][a-zA-Z0-9_-]*$/,
            keyMsgFail    => '__badVariableName__',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_:\-]*$/,
            msgFail       => '__badValue__',
            default       => { cn => 'cn', mail => 'mail', uid => 'uid', },
            documentation => 'Demo exported variables',
        },

        # AD
        ADPwdExpireWarning => {
            type          => 'int',
            default       => 0,
            documentation => 'AD password expire warning',
        },
        ADPwdMaxAge => {
            type          => 'int',
            default       => 0,
            documentation => 'AD password max age',
        },

        # LDAP
        managerDn => {
            type          => 'text',
            test          => qr/^(?:\w+=.*)?$/,
            msgFail       => '__badValue__',
            default       => '',
            documentation => 'LDAP manager DN',
        },
        managerPassword => {
            type          => 'password',
            test          => qr/^\S*$/,
            msgFail       => '__badValue__',
            default       => '',
            documentation => 'LDAP manager Password',
        },
        ldapAuthnLevel => {
            type          => 'int',
            default       => 2,
            documentation => 'LDAP authentication level',
        },
        ldapBase => {
            type          => 'text',
            test          => qr/^(?:\w+=.*|)$/,
            msgFail       => '__badValue__',
            default       => 'dc=example,dc=com',
            documentation => 'LDAP search base',
        },
        ldapExportedVars => {
            type          => 'keyTextContainer',
            keyTest       => qr/^!?[a-zA-Z][a-zA-Z0-9_-]*$/,
            keyMsgFail    => '__badVariableName__',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_:\-]*$/,
            msgFail       => '__badValue__',
            default       => { cn => 'cn', mail => 'mail', uid => 'uid', },
            documentation => 'LDAP exported variables',
        },
        ldapPort => {
            type          => 'int',
            default       => 389,
            documentation => 'LDAP port',
        },
        ldapServer => {
            type => 'text',
            test => sub {
                my $l = shift;
                my (@s) = split( /[\s,]+/, $l );
                foreach my $s (@s) {
                    $s =~
m{^(?:ldapi://[^/]*/?|\w[\w\-\.]*(?::\d{1,5})?|ldap(?:s|\+tls)?://\w[\w\-\.]*(?::\d{1,5})?/?.*)$}o
                      or return ( 0, "__badLdapUri__: \"$s\"" );
                }
                return 1;
            },
            default       => 'ldap://localhost',
            documentation => 'LDAP server (host or URI)',
        },
        ldapPwdEnc => {
            type          => 'text',
            test          => qr/^[a-zA-Z0-9_][a-zA-Z0-9_\-]*[a-zA-Z0-9_]$/,
            msgFail       => '__badEncoding__',
            default       => 'utf-8',
            documentation => 'LDAP password encoding',
        },
        ldapUsePasswordResetAttribute => {
            default       => 0,
            type          => 'bool',
            default       => 1,
            documentation => 'LDAP store reset flag in an attribute',
        },
        ldapPasswordResetAttribute => {
            type          => 'text',
            default       => 'pwdReset',
            documentation => 'LDAP password reset attribute',
        },
        ldapPasswordResetAttributeValue => {
            type          => 'text',
            default       => 'TRUE',
            documentation => 'LDAP password reset value',
        },
        ldapPpolicyControl => {
            default => 0,
            type    => 'bool',
        },
        ldapSetPassword => {
            default => 0,
            type    => 'bool',
        },
        ldapChangePasswordAsUser => {
            default => 0,
            type    => 'bool',
        },
        ldapSearchDeref => {
            type   => 'select',
            select => [
                { k => 'never',  v => 'never' },
                { k => 'search', v => 'search' },
                { k => 'find',   v => 'find' },
                { k => 'always', v => 'always' }
            ],
            default       => 'find',
            documentation => '"deref" param of Net::LDAP::search()',
        },
        mailLDAPFilter     => { type => 'text', },
        LDAPFilter         => { type => 'text', },
        AuthLDAPFilter     => { type => 'text', },
        ldapGroupRecursive => {
            default       => 0,
            type          => 'bool',
            documentation => 'LDAP recursive search in groups',
        },
        ldapGroupObjectClass => {
            type          => 'text',
            default       => 'groupOfNames',
            documentation => 'LDAP object class of groups',
        },
        ldapGroupBase          => { type => 'text', },
        ldapGroupAttributeName => {
            type          => 'text',
            default       => 'member',
            documentation => 'LDAP attribute name for member in groups',
        },
        ldapGroupAttributeNameUser => {
            type    => 'text',
            default => 'dn',
            documentation =>
'LDAP attribute name in user entry referenced as member in groups',
        },
        ldapGroupAttributeNameSearch => {
            type          => 'text',
            default       => 'cn',
            documentation => 'LDAP attributes to search in groups',
        },
        ldapGroupAttributeNameGroup => {
            type    => 'text',
            default => 'dn',
            documentation =>
'LDAP attribute name in group entry referenced as member in groups',
        },
        ldapTimeout => {
            type          => 'int',
            default       => 120,
            documentation => 'LDAP connection timeout',
        },
        ldapVersion => {
            type          => 'int',
            default       => 3,
            documentation => 'LDAP protocol version',
        },
        ldapRaw                       => { type => 'text', },
        ldapAllowResetExpiredPassword => {
            default       => 0,
            type          => 'bool',
            documentation => 'Allow a user to reset his expired password',
        },

        # SSL
        SSLAuthnLevel => {
            type          => 'int',
            default       => 5,
            documentation => 'SSL authentication level',
        },
        SSLVar => { type => 'text', },

        # CAS
        CAS_authnLevel => {
            type          => 'int',
            default       => 1,
            documentation => 'CAS authentication level',
        },
        CAS_url => {
            type    => 'text',
            test    => $url,
            msgFail => '__badUrl__',
        },
        CAS_CAFile  => { type => 'text', },
        CAS_renew   => { type => 'bool', },
        CAS_gateway => { type => 'bool', },
        CAS_pgtFile => {
            type          => 'text',
            default       => '/tmp/pgt.txt',
            documentation => 'CAS PGT file',
        },
        CAS_proxiedServices => {
            type       => 'keyTextContainer',
            keyTest    => qr/^\w+$/,
            keyMsgFail => '__badCasProxyId__',
        },

        # Radius
        radiusAuthnLevel => {
            type          => 'int',
            default       => 3,
            documentation => 'Radius authentication level',
        },
        radiusSecret => { type => 'text', },
        radiusServer => { type => 'text', },

        # Remote
        remotePortal        => { type => 'text', },
        remoteGlobalStorage => {
            type          => 'PerlModule',
            default       => 'Lemonldap::NG::Common::Apache::Session::SOAP',
            documentation => 'Remote session backend',
        },
        remoteGlobalStorageOptions => {
            type    => 'keyTextContainer',
            default => {
                proxy => 'http://auth.example.com/index.pl/sessions',
                ns =>
                  'http://auth.example.com/Lemonldap/NG/Common/CGI/SOAPService',
            },
            documentation => 'Demo exported variables',
        },

        # Proxy
        soapAuthService    => { type => 'text', },
        remoteCookieName   => { type => 'text', },
        soapSessionService => { type => 'text', },

        # OpenID
        openIdAuthnLevel => {
            type          => 'int',
            default       => 1,
            documentation => 'OpenID authentication level',
        },
        openIdSecret       => { type => 'text', },
        openIdExportedVars => {
            type          => 'keyTextContainer',
            keyTest       => qr/^!?[a-zA-Z][a-zA-Z0-9_-]*$/,
            keyMsgFail    => '__badVariableName__',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_:\-]*$/,
            msgFail       => '__badValue__',
            default       => {},
            documentation => 'OpenID exported variables',
        },
        'openIdIDPList' => { 'type' => 'blackWhiteList', default => '0;' },

        # Google
        googleAuthnLevel => {
            type          => 'int',
            default       => 1,
            documentation => 'Google authentication level',
        },
        googleExportedVars => {
            type          => 'keyTextContainer',
            keyTest       => qr/^!?[a-zA-Z][a-zA-Z0-9_-]*$/,
            keyMsgFail    => '__badVariableName__',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_:\-]*$/,
            msgFail       => '__badValue__',
            default       => {},
            documentation => 'Google exported variables',
        },

        # Facebook
        facebookAuthnLevel => {
            type          => 'int',
            default       => 1,
            documentation => 'Facebook authentication level',
        },
        facebookAppId        => { type => 'text', },
        facebookAppSecret    => { type => 'text', },
        facebookExportedVars => {
            type          => 'keyTextContainer',
            keyTest       => qr/^!?[a-zA-Z][a-zA-Z0-9_-]*$/,
            keyMsgFail    => '__badVariableName__',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_:\-]*$/,
            msgFail       => '__badValue__',
            default       => {},
            documentation => 'Facebook exported variables',
        },

        # Twitter
        twitterAuthnLevel => {
            type          => 'int',
            default       => 1,
            documentation => 'Twitter authentication level',
        },
        twitterKey     => { type => 'text', },
        twitterSecret  => { type => 'text', },
        twitterAppName => { type => 'text', },

        # LinkedIn
        linkedInAuthnLevel => {
            type          => 'int',
            default       => 1,
            documentation => 'LinkedIn authentication level',
        },
        linkedInClientID     => { type => 'text', },
        linkedInClientSecret => { type => 'password', },
        linkedInFields       => {
            type    => 'text',
            default => 'id,first-name,last-name,email-address'
        },
        linkedInUserField => { type => 'text', default => 'emailAddress' },
        linkedInScope =>
          { type => 'text', default => 'r_basicprofile r_emailaddress' },

        # WebID
        webIDAuthnLevel => {
            type          => 'int',
            default       => 1,
            documentation => 'WebID authentication level',
        },
        webIDWhitelist    => { type => 'text', },
        webIDExportedVars => {
            type          => 'keyTextContainer',
            keyTest       => qr/^!?[a-zA-Z][a-zA-Z0-9_-]*$/,
            keyMsgFail    => '__badVariableName__',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_:\-]*$/,
            msgFail       => '__badValue__',
            default       => {},
            documentation => 'WebID exported variables',
        },

        # DBI
        dbiAuthnLevel => {
            type          => 'int',
            default       => 2,
            documentation => 'DBI authentication level',
        },
        dbiAuthChain       => { type => 'text', },
        dbiAuthUser        => { type => 'text', },
        dbiAuthPassword    => { type => 'password', },
        dbiUserChain       => { type => 'text', },
        dbiUserUser        => { type => 'text', },
        dbiUserPassword    => { type => 'password', },
        dbiAuthTable       => { type => 'text', },
        dbiUserTable       => { type => 'text', },
        dbiAuthLoginCol    => { type => 'text', },
        dbiAuthPasswordCol => { type => 'text', },
        dbiPasswordMailCol => { type => 'text', },
        userPivot          => { type => 'text', },
        dbiAuthPasswordHash =>
          { type => 'text', help => 'authdbi.html#password', },
        dbiDynamicHashEnabled =>
          { type => 'bool', help => 'authdbi.html#password', },
        dbiDynamicHashValidSchemes =>
          { type => 'text', help => 'authdbi.html#password', },
        dbiDynamicHashValidSaltedSchemes =>
          { type => 'text', help => 'authdbi.html#password', },
        dbiDynamicHashNewPasswordScheme =>
          { type => 'text', help => 'authdbi.html#password', },
        dbiExportedVars => {
            type          => 'keyTextContainer',
            keyTest       => qr/^!?[a-zA-Z][a-zA-Z0-9_-]*$/,
            keyMsgFail    => '__badVariableName__',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_:\-]*$/,
            msgFail       => '__badValue__',
            default       => {},
            documentation => 'DBI exported variables',
        },

        # Apache
        apacheAuthnLevel => {
            type          => 'int',
            default       => 4,
            documentation => 'Apache authentication level',
        },

        # Null
        nullAuthnLevel => {
            type          => 'int',
            default       => 2,
            documentation => 'Null authentication level',
        },

        # Slave
        slaveAuthnLevel => {
            type          => 'int',
            default       => 2,
            documentation => 'Slave authentication level',
        },
        slaveUserHeader   => { type => 'text', },
        slaveExportedVars => {
            type          => 'keyTextContainer',
            keyTest       => qr/^!?[a-zA-Z][a-zA-Z0-9_-]*$/,
            keyMsgFail    => '__badVariableName__',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_:\-]*$/,
            msgFail       => '__badValue__',
            default       => {},
            documentation => 'Slave exported variables',
        },
        slaveMasterIP => {
            type    => 'text',
            test    => qr/^($Regexp::Common::URI::RFC2396::IPv4address\s*)*$/,
            msgFail => '__badIPv4Address__',
        },
        slaveHeaderName    => { type => 'text', },
        slaveHeaderContent => { type => 'text', },

        # Choice
        authChoiceParam => {
            type          => 'text',
            default       => 'lmAuth',
            documentation => 'Applications list',
        },
        authChoiceModules => {
            type       => 'authChoiceContainer',
            keyTest    => qr/^(\d*)?[a-zA-Z0-9_]+$/,
            keyMsgFail => '__badChoiceKey__',
            test       => sub { 1 },
            select     => [
                [
                    { k => 'Apache',    v => 'Apache' },
                    { k => 'AD',        v => 'Active Directory' },
                    { k => 'BrowserID', v => 'BrowserID (Mozilla Persona)' },
                    { k => 'CAS', v => 'Central Authentication Service (CAS)' },
                    { k => 'DBI', v => 'Database (DBI)' },
                    { k => 'Demo',          v => 'Demo' },
                    { k => 'Facebook',      v => 'Facebook' },
                    { k => 'Google',        v => 'Google' },
                    { k => 'LDAP',          v => 'LDAP' },
                    { k => 'LinkedIn',      v => 'LinkedIn' },
                    { k => 'Null',          v => 'None' },
                    { k => 'OpenID',        v => 'OpenID' },
                    { k => 'OpenIDConnect', v => 'OpenID Connect' },
                    { k => 'Proxy',         v => 'Proxy' },
                    { k => 'Radius',        v => 'Radius' },
                    { k => 'Remote',        v => 'Remote' },
                    { k => 'SAML',          v => 'SAML v2' },
                    { k => 'Slave',         v => 'Slave' },
                    { k => 'SSL',           v => 'SSL' },
                    { k => 'Twitter',       v => 'Twitter' },
                    { k => 'WebID',         v => 'WebID' },
                    { k => 'Yubikey',       v => 'Yubikey' }
                ],
                [
                    { k => 'AD',            v => 'Active Directory' },
                    { k => 'DBI',           v => 'Database (DBI)' },
                    { k => 'Demo',          v => 'Demo' },
                    { k => 'Facebook',      v => 'Facebook' },
                    { k => 'Google',        v => 'Google' },
                    { k => 'LDAP',          v => 'LDAP' },
                    { k => 'Null',          v => 'None' },
                    { k => 'OpenID',        v => 'OpenID' },
                    { k => 'OpenIDConnect', v => 'OpenID Connect' },
                    { k => 'Proxy',         v => 'Proxy' },
                    { k => 'Remote',        v => 'Remote' },
                    { k => 'SAML',          v => 'SAML v2' },
                    { k => 'Slave',         v => 'Slave' },
                    { k => 'WebID',         v => 'WebID' }
                ],
                [
                    { k => 'AD',   v => 'Active Directory' },
                    { k => 'DBI',  v => 'Database (DBI)' },
                    { k => 'Demo', v => 'Demo' },
                    { k => 'LDAP', v => 'LDAP' },
                    { k => 'Null', v => 'None' }
                ]
            ],
        },

        # Multi
        multiAuthStack => {
            type => 'authParamsText',
        },
        multiUserDBStack => {
            type => 'authParamsText',
        },
        multiValuesSeparator => {
            type          => 'authParamsText',
            default       => '; ',
            documentation => 'Separator for multiple values',
        },

        # Yubikey
        yubikeyAuthnLevel => {
            type          => 'int',
            default       => 3,
            documentation => 'Yubikey authentication level',
        },
        yubikeyClientID     => { type => 'text', },
        yubikeySecretKey    => { type => 'text', },
        yubikeyPublicIDSize => {
            type          => 'int',
            default       => 12,
            documentation => 'Yubikey public ID size',
        },

        # BrowserID
        browserIdAuthnLevel => {
            type          => 'int',
            default       => 1,
            documentation => 'Browser ID authentication level',
        },
        browserIdAutoLogin       => { type => 'bool', },
        browserIdVerificationURL => { type => 'text', },
        browserIdSiteName        => { type => 'text', },
        browserIdSiteLogo        => { type => 'text', },
        browserIdBackgroundColor => { type => 'text', },

        # OpenID Connect auth params
        oidcAuthnLevel => {
            type          => 'int',
            default       => 1,
            documentation => 'OpenID Connect authentication level',
        },
        oidcRPCallbackGetParam => {
            type          => 'text',
            default       => 'openidconnectcallback',
            documentation => 'OpenID Connect Callback GET URLparameter',
        },
        oidcRPStateTimeout => {
            type          => 'int',
            default       => 600,
            documentation => 'OpenID Connect Timeout of state sessions',
        },

        # OpenID Connect service
        oidcServiceMetaDataIssuer => {
            type          => 'text',
            default       => 'http://auth.example.com',
            documentation => 'OpenID Connect issuer',
        },
        oidcServiceMetaDataAuthorizeURI => {
            type          => 'text',
            default       => 'authorize',
            documentation => 'OpenID Connect authorizaton endpoint',
        },
        oidcServiceMetaDataTokenURI => {
            type          => 'text',
            default       => 'token',
            documentation => 'OpenID Connect token endpoint',
        },
        oidcServiceMetaDataUserInfoURI => {
            type          => 'text',
            default       => 'userinfo',
            documentation => 'OpenID Connect user info endpoint',
        },
        oidcServiceMetaDataJWKSURI => {
            type          => 'text',
            default       => 'jwks',
            documentation => 'OpenID Connect JWKS endpoint',
        },
        oidcServiceMetaDataRegistrationURI => {
            type          => 'text',
            default       => 'register',
            documentation => 'OpenID Connect registration endpoint',
        },
        oidcServiceMetaDataEndSessionURI => {
            type          => 'text',
            default       => 'logout',
            documentation => 'OpenID Connect end session endpoint',
        },
        oidcServiceMetaDataCheckSessionURI => {
            type          => 'text',
            default       => 'checksession',
            documentation => 'OpenID Connect check session iframe',
        },
        oidcServiceMetaDataAuthnContext => {
            type    => 'keyTextContainer',
            keyTest => qr/\w/,
            default => {
                'loa-1' => 1,
                'loa-2' => 2,
                'loa-3' => 3,
                'loa-4' => 4,
                'loa-5' => 5,
            },
            documentation => 'OpenID Connect Authentication Context Class Ref',
        },
        oidcServicePrivateKeySig => { type => 'RSAPrivateKey', },
        oidcServicePublicKeySig  => { type => 'RSAPublicKey', },
        oidcServiceKeyIdSig      => {
            type          => 'text',
            documentation => 'OpenID Connect Signature Key ID',
        },
        oidcServiceAllowDynamicRegistration => {
            type          => 'bool',
            default       => '0',
            documentation => 'OpenID Connect allow dynamic client registration',
        },
        oidcServiceAllowAuthorizationCodeFlow => {
            type          => 'bool',
            default       => '1',
            documentation => 'OpenID Connect allow authorization code flow',
        },
        oidcServiceAllowImplicitFlow => {
            type          => 'bool',
            default       => '0',
            documentation => 'OpenID Connect allow implicit flow',
        },
        oidcServiceAllowHybridFlow => {
            type          => 'bool',
            default       => '0',
            documentation => 'OpenID Connect allow hybrid flow',
        },
        oidcStorage        => { type => 'PerlModule', },
        oidcStorageOptions => {
            type => 'keyTextContainer',
        },

        # OpenID Connect metadata nodes
        oidcOPMetaDataNodes => {
            type => 'oidcOPMetaDataNodeContainer',
            help =>
'authopenidconnect.html#declare_the_openid_connect_provider_in_llng',
        },
        oidcRPMetaDataNodes => {
            type => 'oidcRPMetaDataNodeContainer',
            help =>
              'idpopenidconnect.html#configuration_of_relying_party_in_llng',
        },
        oidcOPMetaDataOptions => { type => 'subContainer', },
        oidcRPMetaDataOptions => { type => 'subContainer', },

        # OpenID Connect providers
        oidcOPMetaDataJSON         => { type => 'file', },
        oidcOPMetaDataJWKS         => { type => 'file', },
        oidcOPMetaDataExportedVars => {
            type    => 'keyTextContainer',
            default => {
                'cn'   => 'name',
                'sn'   => 'family_name',
                'mail' => 'email',
                'uid'  => 'sub'
            }
        },
        oidcOPMetaDataOptionsConfigurationURI => { type => 'url', },
        oidcOPMetaDataOptionsJWKSTimeout  => { type => 'int', default => 0 },
        oidcOPMetaDataOptionsClientID     => { type => 'text', },
        oidcOPMetaDataOptionsClientSecret => { type => 'password', },
        oidcOPMetaDataOptionsScope =>
          { type => 'text', default => 'openid profile' },
        oidcOPMetaDataOptionsDisplay => {
            type   => 'select',
            select => [
                { k => '',      v => '' },
                { k => 'page',  v => 'page' },
                { k => 'popup', v => 'popup' },
                { k => 'touch', v => 'touch' },
                { k => 'wap',   v => 'wap' },
            ],
            default => "",
        },
        oidcOPMetaDataOptionsPrompt    => { type => 'text' },
        oidcOPMetaDataOptionsMaxAge    => { type => 'int', default => 0 },
        oidcOPMetaDataOptionsUiLocales => { type => 'text', },
        oidcOPMetaDataOptionsAcrValues => { type => 'text', },
        oidcOPMetaDataOptionsTokenEndpointAuthMethod => {
            type   => 'select',
            select => [
                { k => 'client_secret_post',  v => 'client_secret_post' },
                { k => 'client_secret_basic', v => 'client_secret_basic' },
            ],
            default => 'client_secret_post',
        },
        oidcOPMetaDataOptionsCheckJWTSignature =>
          { type => 'bool', default => 1 },
        oidcOPMetaDataOptionsIDTokenMaxAge => { type => 'int',  default => 30 },
        oidcOPMetaDataOptionsUseNonce      => { type => 'bool', default => 1 },
        oidcOPMetaDataOptionsDisplayName  => { type => 'text', },
        oidcOPMetaDataOptionsIcon         => { type => 'text', },
        oidcOPMetaDataOptionsStoreIDToken => { type => 'bool', default => 0 },

        # OpenID Connect relying parties
        oidcRPMetaDataExportedVars => {
            type    => 'keyTextContainer',
            default => {
                'name'        => 'cn',
                'family_name' => 'sn',
                'email'       => 'mail'
            }
        },
        oidcRPMetaDataOptionsClientID       => { type => 'text', },
        oidcRPMetaDataOptionsClientSecret   => { type => 'password', },
        oidcRPMetaDataOptionsDisplayName    => { type => 'text', },
        oidcRPMetaDataOptionsIcon           => { type => 'text', },
        oidcRPMetaDataOptionsUserIDAttr     => { type => 'text', },
        oidcRPMetaDataOptionsIDTokenSignAlg => {
            type   => 'select',
            select => [
                { k => 'none',  v => 'None' },
                { k => 'HS256', v => 'HS256' },
                { k => 'HS384', v => 'HS384' },
                { k => 'HS512', v => 'HS512' },
                { k => 'RS256', v => 'RS256' },
                { k => 'RS384', v => 'RS384' },
                { k => 'RS512', v => 'RS512' },
            ],
            default => 'HS512',
        },
        oidcRPMetaDataOptionsIDTokenExpiration =>
          { type => 'int', default => 3600 },
        oidcRPMetaDataOptionsAccessTokenExpiration =>
          { type => 'int', default => 3600 },
        oidcRPMetaDataOptionsRedirectUris => { type => 'text', },
        oidcRPMetaDataOptionsExtraClaims =>
          { type => 'keyTextContainer', default => {} },
        oidcRPMetaDataOptionsBypassConsent => { type => 'bool', default => 0 },
        oidcRPMetaDataOptionsPostLogoutRedirectUris => { type => 'text', },

    };
}

1;
