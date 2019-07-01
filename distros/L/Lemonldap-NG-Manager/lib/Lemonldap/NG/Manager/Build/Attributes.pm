#  This file contains the description of all configuration parameters
# It may be included only by batch files, never in portal or handler chain
# for performances reasons

# DON'T FORGET TO RUN "make json" AFTER EACH CHANGE

package Lemonldap::NG::Manager::Build::Attributes;

our $VERSION = '2.0.5';
use strict;
use Regexp::Common qw/URI/;

sub perlExpr {
    my ( $val, $conf ) = @_;
    my $cpt = new Safe;
    $cpt->share_from( 'MIME::Base64', ['&encode_base64'] );
    $cpt->share_from( 'Lemonldap::NG::Handler::Main::Jail',
        [ '&encrypt', '&token' ] );
    $cpt->share_from( 'Lemonldap::NG::Common::Safelib',
        $Lemonldap::NG::Common::Safelib::functions );
    $cpt->reval("BEGIN { 'warnings'->unimport; } $val");
    my $err = join( '',
        grep { $_ =~ /Undefined subroutine/ ? () : $_ } split( /\n/, $@ ) );
    return $err ? ( 1, "__badExpression__: $err" ) : (1);
}

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
            test    => sub { return perlExpr(@_) },
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
                my $test = grep ( { $_ eq $_[0] }
                    map ( { $_->{k} } @{ $_[2]->{select} } ) );
                return $test
                  ? 1
                  : ( 1, "Invalid value '$_[0]' for this select" );
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
/^(?:(?:\-+\s*BEGIN\s+(?:RSA\s+)?PRIVATE\s+KEY\s*\-+\r?\n)?(?:Proc-Type:.*\r?\nDEK-Info:.*\r?\n[\r\n]*)?[a-zA-Z0-9\/\+\r\n]+={0,2}(?:\r?\n\-+\s*END\s+(?:RSA\s+)PRIVATE\s+KEY\s*\-+)?[\r\n]*)?$/s
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
        array => {
            test => sub { 1 }
        },
    };
}

