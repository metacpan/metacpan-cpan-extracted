#  This file contains the description of all configuration parameters
# It may be included only by batch files, never in portal or handler chain
# for performances reasons

# DON'T FORGET TO RUN "make json" AFTER EACH CHANGE

package Lemonldap::NG::Manager::Build::Attributes;

our $VERSION = '2.21.0';
use strict;
use Regexp::Common qw/URI/;

sub perlExpr {
    my ( $val, $conf ) = @_;
    my $cpt = new Safe;
    $cpt->share_from( 'MIME::Base64', ['&encode_base64'] );
    $cpt->share_from(
        'Lemonldap::NG::Handler::Main::Jail',
        [
            '&encrypt', '&token',
            @Lemonldap::NG::Handler::Main::Jail::builtCustomFunctions
        ]
    );
    $cpt->share_from( 'Lemonldap::NG::Common::Safelib',
        $Lemonldap::NG::Common::Safelib::functions );
    $cpt->reval($val);
    my $err = join( '',
        grep { $_ =~ /(?:Undefined subroutine|Devel::StackTrace)/ ? () : $_ }
          split( /\n/, $@ ) );
    return ( -1, "__badExpression__: $err" )
      if ( $err && $conf->{useSafeJail} );
    return ( $val =~ qr/(?<=[^=<!>\|\?])=(?![>=~])/
          && $conf->{avoidAssignment} )
      ? ( 1, "__badExpressionAssignment__" )
      : 1;
}