sub attributes {
    return {

        # Other
        checkTime => {
            type => 'int',
            documentation =>
              'Timeout to check new configuration in local cache',
            default => 600,
            flags   => 'hp',
        },
        mySessionAuthorizedRWKeys => {
            type          => 'array',
            documentation => 'Alterable session keys by user itself',
            default =>
              [ '_appsListOrder', '_oidcConnectedRP', '_oidcConsents' ],
        },
        configStorage => {
            type          => 'text',
            documentation => 'Configuration storage',
            flags         => 'hmp',
        },
        localStorage => {
            type          => 'text',
            documentation => 'Local cache',
            flags         => 'hmp',
        },
        localStorageOptions => {
            type          => 'keyTextContainer',
            documentation => 'Local cache parameters',
            flags         => 'hmp',
        },
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
        cfgVersion => {
            type          => 'text',
            documentation => 'Version of LLNG which build configuration',
        },
        status => {
            type          => 'bool',
            documentation => 'Status daemon activation',
            flags         => 'h',
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
            help          => 'customfunctions.html',
            msgFail       => "__badCustomFuncName__",
            documentation => 'List of custom functions',
            flags         => 'hmp',
        },
        https => {
            default       => -1,
            type          => 'trool',
            documentation => 'Use HTTPS for redirection from portal',
            flags         => 'h',
        },
        infoFormMethod => {
            type => "select",
            select =>
              [ { k => 'get', v => 'GET' }, { k => 'post', v => 'POST' }, ],
            default       => 'get',
            documentation => 'HTTP method for info page form',
        },
        port => {
            default       => -1,
            type          => 'int',
            documentation => 'Force port in redirection',
            flags         => 'h',
        },
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
            flags         => 'h',
        },
        nginxCustomHandlers => {
            type    => 'keyTextContainer',
            keyTest => qr/^\w+$/,
            test    => qr/^[a-zA-Z][a-zA-Z0-9]*(?:::[a-zA-Z][a-zA-Z0-9]*)*$/,
            help    => 'handlerarch.html',
            msgFail => '__badPerlPackageName__',
            documentation => 'Custom Nginx handler (deprecated)',
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
            flags         => 'hmp',
            test          => $url,
            msgFail       => '__badUrl__',
        },
        portalStatus => {
            type          => 'bool',
            default       => 0,
            help          => 'status.html',
            documentation => 'Enable portal status',
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
        reloadTimeout => {
            type          => 'int',
            default       => 5,
            documentation => 'Configuration reload timeout',
            flags         => 'm',
        },
        reloadUrls => {
            type          => 'keyTextContainer',
            help          => 'configlocation.html#configuration_reload',
            keyTest       => qr/^$Regexp::Common::URI::RFC2396::host(?::\d+)?$/,
            test          => $url,
            msgFail       => '__badUrl__',
            documentation => 'URL to call on reload',
        },
        portalMainLogo => {
            type          => 'text',
            default       => 'common/logos/logo_llng_400px.png',
            documentation => 'Portal main logo path',
        },
        showLanguages => {
            type          => 'bool',
            default       => 1,
            documentation => 'Display langs icons',
        },
        staticPrefix => {
            type          => 'text',
            documentation => 'Prefix of static files for HTML templates',
        },
        multiValuesSeparator => {
            type          => 'authParamsText',
            default       => '; ',
            documentation => 'Separator for multiple values',
            flags         => 'hmp',
        },
        stayConnected => {
            type => 'bool',

            #help          => 'stayconnected.html',
            default       => 0,
            documentation => 'Enable StayConnected plugin',
        },
        checkState => {
            type          => 'bool',
            default       => 0,
            documentation => 'Enable CheckState plugin',
        },
        checkStateSecret => {
            type          => 'text',
            documentation => 'Secret token for CheckState plugin',
        },
        checkUser => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable check user',
            flags         => 'p',
        },
        checkUserIdRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            default       => 1,
            documentation => 'checkUser identities rule',
        },
        checkUserHiddenAttributes => {
            type          => 'text',
            default       => '_loginHistory hGroups',
            documentation => 'Attributes to hide in CheckUser plugin',
            flags         => 'p',
        },
        checkUserDisplayPersistentInfo => {
            default       => 0,
            type          => 'bool',
            documentation => 'Display persistent session info',
            flags         => 'p',
        },
        checkUserDisplayEmptyValues => {
            default       => 0,
            type          => 'bool',
            documentation => 'Display session empty values',
            flags         => 'p',
        },
        impersonationMergeSSOgroups => {
            default       => 0,
            type          => 'boolOrExpr',
            documentation => 'Merge spoofed and real SSO groups',
            flags         => 'p',
        },
        impersonationPrefix => {
            type          => 'text',
            default       => 'real_',
            documentation => 'Prefix to rename real session attributes',
            flags         => 'p',
        },
        impersonationRule => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Impersonation activation rule',
        },
        impersonationIdRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            default       => 1,
            documentation => 'Impersonation identities rule',
        },
        impersonationHiddenAttributes => {
            type          => 'text',
            default       => '_2fDevices _loginHistory',
            documentation => 'Attributes to skip',
            flags         => 'p',
        },
        impersonationSkipEmptyValues => {
            default       => 1,
            type          => 'bool',
            documentation => 'Skip session empty values',
            flags         => 'p',
        },
        skipRenewConfirmation => {
            type    => 'bool',
            default => 0,
            documentation =>
              'Avoid asking confirmation when an Issuer asks to renew auth',
        },
        handlerInternalCache => {
            type          => 'int',
            default       => 15,
            documentation => 'Handler internal cache timeout',
            flags         => 'hp',
        },
        handlerServiceTokenTTL => {
            type          => 'int',
            default       => 30,
            documentation => 'Handler ServiceToken timeout',
            flags         => 'hp',
        },

        # Loggers (ini only)
        logLevel => {
            type          => 'text',
            documentation => 'Log level, must be set in .ini',
            flags         => 'hmp',
        },
        logger => {
            type          => 'text',
            documentation => 'technical logger',
            flags         => 'hmp',
        },
        userLogger => {
            type          => 'text',
            documentation => 'User actions logger',
            flags         => 'hmp',
        },
        log4perlConfFile => {
            type          => 'text',
            documentation => 'Log4Perl logger configuration file',
            flags         => 'hmp',
        },
        sentryDsn => {
            type          => 'text',
            documentation => 'Sentry logger DSN',
            flags         => 'hmp',
        },
        syslogFacility => {
            type          => 'text',
            documentation => 'Syslog logger technical facility',
            flags         => 'hmp',
        },
        userSyslogFacility => {
            type          => 'text',
            documentation => 'Syslog logger user-actions facility',
            flags         => 'hmp',
        },

        # Manager or PSGI protected apps
        protection => {
            type          => 'text',
            test          => qr/^(?:none|authenticate|manager|)$/,
            msgFail       => '__authorizedValues__: none authenticate manager',
            documentation => 'Manager protection method',
            flags         => 'hm',
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
            select        => [ { k => 'bootstrap', v => 'Bootstrap' }, ],
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
                {
                    k => "Aletschgletscher_mit_Pinus_cembra1.jpg",
                    v => 'Pinus'
                },
            ],
        },
        portalSkinRules => {
            type          => 'keyTextContainer',
            help          => 'portalcustom.html',
            keyTest       => sub { return perlExpr(@_) },
            keyMsgFail    => '__badSkinRule__',
            test          => qr/^\w+$/,
            msgFail       => '__badValue__',
            documentation => 'Rules to choose portal skin',
        },

        # Security
        formTimeout => {
            default       => 120,
            type          => 'int',
            documentation => 'Token timeout for forms',
        },
        requireToken => {
            default       => 1,
            type          => 'boolOrExpr',
            documentation => 'Enable token for forms',
        },
        tokenUseGlobalStorage => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable global token storage',
        },
        cda => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable Cross Domain Authentication',
            flags         => 'hp',
        },
        checkXSS => {
            default       => 1,
            type          => 'bool',
            documentation => 'Check XSS',
        },
        portalForceAuthn => {
            default => 0,
            help    => 'forcereauthn.html',
            type    => 'bool',
            documentation =>
              'Enable force to authenticate when displaying portal',
        },
        portalForceAuthnInterval => {
            default => 5,
            type    => 'int',
            documentation =>
'Maximum interval in seconds since last authentication to force reauthentication',
        },
        bruteForceProtection => {
            default       => 0,
            help          => 'bruteforceprotection.html',
            type          => 'bool',
            documentation => 'Enable brute force attack protection',
        },
        bruteForceProtectionTempo => {
            default => 30,
            type    => 'int',
            documentation =>
              'Brute force attack protection -> Tempo before try again',
        },
        bruteForceProtectionMaxAge => {
            default => 300,
            type    => 'int',
            documentation =>
'Brute force attack protection -> Max age between last and first allowed failed login',
        },
        bruteForceProtectionMaxFailed => {
            default => 3,
            type    => 'int',
            documentation =>
              'Brute force attack protection -> Max allowed failed login',
        },
        grantSessionRules => {
            type          => 'grantContainer',
            keyTest       => sub { return perlExpr(@_) },
            test          => sub { 1 },
            documentation => 'Rules to grant sessions',
        },
        hiddenAttributes => {
            type          => 'text',
            default       => '_password _2fDevices',
            documentation => 'Name of attributes to hide in logs',
        },
        key => {
            type          => 'password',
            documentation => 'Secret key',
        },
        corsEnabled => {
            default       => 1,
            type          => 'bool',
            documentation => 'Enable Cross-Origin Resource Sharing',
        },
        corsAllow_Credentials => {
            type    => 'text',
            default => 'true',
            documentation =>
              'Allow credentials for Cross-Origin Resource Sharing',
        },
        corsAllow_Headers => {
            type    => 'text',
            default => '*',
            documentation =>
              'Allowed headers for Cross-Origin Resource Sharing',
        },
        corsAllow_Methods => {
            type    => 'text',
            default => 'POST,GET',
            documentation =>
              'Allowed methods for Cross-Origin Resource Sharing',
        },
        corsAllow_Origin => {
            type    => 'text',
            default => '*',
            documentation =>
              'Allowed origine for Cross-Origin Resource Sharing',
        },
        corsExpose_Headers => {
            type    => 'text',
            default => '*',
            documentation =>
              'Exposed headers for Cross-Origin Resource Sharing',
        },
        corsMax_Age => {
            type    => 'text',
            default => '86400',    # 24 hours
            documentation => 'MAx-age for Cross-Origin Resource Sharing',
        },
        cspDefault => {
            type          => 'text',
            default       => "'self'",
            documentation => 'Default value for Content-Security-Policy',
        },
        cspFormAction => {
            type    => 'text',
            default => "'self'",
            documentation =>
              'Form action destination for Content-Security-Policy',
        },
        cspImg => {
            type          => 'text',
            default       => "'self' data:",
            documentation => 'Image source for Content-Security-Policy',
        },
        cspScript => {
            type          => 'text',
            default       => "'self'",
            documentation => 'Javascript source for Content-Security-Policy',
        },
        cspStyle => {
            type          => 'text',
            default       => "'self'",
            documentation => 'Style source for Content-Security-Policy',
        },
        cspConnect => {
            type    => 'text',
            default => "'self'",
            documentation =>
              'Authorized Ajax destination for Content-Security-Policy',
        },
        cspFont => {
            type          => 'text',
            default       => "'self'",
            documentation => 'Font source for Content-Security-Policy',
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
        randomPasswordRegexp => {
            type          => 'pcre',
            default       => '[A-Z]{3}[a-z]{5}.\d{2}',
            documentation => 'Regular expression to create a random password',
        },
        trustedDomains =>
          { type => 'text', documentation => 'Trusted domains', },
        storePassword => {
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
        userControl => {
            type          => 'pcre',
            default       => '^[\w\.\-@]+$',
            documentation => 'Regular expression to validate login',
        },
        useRedirectOnError => {
            type          => 'bool',
            default       => 1,
            documentation => 'Use 302 redirect code for error (500)',
            flags         => 'h',
        },
        useRedirectOnForbidden => {
            default       => 0,
            type          => 'bool',
            documentation => 'Use 302 redirect code for forbidden (403)',
        },
        useSafeJail => {
            default       => 1,
            type          => 'bool',
            help          => 'safejail.html',
            documentation => 'Activate Safe jail',
            flags         => 'hp',
        },
        whatToTrace => {
            type          => 'lmAttrOrMacro',
            default       => 'uid',
            documentation => 'Session parameter used to fill REMOTE_USER',
            flags         => 'hp',
        },
        lwpOpts => {
            type          => 'keyTextContainer',
            documentation => 'Options given to LWP::UserAgent',
        },
        lwpSslOpts => {
            type          => 'keyTextContainer',
            documentation => 'SSL options given to LWP::UserAgent',
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
            default       => 0,
            type          => 'bool',
            documentation => 'Display reset password button in portal',
        },
        passwordResetAllowedRetries => {
            default       => 3,
            type          => 'int',
            documentation => 'Maximum number of retries to reset password',
        },
        portalDisplayOidcConsents => {
            type          => 'boolOrExpr',
            default       => '$_oidcConnectedRP',
            documentation => 'Display OIDC consent tab in portal',
        },

        # Cookies
        cookieExpiration => {
            type          => 'int',
            documentation => 'Cookie expiration',
            flags         => 'hp',
        },
        cookieName => {
            type          => 'text',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_-]*$/,
            msgFail       => '__badCookieName__',
            default       => 'lemonldap',
            documentation => 'Name of the main cookie',
            flags         => 'hp',
        },
        domain => {
            type          => 'text',
            test          => qr/^(?:$Regexp::Common::URI::RFC2396::hostname)?$/,
            msgFail       => '__badDomainName__',
            default       => 'example.com',
            documentation => 'DNS domain',
            flags         => 'hp',
        },
        httpOnly => {
            default       => 1,
            type          => 'bool',
            documentation => 'Enable httpOnly flag in cookie',
            flags         => 'hp',
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
            flags         => 'hp',
        },

        # Viewer
        viewerHiddenKeys => {
            type          => 'text',
            default       => 'samlIDPMetaDataNodes samlSPMetaDataNodes',
            documentation => 'Hidden Conf keys',
            flags         => 'm',
        },
        viewerAllowBrowser => {
            type          => 'bool',
            default       => 0,
            documentation => 'Allow configuration browser',
        },
        viewerAllowDiff => {
            type          => 'bool',
            default       => 0,
            documentation => 'Allow configuration diff',
        },

        # Notification
        oldNotifFormat => {
            type          => 'bool',
            default       => 0,
            documentation => 'Use old XML format for notifications',
        },
        notificationWildcard => {
            type          => 'text',
            default       => 'allusers',
            documentation => 'Notification string to match all users',
        },
        notificationXSLTfile => {
            type          => 'text',
            documentation => 'Custom XSLT document for notifications',
        },
        notification => {
            default       => 0,
            type          => 'bool',
            documentation => 'Notification activation',
        },
        notificationServer => {
            default       => 0,
            type          => 'bool',
            documentation => 'Notification server activation',
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
            default       => 1,
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
            test          => sub { return perlExpr(@_) },
            default       => {},
            documentation => 'Groups',
        },
        macros => {
            type => 'keyTextContainer',
            help =>
              'exportedvars.html#extend_variables_using_macros_and_groups',
            keyTest       => qr/^[_a-zA-Z][a-zA-Z0-9_]*$/,
            keyMsgFail    => '__badMacroName__',
            test          => sub { return perlExpr(@_) },
            default       => {},
            documentation => 'Macros',
        },

        # Storage
        globalStorage => {
            type          => 'PerlModule',
            default       => 'Apache::Session::File',
            documentation => 'Session backend module',
            flags         => 'hp',
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
            flags         => 'hp',
        },
        localSessionStorage => {
            type          => 'PerlModule',
            default       => 'Cache::FileCache',
            documentation => 'Local sessions cache module',
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
        persistentStorage => {
            type          => 'PerlModule',
            documentation => 'Storage module for persistent sessions'
        },
        persistentStorageOptions => {
            type          => 'keyTextContainer',
            documentation => 'Options for persistent sessions storage module'
        },
        sessionDataToRemember => {
            type          => 'keyTextContainer',
            keyTest       => qr/^[_a-zA-Z][a-zA-Z0-9_]*$/,
            keyMsgFail    => '__invalidSessionData__',
            documentation => 'Data to remember in login history',
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
            default       => 0,
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
            default       => 0,
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

        # SMTP server
        SMTPServer => {
            type    => 'text',
            default => '',
            test    => qr/^(?:$Regexp::Common::URI::RFC2396::host(?::\d+)?)?$/,
            documentation => 'SMTP Server',
        },
        SMTPPort => {
            type          => 'int',
            documentation => 'Fix SMTP port',
        },
        SMTPTLS => {
            type    => 'select',
            default => '',
            select  => [
                { k => '',         v => 'none' },
                { k => 'starttls', v => 'SMTP + STARTTLS' },
                { k => 'ssl',      v => 'SMTPS' },
            ],
            documentation => 'TLS protocol to use with SMTP',
        },
        SMTPTLSOpts => {
            type          => 'keyTextContainer',
            documentation => 'TLS/SSL options for SMTP',
        },
        SMTPAuthUser => {
            type          => 'text',
            documentation => 'Login to use to send mails',
        },
        SMTPAuthPass => {
            type          => 'password',
            documentation => 'Password to use to send mails',
        },

        # Mails
        mailCharset => {
            type          => 'text',
            default       => 'utf-8',
            documentation => 'Mail charset',
        },
        mailFrom => {
            type          => 'text',
            default       => 'noreply@example.com',
            documentation => 'Sender email',
        },
        mailSessionKey => {
            type          => 'text',
            default       => 'mail',
            documentation => 'Session parameter where mail is stored',
        },
        mailReplyTo => { type => 'text', documentation => 'Reply-To address' },
        mailTimeout => {
            type          => 'int',
            default       => 0,
            documentation => 'Mail password reset session timeout',
        },

        # Password reset
        mailBody => {
            type          => 'longtext',
            documentation => 'Custom password reset mail body',
        },

        mailConfirmBody => {
            type          => 'longtext',
            documentation => 'Custom confirm password reset mail body',
        },
        mailConfirmSubject => {
            type          => 'text',
            documentation => 'Mail subject for reset confirmation',
        },
        mailSubject => {
            type          => 'text',
            documentation => 'Mail subject for new password email',
        },

        mailUrl => {
            type          => 'url',
            default       => 'http://auth.example.com/resetpwd',
            documentation => 'URL of password reset page',
        },

        # Registration
        registerConfirmSubject => {
            type          => 'text',
            documentation => 'Mail subject for register confirmation',
        },
        registerDB => {
            type   => 'select',
            select => [
                { k => 'AD',     v => 'Active Directory' },
                { k => 'Demo',   v => 'Demonstration' },
                { k => 'LDAP',   v => 'LDAP' },
                { k => 'Null',   v => 'None' },
                { k => 'Custom', v => 'customModule' },
            ],
            default       => 'Null',
            documentation => 'Register module',
        },
        registerDoneSubject => {
            type          => 'text',
            documentation => 'Mail subject when register is done',
        },
        registerTimeout => {
            default       => 0,
            type          => 'int',
            documentation => 'Register session timeout',
        },
        registerUrl => {
            type          => 'text',
            default       => 'http://auth.example.com/register',
            documentation => 'URL of register page',
        },

        # Upgrade session
        upgradeSession => {
            type          => 'bool',
            default       => 1,
            documentation => 'Upgrade session activation',
        },

        # 2F
        max2FDevices => {
            default       => 10,
            type          => 'int',
            documentation => 'Maximum registered 2F devices',
        },
        max2FDevicesNameLength => {
            default       => 20,
            type          => 'int',
            documentation => 'Maximum 2F devices name length',
        },

        # U2F
        u2fActivation => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'U2F activation',
        },
        u2fSelfRegistration => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'U2F self registration activation',
        },
        u2fAuthnLevel => {
            type => 'int',
            documentation =>
              'Authentication level for users authentified by password+U2F'
        },
        u2fUserCanRemoveKey => {
            type          => 'bool',
            default       => 1,
            documentation => 'Authorize users to remove existing U2F key',
        },
        u2fTTL => {
            type          => 'int',
            documentation => 'U2F device time to live',
        },

        # TOTP second factor
        totp2fActivation => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'TOTP activation',
        },
        totp2fSelfRegistration => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'TOTP self registration activation',
        },
        totp2fAuthnLevel => {
            type => 'int',
            documentation =>
              'Authentication level for users authentified by password+TOTP'
        },
        totp2fIssuer => {
            type          => 'text',
            documentation => 'TOTP Issuer',
        },
        totp2fInterval => {
            type          => 'int',
            default       => 30,
            documentation => 'TOTP interval',
        },
        totp2fRange => {
            type          => 'int',
            default       => 1,
            documentation => 'TOTP range (number of interval to test)',
        },
        totp2fDigits => {
            type          => 'int',
            default       => 6,
            documentation => 'Number of digits for TOTP code',
        },
        totp2fDisplayExistingSecret => {
            type    => 'bool',
            default => 0,
            documentation =>
              'Display existing TOTP secret in registration form',
        },
        totp2fUserCanChangeKey => {
            type          => 'bool',
            default       => 0,
            documentation => 'Authorize users to change existing TOTP secret',
        },
        totp2fUserCanRemoveKey => {
            type          => 'bool',
            default       => 1,
            documentation => 'Authorize users to remove existing TOTP secret',
        },
        totp2fTTL => {
            type          => 'int',
            documentation => 'TOTP device time to live ',
        },

        # UTOTP 2F
        utotp2fActivation => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'UTOTP activation (mixed U2F/TOTP module)',
        },
        utotp2fAuthnLevel => {
            type => 'int',
            documentation =>
'Authentication level for users authentified by password+(U2F or TOTP)'
        },

        # Mail second factor
        mail2fActivation => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Mail second factor activation',
        },
        mail2fSubject => {
            type          => 'text',
            documentation => 'Mail subject for second factor authentication',
        },
        mail2fBody => {
            type          => 'longtext',
            documentation => 'Mail body for second factor authentication',
        },
        mail2fCodeRegex => {
            type          => 'pcre',
            default       => '\d{6}',
            documentation => 'Regular expression to create a mail OTP code',
        },
        mail2fTimeout => {
            type          => 'int',
            documentation => 'Second factor code timeout',
        },
        mail2fAuthnLevel => {
            type => 'int',
            documentation =>
'Authentication level for users authenticated by Mail second factor'
        },
        mail2fLogo => {
            type          => 'text',
            documentation => 'Custom logo for Mail 2F',
        },

        # External second factor
        ext2fActivation => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'External second factor activation',
        },
        ext2fCodeActivation => {
            type          => 'pcre',
            default       => '\d{6}',
            documentation => 'OTP generated by Portal',
        },
        ext2FSendCommand => {
            type          => 'text',
            documentation => 'Send command of External second factor',
        },
        ext2FValidateCommand => {
            type          => 'text',
            documentation => 'Validation command of External second factor',
        },
        ext2fAuthnLevel => {
            type => 'int',
            documentation =>
'Authentication level for users authentified by External second factor'
        },
        ext2fLogo => {
            type          => 'text',
            documentation => 'Custom logo for External 2F',
        },

        #  REST External second factor
        rest2fActivation => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'REST second factor activation',
        },
        rest2fInitUrl => {
            type          => 'url',
            documentation => 'REST 2F init URL',
        },
        rest2fInitArgs => {
            type          => 'keyTextContainer',
            keyTest       => qr/^\w+$/,
            keyMsgFail    => '__badKeyName__',
            test          => qr/^\w+$/,
            msgFail       => '__badValue__',
            documentation => 'Args for REST 2F init',
        },
        rest2fVerifyUrl => {
            type          => 'url',
            keyTest       => qr/^\w+$/,
            keyMsgFail    => '__badKeyName__',
            test          => qr/^\w+$/,
            msgFail       => '__badValue__',
            documentation => 'REST 2F init URL',
        },
        rest2fVerifyArgs => {
            type          => 'keyTextContainer',
            documentation => 'Args for REST 2F init',
        },
        rest2fAuthnLevel => {
            type => 'int',
            documentation =>
'Authentication level for users authentified by REST second factor'
        },
        rest2fLogo => {
            type          => 'text',
            documentation => 'Custom logo for REST 2F',
        },

        # Yubikey 2FA
        yubikey2fActivation => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Yubikey second factor activation',
        },
        yubikey2fSelfRegistration => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Yubikey self registration activation',
        },
        yubikey2fAuthnLevel => {
            type => 'int',
            documentation =>
'Authentication level for users authentified by Yubikey second factor'
        },
        yubikey2fClientID => {
            type          => 'text',
            documentation => 'Yubico client ID',
        },
        yubikey2fSecretKey => {
            type          => 'text',
            documentation => 'Yubico secret key',
        },
        yubikey2fNonce => {
            type          => 'text',
            documentation => 'Yubico nonce',
        },
        yubikey2fUrl => {
            type          => 'text',
            documentation => 'Yubico server',
        },
        yubikey2fPublicIDSize => {
            type          => 'int',
            default       => 12,
            documentation => 'Yubikey public ID size',
        },
        yubikey2fUserCanRemoveKey => {
            type          => 'bool',
            default       => 1,
            documentation => 'Authorize users to remove existing Yubikey',
        },
        yubikey2fTTL => {
            type          => 'int',
            documentation => 'Yubikey device time to live',
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
            default       => 0,
            type          => 'bool',
            documentation => 'Allow only one user per IP',
        },
        singleSessionUserByIP => {
            default       => 0,
            type          => 'bool',
            documentation => 'Allow only one session per user on an IP',
        },

        # REST server
        restSessionServer => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable REST session server',
        },
        restExportSecretKeys => {
            default => 0,
            type    => 'bool',
            documentation =>
              'Allow to export secret keys in REST session server',
        },
        restConfigServer => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable REST config server',
        },
        restAuthnLevel => {
            type          => 'int',
            default       => 2,
            documentation => 'REST authentication level',
        },

        # SOAP server
        soapSessionServer => {
            default       => 0,
            type          => 'bool',
            help          => 'soapservices.html',
            documentation => 'Enable SOAP session server',
        },
        soapConfigServer => {
            default       => 0,
            type          => 'bool',
            help          => 'soapservices.html',
            documentation => 'Enable SOAP config server',
        },
        exportedAttr => {
            type => 'text',
            documentation =>
              'List of attributes to export by SOAP or REST servers',
        },
        wsdlServer => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable /portal.wsdl server',
        },

        # AutoSignin
        autoSigninRules => {
            type          => 'keyTextContainer',
            documentation => 'List of auto signin rules',
        },

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
                    return &perlExpr( $s, $conf );
                },
                msgFail => '__badExpression__',
            },
            keyTest => qr/^(?:\*\.)?$Regexp::Common::URI::RFC2396::hostname$/,
            keyMsgFail    => '__badHostname__',
            default       => { default => 'deny', },
            documentation => 'Virtualhost rules',
            flags         => 'h',
        },
        exportedHeaders => {
            type    => 'keyTextContainer',
            help    => 'writingrulesand_headers.html#headers',
            keyTest => qr/^(?:\*\.)?$Regexp::Common::URI::RFC2396::hostname$/,
            keyMsgFail => '__badHostname__',
            test       => {
                keyTest    => qr/^(?=[^\-])[\w\-]+(?<=[^-])$/,
                keyMsgFail => '__badHeaderName__',
                test       => sub { return perlExpr(@_) },
            },
            documentation => 'Virtualhost headers',
            flags         => 'h',
        },
        post => {
            type    => 'postContainer',
            help    => 'formreplay.html',
            test    => sub { 1 },
            keyTest => qr/^(?:\*\.)?$Regexp::Common::URI::RFC2396::hostname$/,
            keyMsgFail    => '__badHostname__',
            documentation => 'Virtualhost urls/Data to post',
        },

        vhostOptions => { type => 'subContainer', },
        vhostPort    => {
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
        vhostServiceTokenTTL => {
            type    => 'int',
            default => -1,
        },
        vhostAliases => { type => 'text', },
        vhostType    => {
            type   => 'select',
            select => [
                { k => 'AuthBasic',    v => 'AuthBasic' },
                { k => 'CDA',          v => 'CDA' },
                { k => 'DevOps',       v => 'DevOps' },
                { k => 'DevOpsST',     v => 'DevOpsST' },
                { k => 'Main',         v => 'Main' },
                { k => 'OAuth2',       v => 'OAuth2' },
                { k => 'SecureToken',  v => 'SecureToken' },
                { k => 'ServiceToken', v => 'ServiceToken' },
                { k => 'Zimbra',       v => 'ZimbraPreAuth' },
            ],
            default       => 'Main',
            documentation => 'Handler type',
        },
        vhostAuthnLevel => { type => 'int', },

        # SecureToken parameters
        secureTokenAllowOnError => {
            type          => 'text',
            documentation => 'Secure Token allow requests in error',
            flags         => 'h',
        },
        secureTokenAttribute => {
            type          => 'text',
            documentation => 'Secure Token attribute',
            flags         => 'h',
        },
        secureTokenExpiration => {
            type          => 'text',
            documentation => 'Secure Token expiration',
            flags         => 'h',
        },
        secureTokenHeader => {
            type          => 'text',
            documentation => 'Secure Token header',
            flags         => 'h',
        },
        secureTokenMemcachedServers => {
            type          => 'text',
            documentation => 'Secure Token Memcached servers',
            flags         => 'h',
        },
        secureTokenUrls => {
            type          => 'text',
            documentation => '',
            flags         => 'h',
        },

        # Zimbra handler parameters
        zimbraAccountKey => {
            type          => 'text',
            flags         => 'h',
            documentation => 'Zimbra account session key',
        },
        zimbraBy => {
            type          => 'text',
            flags         => 'h',
            documentation => 'Zimbra account type',
        },
        zimbraPreAuthKey => {
            type          => 'text',
            flags         => 'h',
            documentation => 'Zimbra preauthentication key',
        },
        zimbraSsoUrl => {
            type          => 'text',
            flags         => 'h',
            documentation => 'Zimbra local SSO URL pattern',
        },
        zimbraUrl => {
            type          => 'text',
            flags         => 'h',
            documentation => 'Zimbra preauthentication URL',
        },

        # CAS IDP
        casAttr =>
          { type => 'text', documentation => 'Pivot attribute for CAS', },
        casAttributes => {
            type          => 'keyTextContainer',
            documentation => 'CAS exported attributes',
        },
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
        casStorage => {
            type          => 'PerlModule',
            documentation => 'Apache::Session module to store CAS user data',
        },
        casStorageOptions => {
            type          => 'keyTextContainer',
            documentation => 'Apache::Session module parameters',
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

        # Partners
        casAppMetaDataOptions => {
            type          => 'subContainer',
            documentation => 'Root of CAS app options',
        },
        casAppMetaDataExportedVars => {
            type          => 'keyTextContainer',
            default       => { cn => 'cn', mail => 'mail', uid => 'uid', },
            documentation => 'CAS exported variables',
        },
        casAppMetaDataOptionsService => {
            type          => 'url',
            documentation => 'CAS App service',
        },
        casAppMetaDataOptionsUserAttribute => {
            type          => 'text',
            documentation => 'CAS User attribute',
        },
        casAppMetaDataOptionsRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            documentation => 'CAS App rule',
        },

        # Fake attribute: used by manager REST API to agglomerate all nodes
        # related to a CAS SP partner
        casAppMetaDataNodes => {
            type     => 'casAppMetaDataNodeContainer',
            template => 'casAppMetaDataNode',
            help     => 'idpcas.html#configuring_cas_applications',
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
        samlServiceSignatureMethod => {
            type   => 'select',
            select => [
                { k => 'RSA_SHA1',   v => 'RSA SHA1' },
                { k => 'RSA_SHA256', v => 'RSA SHA256' },
            ],
            default => 'RSA_SHA1',
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
        samlStorage => {
            type          => 'PerlModule',
            documentation => 'Apache::Session module to store SAML user data',
        },
        samlStorageOptions => {
            type          => 'keyTextContainer',
            documentation => 'Apache::Session module parameters',
        },
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
        samlDiscoveryProtocolActivation => {
            default       => 0,
            type          => 'bool',
            documentation => 'SAML Discovery Protocol activation',
        },
        samlDiscoveryProtocolURL => {
            type          => 'text',
            test          => $url,
            msgFail       => '__badUrl__',
            documentation => 'SAML Discovery Protocol EndPoint URL',
        },
        samlDiscoveryProtocolPolicy => {
            type          => 'text',
            documentation => 'SAML Discovery Protocol Policy',
        },
        samlDiscoveryProtocolIsPassive => {
            default       => 0,
            type          => 'bool',
            documentation => 'SAML Discovery Protocol Is Passive',
        },
        samlRelayStateTimeout => {
            type          => 'int',
            default       => 600,
            documentation => 'SAML timeout of relay state',
        },
        samlOverrideIDPEntityID => {
            type          => 'text',
            documentation => 'Override SAML EntityID when acting as an IDP',
            default       => '',
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
            help     => 'authsaml.html',
        },

        # Fake attribute: used by manager REST API to agglomerate all nodes
        # related to a SAML SP partner
        samlSPMetaDataNodes => {
            type     => 'samlSPMetaDataNodeContainer',
            template => 'samlSPMetaDataNode',
            help     => 'idpsaml.html',
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
            test => sub {
                my $v = shift;
                return 1 unless ( $v and %$v );
                my @msg;
                my $res = 1;
                my %entityIds;
                foreach my $idpId ( keys %$v ) {
                    unless ( $v->{$idpId}->{samlIDPMetaDataXML} =~
                        /entityID="(.+?)"/si )
                    {
                        push @msg, "$idpId SAML metadata has no EntityID";
                        $res = 0;
                        next;
                    }
                    my $eid = $1;
                    if ( defined $entityIds{$eid} ) {
                        push @msg,
"$idpId and $entityIds{$eid} have the same SAML EntityID";
                        $res = 0;
                        next;
                    }
                    $entityIds{$eid} = $idpId;
                }
                return ( $res, join( ', ', @msg ) );
            },
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
                { k => 'artifact-get',  v => 'Artifact GET' },
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
        samlIDPMetaDataOptionsUserAttribute => { type => 'text', },
        samlIDPMetaDataOptionsDisplayName   => { type => 'text', },
        samlIDPMetaDataOptionsIcon          => { type => 'text', },
        samlIDPMetaDataOptionsSortNumber    => { type => 'int', },

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
        samlSPMetaDataXML     => { type => 'file', },
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
        samlSPMetaDataOptionsNameIDSessionKey => { type => 'text', },
        samlSPMetaDataOptionsOneTimeUse       => {
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
        samlSPMetaDataOptionsRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            documentation => 'Rule to grant access to this SP',
        },

        # AUTH, USERDB and PASSWORD MODULES
        authentication => {
            type   => 'select',
            select => [
                { k => 'Apache',      v => 'Apache' },
                { k => 'AD',          v => 'Active Directory' },
                { k => 'DBI',         v => 'Database (DBI)' },
                { k => 'Facebook',    v => 'Facebook' },
                { k => 'GPG',         v => 'GPG' },
                { k => 'Kerberos',    v => 'Kerberos' },
                { k => 'LDAP',        v => 'LDAP' },
                { k => 'LinkedIn',    v => 'LinkedIn' },
                { k => 'PAM',         v => 'PAM' },
                { k => 'Radius',      v => 'Radius' },
                { k => 'REST',        v => 'REST' },
                { k => 'SSL',         v => 'SSL' },
                { k => 'Twitter',     v => 'Twitter' },
                { k => 'WebID',       v => 'WebID' },
                { k => 'Demo',        v => 'Demonstration' },
                { k => 'Choice',      v => 'authChoice' },
                { k => 'Combination', v => 'combineMods' },
                { k => 'CAS',    v => 'Central Authentication Service (CAS)' },
                { k => 'OpenID', v => 'OpenID' },
                { k => 'OpenIDConnect', v => 'OpenID Connect' },
                { k => 'SAML',          v => 'SAML v2' },
                { k => 'Proxy',         v => 'Proxy' },
                { k => 'Remote',        v => 'Remote' },
                { k => 'Slave',         v => 'Slave' },
                { k => 'Null',          v => 'None' },
                { k => 'Custom',        v => 'customModule' },
            ],
            default       => 'Demo',
            documentation => 'Authentication module',
        },
        userDB => {
            type   => 'select',
            select => [
                { k => 'Same',   v => 'Same' },
                { k => 'AD',     v => 'Active Directory' },
                { k => 'DBI',    v => 'Database (DBI)' },
                { k => 'LDAP',   v => 'LDAP' },
                { k => 'REST',   v => 'REST' },
                { k => 'Null',   v => 'None' },
                { k => 'Custom', v => 'customModule' },
            ],
            default       => 'Same',
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
                { k => 'REST',   v => 'REST' },
                { k => 'Null',   v => 'None' },
                { k => 'Custom', v => 'customModule' },
            ],
            default       => 'Demo',
            documentation => 'Password module',
        },

        # Second Factor Engine
        sfEngine => {
            type          => 'text',
            default       => '::2F::Engines::Default',
            documentation => 'Second factor engine',
        },
        sfRequired => {
            type          => 'boolOrExpr',
            default       => 0,
            help          => 'secondfactor.html',
            documentation => 'Second factor required',
        },
        sfRemovedMsgRule => {
            type    => 'boolOrExpr',
            default => 0,
            help    => 'secondfactor.html',
            documentation =>
              'Display a message if at leat one expired SF has been removed',
        },
        sfRemovedUseNotif => {
            default       => 0,
            type          => 'bool',
            documentation => 'Use Notifications plugin to display message',
        },
        sfRemovedNotifRef => {
            type          => 'text',
            default       => 'RemoveSF',
            help          => 'secondfactor.html',
            documentation => 'Notification reference',
        },
        sfRemovedNotifTitle => {
            type          => 'text',
            default       => 'Second factor notification',
            help          => 'secondfactor.html',
            documentation => 'Notification title',
        },
        sfRemovedNotifMsg => {
            type => 'text',
            default =>
              '_removedSF_ expired second factor(s) has/have been removed!',
            help          => 'secondfactor.html',
            documentation => 'Notification message',
        },
        available2F => {
            type          => 'text',
            default       => 'UTOTP,TOTP,U2F,REST,Mail2F,Ext2F,Yubikey',
            documentation => 'Available second factor modules',
        },
        available2FSelfRegistration => {
            type    => 'text',
            default => 'TOTP,U2F,Yubikey',
            documentation =>
              'Available self-registration modules for second factor',
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
        mailLDAPFilter => {
            type          => 'text',
            documentation => 'LDAP filter for mail search'
        },
        LDAPFilter =>
          { type => 'text', documentation => 'Default LDAP filter' },
        AuthLDAPFilter => {
            type          => 'text',
            documentation => 'LDAP filter for auth search'
        },
        ldapGroupDecodeSearchedValue => {
            default       => 0,
            type          => 'bool',
            documentation => 'Decode value before searching it in LDAP groups',
        },
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
        SSLVar => {
            type    => 'text',
            default => 'SSL_CLIENT_S_DN_Email'
        },
        SSLVarIf => {
            type    => 'keyTextContainer',
            default => {}
        },
        sslByAjax => {
            type          => 'bool',
            default       => 0,
            documentation => 'Use Ajax request for SSL',
        },
        sslHost => {
            type          => 'url',
            documentation => 'URL for SSL Ajax request',
        },

        # CAS
        casAuthnLevel => {
            type          => 'int',
            default       => 1,
            documentation => 'CAS authentication level',
        },
        casSrvMetaDataExportedVars => {
            type          => 'keyTextContainer',
            default       => { cn => 'cn', mail => 'mail', uid => 'uid', },
            documentation => 'CAS exported variables',
        },
        casSrvMetaDataOptions => {
            type          => 'subContainer',
            documentation => 'Root of CAS server options',
        },
        casSrvMetaDataOptionsGateway => { type => 'bool', default => 0 },
        casSrvMetaDataOptionsProxiedServices => {
            type       => 'keyTextContainer',
            keyTest    => qr/^\w/,
            keyMsgFail => '__badCasProxyId__',
        },
        casSrvMetaDataOptionsRenew => { type => 'bool', default => 0 },
        casSrvMetaDataOptionsUrl   => {
            type    => 'text',
            test    => $url,
            msgFail => '__badUrl__',
        },
        casSrvMetaDataOptionsDisplayName => {
            type          => 'text',
            documentation => 'Name to display for CAS server',
        },
        casSrvMetaDataOptionsIcon => {
            type          => 'text',
            documentation => 'Path of CAS Server Icon',
        },
        casSrvMetaDataOptionsSortNumber => {
            type          => 'int',
            documentation => 'Number to sort buttons',
        },

        # Fake attribute: used by manager REST API to agglomerate all nodes
        # related to a CAS IDP partner
        casSrvMetaDataNodes => {
            type     => 'casSrvMetaDataNodeContainer',
            template => 'casSrvMetaDataNode',
            help     => 'authcas.html',
        },

        # PAM
        pamAuthnLevel => {
            type          => 'int',
            default       => 2,
            documentation => 'PAM authentication level',
        },
        pamService => {
            type          => 'text',
            default       => 'login',
            documentation => 'PAM service',
        },

        # GPG
        gpgDb => {
            type          => 'text',
            default       => '',
            documentation => 'GPG keys database',
        },
        gpgAuthnLevel => {
            type          => 'int',
            default       => 5,
            documentation => 'GPG authentication level',
        },

        # Radius
        radiusAuthnLevel => {
            type          => 'int',
            default       => 3,
            documentation => 'Radius authentication level',
        },
        radiusSecret => { type => 'text', },
        radiusServer => { type => 'text', },

        # REST
        restAuthUrl   => { type => 'url' },
        restUserDBUrl => { type => 'url' },

        # TODO: add restMailDBUrl
        restPwdConfirmUrl => { type => 'url' },
        restPwdModifyUrl  => { type => 'url' },

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
                proxy => 'http://auth.example.com/sessions',
                ns =>
'http://auth.example.com/Lemonldap/NG/Common/PSGI/SOAPService',
            },
            documentation => 'Apache::Session module parameters',
        },

        # Proxy
        proxyAuthService    => { type => 'text', },
        proxySessionService => { type => 'text', },
        remoteCookieName    => { type => 'text', },
        proxyUseSoap        => {
            type          => 'bool',
            default       => 0,
            documentation => 'Use SOAP instead of REST',
        },
        proxyAuthnLevel => {
            type          => 'int',
            default       => 2,
            documentation => 'Proxy authentication level',
        },

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
        facebookUserField => { type => 'text', default => 'id' },

        # Twitter
        twitterAuthnLevel => {
            type          => 'int',
            default       => 1,
            documentation => 'Twitter authentication level',
        },
        twitterKey       => { type => 'text', },
        twitterSecret    => { type => 'text', },
        twitterAppName   => { type => 'text', },
        twitterUserField => { type => 'text', default => 'screen_name' },

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
        dbiAuthChain    => { type => 'text', },
        dbiAuthUser     => { type => 'text', },
        dbiAuthPassword => { type => 'password', },
        dbiUserChain    => { type => 'text', },
        dbiUserUser     => { type => 'text', },
        dbiUserPassword => { type => 'password', },
        dbiAuthTable    => { type => 'text', },
        dbiUserTable    => { type => 'text', },

        # TODO: add dbiMailCol
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
            default       => 0,
            documentation => 'Null authentication level',
        },

        # Kerberos
        krbKeytab => {
            type          => 'text',
            documentation => 'Kerberos keytab',
        },
        krbByJs => {
            type          => 'bool',
            default       => 0,
            documentation => 'Launch Kerberos authentication by Ajax',
        },
        krbAuthnLevel => {
            type          => 'int',
            default       => 3,
            documentation => 'Null authentication level',
        },
        krbRemoveDomain => {
            type          => 'bool',
            default       => 1,
            documentation => 'Remove domain in Kerberos username',
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
            select     => [ [
                    { k => 'Apache', v => 'Apache' },
                    { k => 'AD',     v => 'Active Directory' },
                    {
                        k => 'CAS',
                        v => 'Central Authentication Service (CAS)'
                    },
                    { k => 'DBI',           v => 'Database (DBI)' },
                    { k => 'Demo',          v => 'Demo' },
                    { k => 'Facebook',      v => 'Facebook' },
                    { k => 'GPG',           v => 'GPG' },
                    { k => 'Kerberos',      v => 'Kerberos' },
                    { k => 'LDAP',          v => 'LDAP' },
                    { k => 'LinkedIn',      v => 'LinkedIn' },
                    { k => 'PAM',           v => 'PAM' },
                    { k => 'Null',          v => 'None' },
                    { k => 'OpenID',        v => 'OpenID' },
                    { k => 'OpenIDConnect', v => 'OpenID Connect' },
                    { k => 'Proxy',         v => 'Proxy' },
                    { k => 'Radius',        v => 'Radius' },
                    { k => 'REST',          v => 'REST' },
                    { k => 'Remote',        v => 'Remote' },
                    { k => 'SAML',          v => 'SAML v2' },
                    { k => 'Slave',         v => 'Slave' },
                    { k => 'SSL',           v => 'SSL' },
                    { k => 'Twitter',       v => 'Twitter' },
                    { k => 'WebID',         v => 'WebID' },
                    { k => 'Custom',        v => 'customModule' },
                ],
                [
                    { k => 'AD', v => 'Active Directory' },
                    {
                        k => 'CAS',
                        v => 'Central Authentication Service (CAS)'
                    },
                    { k => 'DBI',           v => 'Database (DBI)' },
                    { k => 'Demo',          v => 'Demo' },
                    { k => 'Facebook',      v => 'Facebook' },
                    { k => 'LDAP',          v => 'LDAP' },
                    { k => 'Null',          v => 'None' },
                    { k => 'OpenID',        v => 'OpenID' },
                    { k => 'OpenIDConnect', v => 'OpenID Connect' },
                    { k => 'Proxy',         v => 'Proxy' },
                    { k => 'REST',          v => 'REST' },
                    { k => 'Remote',        v => 'Remote' },
                    { k => 'SAML',          v => 'SAML v2' },
                    { k => 'Slave',         v => 'Slave' },
                    { k => 'WebID',         v => 'WebID' },
                    { k => 'Custom',        v => 'customModule' },
                ],
                [
                    { k => 'AD',     v => 'Active Directory' },
                    { k => 'DBI',    v => 'Database (DBI)' },
                    { k => 'Demo',   v => 'Demo' },
                    { k => 'LDAP',   v => 'LDAP' },
                    { k => 'REST',   v => 'REST' },
                    { k => 'Null',   v => 'None' },
                    { k => 'Custom', v => 'customModule' },
                ]
            ],
            documentation => 'Hash list of Choice strings',
        },

        # Combination
        combination => {
            type          => 'text',
            documentation => 'Combination rule'
        },
        combModules => {
            type          => 'cmbModuleContainer',
            keyTest       => qr/^\w+$/,
            test          => sub { 1 },
            documentation => 'Combination module description',
            select        => [
                { k => 'Apache',   v => 'Apache' },
                { k => 'AD',       v => 'Active Directory' },
                { k => 'DBI',      v => 'Database (DBI)' },
                { k => 'Facebook', v => 'Facebook' },
                { k => 'GPG',      v => 'GPG' },
                { k => 'Kerberos', v => 'Kerberos' },
                { k => 'LDAP',     v => 'LDAP' },
                { k => 'LinkedIn', v => 'LinkedIn' },
                { k => 'PAM',      v => 'PAM' },
                { k => 'Radius',   v => 'Radius' },
                { k => 'REST',     v => 'REST' },
                { k => 'SSL',      v => 'SSL' },
                { k => 'Twitter',  v => 'Twitter' },
                { k => 'WebID',    v => 'WebID' },
                { k => 'Demo',     v => 'Demonstration' },
                { k => 'CAS',    v => 'Central Authentication Service (CAS)' },
                { k => 'OpenID', v => 'OpenID' },
                { k => 'OpenIDConnect', v => 'OpenID Connect' },
                { k => 'SAML',          v => 'SAML v2' },
                { k => 'Proxy',         v => 'Proxy' },
                { k => 'Remote',        v => 'Remote' },
                { k => 'Slave',         v => 'Slave' },
                { k => 'Null',          v => 'None' },
                { k => 'Custom',        v => 'customModule' },
            ],
        },

        # Custom auth modules
        customAuth => {
            type          => 'text',
            documentation => 'Custom auth module',
        },
        customUserDB => {
            type          => 'text',
            documentation => 'Custom user DB module',
        },
        customPassword => {
            type          => 'text',
            documentation => 'Custom password module',
        },
        customRegister => {
            type          => 'text',
            documentation => 'Custom register module',
        },
        customAddParams => {
            type          => 'keyTextContainer',
            documentation => 'Custom additional parameters',
        },

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
            default       => 'checksession.html',
            documentation => 'OpenID Connect check session iframe',
        },
        oidcServiceMetaDataBackChannelURI => {
            type          => 'text',
            default       => 'blogout',
            documentation => 'OpenID Connect Front-Channel logout endpoint',
        },
        oidcServiceMetaDataFrontChannelURI => {
            type          => 'text',
            default       => 'flogout',
            documentation => 'OpenID Connect Front-Channel logout endpoint',
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
            default       => 0,
            documentation => 'OpenID Connect allow dynamic client registration',
        },
        oidcServiceAllowAuthorizationCodeFlow => {
            type          => 'bool',
            default       => 1,
            documentation => 'OpenID Connect allow authorization code flow',
        },
        oidcServiceAllowImplicitFlow => {
            type          => 'bool',
            default       => 0,
            documentation => 'OpenID Connect allow implicit flow',
        },
        oidcServiceAllowHybridFlow => {
            type          => 'bool',
            default       => 0,
            documentation => 'OpenID Connect allow hybrid flow',
        },
        oidcStorage => {
            type          => 'PerlModule',
            documentation => 'Apache::Session module to store OIDC user data',
        },
        oidcStorageOptions => {
            type          => 'keyTextContainer',
            documentation => 'Apache::Session module parameters',
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
        oidcOPMetaDataOptionsSortNumber   => { type => 'int', },

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
        oidcRPMetaDataOptionsBypassConsent => {
            type    => 'bool',
            help    => 'openidconnectclaims.html',
            default => 0
        },
        oidcRPMetaDataOptionsPostLogoutRedirectUris => { type => 'text', },
        oidcRPMetaDataOptionsLogoutUrl              => {
            type          => 'url',
            documentation => 'Logout URL',
        },
        oidcRPMetaDataOptionsLogoutType => {
            type   => 'select',
            select => [
                { k => 'front', v => 'Front Channel' },
                { k => 'back',  v => 'Back Channel' },
            ],
            default       => 'front',
            documentation => 'Logout type',
        },
        oidcRPMetaDataOptionsLogoutSessionRequired => {
            type          => 'bool',
            default       => 0,
            documentation => 'Session required for logout',
        },
        oidcRPMetaDataOptionsPublic => {
            type          => 'bool',
            default       => 0,
            documentation => 'Declare this RP as public client',
        },
        oidcRPMetaDataOptionsRequirePKCE => {
            type          => 'bool',
            default       => 0,
            documentation => 'Require PKCE',
        },
        oidcRPMetaDataOptionsRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            documentation => 'Rule to grant access to this RP',
        },
    };
}

1;