my $url_re = $RE{URI}{HTTP}{ -scheme => "https?" };
$url_re =~ s/(?<=[^\\])\$/\\\$/g;
my $url        = qr/$url_re/;
my $urlOrEmpty = qr/(?:^$|$url_re)/;

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
            test    => $urlOrEmpty,
            msgFail => '__badUrl__',
        },
        PerlModule => {
            form => 'text',
            test => qr/^(?:[a-zA-Z][a-zA-Z0-9]*)*(?:::[a-zA-Z][a-zA-Z0-9]*)*$/,
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
                    or $val =~ m/^_/ );
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
        intOrNull => {
            test    => qr/^\-?\d*$/,
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
                return ( 0, "Value is not a scalar" ) if ref( $_[0] );
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
/^(?:(?:\-+\s*BEGIN\s+(?:(?:RSA|ENCRYPTED)\s+)?PRIVATE\s+KEY\s*\-+\r?\n)?(?:Proc-Type:.*\r?\nDEK-Info:.*\r?\n[\r\n]*)?[a-zA-Z0-9\/\+\r\n]+={0,2}(?:\r?\n\-+\s*END\s+(?:(?:RSA|ENCRYPTED)\s+)?PRIVATE\s+KEY\s*\-+)?[\r\n]*)?$/s
                    ? (1)
                    : ( 1, '__badPemEncoding__' )
                );
            },
        },
        'EcOrRSAPublicKeyOrCertificate' => {
            'test' => sub {
                return (
                    $_[0] =~
/^(?:(?:\-+\s*BEGIN\s+(?:PUBLIC\s+KEY|CERTIFICATE)\s*\-+\r?\n)?[a-zA-Z0-9\/\+\r\n]+={0,2}(?:\r?\n\-+\s*END\s+(?:PUBLIC\s+KEY|CERTIFICATE)\s*\-+)?[\r\n]*)?$/s
                    ? (1)
                    : ( 1, '__badPemEncoding__' )
                );
            },
        },
        EcOrRSAPrivateKey => {
            test => sub {
                return (
                    $_[0] =~
/^(?:(?:\-+\s*BEGIN\s+(?:(?:RSA|EC|ENCRYPTED)\s+)?PRIVATE\s+KEY\s*\-+\r?\n)?(?:Proc-Type:.*\r?\nDEK-Info:.*\r?\n[\r\n]*)?[a-zA-Z0-9\/\+\r\n]+={0,2}(?:\r?\n\-+\s*END\s+(?:(?:RSA|EC|ENCRYPTED)\s+)?PRIVATE\s+KEY\s*\-+)?[\r\n]*)?$/s
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
        oidcAttribute => {
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

use constant oidcEncAlgorithmEnc => [
    { k => 'A256CBC-HS512', v => 'A256CBC-HS512' },
    { k => 'A256GCM',       v => 'A256GCM' },
    { k => 'A192CBC-HS384', v => 'A192CBC-HS384' },
    { k => 'A192GCM',       v => 'A192GCM' },
    { k => 'A128CBC-HS256', v => 'A128CBC-HS256' },
    { k => 'A128GCM',       v => 'A128GCM' },
];

use constant oidcEncAlgorithmAlg => [

    # Symetric encryption not supported
    #{ k => 'A128KW',             v => 'A128KW' },
    #{ k => 'A192KW',             v => 'A192KW' },
    #{ k => 'A256KW',             v => 'A256KW' },
    #{ k => 'A128GCMKW',          v => 'A128GCMKW' },
    #{ k => 'A192GCMKW',          v => 'A192GCMKW' },
    #{ k => 'A256GCMKW',          v => 'A256GCMKW' },
    #{ k => 'PBES2-HS256+A128KW', v => 'PBES2-HS256+A128KW' },
    #{ k => 'PBES2-HS384+A192KW', v => 'PBES2-HS384+A192KW' },
    #{ k => 'PBES2-HS512+A256KW', v => 'PBES2-HS512+A256KW' },
    { k => '',               v => 'None' },
    { k => 'RSA-OAEP',       v => 'RSA-OAEP' },
    { k => 'RSA-OAEP-256',   v => 'RSA-OAEP-256' },
    { k => 'RSA1_5',         v => 'RSA1_5' },
    { k => 'ECDH-ES',        v => 'ECDH-ES' },
    { k => 'ECDH-ES+A128KW', v => 'ECDH-ES+A128KW' },
    { k => 'ECDH-ES+A192KW', v => 'ECDH-ES+A192KW' },
    { k => 'ECDH-ES+A256KW', v => 'ECDH-ES+A256KW' },
];

use constant oidcSigAlgorithmAlg => [
    { k => 'HS256', v => 'HS256' },
    { k => 'HS384', v => 'HS384' },
    { k => 'HS512', v => 'HS512' },
    { k => 'RS256', v => 'RS256' },
    { k => 'RS384', v => 'RS384' },
    { k => 'RS512', v => 'RS512' },
    { k => 'PS256', v => 'PS256' },
    { k => 'PS384', v => 'PS384' },
    { k => 'PS512', v => 'PS512' },
    { k => 'ES256', v => 'ES256' },
    { k => 'ES384', v => 'ES384' },
    { k => 'ES512', v => 'ES512' },
    { k => 'EdDSA', v => 'EdDSA' },
];

sub attributes {
    return {

        # Other
        checkTime => {
            type          => 'int',
            documentation =>
              'Timeout to check new configuration in local cache',
            default => 600,
            flags   => 'hp',
        },
        checkMsg => {
            type          => 'int',
            documentation => 'Timeout to check new evant',
            default       => 5,
            flags         => 'hp',
        },
        defaultNewKeySize => {
            type          => 'int',
            documentation => 'Default size for new RSA key helper',
            default       => 2048,
            flags         => 'm',
        },
        mySessionAuthorizedRWKeys => {
            type          => 'array',
            documentation => 'Alterable session keys by user itself',
            default       => [
                '_appsListOrder',      '_oidcConnectedRP',
                '_oidcConnectedRPIDs', '_oidcConsents'
            ],
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
        eventStatus => {
            type          => 'bool',
            documentation => 'Push status into message broker',
            flags         => 'h',
        },
        statusQueueName => {
            type          => 'text',
            default       => 'llng_status',
            flags         => 'h',
            documentation => 'Status channel name',
        },
        confirmFormMethod => {
            type   => "select",
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
            type   => "select",
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
        portalFavicon => {
            type          => 'text',
            default       => 'common/favicon.ico',
            documentation => 'Path to favicon file',
        },
        portalCustomCss => {
            type          => 'text',
            documentation => 'Path to custom CSS file',
        },
        portalCustomJs => {
            type          => 'text',
            documentation => 'Path to custom JS file',
        },
        portalStatus => {
            type          => 'bool',
            default       => 0,
            help          => 'status.html',
            documentation => 'Enable portal status',
        },
        portalUserAttr => {
            type          => 'text',
            default       => '_user',
            documentation =>
              'Session parameter to display connected user in portal',
        },
        redirectFormMethod => {
            type   => "select",
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
            keyTest       => qr/^$Regexp::Common::URI::RFC2396::host(?::\d+)?$/,
            test          => $url,
            msgFail       => '__badUrl__',
            documentation => 'URL to call on reload',
        },
        compactConf => {
            type          => 'bool',
            default       => 0,
            documentation => 'Compact configuration',
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
        scrollTop => {
            type          => 'int',
            default       => 400,
            documentation => 'Display back to top button',
        },
        floatingCategoryName => {
            type          => 'text',
            documentation => 'Name of the category displayed as floating menu',
        },
        staticPrefix => {
            type          => 'text',
            documentation => 'Prefix of static files for HTML templates',
        },
        groupsBeforeMacros => {
            type          => 'bool',
            default       => 0,
            documentation => 'Compute groups before macros',
        },
        multiValuesSeparator => {
            type          => 'authParamsText',
            default       => '; ',
            documentation => 'Separator for multiple values',
            flags         => 'hmp',
        },
        rememberAuthChoiceForgetAtLogout => {
            type          => 'bool',
            default       => 0,
            documentation => 'Forget Auth Choice at logout',
        },
        rememberAuthChoiceRule => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'remember auth choice activation rule',
        },
        rememberCookieName => {
            type          => 'text',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_-]*$/,
            msgFail       => '__badCookieName__',
            default       => 'llngrememberauthchoice',
            documentation => 'Name of the remember auth choice cookie',
            flags         => 'p',
        },
        rememberCookieTimeout => {
            type          => 'int',
            default       => 31536000,
            documentation => 'lifetime of the remember auth choice cookie',
            flags         => 'm',
        },
        rememberDefaultChecked => {
            type          => 'bool',
            default       => 0,
            documentation =>
              'Is remember auth choice checkbox enabled by default?',
        },
        rememberTimer => {
            type          => 'int',
            default       => 5,
            documentation =>
              'timer before automatic authentication with remembered choice',
            flags => 'm',
        },
        stayConnected => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Stay connected activation rule',
        },
        stayConnectedBypassFG => {
            type          => 'bool',
            default       => 0,
            documentation => 'Disable fingerprint checkng',
        },
        stayConnectedTimeout => {
            type          => 'int',
            default       => 2592000,
            documentation =>
              'StayConnected persistent connexion session timeout',
            flags => 'm',
        },
        stayConnectedCookieName => {
            type          => 'text',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_-]*$/,
            msgFail       => '__badCookieName__',
            default       => 'llngconnection',
            documentation => 'Name of the stayConnected plugin cookie',
            flags         => 'p',
        },
        stayConnectedSingleSession => {
            default       => 0,
            type          => 'bool',
            documentation => 'Allow only one permanent session per user',
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
        checkDevOps => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable check DevOps',
            flags         => 'p',
        },
        checkDevOpsDownload => {
            default       => 1,
            type          => 'bool',
            documentation => 'Enable check DevOps download field',
            flags         => 'p',
        },
        checkDevOpsDisplayNormalizedHeaders => {
            default       => 1,
            type          => 'bool',
            documentation => 'Display normalized headers',
            flags         => 'p',
        },
        checkDevOpsCheckSessionAttributes => {
            default       => 1,
            type          => 'bool',
            documentation => 'Check if session attributes exist',
            flags         => 'p',
        },
        checkHIBP => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable check HIBP',
            flags         => 'p',
        },
        checkHIBPURL => {
            default       => 'https://api.pwnedpasswords.com/range/',
            type          => 'url',
            documentation => 'URL of Have I Been Pwned API',
            flags         => 'p',
        },
        checkHIBPRequired => {
            default       => 1,
            type          => 'bool',
            documentation => 'Require HIBP check to pass',
            flags         => 'p',
        },
        checkEntropy => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable entropy check of password',
            flags         => 'p',
        },
        checkEntropyRequired => {
            default       => 0,
            type          => 'bool',
            documentation => 'Require entropy check to pass',
            flags         => 'p',
        },
        checkEntropyRequiredLevel => {
            type          => 'int',
            documentation =>
              'Minimal entropy required for the password to be accepted',
            flags => 'p',
        },
        initializePasswordReset => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable Password Reset API plugin',
            flags         => 'p',
        },
        initializePasswordResetSecret => {
            type          => 'password',
            documentation => 'Secret key for the Initialize Password Reset API',
            flags         => 'p',
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
        checkUserUnrestrictedUsersRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            documentation => 'checkUser unrestricted users rule',
            flags         => 'p',
        },
        checkUserHiddenAttributes => {
            type          => 'text',
            default       => '_loginHistory, _session_id, hGroups',
            documentation => 'Attributes to hide in CheckUser plugin',
            flags         => 'p',
        },
        checkUserSearchAttributes => {
            type          => 'text',
            documentation =>
              'Attributes used for retrieving sessions in user DataBase',
            flags => 'p',
        },
        checkUserDisplayPersistentInfo => {
            default       => 0,
            type          => 'boolOrExpr',
            documentation => 'Display persistent session info rule',
            flags         => 'p',
        },
        checkUserDisplayEmptyValues => {
            default       => 0,
            type          => 'boolOrExpr',
            documentation => 'Display session empty values rule',
            flags         => 'p',
        },
        checkUserDisplayEmptyHeaders => {
            default       => 0,
            type          => 'boolOrExpr',
            documentation => 'Display empty headers rule',
            flags         => 'p',
        },
        checkUserDisplayNormalizedHeaders => {
            default       => 0,
            type          => 'boolOrExpr',
            documentation => 'Display normalized headers rule',
            flags         => 'p',
        },
        checkUserDisplayComputedSession => {
            default       => 1,
            type          => 'boolOrExpr',
            documentation => 'Display empty headers rule',
            flags         => 'p',
        },
        checkUserDisplayHistory => {
            default       => 0,
            type          => 'boolOrExpr',
            documentation => 'Display history rule',
            flags         => 'p',
        },
        checkUserDisplayHiddenAttributes => {
            default       => 0,
            type          => 'boolOrExpr',
            documentation => 'Display hidden attributes rule',
            flags         => 'p',
        },
        checkUserHiddenHeaders => {
            type       => 'keyTextContainer',
            keyTest    => qr/^\S+$/,
            keyMsgFail => '__badHostname__',
            test       => {
                keyTest    => qr/^(?=[^\-])[\w\-\s]+(?<=[^-])$/,
                keyMsgFail => '__badHeaderName__',
                test       => sub { return perlExpr(@_) },
            },
            documentation => 'Header values to hide if not empty',
        },
        findUser => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable find user',
            flags         => 'p',
        },
        findUserSearchingAttributes => {
            type          => 'keyTextContainer',
            keyTest       => qr/^\S+$/,
            documentation => 'Attributes used for searching accounts',
        },
        findUserExcludingAttributes => {
            type          => 'keyTextContainer',
            keyTest       => qr/^\S+$/,
            documentation => 'Attributes used for excluding accounts',
        },
        findUserWildcard => {
            type          => 'text',
            default       => '*',
            documentation => 'Character used as wildcard',
        },
        findUserControl => {
            type          => 'pcre',
            default       => '^[*\w]+$',
            documentation => 'Regular expression to validate parameters',
        },
        newLocationWarning => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable New Location Warning',
        },
        newLocationWarningLocationAttribute => {
            type          => 'text',
            default       => 'ipAddr',
            documentation => 'New location session attribute',
        },
        newLocationWarningLocationDisplayAttribute => {
            type          => 'text',
            default       => '',
            documentation => 'New location session attribute for user display',
        },
        newLocationWarningMaxValues => {
            type          => 'int',
            default       => '0',
            documentation => 'How many previous locations should be compared',
        },
        newLocationWarningMailAttribute => {
            type          => 'text',
            documentation => 'New location warning mail session attribute',
        },
        newLocationWarningMailBody => {
            type          => 'longtext',
            documentation => 'Mail body for new location warning',
        },
        newLocationWarningMailSubject => {
            type          => 'text',
            documentation => 'Mail subject for new location warning',
        },
        globalLogoutRule => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Global logout activation rule',
            flags         => 'p',
        },
        globalLogoutTimer => {
            default       => 1,
            type          => 'bool',
            documentation => 'Global logout auto accept time',
            flags         => 'p',
        },
        globalLogoutCustomParam => {
            type          => 'text',
            documentation => 'Custom session parameter to display',
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
            flags         => 'p',
        },
        impersonationIdRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            default       => 1,
            documentation => 'Impersonation identities rule',
            flags         => 'p',
        },
        impersonationUnrestrictedUsersRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            documentation => 'Impersonation unrestricted users rule',
            flags         => 'p',
        },
        impersonationHiddenAttributes => {
            type          => 'text',
            default       => '_2fDevices, _loginHistory',
            documentation => 'Attributes to skip',
            flags         => 'p',
        },
        impersonationSkipEmptyValues => {
            default       => 1,
            type          => 'bool',
            documentation => 'Skip session empty values',
            flags         => 'p',
        },
        contextSwitchingRule => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Context switching activation rule',
            flags         => 'p',
        },
        contextSwitchingIdRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            default       => 1,
            documentation => 'Context switching identities rule',
            flags         => 'p',
        },
        contextSwitchingUnrestrictedUsersRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            documentation => 'Context switching unrestricted users rule',
            flags         => 'p',
        },
        contextSwitchingStopWithLogout => {
            type          => 'bool',
            default       => 1,
            documentation => 'Stop context switching by logout',
            flags         => 'p',
        },
        contextSwitchingAllowed2fModifications => {
            type          => 'bool',
            default       => 0,
            documentation => 'Allowed SFA modifications',
            flags         => 'p',
        },
        contextSwitchingPrefix => {
            type          => 'text',
            default       => 'switching',
            documentation => 'Prefix to store real session Id',
            flags         => 'p',
        },
        decryptValueRule => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Decrypt value activation rule',
            flags         => 'p',
        },
        decryptValueFunctions => {
            type          => 'text',
            test          => qr/^(?:\w+(?:::\w+)*(?:\s+\w+(?:::\w+)*)*)?$/,
            msgFail       => "__badCustomFuncName__",
            documentation => 'Custom function used for decrypting values',
            flags         => 'p',
        },
        skipRenewConfirmation => {
            type          => 'bool',
            default       => 0,
            documentation =>
              'Avoid asking confirmation when an Issuer asks to renew auth',
        },
        skipUpgradeConfirmation => {
            type          => 'bool',
            default       => 0,
            documentation =>
              'Avoid asking confirmation during a session upgrade',
        },
        refreshSessions => {
            type          => 'bool',
            help          => "refreshsessionapi.html",
            documentation => 'Refresh sessions plugin',
        },
        forceGlobalStorageIssuerOTT => {
            type          => 'bool',
            documentation =>
              'Force Issuer tokens to be stored into Global Storage',
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
        lokiUrl => {
            type          => 'text',
            documentation => 'Loki API',
            flags         => 'hmp',
        },
        lokiLabel => {
            type          => 'text',
            documentation => 'Loki label, default llng',
            flags         => 'hmp',
        },
        lokiInstance => {
            type          => 'text',
            documentation => 'Loki instance, default `hostname` output',
            flags         => 'hmp',
        },
        lokiEnv => {
            type          => 'text',
            documentation => 'Loki env, default "prod"',
            flags         => 'hmp',
        },
        lokiTenant => {
            type          => 'text',
            documentation => 'Loki Tenant',
            flags         => 'hmp',
        },
        lokiTenantHeader => {
            type          => 'text',
            documentation => 'Loki Tenant Header name',
            flags         => 'hmp',
        },
        lokiAuthorization => {
            type          => 'text',
            documentation => 'Loki Authorization header value',
            flags         => 'hmp',
        },
        lokiService => {
            type          => 'text',
            documentation => 'Loki Service (technical context)',
            flags         => 'hmp',
        },
        lokiUserService => {
            type          => 'text',
            documentation => 'Loki (userLogger context)',
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
            help    => 'portalmenu.html#categories-and-applications',
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
            type          => 'bool',
            default       => 0,
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
            test          => sub { 1 },
            msgFail       => '__badValue__',
            documentation => 'Rules to choose portal skin',
        },
        cacheTagSalt => {
            type          => 'text',
            documentation => 'Salt value for cache busting tag',
        },

        # Security
        formTimeout => {
            default       => 120,
            type          => 'int',
            documentation => 'Token timeout for forms',
        },
        issuersTimeout => {
            default       => 120,
            type          => 'int',
            documentation => 'Token timeout for issuers',
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
            default       => 0,
            help          => 'forcereauthn.html',
            type          => 'bool',
            documentation =>
              'Enable force to authenticate when displaying portal',
        },
        portalForceAuthnInterval => {
            default       => 300,
            type          => 'int',
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
            default       => 30,
            type          => 'int',
            documentation => 'Lock time',
        },
        bruteForceProtectionMaxAge => {
            default       => 300,
            type          => 'int',
            documentation => 'Max age between current and first failed login',
        },
        bruteForceProtectionMaxFailed => {
            default       => 3,
            type          => 'int',
            documentation => 'Max allowed failed login',
        },
        bruteForceProtectionMaxLockTime => {
            default       => 900,
            type          => 'int',
            documentation => 'Max lock time',
        },
        bruteForceProtectionIncrementalTempo => {
            default       => 0,
            help          => 'bruteforceprotection.html',
            type          => 'bool',
            documentation =>
              'Enable incremental lock time for brute force attack protection',
        },
        bruteForceProtectionLockTimes => {
            type          => 'text',
            default       => '15, 30, 60, 300, 600',
            documentation =>
              'Incremental lock time values for brute force attack protection',
        },
        grantSessionRules => {
            type          => 'grantContainer',
            keyTest       => sub { return perlExpr(@_) },
            test          => sub { 1 },
            documentation => 'Rules to grant sessions',
            default       => {},
        },
        hiddenAttributes => {
            type          => 'text',
            default       => '_password _2fDevices',
            documentation => 'Name of attributes to hide in logs',
        },
        displaySessionId => {
            type          => 'bool',
            default       => 1,
            documentation => 'Display _session_id with sessions explorer',
        },
        persistentSessionAttributes => {
            type    => 'text',
            default => '_loginHistory _2fDevices _oidcConsents notification_',
            documentation => 'Persistent session attributes to hide',
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
            type          => 'text',
            default       => 'true',
            documentation =>
              'Allow credentials for Cross-Origin Resource Sharing',
        },
        corsAllow_Headers => {
            type          => 'text',
            default       => '*',
            documentation =>
              'Allowed headers for Cross-Origin Resource Sharing',
        },
        corsAllow_Methods => {
            type          => 'text',
            default       => 'POST,GET',
            documentation =>
              'Allowed methods for Cross-Origin Resource Sharing',
        },
        corsAllow_Origin => {
            type          => 'text',
            default       => '*',
            documentation =>
              'Allowed origine for Cross-Origin Resource Sharing',
        },
        corsExpose_Headers => {
            type          => 'text',
            default       => '*',
            documentation =>
              'Exposed headers for Cross-Origin Resource Sharing',
        },
        corsMax_Age => {
            type          => 'text',
            default       => '86400',    # 24 hours
            documentation => 'Max-age for Cross-Origin Resource Sharing',
        },
        strictTransportSecurityMax_Age => {
            type          => 'text',
            documentation => 'Max-age for Strict-Transport-Security',
        },
        cspDefault => {
            type          => 'text',
            default       => "'self'",
            documentation => 'Default value for Content-Security-Policy',
        },
        cspFormAction => {
            type          => 'text',
            default       => "*",
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
            type          => 'text',
            default       => "'self'",
            documentation =>
              'Authorized Ajax destination for Content-Security-Policy',
        },
        cspFont => {
            type          => 'text',
            default       => "'self'",
            documentation => 'Font source for Content-Security-Policy',
        },
        cspFrameAncestors => {
            type          => 'text',
            default       => '',
            documentation => 'Frame-Ancestors for Content-Security-Policy',
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
        trustedBrowserUseTotp => {
            type          => 'bool',
            default       => 1,
            documentation => 'Use TOTP for trusted browser registration',
        },
        trustedBrowserRule => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Trusted browser registration rule',
        },
        trustedDomains =>
          { type => 'text', documentation => 'Trusted domains', },
        storePassword => {
            default       => 0,
            type          => 'bool',
            documentation => 'Store password in session',
        },
        storePasswordEncrypted => {
            default       => 0,
            type          => 'bool',
            documentation => 'Crypt the password in session',
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
        browsersDontStorePassword => {
            default       => 0,
            type          => 'bool',
            documentation => 'Avoid browsers to store users password',
        },
        useRedirectAjaxOnUnauthorized => {
            type          => 'bool',
            default       => 1,
            documentation =>
              'Redirect Ajax requests to portal for unauthorized (401)',
            flags => 'h',
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
        avoidAssignment => {
            default       => 0,
            type          => 'bool',
            help          => 'safejail.html',
            documentation => 'Avoid assignment in expressions',
            flags         => 'hp',
        },
        whatToTrace => {
            type          => 'lmAttrOrMacro',
            default       => 'uid',
            documentation => 'Session parameter used to fill REMOTE_USER',
            flags         => 'hp',
        },
        customToTrace => {
            type          => 'lmAttrOrMacro',
            documentation => 'Session parameter used to fill REMOTE_CUSTOM',
            flags         => 'hp',
        },
        lwpOpts => {
            type          => 'keyTextContainer',
            documentation => 'Options passed to LWP::UserAgent',
            default       => { timeout => 10 },
        },
        lwpSslOpts => {
            type          => 'keyTextContainer',
            documentation => 'TLS/SSL options passed to LWP::UserAgent',
        },

        # CrowdSec plugin
        crowdsec => {
            type          => 'bool',
            documentation => 'CrowdSec plugin activation',
        },
        crowdsecAction => {
            type   => 'select',
            select => [
                { k => 'reject', v => 'Reject' },
                { k => 'warn',   v => 'Warn' },
            ],
            default       => 'reject',
            documentation => 'CrowdSec action',
        },
        crowdsecUrl => {
            type          => 'url',
            documentation => 'Base URL of CrowdSec local API',
        },
        crowdsecKey => {
            type          => 'text',
            documentation => 'CrowdSec API key',
        },
        crowdsecIgnoreFailures => {
            type          => 'bool',
            documentation => 'Ignore Crowdsec errors',
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
            type          => 'boolOrExpr',
            default       => 1,
            documentation => 'Display logout tab in portal',
        },
        portalDisplayCertificateResetByMail => {
            type          => 'bool',
            default       => 0,
            documentation =>
              'Display certificate reset by mail button in portal',
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
        portalDisplayOidcConsents => {
            type          => 'boolOrExpr',
            default       => '$_oidcConsents && $_oidcConsents =~ /\w+/',
            documentation => 'Display OIDC consents tab in portal',
        },
        portalDisplayOrder => {
            type    => 'text',
            default =>
              'Appslist ChangePassword LoginHistory OidcConsents Logout',
            documentation => 'List for ordering tabs in portal',
        },
        portalDisplayGeneratePassword => {
            default       => 1,
            type          => 'bool',
            documentation =>
              'Display password generate box in reset password form',
        },
        portalDisplayRefreshMyRights => {
            default       => 1,
            type          => 'bool',
            documentation => 'Display link to refresh the user session',
        },
        portalEnablePasswordDisplay => {
            default       => 0,
            type          => 'bool',
            documentation => 'Allow to display password in login form',
        },
        passwordResetAllowedRetries => {
            default       => 3,
            type          => 'int',
            documentation => 'Maximum number of retries to reset password',
        },

        # Cookies
        cookieExpiration => {
            type          => 'intOrNull',
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
            type => 'text',
            test =>
              qr/^(?:(?:$Regexp::Common::URI::RFC2396::hostname|#\w+#))?$/,
            msgFail       => '__badDomainName__',
            default       => 'example.com',
            documentation => 'DNS domain',
            flags         => 'hp',
        },
        pdataDomain => {
            type          => 'text',
            test          => qr/^(?:$Regexp::Common::URI::RFC2396::hostname)?$/,
            msgFail       => '__badDomainName__',
            default       => '',
            documentation => 'pdata cookie DNS domain',
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
        hashedSessionStore => {
            type          => 'bool',
            default       => 0,
            documentation => 'Securize storage of sensible sessions',
        },
        sameSite => {
            type   => 'select',
            select => [
                { k => '',       v => '' },
                { k => 'Strict', v => 'Strict' },
                { k => 'Lax',    v => 'Lax' },
                { k => 'None',   v => 'None' },
            ],
            default       => '',
            documentation => 'Cookie SameSite value',
            flags         => 'hp',
        },

        # Viewer
        viewerHiddenKeys => {
            type          => 'text',
            default       => 'samlIDPMetaDataNodes, samlSPMetaDataNodes',
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
        publicNotifications => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable PublicNotification plugin',
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
        notificationsExplorer => {
            default       => 0,
            type          => 'bool',
            documentation => 'Notifications explorer activation',
        },
        notificationsMaxRetrieve => {
            default       => 3,
            type          => 'int',
            documentation => 'Max number of displayed notifications',
        },
        notificationServer => {
            default       => 0,
            type          => 'bool',
            documentation => 'Notification server activation',
        },
        notificationDefaultCond => {
            type          => 'text',
            default       => '',
            documentation => 'Notification default condition',
        },
        notificationServerGET => {
            default       => 0,
            type          => 'bool',
            documentation => 'Notification server activation',
        },
        notificationServerPOST => {
            default       => 1,
            type          => 'bool',
            documentation => 'Notification server activation',
        },
        notificationServerDELETE => {
            default       => 0,
            type          => 'bool',
            documentation => 'Notification server activation',
        },
        notificationServerSentAttributes => {
            type          => 'text',
            default       => 'uid reference date title subtitle text check',
            documentation =>
              'Prameters to send with notification server GET method',
            flags => 'p',
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
            type          => 'boolOrExpr',
            documentation => 'Captcha on login page',
        },
        captcha_mail_enabled => {
            default       => 1,
            type          => 'boolOrExpr',
            documentation => 'Captcha on password reset page',
        },
        captcha_register_enabled => {
            default       => 1,
            type          => 'boolOrExpr',
            documentation => 'Captcha on account creation page',
        },
        captcha_size => {
            type          => 'int',
            default       => 6,
            documentation => 'Captcha size',
        },
        captcha => {
            type          => 'PerlModule',
            documentation => 'Captcha backend module',
            flags         => 'hp',
        },
        captchaOptions => {
            type          => 'keyTextContainer',
            documentation => 'Captcha module options',
            flags         => 'hp',
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
              'exportedvars.html#extend-variables-using-macros-and-groups',
            test          => sub { return perlExpr(@_) },
            default       => {},
            documentation => 'Groups',
        },
        macros => {
            type => 'keyTextContainer',
            help =>
              'exportedvars.html#extend-variables-using-macros-and-groups',
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
                'Directory'      => '/var/lib/lemonldap-ng/sessions/',
                'LockDirectory'  => '/var/lib/lemonldap-ng/sessions/lock/',
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
                'cache_root'         => '/var/cache/lemonldap-ng',
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
            keyTest       => qr/^(\d+_)?[_a-zA-Z][a-zA-Z0-9_]*$/,
            keyMsgFail    => '__invalidSessionData__',
            documentation => 'Data to remember in login history',
        },
        disablePersistentStorage => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enabled persistent storage',
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

        # Message broker
        messageBroker => {
            type          => 'select',
            documentation => 'Messages broker module',
            select        => [
                { k => '',        v => '' },
                { k => '::Redis', v => 'Redis' },
                { k => '::Pg',    v => 'PostgreSQL' },
                { k => '::MQTT',  v => 'MQTT' },
            ],
            flags => 'hp',
        },
        messageBrokerOptions => {
            type          => 'keyTextContainer',
            default       => {},
            documentation => 'Options of messages broker module',
            flags         => 'hp',
        },
        eventQueueName => {
            type          => 'text',
            default       => 'llng_events',
            documentation => 'Event channel name',
        },

        # Jitsi Meet tokens issuer
        issuerDBJitsiMeetTokensActivation => {
            type          => 'bool',
            default       => 0,
            documentation => 'Jitsi issuer activation',
        },
        issuerDBJitsiMeetTokensPath => {
            type          => 'text',
            default       => '^/jitsi/',
            documentation => 'Jitsi issuer request path',
        },
        issuerDBJitsiMeetTokensRule => {
            type          => 'boolOrExpr',
            default       => 1,
            documentation => 'Jitsi issuer rule',
        },

        jitsiDefaultServer => {
            type          => 'url',
            documentation => 'Jitsi server URL',
        },
        jitsiAppId => {
            type          => 'text',
            documentation => 'Jitsi application ID',
        },
        jitsiAppSecret => {
            type          => 'text',
            documentation => 'Jitsi application secret',
        },
        jitsiSigningAlg => {
            type          => 'select',
            select        => oidcSigAlgorithmAlg,
            default       => 'RS256',
            documentation => 'Jitsi JWT signature method',
        },
        jitsiExpiration => {
            type          => 'int',
            default       => '300',
            documentation => 'Jitsi JWT expiration',
        },
        jitsiIdAttribute => {
            type          => 'text',
            documentation => 'Jitsi attribute for ID',
        },
        jitsiNameAttribute => {
            type          => 'text',
            documentation => 'Jitsi attribute for name',
        },
        jitsiMailAttribute => {
            type          => 'text',
            documentation => 'Jitsi attribute for email',
        },

        # Password
        mailOnPasswordChange => {
            default       => 0,
            type          => 'bool',
            documentation => 'Send a mail when password is changed',
        },
        portalRequireOldPassword => {
            default       => 1,
            type          => 'boolOrExpr',
            documentation =>
              'Rule to require old password to change the password',
        },
        hideOldPassword => {
            default       => 1,
            type          => 'bool',
            documentation => 'Hide old password in portal',
        },
        passwordPolicyActivation => {
            type          => 'boolOrExpr',
            default       => 1,
            documentation => 'Enable password policy',
        },
        passwordPolicyMinSize => {
            default       => 0,
            type          => 'int',
            documentation => 'Password policy: minimal size',
        },
        passwordPolicyMaxSize => {
            default       => 0,
            type          => 'int',
            documentation => 'Password policy: maximal size',
        },
        passwordPolicyMinLower => {
            default       => 0,
            type          => 'int',
            documentation => 'Password policy: minimal lower characters',
        },
        passwordPolicyMinUpper => {
            default       => 0,
            type          => 'int',
            documentation => 'Password policy: minimal upper characters',
        },
        passwordPolicyMinDigit => {
            default       => 0,
            type          => 'int',
            documentation => 'Password policy: minimal digit characters',
        },
        passwordPolicyMinSpeChar => {
            default       => 0,
            type          => 'int',
            documentation => 'Password policy: minimal special characters',
        },
        passwordPolicySpecialChar => {
            default       => '__ALL__',
            type          => 'text',
            test          => qr/^(?:__ALL__|[\S\W]*)$/,
            documentation => 'Password policy: allowed special characters',
        },
        portalDisplayPasswordPolicy => {
            default       => 0,
            type          => 'bool',
            documentation => 'Display policy in password form',
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
            documentation => 'URL of password reset page',
        },

        # Certificate reset by mail
        certificateResetByMailCeaAttribute => {
            type    => 'text',
            default => 'description'
        },
        certificateResetByMailCertificateAttribute => {
            type    => 'text',
            default => 'userCertificate;binary',
        },
        certificateResetByMailStep1Subject => {
            type          => 'text',
            documentation => 'Mail subject for certificate reset email',
        },
        certificateResetByMailStep1Body => {
            type          => 'longtext',
            documentation => 'Custom Certificate reset mail body',
        },
        certificateResetByMailStep2Subject => {
            type          => 'text',
            documentation => 'Mail subject for reset confirmation',
        },
        certificateResetByMailStep2Body => {
            type          => 'longtext',
            documentation => 'Custom confirm Certificate reset mail body',
        },
        certificateResetByMailURL => {
            type          => 'url',
            documentation => 'URL of certificate reset page',
        },
        certificateResetByMailValidityDelay => {
            type    => 'int',
            default => 0
        },

        # Registration
        registerConfirmSubject => {
            type          => 'text',
            documentation => 'Mail subject for register confirmation',
        },
        registerConfirmBody => {
            type          => 'longtext',
            documentation => 'Mail body for register confirmation',
        },
        registerDoneSubject => {
            type          => 'text',
            documentation => 'Mail subject when register is done',
        },
        registerDoneBody => {
            type          => 'longtext',
            documentation => 'Mail body when register is done',
        },
        registerTimeout => {
            default       => 0,
            type          => 'int',
            documentation => 'Register session timeout',
        },
        registerUrl => {
            type          => 'url',
            documentation => 'URL of register page',
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

        # Upgrade session
        upgradeSession => {
            type          => 'bool',
            default       => 1,
            documentation => 'Upgrade session activation',
        },
        forceGlobalStorageUpgradeOTT => {
            type          => 'bool',
            documentation =>
              'Force Upgrade tokens be stored into Global Storage',
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

        # Okta 2FA
        okta2fActivation => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Okta2F activation',
        },
        okta2fAdminURL => {
            type          => 'url',
            documentation => 'Okta Administration URL'
        },
        okta2fApiKey => {
            type          => 'text',
            documentation => 'Okta API key'
        },
        okta2fAuthnLevel => {
            type          => 'intOrNull',
            documentation =>
              'Authentication level for users authentified by Okta2F'
        },
        okta2fLabel => {
            type          => 'text',
            documentation => 'Portal label for Okta2F'
        },
        okta2fLoginAttribute => {
            type          => 'text',
            documentation => 'Session key containing Okta login'
        },
        okta2fLogo => {
            type          => 'text',
            documentation => 'Custom logo for Okta 2F',
        },

        # Password 2FA
        password2fActivation => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Password2F activation',
        },
        password2fSelfRegistration => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Password2F self registration activation',
        },
        password2fAuthnLevel => {
            type          => 'intOrNull',
            documentation =>
              'Authentication level for users authentified by Password2F'
        },
        password2fLabel => {
            type          => 'text',
            documentation => 'Portal label for Password2F'
        },
        password2fLogo => {
            type          => 'text',
            documentation => 'Custom logo for Password 2F',
        },
        password2fUserCanRemoveKey => {
            type          => 'bool',
            default       => 1,
            documentation =>
              'Authorize users to remove existing Password2F secret',
        },
        password2fTTL => {
            type          => 'intOrNull',
            documentation => 'Password2F device time to live ',
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
            type          => 'intOrNull',
            documentation =>
              'Authentication level for users authentified by password+TOTP'
        },
        totp2fLabel => {
            type          => 'text',
            documentation => 'Portal label for TOTP 2F'
        },
        totp2fLogo => {
            type          => 'text',
            documentation => 'Custom logo for TOTP 2F',
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
        totp2fUserCanRemoveKey => {
            type          => 'bool',
            default       => 1,
            documentation => 'Authorize users to remove existing TOTP secret',
        },
        totp2fTTL => {
            type          => 'intOrNull',
            documentation => 'TOTP device time to live ',
        },
        totp2fEncryptSecret => {
            type          => 'bool',
            default       => 0,
            documentation => 'Encrypt TOTP secrets in database',
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
            type          => 'intOrNull',
            documentation => 'Second factor code timeout',
        },
        mail2fResendInterval => {
            type          => 'text',
            documentation => 'Delay before user is allowed to resend code',
        },
        mail2fAuthnLevel => {
            type          => 'intOrNull',
            documentation =>
'Authentication level for users authenticated by Mail second factor'
        },
        mail2fLabel => {
            type          => 'text',
            documentation => 'Portal label for Mail second factor'
        },
        mail2fLogo => {
            type          => 'text',
            documentation => 'Custom logo for Mail 2F',
        },
        mail2fSessionKey => {
            type          => 'text',
            documentation => 'Session parameter where mail is stored',
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
        ext2fResendInterval => {
            type          => 'text',
            documentation => 'Delay before user is allowed to resend code',
        },
        ext2fAuthnLevel => {
            type          => 'intOrNull',
            documentation =>
'Authentication level for users authentified by External second factor'
        },
        ext2fLabel => {
            type          => 'text',
            documentation => 'Portal label for External second factor'
        },
        ext2fLogo => {
            type          => 'text',
            documentation => 'Custom logo for External 2F',
        },

        # Radius second factor
        radius2fActivation => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'Radius second factor activation',
        },
        radius2fSecret             => { type => 'text', },
        radius2fServer             => { type => 'text', },
        radius2fUsernameSessionKey => {
            type          => 'text',
            documentation => 'Session key used as Radius login'
        },
        radius2fTimeout => {
            type          => 'int',
            default       => 20,
            documentation => 'Radius 2f verification timeout',
        },
        radius2fMsgAuth => {
            type          => 'bool',
            documentation => 'Use Message-Authentication for Radius requests',
        },
        radius2fSendInitialRequest => {
            type          => 'bool',
            default       => 0,
            documentation => 'Dial in to radius server before displaying form',
        },
        radius2fAuthnLevel => {
            type          => 'intOrNull',
            documentation =>
'Authentication level for users authenticated by Radius second factor'
        },
        radius2fLogo => {
            type          => 'text',
            documentation => 'Custom logo for Radius 2F',
        },
        radius2fLabel => {
            type          => 'text',
            documentation => 'Portal label for Radius 2F'
        },

        #  REST External second factor
        rest2fActivation => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'REST second factor activation',
        },
        rest2fCodeActivation => {
            type          => 'pcre',
            documentation => 'OTP generated by Portal',
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
        rest2fResendInterval => {
            type          => 'text',
            documentation => 'Delay before user is allowed to resend code',
        },
        rest2fAuthnLevel => {
            type          => 'intOrNull',
            documentation =>
'Authentication level for users authentified by REST second factor'
        },
        rest2fLabel => {
            type          => 'text',
            documentation => 'Portal label for REST second factor'
        },
        rest2fLogo => {
            type          => 'text',
            documentation => 'Custom logo for REST 2F',
        },
        radius2fDictionaryFile    => { type => 'text' },
        radius2fRequestAttributes => {
            type => 'keyTextContainer',

            keyTest    => qr/^[a-zA-Z0-9_-]*$/,
            keyMsgFail => '__badKeyName__',

            default       => {},
            documentation => 'RADIUS second factor authentication attributes',
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
            type          => 'intOrNull',
            documentation =>
'Authentication level for users authentified by Yubikey second factor'
        },
        yubikey2fLabel => {
            type          => 'text',
            documentation => 'Portal label for Yubikey second factor'
        },
        yubikey2fLogo => {
            type          => 'text',
            documentation => 'Custom logo for Yubikey 2F',
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
            type          => 'url',
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
        yubikey2fFromSessionAttribute => {
            type          => 'text',
            documentation =>
              'Provision yubikey from the given session variable',
        },
        yubikey2fTTL => {
            type          => 'intOrNull',
            documentation => 'Yubikey device time to live',
        },

        # WebAuthn 2FA
        webauthn2fActivation => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'WebAuthn second factor activation',
        },
        webauthn2fSelfRegistration => {
            type          => 'boolOrExpr',
            default       => 0,
            documentation => 'WebAuthn self registration activation',
        },
        webauthn2fAuthnLevel => {
            type          => 'intOrNull',
            documentation =>
'Authentication level for users authentified by WebAuthn second factor'
        },
        webauthn2fLabel => {
            type          => 'text',
            documentation => 'Portal label for WebAuthn second factor'
        },
        webauthn2fLogo => {
            type          => 'text',
            documentation => 'Custom logo for WebAuthn 2F',
        },
        webauthn2fUserVerification => {
            type   => 'select',
            select => [
                { k => 'discouraged', v => 'Discouraged' },
                { k => 'preferred',   v => 'Preferred' },
                { k => 'required',    v => 'Required' },
            ],
            default       => 'preferred',
            documentation => 'Verify user during registration and login',
        },
        webauthn2fAttestation => {
            type   => 'select',
            select => [
                { k => 'none',       v => 'None' },
                { k => 'direct',     v => 'Direct' },
                { k => 'indirect',   v => 'Indirect' },
                { k => 'enterprise', v => 'Enterprise' },
            ],
            default       => 'none',
            documentation => 'Ask the authenticator for an attestation',
        },
        webauthn2fAttestationTrust => {
            type          => 'file',
            documentation =>
              'Certificate bundle for attestation trust validation',
        },
        webauthn2fResidentKey => {
            type   => 'select',
            select => [
                { k => '',            v => '' },
                { k => 'discouraged', v => 'Discouraged' },
                { k => 'preferred',   v => 'Preferred' },
                { k => 'required',    v => 'Required' },
            ],
            documentation => 'Use discoverable credential',
        },
        webauthn2fUserCanRemoveKey => {
            type          => 'bool',
            default       => 1,
            documentation => 'Authorize users to remove existing WebAuthn',
        },
        webauthnDisplayNameAttr => {
            type          => 'text',
            documentation => 'Session attribute containing user display name',
        },
        webauthnRpId => {
            type          => 'text',
            documentation => 'WebAuthn Relying Party ID',
        },
        webauthnAppId => {
            type          => 'bool',
            default       => 1,
            documentation => 'Send AppID extension',
        },
        webauthnRpName => {
            type          => 'text',
            documentation => 'WebAuthn Relying Party display name',
        },
        webauthnDefaultTransports => {
            type          => 'text',
            documentation => 'WebAuthn default transports',
        },
        webauthnAuthnLevel => {
            type          => 'int',
            default       => 3,
            documentation => 'WebAuthn authentication level',
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
            type          => 'boolOrExpr',
            documentation => 'Allow only one session per user',
        },
        singleIP => {
            default       => 0,
            type          => 'boolOrExpr',
            documentation => 'Allow only one session per IP',
        },
        singleUserByIP => {
            default       => 0,
            type          => 'boolOrExpr',
            documentation => 'Allow only one user per IP',
        },

        # REST server
        restSessionServer => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable REST session server',
        },
        restAuthServer => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable REST authentication server',
        },
        restPasswordServer => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable REST password reset server',
        },
        restExportSecretKeys => {
            default       => 0,
            type          => 'bool',
            documentation =>
              'Allow to export secret keys in REST session server',
        },
        restClockTolerance => {
            default       => 15,
            type          => 'int',
            documentation =>
              'How tolerant the REST session server will be to clock dift',
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
            type          => 'text',
            documentation =>
              'List of attributes to export by SOAP or REST servers',
        },
        wsdlServer => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable /portal.wsdl server',
        },

        # SOAP Procy client
        soapProxyUrn => {
            default       => 'urn:Lemonldap/NG/Common/PSGI/SOAPService',
            type          => 'text',
            documentation => 'SOAP URN for Proxy',
        },

        # AutoSignin
        autoSigninRules => {
            type          => 'keyTextContainer',
            keyTest       => sub { return perlExpr(@_) },
            test          => sub { 1 },
            help          => 'autosignin.html',
            documentation => 'List of auto signin rules',
        },

        # Adaptative Authentication Level
        adaptativeAuthenticationLevelRules => {
            type          => 'keyTextContainer',
            keyTest       => sub { return perlExpr(@_) },
            test          => sub { 1 },
            help          => "adaptativeauthenticationlevel.html",
            documentation => 'Adaptative authentication level rules',
        },

        # LocationDetect plugin
        locationDetect => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable LocationDetect plugin',
        },
        locationDetectGeoIpDatabase => {
            type          => 'text',
            documentation => 'Path to GeoIP database',
        },
        locationDetectGeoIpLanguages => {
            default       => 'en, fr',
            type          => 'text',
            documentation => 'Languages for GeoIP database',
        },
        locationDetectIpDetail => {
            type          => 'text',
            documentation => 'Information requested for IP',
        },
        locationDetectUaDetail => {
            type          => 'text',
            documentation => 'Information requested for User Agent',
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
            keyTest       => qr/^\S+$/,
            keyMsgFail    => '__badHostname__',
            default       => { default => 'deny', },
            documentation => 'Virtualhost rules',
            flags         => 'h',
        },
        exportedHeaders => {
            type       => 'keyTextContainer',
            help       => 'writingrulesand_headers.html#headers',
            keyTest    => qr/^\S+$/,
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
            type          => 'postContainer',
            help          => 'formreplay.html',
            test          => sub { 1 },
            keyTest       => qr/^\S+$/,
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
        vhostComment => {
            type    => 'longtext',
            default => '',
        },
        vhostAccessToTrace => { type => 'text', default => '' },
        vhostAliases       => { type => 'text', default => '' },
        vhostType          => {
            type   => 'select',
            select => [
                { k => 'AuthBasic',     v => 'AuthBasic' },
                { k => 'CDA',           v => 'CDA' },
                { k => 'DevOps',        v => 'DevOps' },
                { k => 'DevOpsST',      v => 'DevOpsST' },
                { k => 'DevOpsCDA',     v => 'DevOpsCDA' },
                { k => 'Main',          v => 'Main' },
                { k => 'OAuth2',        v => 'OAuth2' },
                { k => 'SecureToken',   v => 'SecureToken' },
                { k => 'ServiceToken',  v => 'ServiceToken' },
                { k => 'ZimbraPreAuth', v => 'ZimbraPreAuth' },
            ],
            default       => 'Main',
            documentation => 'Handler type',
        },
        vhostAuthnLevel     => { type => 'intOrNull' },
        vhostDevOpsRulesUrl => { type => 'url' },

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
        casStrictMatching => {
            default       => 0,
            type          => 'bool',
            documentation => 'Disable host-based matching of CAS services',
        },
        casTicketExpiration => {
            default       => 0,
            type          => 'int',
            documentation => 'Expiration time of Service and Proxy tickets',
        },
        casBackChannelSingleLogout => {
            default       => 0,
            type          => 'bool',
            documentation => 'Enable CAS (Back-Channel) Single Logout',
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
        casAppMetaDataOptionsAuthnLevel => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            documentation =>
              'Authentication level requires to access to this CAS application',
        },
        casAppMetaDataOptionsComment => {
            type          => 'longtext',
            documentation => 'Comment for this CAS application',
        },
        casAppMetaDataOptionsDisplayName => {
            type => 'text',
        },
        casAppMetaDataOptionsLogout => {
            type    => 'trool',
            default => -1,
        },
        casAppMetaDataOptionsRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            documentation => 'CAS application rule',
        },
        casAppMetaDataOptionsService => {
            type          => 'text',
            documentation => 'CAS application service',
        },
        casSrvMetaDataOptionsSamlValidate => {
            type          => 'bool',
            documentation => 'use SAML validateion',
        },
        casAppMetaDataOptionsUserAttribute => {
            type          => 'text',
            documentation => 'CAS User attribute',
        },
        casAppMetaDataOptionsAllowProxy => {
            type          => 'bool',
            documentation => 'Allow CAS proxy',
            default       => 1,
        },
        casAppMetaDataMacros => {
            type => 'keyTextContainer',
            help =>
              'exportedvars.html#extend-variables-using-macros-and-groups',
            test => {
                keyTest    => qr/^[_a-zA-Z][a-zA-Z0-9_]*$/,
                keyMsgFail => '__badMacroName__',
                test       => sub { return perlExpr(@_) },
            },
            default       => {},
            documentation => 'Macros',
        },

        # Fake attribute: used by manager REST API to agglomerate all nodes
        # related to a CAS SP partner
        casAppMetaDataNodes => {
            type     => 'casAppMetaDataNodeContainer',
            template => 'casAppMetaDataNode',
            help     => 'idpcas.html#configuring-cas-applications',
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
                { k => 'RSA_SHA384', v => 'RSA SHA384' },
                { k => 'RSA_SHA512', v => 'RSA SHA512' },
            ],
            default => 'RSA_SHA256',
        },
        samlServiceUseCertificateInResponse => {
            type          => 'bool',
            default       => 0,
            documentation =>
              'Use certificate instead of public key in SAML responses',
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
        samlAuthnContextMapExtra => {
            type          => 'keyTextContainer',
            keyTest       => qr/\w/,
            documentation => 'SAML extra authn contexts',
        },
        samlAuthnContextMapPassword => {
            type          => 'int',
            default       => 2,
            documentation => 'SAML authn context password level',
        },
        samlAuthnContextMapPasswordProtectedTransport => {
            type          => 'int',
            default       => 3,
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
        samlFederationFiles => {
            type          => 'text',
            documentation => 'Path to SAML Federation Metadata',
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
            help       => 'authsaml.html#exported-attributes',
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
        samlIDPMetaDataOptionsFederationEntityID => {
            type => 'text',
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
        samlIDPMetaDataOptionsCheckSSOMessageSignature => {
            type    => 'bool',
            default => 1,
        },
        samlIDPMetaDataOptionsComment => {
            type => 'longtext'
        },
        samlIDPMetaDataOptionsForceUTF8 => {
            type    => 'bool',
            default => 0,
        },
        samlIDPMetaDataOptionsSignSSOMessage => {
            type    => 'trool',
            default => -1,
        },
        samlIDPMetaDataOptionsSignSLOMessage => {
            type    => 'trool',
            default => -1,
        },
        samlIDPMetaDataOptionsSignatureMethod => {
            type   => 'select',
            select => [
                { k => '',           v => 'default' },
                { k => 'RSA_SHA1',   v => 'RSA SHA1' },
                { k => 'RSA_SHA256', v => 'RSA SHA256' },
                { k => 'RSA_SHA384', v => 'RSA SHA384' },
                { k => 'RSA_SHA512', v => 'RSA SHA512' },
            ],
            default => '',
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
        samlIDPMetaDataOptionsTooltip       => { type => 'text', },
        samlIDPMetaDataOptionsSortNumber    => { type => 'intOrNull', },

        # SP keys
        samlSPMetaDataExportedAttributes => {
            type       => 'samlAttributeContainer',
            help       => 'idpsaml.html#exported-attributes',
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
        samlSPMetaDataOptionsFederationEntityID => {
            type => 'text',
        },
        samlSPMetaDataOptionsFederationOptionalAttributes => {
            type   => 'select',
            select =>
              [ { k => '', v => 'keep' }, { k => 'ignore', v => 'ignore' }, ],
            default => '',
        },
        samlSPMetaDataOptionsFederationRequiredAttributes => {
            type   => 'select',
            select => [
                { k => '',         v => 'keep' },
                { k => 'optional', v => 'makeoptional' },
                { k => 'ignore',   v => 'ignore' },
            ],
            default => '',
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
            type    => 'samlAssertion',
            default =>
              '0;1;urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact;'
              . '#PORTAL#/saml/proxySingleSignOnArtifact',
            documentation => 'SAML SP ACS HTTP artifact',
        },
        samlSPSSODescriptorAssertionConsumerServiceHTTPPost => {
            type    => 'samlAssertion',
            default => '1;0;urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST;'
              . '#PORTAL#/saml/proxySingleSignOnPost',
            documentation => 'SAML SP ACS HTTP POST',
        },
        samlSPSSODescriptorArtifactResolutionServiceArtifact => {
            type    => 'samlAssertion',
            default => '1;0;urn:oasis:names:tc:SAML:2.0:bindings:SOAP;'
              . '#PORTAL#/saml/artifact',
            documentation => 'SAML SP artifact resolution service ',
        },
        samlSPMetaDataOptionsComment => {
            type => 'longtext'
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
        samlSPMetaDataOptionsNameIDSessionKey    => { type => 'text' },
        samlSPMetaDataOptionsNotOnOrAfterTimeout => {
            type    => 'int',
            default => 72000,
        },
        samlSPMetaDataOptionsOneTimeUse => {
            type    => 'bool',
            default => 0,
        },
        samlSPMetaDataOptionsSessionNotOnOrAfterTimeout => {
            type    => 'int',
            default => 72000,
        },
        samlSPMetaDataOptionsSignSSOMessage => {
            type    => 'trool',
            default => -1,
        },
        samlSPMetaDataOptionsSignatureMethod => {
            type   => 'select',
            select => [
                { k => '',           v => 'default' },
                { k => 'RSA_SHA1',   v => 'RSA SHA1' },
                { k => 'RSA_SHA256', v => 'RSA SHA256' },
                { k => 'RSA_SHA384', v => 'RSA SHA384' },
                { k => 'RSA_SHA512', v => 'RSA SHA512' },
            ],
            default => '',
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
        samlSPMetaDataOptionsAuthnLevel => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            documentation =>
              'Authentication level requires to access to this SP',
        },
        samlSPMetaDataOptionsRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            documentation => 'Rule to grant access to this SP',
        },
        samlSPMetaDataMacros => {
            type => 'keyTextContainer',
            help =>
              'exportedvars.html#extend-variables-using-macros-and-groups',
            test => {
                keyTest    => qr/^[_a-zA-Z][a-zA-Z0-9_]*$/,
                keyMsgFail => '__badMacroName__',
                test       => sub { return perlExpr(@_) },
            },
            default       => {},
            documentation => 'Macros',
        },

        # AUTH, USERDB and PASSWORD MODULES
        authentication => {
            type   => 'select',
            select => [
                { k => 'Apache',      v => 'Apache' },
                { k => 'AD',          v => 'Active Directory' },
                { k => 'DBI',         v => 'Database (DBI)' },
                { k => 'Facebook',    v => 'Facebook' },
                { k => 'GitHub',      v => 'GitHub' },
                { k => 'GPG',         v => 'GPG' },
                { k => 'Kerberos',    v => 'Kerberos' },
                { k => 'LDAP',        v => 'LDAP' },
                { k => 'LinkedIn',    v => 'LinkedIn' },
                { k => 'PAM',         v => 'PAM' },
                { k => 'Radius',      v => 'Radius' },
                { k => 'REST',        v => 'REST' },
                { k => 'SSL',         v => 'mTLS' },
                { k => 'Twitter',     v => 'Twitter' },
                { k => 'WebID',       v => 'WebID (deprecated)' },
                { k => 'WebAuthn',    v => 'WebAuthn' },
                { k => 'Demo',        v => 'Demonstration' },
                { k => 'Choice',      v => 'authChoice' },
                { k => 'Combination', v => 'combineMods' },
                { k => 'CAS',    v => 'Central Authentication Service (CAS)' },
                { k => 'OpenID', v => 'OpenID 2.0 (deprecated)' },
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
                { k => 'AD',          v => 'Active Directory' },
                { k => 'Choice',      v => 'authChoice' },
                { k => 'DBI',         v => 'Database (DBI)' },
                { k => 'Demo',        v => 'Demonstration' },
                { k => 'LDAP',        v => 'LDAP' },
                { k => 'REST',        v => 'REST' },
                { k => 'Null',        v => 'None' },
                { k => 'Combination', v => 'combineMods' },
                { k => 'Custom',      v => 'customModule' },
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
        sfRetries => {
            type          => 'intOrNull',
            documentation => 'Allowed number of retries',
        },
        sfRequired => {
            type          => 'boolOrExpr',
            default       => 0,
            help          => 'secondfactor.html',
            documentation => 'Second factor required',
        },
        sfOnlyUpgrade => {
            type          => 'bool',
            default       => 0,
            help          => 'secondfactor.html',
            documentation => 'Only trigger second factor on session upgrade',
        },
        sfManagerRule => {
            type          => 'boolOrExpr',
            default       => 1,
            help          => 'secondfactor.html',
            documentation => 'Rule to display second factor Manager link',
        },
        sfRemovedMsgRule => {
            type          => 'boolOrExpr',
            default       => 0,
            help          => 'secondfactor.html',
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
            type    => 'text',
            default =>
'_removedSF_ expired second factor(s) has/have been removed (_nameSF_)!',
            help          => 'secondfactor.html',
            documentation => 'Notification message',
        },
        sfLoginTimeout => {
            type          => 'intOrNull',
            documentation => 'Timeout for 2F login process',
        },
        sfRegisterTimeout => {
            type          => 'intOrNull',
            documentation => 'Timeout for 2F registration process',
        },
        available2F => {
            type    => 'text',
            default => join( ',',
                qw/TOTP REST Mail2F Ext2F WebAuthn Yubikey Radius Password Okta/
            ),
            documentation => 'Available second factor modules',
        },
        available2FSelfRegistration => {
            type          => 'text',
            default       => join( ',', qw/Password TOTP WebAuthn Yubikey/ ),
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
            test          => qr/^.*$/,
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
            type          => 'intOrNull',
            documentation => 'LDAP port',
        },
        ldapServer => {
            type => 'text',
            test => sub {
                my $l = shift;
                my (@s) = split( /[\s,]+/, $l );
                foreach my $s (@s) {
                    $s =~
m{^(?:ldapi://[^/]*/?|\w[\w\-\.]*(?::\d{1,5})?|ldap(?:s|\+tls)?://\w[\w\-\.]*(?::\d{1,5})?/?.*)$}
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
        ldapGetUserBeforePasswordChange => {
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
        groupLDAPFilter => {
            type          => 'text',
            documentation => 'LDAP filter for group search'
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
            type          => 'text',
            default       => 'dn',
            documentation =>
'LDAP attribute name in user entry referenced as member in groups',
        },
        ldapGroupAttributeNameSearch => {
            type          => 'text',
            default       => 'cn',
            documentation => 'LDAP attributes to search in groups',
        },
        ldapGroupAttributeNameGroup => {
            type          => 'text',
            default       => 'dn',
            documentation =>
'LDAP attribute name in group entry referenced as member in groups',
        },
        ldapTimeout => {
            type          => 'int',
            default       => 10,
            documentation => 'LDAP connection timeout',
        },
        ldapIOTimeout => {
            type          => 'int',
            default       => 10,
            documentation => 'LDAP operation timeout',
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
        ldapITDS => {
            default       => 0,
            type          => 'bool',
            documentation => 'Support for IBM Tivoli Directory Server',
        },
        ldapVerify => {
            type          => 'bool',
            documentation => 'Whether to validate LDAP certificates',
            type          => "select",
            select        => [
                { k => 'none',     v => 'None' },
                { k => 'optional', v => 'Optional' },
                { k => 'require',  v => 'Require' },
            ],
            default => 'require',
        },
        ldapCAFile => {
            type          => 'text',
            documentation =>
              'Location of the certificate file for LDAP connections',
        },
        ldapCAPath => {
            type          => 'text',
            documentation =>
              'Location of the CA directory for LDAP connections',
        },

        # SSL
        SSLAuthnLevel => {
            type          => 'int',
            default       => 5,
            documentation => 'Mutual TLS authentication level',
        },
        SSLVar => {
            type    => 'text',
            default => 'SSL_CLIENT_S_DN_Email'
        },
        SSLIssuerVar => {
            type    => 'text',
            default => 'SSL_CLIENT_I_DN'
        },
        SSLVarIf => {
            type    => 'keyTextContainer',
            keyTest => sub { 1 },
            default => {}
        },
        sslByAjax => {
            type          => 'bool',
            default       => 0,
            documentation => 'Use Ajax request for Mutual TLS Authentication',
        },
        sslHost => {
            type          => 'url',
            documentation => 'URL for Mutual TLS Authentication Ajax request',
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
        casSrvMetaDataOptionsComment => {
            type          => 'longtext',
            documentation => 'Comment for this CAS server',
        },
        casSrvMetaDataOptionsDisplayName => {
            type          => 'text',
            documentation => 'Name to display for this CAS server',
        },
        casSrvMetaDataOptionsIcon => {
            type          => 'text',
            documentation => 'Path of CAS server icon',
        },
        casSrvMetaDataOptionsSortNumber => {
            type          => 'intOrNull',
            documentation => 'Number to sort buttons',
        },
        casSrvMetaDataOptionsResolutionRule => {
            type    => 'longtext',
            default => '',
        },
        casSrvMetaDataOptionsTooltip => {
            type          => 'text',
            documentation => 'Tooltip for this CAS Server',
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
        radiusSecret  => { type => 'text' },
        radiusServer  => { type => 'text' },
        radiusTimeout => {
            type => 'intOrNull',
        },
        radiusMsgAuth => {
            type          => 'bool',
            documentation => 'Use Message-Authentication for Radius requests',
        },
        radiusExportedVars => {
            type => 'keyTextContainer',

            # session key name
            keyTest    => qr/^!?[a-zA-Z][a-zA-Z0-9_-]*$/,
            keyMsgFail => '__badVariableName__',

            # radius attribue name (from discitonary)
            test          => qr/^[a-zA-Z][a-zA-Z0-9_:\-]*$/,
            msgFail       => '__badValue__',
            default       => {},
            documentation => 'RADIUS exported variables',
        },
        radiusDictionaryFile    => { type => 'text' },
        radiusRequestAttributes => {
            type => 'keyTextContainer',

            keyTest    => qr/^[a-zA-Z0-9_-]*$/,
            keyMsgFail => '__badKeyName__',

            default       => {},
            documentation => 'RADIUS authentication attributes',
        },

        # REST
        restAuthUrl       => { type => 'url' },
        restUserDBUrl     => { type => 'url' },
        restFindUserDBUrl => { type => 'url' },

        restPwdConfirmUrl => { type => 'url' },
        restPwdModifyUrl  => { type => 'url' },

        # Remote
        remoteCookieName => {
            type          => 'text',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_-]*$/,
            msgFail       => '__badCookieName__',
            documentation => 'Name of the remote portal cookie',
            flags         => 'p',
        },
        remotePortal        => { type => 'text' },
        remoteGlobalStorage => {
            type          => 'PerlModule',
            default       => 'Lemonldap::NG::Common::Apache::Session::SOAP',
            documentation => 'Remote session backend',
        },
        remoteGlobalStorageOptions => {
            type    => 'keyTextContainer',
            default => {
                proxy => 'http://auth.example.com/sessions',
                ns    =>
'http://auth.example.com/Lemonldap/NG/Common/PSGI/SOAPService',
            },
            documentation => 'Apache::Session module parameters',
        },

        # Proxy
        proxyAuthService            => { type => 'text' },
        proxySessionService         => { type => 'text' },
        proxyAuthServiceChoiceValue => { type => 'text' },
        proxyAuthServiceChoiceParam => {
            type    => 'text',
            default => 'lmAuth'
        },
        proxyAuthServiceImpersonation => {
            type          => 'bool',
            default       => 0,
            documentation => 'Enable internal portal Impersonation',
        },
        proxyCookieName => {
            type          => 'text',
            test          => qr/^[a-zA-Z][a-zA-Z0-9_-]*$/,
            msgFail       => '__badCookieName__',
            documentation => 'Name of the internal portal cookie',
            flags         => 'p',
        },
        proxyUseSoap => {
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
        linkedInScope     =>
          { type => 'text', default => 'r_liteprofile r_emailaddress' },

        # GitHub
        githubAuthnLevel => {
            type          => 'int',
            default       => 1,
            documentation => 'GitHub authentication level',
        },
        githubClientID     => { type => 'text', },
        githubClientSecret => { type => 'password', },
        githubScope        => { type => 'text', default => 'user:email' },
        githubUserField    => { type => 'text', default => 'login' },

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
        dbiAuthTable    => { type => 'text', },
        dbiUserTable    => { type => 'text', },

        # TODO: add dbiMailCol
        dbiAuthLoginCol     => { type => 'text', },
        dbiAuthPasswordCol  => { type => 'text', },
        dbiPasswordMailCol  => { type => 'text', },
        userPivot           => { type => 'text', },
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
            default       => 3,
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
        krbAllowedDomains => {
            type          => 'text',
            documentation => 'Allowed domains',
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
        slaveDisplayLogo   => {
            type          => 'bool',
            default       => 0,
            documentation => 'Display Slave authentication logo',
        },

        # Choice
        authChoiceParam => {
            type          => 'text',
            default       => 'lmAuth',
            documentation => 'Applications list',
        },
        authChoiceAuthBasic => {
            type          => 'text',
            documentation => 'Auth module used by AuthBasic handler',
        },
        authChoiceFindUser => {
            type          => 'text',
            documentation => 'Auth module used by FindUser plugin',
        },
        authChoiceSelectOnly => {
            type          => 'bool',
            documentation => 'Automatically select only available choice',
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
                    { k => 'GitHub',        v => 'GitHub' },
                    { k => 'GPG',           v => 'GPG' },
                    { k => 'Kerberos',      v => 'Kerberos' },
                    { k => 'LDAP',          v => 'LDAP' },
                    { k => 'LinkedIn',      v => 'LinkedIn' },
                    { k => 'PAM',           v => 'PAM' },
                    { k => 'Null',          v => 'None' },
                    { k => 'OpenID',        v => 'OpenID 2.0 (deprecated)' },
                    { k => 'OpenIDConnect', v => 'OpenID Connect' },
                    { k => 'Proxy',         v => 'Proxy' },
                    { k => 'Radius',        v => 'Radius' },
                    { k => 'REST',          v => 'REST' },
                    { k => 'Remote',        v => 'Remote' },
                    { k => 'SAML',          v => 'SAML v2' },
                    { k => 'Slave',         v => 'Slave' },
                    { k => 'SSL',           v => 'mTLS' },
                    { k => 'Twitter',       v => 'Twitter' },
                    { k => 'WebID',         v => 'WebID (deprecated)' },
                    { k => 'WebAuthn',      v => 'WebAuthn' },
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
                    { k => 'OpenID',        v => 'OpenID 2.0 (deprecated)' },
                    { k => 'OpenIDConnect', v => 'OpenID Connect' },
                    { k => 'Proxy',         v => 'Proxy' },
                    { k => 'REST',          v => 'REST' },
                    { k => 'Remote',        v => 'Remote' },
                    { k => 'SAML',          v => 'SAML v2' },
                    { k => 'Slave',         v => 'Slave' },
                    { k => 'WebID',         v => 'WebID (deprecated)' },
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
                { k => 'GitHub',   v => 'GitHub' },
                { k => 'GPG',      v => 'GPG' },
                { k => 'Kerberos', v => 'Kerberos' },
                { k => 'LDAP',     v => 'LDAP' },
                { k => 'LinkedIn', v => 'LinkedIn' },
                { k => 'PAM',      v => 'PAM' },
                { k => 'Radius',   v => 'Radius' },
                { k => 'REST',     v => 'REST' },
                { k => 'SSL',      v => 'mTLS' },
                { k => 'Twitter',  v => 'Twitter' },
                { k => 'WebID',    v => 'WebID (deprecated)' },
                { k => 'WebAuthn', v => 'WebAuthn' },
                { k => 'Demo',     v => 'Demonstration' },
                { k => 'CAS',    v => 'Central Authentication Service (CAS)' },
                { k => 'OpenID', v => 'OpenID 2.0 (deprecated)' },
                { k => 'OpenIDConnect', v => 'OpenID Connect' },
                { k => 'SAML',          v => 'SAML v2' },
                { k => 'Proxy',         v => 'Proxy' },
                { k => 'Remote',        v => 'Remote' },
                { k => 'Slave',         v => 'Slave' },
                { k => 'Null',          v => 'None' },
                { k => 'Custom',        v => 'customModule' },
            ],
        },
        sfExtra => {
            type          => 'sfExtraContainer',
            help          => "sfextra.html",
            keyTest       => qr/^\w+$/,
            test          => sub { 1 },
            documentation => 'Extra second factors',
            select        => [
                { k => 'Mail2F', v => 'E-Mail' },
                { k => 'REST',   v => 'REST' },
                { k => 'Ext2F',  v => 'External' },
                { k => 'Radius', v => 'Radius' },
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
        customResetCertByMail => {
            type          => 'text',
            documentation => 'Custom certificateResetByMail module',
        },
        customAddParams => {
            type          => 'keyTextContainer',
            documentation => 'Custom additional parameters',
        },

        # Custom plugins
        customPlugins => {
            type          => 'text',
            documentation => 'Custom plugins',
        },
        customPluginsParams => {
            type          => 'keyTextContainer',
            documentation => 'Custom plugins parameters',
        },
        disabledPlugins => {
            type          => 'text',
            documentation => 'Disabled plugins',
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
        oidcServiceMetaDataIntrospectionURI => {
            type          => 'text',
            default       => 'introspect',
            documentation => 'OpenID Connect introspection endpoint',
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
            documentation => 'OpenID Connect Back-Channel logout endpoint',
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
        oidcServiceMetaDataAmrRules => {
            type    => 'keyTextContainer',
            keyTest => qr/\w/,
            test       => sub { return perlExpr(@_) },
            default => {
                'pwd' => '$authenticationLevel == 2',
                'mfa' => '$_2f',
                'pop' => '$_auth eq "WebAuthn" or $_auth eq "SSL"',
                'otp' => '$_2f eq "TOTP"',
            },
            documentation => 'OpenID Connect AMR rules',
            help => 'openidconnectservice.html#amrrules',
        },
        oidcServiceHideMetadata => {
            type          => 'bool',
            Documentation => "Don't display OIDC metadata",
        },

        # OIDC Keys
        oidcServiceOldPrivateKeySig => { type => 'EcOrRSAPrivateKey', },
        oidcServiceOldPublicKeySig  =>
          { type => 'EcOrRSAPublicKeyOrCertificate', },
        oidcServiceOldKeyIdSig => {
            type          => 'text',
            documentation => 'Previous OpenID Connect Signature Key ID',
        },
        oidcServiceOldKeyTypeSig => {
            type    => 'select',
            select  => [ { k => 'RSA', v => 'RSA' }, { k => 'EC', v => 'EC' } ],
            default => 'RSA',
        },

        oidcServicePrivateKeySig => { type => 'EcOrRSAPrivateKey', },
        oidcServicePublicKeySig => { type => 'EcOrRSAPublicKeyOrCertificate', },
        oidcServiceKeyIdSig     => {
            type          => 'text',
            documentation => 'OpenID Connect Signature Key ID',
        },
        oidcServiceKeyTypeSig => {
            type    => 'select',
            select  => [ { k => 'RSA', v => 'RSA' }, { k => 'EC', v => 'EC' } ],
            default => 'RSA',
        },

        oidcServiceNewPrivateKeySig => { type => 'EcOrRSAPrivateKey', },
        oidcServiceNewPublicKeySig  =>
          { type => 'EcOrRSAPublicKeyOrCertificate', },
        oidcServiceNewKeyIdSig => {
            type          => 'text',
            documentation => 'Future OpenID Connect Signature Key ID',
        },
        oidcServiceNewKeyTypeSig => {
            type    => 'select',
            select  => [ { k => 'RSA', v => 'RSA' }, { k => 'EC', v => 'EC' } ],
            default => 'RSA',
        },

        oidcServiceEncAlgorithmAlg => {
            type   => 'select',
            select => [

                # Symetric encryption not supported
                #{ k => 'A128KW',             v => 'A128KW' },
                #{ k => 'A192KW',             v => 'A192KW' },
                #{ k => 'A256KW',             v => 'A256KW' },
                #{ k => 'A128GCMKW',          v => 'A128GCMKW' },
                #{ k => 'A192GCMKW',          v => 'A192GCMKW' },
                #{ k => 'A256GCMKW',          v => 'A256GCMKW' },
                #{ k => 'PBES2-HS256+A128KW', v => 'PBES2-HS256+A128KW' },
                #{ k => 'PBES2-HS384+A192KW', v => 'PBES2-HS384+A192KW' },
                #{ k => 'PBES2-HS512+A256KW', v => 'PBES2-HS512+A256KW' },
                { k => 'RSA-OAEP',       v => 'RSA-OAEP' },
                { k => 'RSA-OAEP-256',   v => 'RSA-OAEP-256' },
                { k => 'RSA1_5',         v => 'RSA1_5' },
                { k => 'ECDH-ES',        v => 'ECDH-ES' },
                { k => 'ECDH-ES+A128KW', v => 'ECDH-ES+A128KW' },
                { k => 'ECDH-ES+A192KW', v => 'ECDH-ES+A192KW' },
                { k => 'ECDH-ES+A256KW', v => 'ECDH-ES+A256KW' },
            ],
            default       => 'RSA-OAEP',
            documentation => 'JWT encryption algorithme',
        },
        oidcServiceEncAlgorithmEnc => {
            type   => 'select',
            select => [
                { k => 'A256CBC-HS512', v => 'A256CBC-HS512' },
                { k => 'A256GCM',       v => 'A256GCM' },
                { k => 'A192CBC-HS384', v => 'A192CBC-HS384' },
                { k => 'A192GCM',       v => 'A192GCM' },
                { k => 'A128CBC-HS256', v => 'A128CBC-HS256' },
                { k => 'A128GCM',       v => 'A128GCM' },
            ],
            default       => 'A256GCM',
            documentation => 'JWT encryption algorithme',
        },

        oidcServiceOldPrivateKeyEnc => { type => 'RSAPrivateKey', },
        oidcServiceOldPublicKeyEnc  => { type => 'RSAPublicKeyOrCertificate', },
        oidcServiceOldKeyIdEnc      => {
            type          => 'text',
            documentation => 'Previous OpenID Connect Encryption Key ID',
        },
        oidcServiceOldKeyTypeEnc => {
            type    => 'select',
            select  => [ { k => 'RSA', v => 'RSA' }, { k => 'EC', v => 'EC' } ],
            default => 'RSA',
        },

        oidcServicePrivateKeyEnc => { type => 'RSAPrivateKey', },
        oidcServicePublicKeyEnc  => { type => 'RSAPublicKeyOrCertificate', },
        oidcServiceKeyIdEnc      => {
            type          => 'text',
            documentation => 'OpenID Connect Encryption Key ID',
        },
        oidcServiceKeyTypeEnc => {
            type    => 'select',
            select  => [ { k => 'RSA', v => 'RSA' }, { k => 'EC', v => 'EC' } ],
            default => 'RSA',
        },

        oidcServiceAllowDynamicRegistration => {
            type          => 'bool',
            default       => 0,
            documentation => 'OpenID Connect allow dynamic client registration',
        },
        oidcServiceAllowOnlyDeclaredScopes => {
            type          => 'bool',
            default       => 0,
            documentation => 'OpenID Connect allow only declared scopes',
        },
        oidcServiceIgnoreScopeForClaims => {
            type          => 'bool',
            default       => 0,
            documentation =>
'OpenID Connect release all attributes even when not allowed by scope',
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
        oidcServiceAuthorizationCodeExpiration => {
            type          => 'int',
            default       => 60,
            documentation => 'OpenID Connect global code TTL',
        },
        oidcServiceAccessTokenExpiration => {
            type          => 'int',
            default       => 3600,
            documentation => 'OpenID Connect global access token TTL',
        },
        oidcServiceDynamicRegistrationExportedVars => {
            type          => 'keyTextContainer',
            documentation =>
              'OpenID Connect exported variables for dynamic registration',
        },
        oidcServiceDynamicRegistrationExtraClaims => {
            type          => 'keyTextContainer',
            keyTest       => qr/^[\x21\x23-\x5B\x5D-\x7E]+$/,
            documentation =>
              'OpenID Connect extra claims for dynamic registration',
        },
        oidcServiceIDTokenExpiration => {
            type          => 'int',
            default       => 3600,
            documentation => 'OpenID Connect global ID token TTL',
        },
        oidcServiceOfflineSessionExpiration => {
            type          => 'int',
            default       => 2592000,
            documentation => 'OpenID Connect global offline session TTL',
        },
        oidcStorage => {
            type          => 'PerlModule',
            documentation => 'Apache::Session module to store OIDC user data',
        },
        oidcStorageOptions => {
            type          => 'keyTextContainer',
            documentation => 'Apache::Session module parameters',
        },
        oidcDropCspHeaders => {
            type          => 'bool',
            documentation => 'Drop CORS headers from OIDC issuer responses',
        },
        oidcServiceMetadataTtl => {
            type          => 'int',
            documentation => 'OIDC Metadata TTL',
        },
        oidcServiceMetaDataDisallowNoneAlg => {
            type        => 'bool',
            description => 'Disallow "none" algorithm for signature',
        },

        # OpenID Connect metadata nodes
        oidcOPMetaDataNodes => {
            type => 'oidcOPMetaDataNodeContainer',
            help =>
'authopenidconnect.html#declare-the-openid-connect-provider-in-ll-ng',
        },
        oidcRPMetaDataNodes => {
            type => 'oidcRPMetaDataNodeContainer',
            help =>
              'idpopenidconnect.html#configuration-of-relying-party-in-ll-ng',
        },
        oidcOPMetaDataOptions => { type => 'subContainer', },
        oidcRPMetaDataOptions => { type => 'subContainer', },

        # OpenID Connect providers
        oidcOPMetaDataJSON => {
            type    => 'file',
            keyTest => sub { 1 }
        },
        oidcOPMetaDataJWKS => {
            type    => 'file',
            keyTest => sub { 1 }
        },
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
        oidcOPMetaDataOptionsJWKSTimeout   => { type => 'int', default => 0 },
        oidcOPMetaDataOptionsUserAttribute => { type => 'text' },
        oidcOPMetaDataOptionsClientID      => { type => 'text', },
        oidcOPMetaDataOptionsClientSecret  => { type => 'password', },
        oidcOPMetaDataOptionsScope         =>
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
                { k => 'client_secret_jwt',   v => 'client_secret_jwt' },
                { k => 'private_key_jwt',     v => 'private_key_jwt' },
            ],
            default => 'client_secret_post',
        },
        oidcOPMetaDataOptionsAuthnEndpointAuthMethod => {
            type   => 'select',
            select =>
              [ { k => '', v => 'None' }, { k => 'jws', v => 'Signed JWT' }, ],
        },
        oidcOPMetaDataOptionsAuthnEndpointAuthSigAlg => {
            type    => 'select',
            select  => oidcSigAlgorithmAlg,
            default => 'RS256',
        },
        oidcOPMetaDataOptionsCheckJWTSignature =>
          { type => 'bool', default => 1 },
        oidcOPMetaDataOptionsIDTokenMaxAge => { type => 'int',  default => 30 },
        oidcOPMetaDataOptionsUseNonce      => { type => 'bool', default => 1 },
        oidcOPMetaDataOptionsDisplayName   => { type => 'text', },
        oidcOPMetaDataOptionsIcon          => { type => 'text', },
        oidcOPMetaDataOptionsStoreIDToken  => { type => 'bool', default => 0 },
        oidcOPMetaDataOptionsSortNumber    => { type => 'intOrNull', },
        oidcOPMetaDataOptionsTooltip       => { type => 'text', },
        oidcOPMetaDataOptionsComment       => { type => 'longtext', },
        oidcOPMetaDataOptionsResolutionRule => {
            type    => 'longtext',
            default => '',
        },
        oidcOPMetaDataOptionsRequirePkce => {
            type          => 'bool',
            default       => 0,
            documentation => 'Use PKCE with this OP',
        },
        oidcOPMetaDataOptionsUserinfoSource => {
            type    => 'select',
            default => 'userinfo',
            select  => [
                { k => 'userinfo',     v => 'Userinfo endpoint' },
                { k => 'id_token',     v => 'ID Token' },
                { k => 'access_token', v => 'Access Token' },
            ],
            documentation => "Source of userinfo",
        },
        oidcOPMetaDataOptionsNoJwtHeader => {
            type          => 'bool',
            default       => 0,
            documentation => "Don't insert typ header",
        },

        # OpenID Connect relying parties
        oidcRPMetaDataExportedVars => {
            help    => 'idpopenidconnect.html#exported-attributes',
            type    => 'oidcAttributeContainer',
            keyTest => qr/\w/,
            test    => qr/\w/,
            default => {
                'name'               => 'cn',
                'preferred_username' => 'uid',
                'email'              => 'mail',
            }
        },
        oidcRPMetaDataOptionsClientID     => { type => 'text', },
        oidcRPMetaDataOptionsClientSecret => { type => 'password', },
        oidcRPMetaDataOptionsAuthMethod   => {
            type   => 'select',
            select => [
                { k => '',                    v => 'Any' },
                { k => 'client_secret_post',  v => 'client_secret_post' },
                { k => 'client_secret_basic', v => 'client_secret_basic' },
                { k => 'client_secret_jwt',   v => 'client_secret_jwt' },
                { k => 'private_key_jwt',     v => 'private_key_jwt' },
            ],
        },
        oidcRPMetaDataOptionsAuthRequiredForAuthorize => {
            type    => 'bool',
            default => 0,
        },
        oidcRPMetaDataOptionsDisplayName    => { type => 'text', },
        oidcRPMetaDataOptionsIcon           => { type => 'text', },
        oidcRPMetaDataOptionsUserIDAttr     => { type => 'text', },
        oidcRPMetaDataOptionsIDTokenSignAlg => {
            type   => 'select',
            select => [ { k => 'none', v => 'None' }, @{&oidcSigAlgorithmAlg} ],
            default => 'RS256',
        },
        oidcRPMetaDataOptionsIDTokenExpiration  => { type => 'intOrNull' },
        oidcRPMetaDataOptionsIDTokenForceClaims =>
          { type => 'bool', default => 0 },
        oidcRPMetaDataOptionsAccessTokenSignAlg => {
            type    => 'select',
            select  => oidcSigAlgorithmAlg,
            default => 'RS256',
        },
        oidcRPMetaDataOptionsUserInfoSignAlg => {
            type   => 'select',
            select => [
                { k => '',      v => 'JSON' },
                { k => 'none',  v => 'JWT/None' },
                { k => 'HS256', v => 'JWT/HS256' },
                { k => 'HS384', v => 'JWT/HS384' },
                { k => 'HS512', v => 'JWT/HS512' },
                { k => 'RS256', v => 'JWT/RS256' },
                { k => 'RS384', v => 'JWT/RS384' },
                { k => 'RS512', v => 'JWT/RS512' },
                { k => 'PS256', v => 'JWT/PS256' },
                { k => 'PS384', v => 'JWT/PS384' },
                { k => 'PS512', v => 'JWT/PS512' },
                { k => 'ES256', v => 'JWT/ES256' },
                { k => 'ES384', v => 'JWT/ES384' },
                { k => 'ES512', v => 'JWT/ES512' },
                { k => 'EdDSA', v => 'JWT/EdDSA' },
            ],
            default => '',
        },
        oidcRPMetaDataOptionsAccessTokenJWT => { type => 'bool', default => 0 },
        oidcRPMetaDataOptionsAccessTokenClaims =>
          { type => 'bool', default => 0 },
        oidcRPMetaDataOptionsAdditionalAudiences   => { type => 'text' },
        oidcRPMetaDataOptionsAccessTokenExpiration => { type => 'intOrNull' },
        oidcRPMetaDataOptionsAuthorizationCodeExpiration =>
          { type => 'intOrNull' },
        oidcRPMetaDataOptionsComment                  => { type => 'longtext' },
        oidcRPMetaDataOptionsOfflineSessionExpiration =>
          { type => 'intOrNull' },
        oidcRPMetaDataOptionsRedirectUris => { type => 'text', },
        oidcRPMetaDataOptionsRequestUris  => { type => 'text', },
        oidcRPMetaDataOptionsExtraClaims  => {
            type    => 'keyTextContainer',
            keyTest => qr/^[\x21\x23-\x5B\x5D-\x7E]+$/,
            default => {},
            help    => 'idpopenidconnect.html#oidcextraclaims'
        },
        oidcRPMetaDataOptionsBypassConsent => {
            type    => 'bool',
            default => 0
        },
        oidcRPMetaDataOptionsPostLogoutRedirectUris => { type => 'text', },
        oidcRPMetaDataOptionsLogoutBypassConfirm    => {
            type          => 'bool',
            default       => 0,
            documentation => 'Bypass logout confirmation'
        },
        oidcRPMetaDataOptionsLogoutUrl => {
            type          => 'text',
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
            documentation => 'Session required for back/front channel logout',
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
        oidcRPMetaDataOptionsAllowOffline => {
            type          => 'bool',
            default       => 0,
            documentation => 'Allow offline access',
        },
        oidcRPMetaDataOptionsAllowPasswordGrant => {
            type          => 'bool',
            default       => 0,
            documentation =>
              'Allow OAuth2 Resource Owner Password Credentials Grant',
        },
        oidcRPMetaDataOptionsAllowClientCredentialsGrant => {
            type          => 'bool',
            default       => 0,
            documentation => 'Allow OAuth2 Client Credentials Grant',
        },
        oidcRPMetaDataOptionsRefreshToken => {
            type          => 'bool',
            default       => 0,
            documentation => 'Issue refresh tokens',
        },
        oidcRPMetaDataOptionsRefreshTokenRotation => {
            type          => 'bool',
            default       => 0,
            documentation => 'Invalidate refresh token after use',
        },
        oidcRPMetaDataOptionsAuthnLevel => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            documentation =>
              'Authentication level requires to access to this RP',
        },
        oidcRPMetaDataOptionsRule => {
            type          => 'text',
            test          => sub { return perlExpr(@_) },
            documentation => 'Rule to grant access to this RP',
        },
        oidcRPMetaDataOptionsAllowNativeSso => {
            type          => 'bool',
            documentation => 'Allow Native SSO for Mobile Apps',
        },
        oidcRPMetaDataMacros => {
            type => 'keyTextContainer',
            help =>
              'exportedvars.html#extend-variables-using-macros-and-groups',
            test => {
                keyTest    => qr/^[_a-zA-Z][a-zA-Z0-9_]*$/,
                keyMsgFail => '__badMacroName__',
                test       => sub { return perlExpr(@_) },
            },
            default       => {},
            documentation => 'Macros',
        },
        oidcRPMetaDataScopeRules => {
            type => 'keyTextContainer',
            help => 'idpopenidconnect.html#scope-rules',
            test => {

                # RFC6749
                keyTest    => qr/^[\x21\x23-\x5B\x5D-\x7E]+$/,
                keyMsgFail => '__badMacroName__',
                test       => sub { return perlExpr(@_) },
            },
            default       => {},
            documentation => 'Scope rules',
        },
        oidcRPMetaDataOptionsJwks => {
            type          => 'file',
            keyTest       => sub { 1 },
            documentation => 'Relying party JWKS document',
        },
        oidcRPMetaDataOptionsJwksUri => {
            type          => 'url',
            help          => 'idpopenidconnect.html',
            documentation =>
              'Relying party JWKS endpoint (to get encryption keys)',
        },
        oidcRPMetaDataOptionsAccessTokenEncKeyMgtAlg => {
            type          => 'select',
            select        => oidcEncAlgorithmAlg,
            documentation => '"alg" algorithm for access_token encryption',
        },
        oidcRPMetaDataOptionsAccessTokenEncContentEncAlg => {
            type          => 'select',
            select        => oidcEncAlgorithmEnc,
            default       => 'A256GCM',
            documentation => '"enc" algorithm for access_token encryption',
        },
        oidcRPMetaDataOptionsIdTokenEncKeyMgtAlg => {
            type          => 'select',
            select        => oidcEncAlgorithmAlg,
            documentation => '"alg" algorithm for id_token encryption',
        },
        oidcRPMetaDataOptionsIdTokenEncContentEncAlg => {
            type          => 'select',
            select        => oidcEncAlgorithmEnc,
            default       => 'A256GCM',
            documentation => '"enc" algorithm for id_token encryption',
        },
        oidcRPMetaDataOptionsUserInfoEncKeyMgtAlg => {
            type          => 'select',
            select        => oidcEncAlgorithmAlg,
            documentation => '"alg" algorithm for user_info encryption',
        },
        oidcRPMetaDataOptionsUserInfoEncContentEncAlg => {
            type          => 'select',
            select        => oidcEncAlgorithmEnc,
            default       => 'A256GCM',
            documentation => '"enc" algorithm for user_info encryption',
        },
        oidcRPMetaDataOptionsLogoutEncKeyMgtAlg => {
            type          => 'select',
            select        => oidcEncAlgorithmAlg,
            documentation => '"alg" algorithm for logout token encryption',
        },
        oidcRPMetaDataOptionsLogoutEncContentEncAlg => {
            type          => 'select',
            select        => oidcEncAlgorithmEnc,
            default       => 'A256GCM',
            documentation => '"enc" algorithm for logout encryption',
        },
        oidcRPMetaDataOptionsAuthnRequireState => {
            type    => 'bool',
            default => 0,
        },
        oidcRPMetaDataOptionsAuthnRequireNonce => {
            type    => 'bool',
            default => 0,
        },
        oidcRPMetaDataOptionsUserinfoRequireHeaderToken => {
            type          => 'bool',
            default       => 0,
            documentation =>
              '/userinfo endpoint requires authn using Bearer token',
        },
        oidcRPMetaDataOptionsTokenXAuthorizedRP => {
            type          => 'text',
            documentation =>
              'List of RP authorized to query for an access_token of this RP',
        },
        oidcRPMetaDataOptionsNoJwtHeader => {
            type          => 'bool',
            default       => 0,
            documentation => "Don't insert typ header",
        },
        appAccessHistoryEnabled => {
            type          => 'bool',
            default       => 0,
            documentation =>
'Shall OIDC/SAML/CAS protected apps access be recorded to session?'
        },
    };
}

1;
