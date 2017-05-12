##@file
# Base package for Lemonldap::NG portal

##@class Lemonldap::NG::Portal::Simple
# Base class for Lemonldap::NG portal
package Lemonldap::NG::Portal::Simple;

use strict;
use warnings;

use Exporter 'import';

use warnings;
use MIME::Base64;
use Lemonldap::NG::Common::CGI;
use CGI::Cookie;
use POSIX qw(strftime);
use Lemonldap::NG::Portal::_i18n;    #inherits
use Lemonldap::NG::Common::Captcha;
use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::Apache::Session
  ;    #link protected session Apache::Session object
use Lemonldap::NG::Common::Safe;    #link protected safe Safe object
use Lemonldap::NG::Common::Safelib;
use Digest::MD5;

# Special comments for doxygen
#inherits Lemonldap::NG::Portal::_SOAP
#inherits Lemonldap::NG::Portal::AuthApache;
#inherits Lemonldap::NG::Portal::AuthAD;
#inherits Lemonldap::NG::Portal::AuthCAS;
#inherits Lemonldap::NG::Portal::AuthChoice;
#inherits Lemonldap::NG::Portal::AuthDBI;
#inherits Lemonldap::NG::Portal::AuthFacebook;
#inherits Lemonldap::NG::Portal::AuthGoogle;
#inherits Lemonldap::NG::Portal::AuthLDAP;
#inherits Lemonldap::NG::Portal::AuthMulti;
#inherits Lemonldap::NG::Portal::AuthNull;
#inherits Lemonldap::NG::Portal::AuthOpenID;
#inherits Lemonldap::NG::Portal::AuthProxy;
#inherits Lemonldap::NG::Portal::AuthRadius;
#inherits Lemonldap::NG::Portal::AuthRemote;
#inherits Lemonldap::NG::Portal::AuthSAML;
#inherits Lemonldap::NG::Portal::AuthSSL;
#inherits Lemonldap::NG::Portal::AuthTwitter;
#inherits Lemonldap::NG::Portal::Display;
#inherits Lemonldap::NG::Portal::IssuerDBCAS
#inherits Lemonldap::NG::Portal::IssuerDBNull
#inherits Lemonldap::NG::Portal::IssuerDBOpenID
#inherits Lemonldap::NG::Portal::IssuerDBSAML
#inherits Lemonldap::NG::Portal::Menu
#link Lemonldap::NG::Common::Notification protected notification
#inherits Lemonldap::NG::Portal::PasswordDBChoice;
#inherits Lemonldap::NG::Portal::PasswordDBDBI;
#inherits Lemonldap::NG::Portal::PasswordDBLDAP;
#inherits Lemonldap::NG::Portal::PasswordDBNull;
#inherits Lemonldap::NG::Portal::UserDBAD;
#inherits Lemonldap::NG::Portal::UserDBChoice;
#inherits Lemonldap::NG::Portal::UserDBDBI;
#inherits Lemonldap::NG::Portal::UserDBFacebook;
#inherits Lemonldap::NG::Portal::UserDBGoogle;
#inherits Lemonldap::NG::Portal::UserDBLDAP;
#inherits Lemonldap::NG::Portal::UserDBMulti;
#inherits Lemonldap::NG::Portal::UserDBNull;
#inherits Lemonldap::NG::Portal::UserDBOpenID;
#inherits Lemonldap::NG::Portal::UserDBProxy;
#inherits Lemonldap::NG::Portal::UserDBRemote;
#inherits Lemonldap::NG::Portal::UserDBSAML;
#inherits Lemonldap::NG::Portal::PasswordDBDBI
#inherits Lemonldap::NG::Portal::PasswordDBLDAP
#inherits Apache::Session
#link Lemonldap::NG::Common::Apache::Session::SOAP protected globalStorage

our $VERSION = '1.4.10';

use base qw(Lemonldap::NG::Common::CGI Exporter);
our @ISA;

# Constants
use constant {

    # Portal errors
    # Developers warning, do not use PE_INFO, it's reserved to autoRedirect.
    # If you want to send an information, use $self->info('text').
    PE_IMG_NOK                          => -5,
    PE_IMG_OK                           => -4,
    PE_INFO                             => -3,
    PE_REDIRECT                         => -2,
    PE_DONE                             => -1,
    PE_OK                               => 0,
    PE_SESSIONEXPIRED                   => 1,
    PE_FORMEMPTY                        => 2,
    PE_WRONGMANAGERACCOUNT              => 3,
    PE_USERNOTFOUND                     => 4,
    PE_BADCREDENTIALS                   => 5,
    PE_LDAPCONNECTFAILED                => 6,
    PE_LDAPERROR                        => 7,
    PE_APACHESESSIONERROR               => 8,
    PE_FIRSTACCESS                      => 9,
    PE_BADCERTIFICATE                   => 10,
    PE_PP_ACCOUNT_LOCKED                => 21,
    PE_PP_PASSWORD_EXPIRED              => 22,
    PE_CERTIFICATEREQUIRED              => 23,
    PE_ERROR                            => 24,
    PE_PP_CHANGE_AFTER_RESET            => 25,
    PE_PP_PASSWORD_MOD_NOT_ALLOWED      => 26,
    PE_PP_MUST_SUPPLY_OLD_PASSWORD      => 27,
    PE_PP_INSUFFICIENT_PASSWORD_QUALITY => 28,
    PE_PP_PASSWORD_TOO_SHORT            => 29,
    PE_PP_PASSWORD_TOO_YOUNG            => 30,
    PE_PP_PASSWORD_IN_HISTORY           => 31,
    PE_PP_GRACE                         => 32,
    PE_PP_EXP_WARNING                   => 33,
    PE_PASSWORD_MISMATCH                => 34,
    PE_PASSWORD_OK                      => 35,
    PE_NOTIFICATION                     => 36,
    PE_BADURL                           => 37,
    PE_NOSCHEME                         => 38,
    PE_BADOLDPASSWORD                   => 39,
    PE_MALFORMEDUSER                    => 40,
    PE_SESSIONNOTGRANTED                => 41,
    PE_CONFIRM                          => 42,
    PE_MAILFORMEMPTY                    => 43,
    PE_BADMAILTOKEN                     => 44,
    PE_MAILERROR                        => 45,
    PE_MAILOK                           => 46,
    PE_LOGOUT_OK                        => 47,
    PE_SAML_ERROR                       => 48,
    PE_SAML_LOAD_SERVICE_ERROR          => 49,
    PE_SAML_LOAD_IDP_ERROR              => 50,
    PE_SAML_SSO_ERROR                   => 51,
    PE_SAML_UNKNOWN_ENTITY              => 52,
    PE_SAML_DESTINATION_ERROR           => 53,
    PE_SAML_CONDITIONS_ERROR            => 54,
    PE_SAML_IDPSSOINITIATED_NOTALLOWED  => 55,
    PE_SAML_SLO_ERROR                   => 56,
    PE_SAML_SIGNATURE_ERROR             => 57,
    PE_SAML_ART_ERROR                   => 58,
    PE_SAML_SESSION_ERROR               => 59,
    PE_SAML_LOAD_SP_ERROR               => 60,
    PE_SAML_ATTR_ERROR                  => 61,
    PE_OPENID_EMPTY                     => 62,
    PE_OPENID_BADID                     => 63,
    PE_MISSINGREQATTR                   => 64,
    PE_BADPARTNER                       => 65,
    PE_MAILCONFIRMATION_ALREADY_SENT    => 66,
    PE_PASSWORDFORMEMPTY                => 67,
    PE_CAS_SERVICE_NOT_ALLOWED          => 68,
    PE_MAILFIRSTACCESS                  => 69,
    PE_MAILNOTFOUND                     => 70,
    PE_PASSWORDFIRSTACCESS              => 71,
    PE_MAILCONFIRMOK                    => 72,
    PE_RADIUSCONNECTFAILED              => 73,
    PE_MUST_SUPPLY_OLD_PASSWORD         => 74,
    PE_FORBIDDENIP                      => 75,
    PE_CAPTCHAERROR                     => 76,
    PE_CAPTCHAEMPTY                     => 77,
    PE_REGISTERFIRSTACCESS              => 78,
    PE_REGISTERFORMEMPTY                => 79,
    PE_REGISTERALREADYEXISTS            => 80,

    # Portal messages
    PM_USER                  => 0,
    PM_DATE                  => 1,
    PM_IP                    => 2,
    PM_SESSIONS_DELETED      => 3,
    PM_OTHER_SESSIONS        => 4,
    PM_REMOVE_OTHER_SESSIONS => 5,
    PM_PP_GRACE              => 6,
    PM_PP_EXP_WARNING        => 7,
    PM_SAML_IDPSELECT        => 8,
    PM_SAML_IDPCHOOSEN       => 9,
    PM_REMEMBERCHOICE        => 10,
    PM_SAML_SPLOGOUT         => 11,
    PM_REDIRECTION           => 12,
    PM_BACKTOSP              => 13,
    PM_BACKTOCASURL          => 14,
    PM_LOGOUT                => 15,
    PM_OPENID_EXCHANGE       => 16,
    PM_CDC_WRITER            => 17,
    PM_OPENID_RPNS           => 18,    # OpenID "requested parameter is not set"
    PM_OPENID_PA             => 19,    # "OpenID policy available at"
    PM_OPENID_AP             => 20,    # OpenID "Asked parameter"
    PM_ERROR_MSG             => 21,
    PM_LAST_LOGINS           => 22,
    PM_LAST_FAILED_LOGINS    => 23,
};

# EXPORTER PARAMETERS
our @EXPORT = qw( PE_IMG_NOK PE_IMG_OK PE_INFO PE_REDIRECT PE_DONE PE_OK
  PE_SESSIONEXPIRED PE_FORMEMPTY PE_WRONGMANAGERACCOUNT PE_USERNOTFOUND
  PE_BADCREDENTIALS PE_LDAPCONNECTFAILED PE_LDAPERROR PE_APACHESESSIONERROR
  PE_FIRSTACCESS PE_BADCERTIFICATE PE_PP_ACCOUNT_LOCKED PE_PP_PASSWORD_EXPIRED
  PE_CERTIFICATEREQUIRED PE_ERROR PE_PP_CHANGE_AFTER_RESET
  PE_PP_PASSWORD_MOD_NOT_ALLOWED PE_PP_MUST_SUPPLY_OLD_PASSWORD
  PE_PP_INSUFFICIENT_PASSWORD_QUALITY PE_PP_PASSWORD_TOO_SHORT
  PE_PP_PASSWORD_TOO_YOUNG PE_PP_PASSWORD_IN_HISTORY PE_PP_GRACE
  PE_PP_EXP_WARNING PE_PASSWORD_MISMATCH PE_PASSWORD_OK PE_NOTIFICATION
  PE_BADURL PE_NOSCHEME PE_BADOLDPASSWORD PE_MALFORMEDUSER PE_SESSIONNOTGRANTED
  PE_CONFIRM PE_MAILFORMEMPTY PE_BADMAILTOKEN PE_MAILERROR PE_MAILOK
  PE_LOGOUT_OK PE_SAML_ERROR PE_SAML_LOAD_SERVICE_ERROR PE_SAML_LOAD_IDP_ERROR
  PE_SAML_SSO_ERROR PE_SAML_UNKNOWN_ENTITY PE_SAML_DESTINATION_ERROR
  PE_SAML_CONDITIONS_ERROR PE_SAML_IDPSSOINITIATED_NOTALLOWED PE_SAML_SLO_ERROR
  PE_SAML_SIGNATURE_ERROR PE_SAML_ART_ERROR PE_SAML_SESSION_ERROR
  PE_SAML_LOAD_SP_ERROR PE_SAML_ATTR_ERROR PE_OPENID_EMPTY PE_OPENID_BADID
  PE_MISSINGREQATTR PE_BADPARTNER PE_MAILCONFIRMATION_ALREADY_SENT
  PE_PASSWORDFORMEMPTY PE_CAS_SERVICE_NOT_ALLOWED PE_MAILFIRSTACCESS
  PE_MAILNOTFOUND PE_PASSWORDFIRSTACCESS PE_MAILCONFIRMOK
  PE_MUST_SUPPLY_OLD_PASSWORD PE_FORBIDDENIP PE_CAPTCHAERROR PE_CAPTCHAEMPTY
  PE_REGISTERFIRSTACCESS PE_REGISTERFORMEMPTY PE_REGISTERALREADYEXISTS
  PM_USER PM_DATE PM_IP PM_SESSIONS_DELETED PM_OTHER_SESSIONS
  PM_REMOVE_OTHER_SESSIONS PM_PP_GRACE PM_PP_EXP_WARNING
  PM_SAML_IDPSELECT PM_SAML_IDPCHOOSEN PM_REMEMBERCHOICE PM_SAML_SPLOGOUT
  PM_REDIRECTION PM_BACKTOSP PM_BACKTOCASURL PM_LOGOUT PM_OPENID_EXCHANGE
  PM_CDC_WRITER PM_OPENID_RPNS PM_OPENID_PA PM_OPENID_AP PM_ERROR_MSG
  PM_LAST_LOGINS PM_LAST_FAILED_LOGINS
);
our %EXPORT_TAGS = ( 'all' => [ @EXPORT, 'import' ], );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# Share secure jail between threads
our $safe;

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($safe);
    };
}

##@cmethod Lemonldap::NG::Portal::Simple new(hashRef args)
# Class constructor.
#@param args hash reference
#@return Lemonldap::NG::Portal::Simple object
sub new {

    @ISA = qw(Lemonldap::NG::Common::CGI Exporter);
    binmode( STDOUT, ":utf8" );
    my $class = shift;
    return $class if ( ref($class) );
    my $self = $class->SUPER::new() or return undef;

    # Reinit _url
    $self->{_url} = '';

    # Get global configuration
    $self->getConf(@_)
      or $self->abort( "Configuration error",
        "Unable to get configuration: $Lemonldap::NG::Common::Conf::msg" );

    # Test mandatory elements

    # 1. Sessions backend
    $self->abort( "Configuration error",
        "You've to indicate a an Apache::Session storage module !" )
      unless ( $self->{globalStorage} );

    # Use global storage for all backends by default

    # Persistent
    $self->{persistentStorage} ||= $self->{globalStorage};
    if (   !$self->{persistentStorageOptions}
        or !%{ $self->{persistentStorageOptions} } )
    {
        $self->{persistentStorageOptions} = $self->{globalStorageOptions};
    }

    # SAML
    $self->{samlStorage} ||= $self->{globalStorage};
    if ( !$self->{samlStorageOptions} or !%{ $self->{samlStorageOptions} } ) {
        $self->{samlStorageOptions} = $self->{globalStorageOptions};
    }

    # CAS
    $self->{casStorage} ||= $self->{globalStorage};
    if ( !$self->{casStorageOptions} or !%{ $self->{casStorageOptions} } ) {
        $self->{casStorageOptions} = $self->{globalStorageOptions};
    }

    # Captcha
    $self->{captchaStorage} ||= $self->{globalStorage};
    if (   !$self->{captchaStorageOptions}
        or !%{ $self->{captchaStorageOptions} } )
    {
        $self->{captchaStorageOptions} = $self->{globalStorageOptions};
    }

    # 2. Domain
    $self->abort( "Configuration error",
        "You've to indicate a domain for cookies" )
      unless ( $self->{domain} );
    $self->{domain} =~ s/^([^\.])/.$1/;

    # Load Display and Menu functions
    $self->loadModule('Lemonldap::NG::Portal::Menu');
    $self->loadModule('Lemonldap::NG::Portal::Display');

    # Rules to allow redirection
    $self->{mustRedirect} =
      defined $ENV{REQUEST_METHOD}
      ? ( $ENV{REQUEST_METHOD} eq "POST" and not $self->param('newpassword') )
      : $self->param('logout') ? 1
      :                          0;

    # Push authentication/userDB/passwordDB modules in @ISA
    foreach my $type (qw(authentication userDB passwordDB registerDB)) {
        my $module_name = 'Lemonldap::NG::Portal::';
        my $db_type     = $type;
        my $db_name     = $self->{$db_type};

        # Adapt module type to real module name
        $db_type =~ s/authentication/Auth/;
        $db_type =~ s/userDB/UserDB/;
        $db_type =~ s/passwordDB/PasswordDB/;
        $db_type =~ s/registerDB/RegisterDB/;

        # Full module name
        $module_name .= $db_type . $db_name;

        # Remove white spaces
        $module_name =~ s/\s.*$//;

        # Try to load module
        $self->abort( "Configuration error", "Unable to load $module_name" )
          unless $self->loadModule($module_name);

        # $self->{authentication} and $self->{userDB} can contains arguments
        # (key1 = scalar_value; key2 = ...)
        unless ( $db_name =~ /^Multi/ ) {
            $db_name =~ s/^\w+\s*//;
            my %h = split( /\s*[=;]\s*/, $db_name ) if ($db_name);
            %$self = ( %h, %$self );
        }
    }

    # Check issuerDB path to load the correct issuerDB module
    foreach my $issuerDBtype (qw(SAML OpenID CAS)) {
        my $module_name = 'Lemonldap::NG::Portal::IssuerDB' . $issuerDBtype;

        $self->lmLog( "[IssuerDB activation] Try issuerDB module $issuerDBtype",
            'debug' );

        # Check activation flag
        my $activation =
          $self->{ "issuerDB" . $issuerDBtype . "Activation" } ||= "0";

        unless ($activation) {
            $self->lmLog(
                "[IssuerDB activation] Activation flag set to off, trying next",
                'debug'
            );
            next;
        }

        # Check the path
        my $path = $self->{ "issuerDB" . $issuerDBtype . "Path" };
        if ( defined $path ) {
            $self->lmLog( "[IssuerDB activation] Found path $path", 'debug' );

            # Get current path
            my $url_path = $self->url( -absolute => 1 );
            $url_path =~ s#^//#/#;
            $self->lmLog(
                "[IssuerDB activation] Path of current request is $url_path",
                'debug' );

            # Match regular expression
            if ( $url_path =~ m#$path# ) {
                $self->abort( "Configuration error",
                    "Unable to load $module_name" )
                  unless $self->loadModule($module_name);

                # Remember loaded module
                $self->{_activeIssuerDB} = $issuerDBtype;
                $self->lmLog(
"[IssuerDB activation] IssuerDB module $issuerDBtype loaded",
                    'debug'
                );
                last;

            }
            else {
                $self->lmLog(
                    "[IssuerDB activation] Path do not match, trying next",
                    'debug' );
                next;
            }

        }
        else {
            $self->lmLog( "[IssuerDB activation] No path defined", 'debug' );
            next;
        }

    }

    # Load default issuerDB module if none was choosed
    unless ( $self->{_activeIssuerDB} ) {

        # Manage old configuration format
        my $db_type = $self->{'issuerDB'} || 'Null';

        my $module_name = 'Lemonldap::NG::Portal::IssuerDB' . $db_type;

        $self->abort( "Configuration error", "Unable to load $module_name" )
          unless $self->loadModule($module_name);

        # Remember loaded module
        $self->{_activeIssuerDB} = $db_type;
        $self->lmLog( "[IssuerDB activation] IssuerDB module $db_type loaded",
            'debug' );
    }

    # Notifications
    if ( $self->{notification} ) {
        require Lemonldap::NG::Common::Notification;
        my $tmp;

        # Use configuration options
        if ( $self->{notificationStorage} ) {
            $tmp->{type} = $self->{notificationStorage};
            foreach ( keys %{ $self->{notificationStorageOptions} } ) {
                $tmp->{$_} = $self->{notificationStorageOptions}->{$_};
            }
        }

        # Else use the configuration backend
        else {
            (%$tmp) = ( %{ $self->{lmConf} } );
            $self->abort( "notificationStorage not defined",
                "This parameter is required to use notification system" )
              unless ( ref($tmp) );

            # Get the type
            $tmp->{type} =~ s/.*:://;
            $tmp->{type} =~ s/(CDBI|RDBI)/DBI/;    # CDBI/RDBI are DBI

            # If type not File, DBI or LDAP, abort
            $self->abort("Only File, DBI or LDAP supported for Notifications")
              unless $tmp->{type} =~ /^(File|DBI|LDAP)$/;

            # Force table name
            $tmp->{table} = 'notifications';
        }

        $tmp->{p}            = $self;
        $self->{notifObject} = Lemonldap::NG::Common::Notification->new($tmp);
        $self->abort($Lemonldap::NG::Common::Notification::msg)
          unless ( $self->{notifObject} );
    }

    # SOAP
    if ( $self->{Soap} or $self->{soap} ) {
        $self->loadModule('Lemonldap::NG::Portal::_SOAP');
        if ( $self->{notification} and $ENV{PATH_INFO} ) {
            $self->{CustomSOAPServices} ||= {};
            $self->{CustomSOAPServices}->{'/notification'} = {
                f => 'newNotification deleteNotification',
                o => $self->{notifObject}
            };
        }
        $self->startSoapServices();
    }

    # Trusted domains
    $self->{trustedDomains} ||= "";
    $self->{trustedDomains} = "*"
      if ( $self->{trustedDomains} =~ /(^|\s)\*(\s|$)/ );
    if ( $self->{trustedDomains} and $self->{trustedDomains} ne "*" ) {
        $self->{trustedDomains} =~ s#(^|\s+)\.#${1}[^/]+.#g;
        $self->{trustedDomains} =
          '(' . join( '|', split( /\s+/, $self->{trustedDomains} ) ) . ')';
        $self->{trustedDomains} =~ s/\./\\./g;
    }

    return $self;
}

##@method boolean loadModule(string module, boolean ignoreError)
# Load a module into portal namespace
# @param module module name
# @param ignoreError set to 1 if error should not appear in logs
# @return boolean
sub loadModule {
    my ( $self, $module, $ignoreError ) = @_;

    return 1 unless $module;

    # Load module test
    eval "require $module";
    if ($@) {
        $self->lmLog( "$module load error: $@", 'error' ) unless $ignoreError;
        return 0;
    }

    # Push module in @ISA
    push @ISA, $module;

    $self->lmLog( "Module $module loaded", 'debug' );

    return 1;
}

##@method protected boolean getConf(hashRef args)
# Copy all parameters in caller object.
#@param args hash-ref
#@return True
sub getConf {
    my ($self) = shift;
    my %args;
    if ( ref( $_[0] ) ) {
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }
    %$self = ( %$self, %args );
    1;
}

## @method protected void setHiddenFormValue(string fieldname, string value, string prefix, boolean base64)
# Add element into $self->{portalHiddenFormValues}, those values could be
# used to hide values into HTML form.
# @param fieldname The field name which will contain the correponding value
# @param value The associated value
# @param prefix Prefix of the field key
# @param base64 Encode value in base64
# @return nothing
sub setHiddenFormValue {
    my ( $self, $key, $val, $prefix, $base64 ) = @_;

    # Default values
    $prefix = "lmhidden_" unless defined $prefix;
    $base64 = 1           unless defined $base64;

    # Store value
    if ($val) {
        $key = $prefix . $key;
        $val = encode_base64($val) if $base64;
        $self->{portalHiddenFormValues}->{$key} = $val;
    }
}

## @method public void getHiddenFormValue(string fieldname, string prefix, boolean base64)
# Get value into $self->{portalHiddenFormValues}.
# @param fieldname The existing field name which contains a value
# @param prefix Prefix of the field key
# @param base64 Decode value from base64
# @return string The associated value
sub getHiddenFormValue {
    my ( $self, $key, $prefix, $base64 ) = @_;

    # Default values
    $prefix = "lmhidden_" unless defined $prefix;
    $base64 = 1           unless defined $base64;

    $key = $prefix . $key;

    # Get value
    if ( my $val = $self->param($key) ) {
        $val = decode_base64($val) if $base64;
        return $val;
    }

    # No value found
    return undef;
}

## @method protected void clearHiddenFormValue(arrayref keys)
# Clear values form stored hidden fields
# Delete all keys if no keys provided
# @param keys Array reference of keys
# @return nothing
sub clearHiddenFormValue {
    my ( $self, $keys ) = @_;

    unless ( defined $keys ) {
        delete $self->{portalHiddenFormValues};
    }
    else {
        delete $self->{portalHiddenFormValues}->{$_} foreach (@$keys);
    }

    return;
}

##@method public string buildHiddenForm()
# Return an HTML representation of hidden values.
# @return HTML code
sub buildHiddenForm {
    my $self = shift;
    my @keys = keys %{ $self->{portalHiddenFormValues} };
    my $val  = '';

    foreach (@keys) {

        # Check XSS attacks
        next
          if $self->checkXSSAttack( $_, $self->{portalHiddenFormValues}->{$_} );

        # Build hidden input HTML code
        $val .= qq{<input type="hidden" name="$_" id="$_" value="}
          . $self->{portalHiddenFormValues}->{$_} . '" />';
    }

    return $val;
}

## @method void initCaptcha(void)
# init captcha module and generate captcha
# @return nothing
sub initCaptcha {
    my $self = shift;

    # Create new captcha
    my $captcha = Lemonldap::NG::Common::Captcha->new(
        {
            storageModule        => $self->{captchaStorage},
            storageModuleOptions => $self->{captchaStorageOptions},
            size                 => $self->{captcha_size},
        }
    );

    $self->{captcha_secret} = $captcha->code;
    $self->{captcha_code}   = $captcha->md5;
    $self->{captcha_img} = $self->{portal} . "?displayCaptcha=" . $captcha->md5;

    $self->lmLog( "Captcha code generated: " . $self->{captcha_code}, 'debug' );

    return;
}

## @method int checkCaptcha(code, ccode)
# Check captcha auth
# @param code that user enter in the form
# @param captcha code generated by Authen::Captcha
# @return a constant
sub checkCaptcha {
    my ( $self, $code, $ccode ) = @_;

    # Get captcha object
    my $captcha = Lemonldap::NG::Common::Captcha->new(
        {
            storageModule        => $self->{captchaStorage},
            storageModuleOptions => $self->{captchaStorageOptions},
            md5                  => $ccode,
            size                 => $self->{captcha_size},
        }
    );

    # Check code
    if ( $captcha && $captcha->code ) {

        if ( $code eq $captcha->code ) {
            $self->lmLog( "Code $code match captcha $ccode", 'debug' );
            return 1;
        }
        return -2;
    }

    return 0;
}

## @method int removeCaptcha(ccode)
# Remove captcha session
# @param captcha code generated by Authen::Captcha
# @return a constant
sub removeCaptcha {
    my ( $self, $ccode ) = @_;

    # Get captcha object
    my $captcha = Lemonldap::NG::Common::Captcha->new(
        {
            storageModule        => $self->{captchaStorage},
            storageModuleOptions => $self->{captchaStorageOptions},
            md5                  => $ccode,
            size                 => $self->{captcha_size},
        }
    );

    # Remove captcha session (will not be used anymore)
    if ( $captcha->removeSession ) {
        $self->lmLog( "Captcha session $ccode removed", 'debug' );
        return 0;
    }
    else {
        $self->lmLog( "Unable to remove captcha session $ccode", 'warn' );
        return 1;
    }
}

## @method boolean isTrustedUrl(string url)
# Check if an URL's domain name is declared in LL::NG config or is declared as trusted domain
# @param url Parameter url
# @param value Parameter value
# @return 1 if url can be trusted, 0 else
sub isTrustedUrl {
    my ( $self, $url ) = @_;
    return
         $url =~ m#^https?://$self->{reVHosts}(:\d+)?/#o
      || $self->{trustedDomains} eq "*"
      || $self->{trustedDomains}
      && $url =~ m#^https?://$self->{trustedDomains}(:\d+)?/#o;
}

## @method boolean checkXSSAttack(string name, string value)
# Check value to detect XSS attack
# @param name Parameter name
# @param value Parameter value
# @return 1 if attack detected, 0 else
sub checkXSSAttack {
    my ( $self, $name, $value ) = @_;

    # Empty values are not bad
    return 0 unless $value;

    # Test value
    $value =~ s/\%25/\%/g;
    if ( $value =~ m/(?:\0|<|'|"|`|\%(?:00|3C|22|27|2C))/ ) {
        $self->lmLog( "XSS attack detected (param: $name | value: $value)",
            "warn" );
        return $self->{checkXSS};
    }

    return 0;
}

=begin WSDL

_IN lang $string Language
_IN code $int Error code
_RETURN $string Error string

=end WSDL

=cut

##@method string msg(int code)
# calls Portal/_i18n.pm to display message in the client's language.
#@param $code message code
#@return message
sub msg {
    my $self = shift;
    my $code = shift;
    return &Lemonldap::NG::Portal::_i18n::msg( $code, $self->{lang} );
}

##@method string error(int code)
# calls Portal/_i18n.pm to display error in the client's language.
#@param $code optional error code
#@return error message
sub error {
    my $self = shift;
    my $code = shift || $self->{error};
    if ( my $lang = shift ) {    # only for SOAP error requests
        $self->{lang} = $self->extract_lang($lang);
    }
    my $msg;

    # Check for customized message
    foreach ( @{ $self->{lang} } ) {
        if ( $self->{ "error_" . $_ . "_" . $code } ) {
            $msg = $self->{ "error_" . $_ . "_" . $code };
            last;
        }
    }
    $msg ||= $self->{ "error_" . $code };

    # Use customized message or built-in message
    if ( defined $msg ) {

        # Manage UTF-8
        utf8::decode($msg);

        $self->lmLog( "Use customized message $msg for error $code", 'debug' );
    }
    else {
        $msg = &Lemonldap::NG::Portal::_i18n::error( $code, $self->{lang} );
    }

    # Return message
    # Manage SOAP
    return $msg;
}

##@method string error_type(int code)
# error_type tells if error is positive, warning or negative
# @param $code Lemonldap::NG error code
# @return "positive", "warning" or "negative"
sub error_type {
    my $self = shift;
    my $code = shift || $self->{error};

    # Positive errors
    return "positive"
      if (
        scalar(
            grep { /^$code$/ } (
                PE_REDIRECT,        PE_DONE,
                PE_OK,              PE_PASSWORD_OK,
                PE_MAILOK,          PE_LOGOUT_OK,
                PE_MAILFIRSTACCESS, PE_PASSWORDFIRSTACCESS,
                PE_MAILCONFIRMOK,   PE_REGISTERFIRSTACCESS,
            )
        )
      );

    # Warning errors
    return "warning"
      if (
        scalar(
            grep { /^$code$/ } (
                PE_INFO,                          PE_SESSIONEXPIRED,
                PE_FORMEMPTY,                     PE_FIRSTACCESS,
                PE_PP_GRACE,                      PE_PP_EXP_WARNING,
                PE_NOTIFICATION,                  PE_BADURL,
                PE_CONFIRM,                       PE_MAILFORMEMPTY,
                PE_MAILCONFIRMATION_ALREADY_SENT, PE_PASSWORDFORMEMPTY,
                PE_CAPTCHAEMPTY,                  PE_REGISTERFORMEMPTY,
            )
        )
      );

    # Negative errors (default)
    return "negative";
}

##@method void header()
# Overload CGI::header() to add Lemonldap::NG cookie.
sub header {
    my $self = shift;
    unshift @_, '-type' unless ($#_);
    if ( $self->{cookie} ) {
        $self->SUPER::header( @_, -cookie => $self->{cookie} );
    }
    else {
        $self->SUPER::header(@_);
    }
}

##@method void redirect()
# Overload CGI::redirect() to add Lemonldap::NG cookie.
sub redirect {
    my $self = shift;
    if ( $self->{cookie} ) {
        $self->SUPER::redirect( @_, -cookie => $self->{cookie} );
    }
    else {
        $self->SUPER::redirect(@_);
    }
}

## @method protected hashref getApacheSession(string id, boolean noInfo)
# Try to recover the session corresponding to id and return session datas.
# If $id is set to undef, return a new session.
# @param id session reference
# @param noInfo do not set Apache REMOTE_USER
# return Lemonldap::NG::Common::Session object
sub getApacheSession {
    my ( $self, $id, $noInfo ) = @_;

    my $apacheSession = Lemonldap::NG::Common::Session->new(
        {
            storageModule        => $self->{globalStorage},
            storageModuleOptions => $self->{globalStorageOptions},
            cacheModule          => $self->{localSessionStorage},
            cacheModuleOptions   => $self->{localSessionStorageOptions},
            id                   => $id,
            kind                 => "SSO",
        }
    );

    if ( $apacheSession->error ) {
        $self->lmLog( $apacheSession->error, 'debug' );
        return;
    }

    unless ($noInfo) {
        $self->setApacheUser( $apacheSession->data->{ $self->{whatToTrace} } )
          if ($id);
        $self->{id} = $apacheSession->id;
    }
    return $apacheSession;
}

## @method protected hashref getPersistentSession(string id)
# Try to recover the persitent session corresponding to id and return session datas.
# If $id is set to undef, return a new session.
# @param id session reference
# return Lemonldap::NG::Common::Session object
sub getPersistentSession {
    my ( $self, $id ) = @_;

    my $persistentSession = Lemonldap::NG::Common::Session->new(
        {
            storageModule        => $self->{persistentStorage},
            storageModuleOptions => $self->{persistentStorageOptions},
            id                   => $id,
            force                => 1,
            kind                 => "Persistent",
        }
    );

    if ( $persistentSession->error ) {
        $self->lmLog( $persistentSession->error, 'debug' );
    }

    return $persistentSession;
}

## @method protected string _md5hash(string s)
# Return md5(s)
# @param $s String to hash
# @return hashed value
sub _md5hash {
    my ( $self, $s ) = @_;
    return substr( Digest::MD5::md5_hex($s), 0, 32 );
}

## @method void updatePersistentSession(hashRef infos, string uid, string id)
# Update persistent session.
# Call updateSession() and store %$infos in a persistent session.
# Note that if the session does not exists, it will be created.
# @param infos hash reference of information to update
# @param uid optional Unhashed persistent session ID
# @param id optional SSO session ID
# @return nothing
sub updatePersistentSession {
    my ( $self, $infos, $uid, $id ) = @_;

    # Return if no infos to update
    return () unless ( ref $infos eq 'HASH' and %$infos );

    # Update current session
    $self->updateSession( $infos, $id );

    $uid ||= $self->{sessionInfo}->{ $self->{whatToTrace} };
    return () unless ($uid);

    my $persistentSession =
      $self->getPersistentSession( $self->_md5hash($uid) );

    $persistentSession->update($infos);

    if ( $persistentSession->error ) {
        $self->lmLog(
            "Cannot update persistent session " . $self->_md5hash($uid),
            'error' );
        $self->lmLog( $persistentSession->error, 'error' );
    }

}

## @method void updateSession(hashRef infos, string id)
# Update session stored.
# If no id is given, try to get it from cookie.
# If the session is available, update datas with $info.
# Note that outdated session data may remain some time on
# server local cache, if there are several LL::NG servers.
# @param infos hash reference of information to update
# @param id Session ID
# @return nothing
sub updateSession {
    my ( $self, $infos, $id ) = @_;

    # Return if no infos to update
    return () unless ( ref $infos eq 'HASH' and %$infos );

    # Recover session ID unless given
    $id ||= $self->{id};
    unless ($id) {
        my %cookies = fetch CGI::Cookie;
        $id ||= $cookies{ $self->{cookieName} }->value
          if ( defined $cookies{ $self->{cookieName} } );
    }

    if ($id) {

        # Update sessionInfo data
        ## sessionInfo updated if $id defined : quite strange !!
        ## See http://jira.ow2.org/browse/LEMONLDAP-430
        foreach ( keys %$infos ) {
            $self->lmLog( "Update sessionInfo $_ with " . $infos->{$_},
                'debug' );
            $self->{sessionInfo}->{$_} = $infos->{$_};
        }

        # Update session in global storage
        if ( my $apacheSession = $self->getApacheSession( $id, 1 ) ) {

            # Store updateTime
            $infos->{updateTime} = strftime( "%Y%m%d%H%M%S", localtime() );

            # Store/update session values
            $apacheSession->update($infos);

            if ( $apacheSession->error ) {
                $self->lmLog( "Cannot update session $id", 'error' );
                $self->lmLog( $apacheSession->error,       'error' );
            }
        }
    }
}

## @method void addSessionValue(string key, string value, string id)
# Add a value into session key if not already present
# @param key Session key
# @param value Value to add
# @param id optional Session identifier
sub addSessionValue {
    my ( $self, $key, $value, $id ) = @_;

    # Mandatory parameters
    return () unless defined $key;
    return () unless defined $value;

    # Get current key value
    my $old_value = $self->{sessionInfo}->{$key};

    # Split old values
    if ( defined $old_value ) {
        my @old_values = split /\Q$self->{multiValuesSeparator}\E/, $old_value;

        # Do nothing if value already exists
        foreach (@old_values) {
            return () if ( $_ eq $value );
        }

        # Add separator
        $old_value .= $self->{multiValuesSeparator};
    }
    else {
        $old_value = "";
    }

    # Store new value
    my $new_value = $old_value . $value;
    $self->updateSession( { $key => $new_value }, $id );

    # Return
    return ();
}

## @method string getFirstValue(string value)
# Get the first value of a multivaluated session value
# @param value the complete value
# @return first value
sub getFirstValue {
    my ( $self, $value ) = @_;

    my @values = split /\Q$self->{multiValuesSeparator}\E/, $value;

    return $values[0];
}

##@method protected int _subProcess(array @subs)
# Execute methods until an error is returned.
# If $self->{$sub} exists, launch it, else launch $self->$sub
#@param @subs array list of subroutines
#@return Lemonldap::NG::Portal error
sub _subProcess {
    my $self = shift;
    my @subs = @_;
    my $err  = undef;

    foreach my $sub (@subs) {
        last if ( $err = $self->_sub($sub) );
    }
    return $err;
}

##@method protected void updateStatus()
# Inform status mechanism module.
# If an handler is launched on the same server with "status=>1", inform the
# status module with the result (portal error).
sub updateStatus {
    my $self = shift;
    print $Lemonldap::NG::Handler::Simple::statusPipe (
        $self->{user} ? $self->{user} : $self->ipAddr )
      . " => $ENV{SERVER_NAME}$ENV{SCRIPT_NAME} "
      . $self->{error} . "\n"
      if ($Lemonldap::NG::Handler::Simple::statusPipe);
}

##@method protected string notification()
#@return Notification stored by checkNotification()
sub notification {
    my $self = shift;
    return $self->{_notification};
}

##@method protected string get_url()
# Return url parameter
# @return url parameter if good, nothing else.
sub get_url {
    my $self = shift;
    return $self->{_url};
}

##@method protected string get_user()
# Return user parameter
# @return user parameter if good, nothing else.
sub get_user {
    my $self = shift;

    return undef unless $self->{user};
    unless ( $self->{user} =~ /$self->{userControl}/o ) {
        $self->lmLog(
            "Value "
              . $self->{user}
              . " does not match userControl regexp: "
              . $self->{userControl},
            'warn'
        );
        return undef;
    }

    return $self->{user};
}

## @method string get_module(string type)
# Return current used module
# @param type auth/user/password/issuer
# @return module name
sub get_module {
    my ( $self, $type ) = @_;

    if ( $type =~ /auth/i ) {
        if ( defined $self->{_multi}->{stack}->[0] ) {
            return $self->{_multi}->{stack}->[0]->[0]->{s};
        }
        if ( defined $self->{_choice}->{modules} ) {
            return $self->{_choice}->{modules}->[0]->{n};
        }
        else {
            return $self->{authentication};
        }
    }

    if ( $type =~ /user/i ) {
        if ( defined $self->{_multi}->{stack}->[1] ) {
            return $self->{_multi}->{stack}->[1]->[0]->{s};
        }
        if ( defined $self->{_choice}->{modules} ) {
            return $self->{_choice}->{modules}->[1]->{n};
        }
        else {
            return $self->{userDB};
        }
    }

    if ( $type =~ /password/i ) {
        if ( defined $self->{_choice}->{modules} ) {
            return $self->{_choice}->{modules}->[2]->{n};
        }
        else {
            return $self->{passwordDB};
        }
    }

    if ( $type =~ /issuer/i ) {
        return $self->{_activeIssuerDB};
    }

    return;
}

##@method private Safe safe()
# Provide the security jail.
#@return Safe object
sub safe {
    my $self = shift;

    # Test if safe already exists
    if ($safe) {

        # Refresh the portal object inside it
        $safe->{p} = $self;

        # Refresh environment variables
        $safe->share_from( 'main', ['%ENV'] );

        return $safe;
    }

    # Else create it
    $safe = Lemonldap::NG::Common::Safe->new($self);

    # Get custom functions
    my @t =
      $self->{customFunctions}
      ? split( /\s+/, $self->{customFunctions} )
      : ();
    foreach (@t) {
        my $sub = $_;
        unless (/::/) {
            $sub = ref($self) . "::$_";
        }
        else {
            s/^.*:://;
        }
        next if ( $self->can($_) );
        eval "sub $_ {
                return $sub( '$self->{portal}', \@_ );
            }";
        $self->lmLog( $@, 'error' ) if ($@);
    }

    # Share %ENV
    $safe->share_from( 'main', ['%ENV'] );

    # Share Safelib
    $safe->share_from( 'Lemonldap::NG::Common::Safelib',
        $Lemonldap::NG::Common::Safelib::functions );

    # Share custom functions and &encode_base64
    $safe->share( '&encode_base64', @t );

    return $safe;
}

##@method private boolean _deleteSession(Lemonldap::NG::Common::Session session, boolean preserveCookie)
# Delete an existing session. If "securedCookie" is set to 2, the http session
# will also be removed.
# @param h tied Apache::Session object
# @param preserveCookie do not delete cookie
# @return True if session has been deleted
sub _deleteSession {
    my ( $self, $session, $preserveCookie ) = @_;

    # Invalidate http cookie and session, if set
    if ( $self->{securedCookie} >= 2 ) {

        # Try to find a linked http session (securedCookie == 2)
        if ( $self->{securedCookie} == 2
            and my $id2 = $session->data->{_httpSession} )
        {
            if ( my $session2 = $self->getApacheSession( $id2, 1 ) ) {
                $session2->remove;
                if ( $session2->error ) {
                    $self->lmLog( "Unable to remove linked session $id2",
                        'debug' );
                    $self->lmLog( $session2->error, 'debug' );
                }
            }
        }

        # Create an obsolete cookie to remove it
        push @{ $self->{cookie} },
          $self->cookie(
            -name    => $self->{cookieName} . 'http',
            -value   => 0,
            -domain  => $self->{domain},
            -path    => "/",
            -secure  => 0,
            -expires => '-1d',
            @_,
          ) unless ($preserveCookie);
    }

    $session->remove;

    # Create an obsolete cookie to remove it
    push @{ $self->{cookie} },
      $self->cookie(
        -name    => $self->{cookieName},
        -value   => 0,
        -domain  => $self->{domain},
        -path    => "/",
        -secure  => 0,
        -expires => '-1d',
        @_,
      ) unless ($preserveCookie);

    # Log
    my $user = $self->{sessionInfo}->{ $self->{whatToTrace} };
    $self->_sub( 'userNotice', "User $user has been disconnected" )
      if $user;

    return $session->error ? 0 : 1;
}

##@method private void _dump(void* variable)
# Dump variable in debug mode
# @param $variable
# @return void
sub _dump {
    my $self     = shift;
    my $variable = shift;

    require Data::Dumper;
    $Data::Dumper::Indent = 0;
    $self->lmLog( "Dump: " . Data::Dumper::Dumper($variable), 'debug' );

    return;
}

##@method protected string info(string t)
# Get or set info to display to the user.
# @param $t optional text to store
# @return HTML text to display
sub info {
    my ( $self, $t ) = @_;
    $self->{_info} .= $t if ( defined $t );
    return $self->{_info};
}

##@method protected string loginInfo(string t)
# Get or set info to display to the user on login screen
# @param $t optional text to store
# @return HTML text to display
sub loginInfo {
    my ( $self, $t ) = @_;
    $self->{_loginInfo} .= $t if ( defined $t );
    return $self->{_loginInfo};
}

##@method public void printImage(string file, string type)
# Print image to STDOUT
# @param $file The path to the file to print
# @param $type The content-type to use (ie: image/png)
# @return void
sub printImage {
    my ( $self, $file, $type ) = @_;
    binmode STDOUT;
    unless ( open( IMAGE, '<', $file ) ) {
        $self->lmLog( "Could not display image '$file'", 'error' );
        return;
    }
    print $self->header(
        $type . '; charset=utf-8; content-length=' . ( stat($file) )[10] );
    my $buffer = "";
    while ( read( IMAGE, $buffer, 4096 ) ) {
        print $buffer;
    }
    close(IMAGE);
}

sub stamp {
    my $self = shift;
    return $self->{cipher} ? $self->{cipher}->encrypt( time() ) : 1;
}

## @method string convertSec(int sec)
# Convert seconds to hours, minutes, seconds
# @param $sec number of seconds
# @return a formated time
sub convertSec {
    my ( $self, $sec ) = @_;
    my ( $day, $hrs, $min ) = ( 0, 0, 0 );

    # Calculate the minutes
    if ( $sec > 60 ) {
        $min = $sec / 60, $sec %= 60;
        $min = int($min);
    }

    # Calculate the hours
    if ( $min > 60 ) {
        $hrs = $min / 60, $min %= 60;
        $hrs = int($hrs);
    }

    # Calculate the days
    if ( $hrs > 24 ) {
        $day = $hrs / 24, $hrs %= 24;
        $day = int($day);
    }

    # Return the date
    return ( $day, $hrs, $min, $sec );
}

## @method string getSkin()
# Return skin name
# @return skin name
sub getSkin {
    my ($self) = @_;

    my $skin = $self->{portalSkin};

    # Fill sessionInfo to eval rule if empty (unauthenticated user)
    $self->{sessionInfo}->{_url}   ||= $self->{urldc};
    $self->{sessionInfo}->{ipAddr} ||= $self->ipAddr;

    # Load specific skin from skinRules
    if ( $self->{portalSkinRules} ) {
        foreach my $skinRule ( sort keys %{ $self->{portalSkinRules} } ) {
            if ( $self->safe->reval($skinRule) ) {
                $skin = $self->{portalSkinRules}->{$skinRule};
                $self->lmLog( "Skin $skin selected from skin rule", 'debug' );
            }
        }
    }

    # Check skin GET/POST parameter
    my $skinParam = $self->param('skin');
    if ( defined $skinParam && !$self->checkXSSAttack( 'skin', $skinParam ) ) {
        $skin = $skinParam;
        $self->lmLog( "Skin $skin selected from GET/POST parameter", 'debug' );
    }

    return $skin;
}

###############################################################
# MAIN subroutine: call all steps until one returns something #
#                  different than PE_OK                       #
###############################################################

##@method boolean process()
# Main method calling functions issued from:
#  - itself:
#    - controlUrlOrigin
#    - checkNotifBack
#    - controlExistingSession
#    - setMacros
#    - setLocalGroups
#    - setPersistentSessionInfo
#    - removeOther
#    - grantSession
#    - store
#    - buildCookie
#    - checkNotification
#    - autoRedirect
#    - updateStatus
#  - authentication module:
#    - authInit
#    - extractFormInfo
#    - setAuthSessionInfo
#    - authenticate
#    - authFinish
#    - authPostStore
#  - userDB module:
#    - userDBInit
#    - getUser
#    - setSessionInfo
#    - setGroups
#  - passwordDB module:
#    - passwordDBInit
#    - modifyPassword
#  - issuerDB module:
#    - issuerDBInit
#    - issuerForUnAuthUser
#    - issuerForAuthUser
#  - MailReset:
#    - sendPasswordMail
#
#@return 1 if all is OK, 0 if session isn't created or a notification has to be done
sub process {
    my ($self) = @_;
    $self->{error} = PE_OK;
    $self->{error} = $self->_subProcess(
        qw(controlUrlOrigin checkNotifBack controlExistingSession
          issuerDBInit authInit issuerForUnAuthUser extractFormInfo
          userDBInit getUser setAuthSessionInfo passwordDBInit
          modifyPassword setSessionInfo setMacros setGroups
          setPersistentSessionInfo setLocalGroups sendPasswordMail
          authenticate authFinish userDBFinish passwordDBFinish
          grantSession removeOther store authPostStore buildCookie
          checkNotification issuerForAuthUser autoRedirect)
    );
    $self->updateStatus;
    return ( ( $self->{error} > 0 ) ? 0 : 1 );
}

##@apmethod int controlUrlOrigin()
# If the user was redirected here, loads 'url' parameter.
# Check also confirm parameter.
#@return Lemonldap::NG::Portal constant
sub controlUrlOrigin {
    my $self = shift;
    if ( my $c = $self->param('confirm') ) {

        # Replace confirm stamp by 1 or -1
        $c =~ s/^(-?)(.*)$/${1}1/;

        # Decrypt confirm stamp if cipher available
        # and confirm not already decrypted
        if ( $self->{cipher} and $2 ne "1" ) {
            my $time = time() - $self->{cipher}->decrypt($2);
            if ( $time < 600 ) {
                $self->lmLog( "Confirm parameter accepted $c", 'debug' );
                $self->param( 'confirm', $c );
            }
            else {
                $self->lmLog( 'Confirmation to old, refused', 'notice' );
                $self->param( 'confirm', 0 );
            }
        }
    }
    $self->{_url} ||= '';
    if ( my $url = $self->param('url') ) {

        # REJECT NON BASE64 URL except for CAS IssuerDB
        if ( $self->get_module('issuer') ne "CAS" ) {
            if ( $url =~ m#[^A-Za-z0-9\+/=]# ) {
                $self->lmLog(
                    "Value must be in BASE64 (param: url | value: $url)",
                    "warn" );
                return PE_BADURL;
            }

            $self->{urldc} = decode_base64($url);
            $self->{urldc} =~ s/[\r\n]//sg;
        }
        else { $self->{urldc} = $url; }

        # For logout request, test if Referer comes from an authorizated site
        my $tmp =
          ( $self->param('logout') ? $ENV{HTTP_REFERER} : $self->{urldc} );

        # XSS attack
        if (
            $self->checkXSSAttack(
                $self->param('logout') ? 'HTTP Referer' : 'urldc',
                $self->{urldc}
            )
          )
        {
            delete $self->{urldc};
            return PE_BADURL;
        }

        # Non protected hosts
        if ( $tmp and !$self->isTrustedUrl($tmp) ) {
            $self->lmLog(
                "URL contains a non protected host (param: "
                  . ( $self->param('logout') ? 'HTTP Referer' : 'urldc' )
                  . " | value: $tmp)",
                "warn"
            );
            delete $self->{urldc};
            return PE_BADURL;
        }

        $self->{_url} = $url;
    }

    PE_OK;
}

##@apmethod int checkNotifBack()
# Checks if a message has been notified to the connected user.
# Call Lemonldap::NG::Common::Notification::checkNotification()
#@return Lemonldap::NG::Portal error code
sub checkNotifBack {
    my $self = shift;
    if ( $self->{notification} and grep( /^reference/, $self->param() ) ) {
        $self->lmLog( "User was on a notification step", 'debug' );
        unless ( $self->{notifObject}->checkNotification($self) ) {
            $self->lmLog(
                "All notifications have not been accepted, display them again",
                'debug'
            );
            $self->{_notification} =
              $self->{notifObject}->getNotification($self);
            return PE_NOTIFICATION;
        }
        else {
            $self->lmLog(
"All notifications have been accepted, follow the authentication process",
                'debug'
            );
            $self->{error} = $self->_subProcess(
                qw(issuerDBInit authInit issuerForAuthUser authFinish autoRedirect)
            );
            return $self->{error} || PE_DONE;
        }
    }
    PE_OK;
}

##@apmethod int controlExistingSession(string id)
# Control existing sessions.
# To overload to control what to do with existing sessions.
# what to do with existing sessions ?
#       - nothing: user is authenticated and process returns true (default)
#       - delete and create a new session (not implemented)
#       - re-authentication (set portalForceAuthn to 1)
#@param $id optional value of the session-id else cookies are examinated.
#@return Lemonldap::NG::Portal constant
sub controlExistingSession {
    my ( $self, $id ) = @_;
    my %cookies;
    %cookies = fetch CGI::Cookie unless ($id);

    # Special request "display captcha"
    if ( $self->param("displayCaptcha") ) {

        my $captcha = Lemonldap::NG::Common::Captcha->new(
            {
                storageModule        => $self->{captchaStorage},
                storageModuleOptions => $self->{captchaStorageOptions},
                md5                  => $self->param("displayCaptcha"),
                size                 => $self->{captcha_size},
            }
        );

        if ( $captcha && $captcha->image ) {
            binmode STDOUT;
            print $self->header( 'image/png'
                  . '; charset=utf-8; content-length='
                  . length( $captcha->image ) );
            print $captcha->image;
        }
        $self->quit();
    }

    # Test if Lemonldap::NG cookie is available
    if (
        $id
        or (    $cookies{ $self->{cookieName} }
            and $id = $cookies{ $self->{cookieName} }->value )
      )
    {
        my $apacheSession = $self->getApacheSession($id);

        if ($apacheSession) {
            %{ $self->{sessionInfo} } = %{ $apacheSession->data };

            # Logout if required
            if ( $self->param('logout') ) {

                # Delete session
                unless ( $self->_deleteSession($apacheSession) ) {
                    $self->lmLog( "Unable to delete session $id", 'error' );
                    $self->lmLog( $apacheSession->error,          'error' );
                    return PE_ERROR;
                }
                else {
                    $self->lmLog( "Session $id deleted from global storage",
                        'debug' );
                }

                # Call issuerDB logout on each used issuerDBmodule
                my $issuerDBList = $self->{sessionInfo}->{_issuerDB};
                if ( defined $issuerDBList ) {
                    foreach my $issuerDBtype (
                        split(
                            /\Q$self->{multiValuesSeparator}\E/,
                            $issuerDBList
                        )
                      )
                    {
                        my $module_name =
                          'Lemonldap::NG::Portal::IssuerDB' . $issuerDBtype;

                        $self->lmLog(
                            "Process logout for issuerDB module $issuerDBtype",
                            'debug'
                        );

                        # Load current IssuerDB module
                        unless ( $self->loadModule($module_name) ) {
                            $self->lmLog( "Unable to load $module_name",
                                'error' );
                            next;
                        }

                        $self->{error} = $self->_subProcess(
                            $module_name . "::issuerDBInit",
                            $module_name . '::issuerLogout'
                        );

                    }
                }

                # Call logout for the module used to authenticate
                $self->lmLog(
                    "Process logout for authentication module "
                      . $self->{sessionInfo}->{_auth},
                    'debug'
                );

                if ( $self->{sessionInfo}->{'_auth'} ne
                    $self->get_module('auth') )
                {
                    my $module_name = 'Lemonldap::NG::Portal::Auth'
                      . $self->{sessionInfo}->{_auth};

                    unless ( $self->loadModule($module_name) ) {
                        $self->lmLog( "Unable to load $module_name", 'error' );
                    }
                    else {
                        eval {
                            $self->{error} = $self->_subProcess(
                                $module_name . "::authInit",
                                $module_name . "::authLogout"
                            );
                        };
                    }
                }
                else {
                    eval {
                        $self->{error} =
                          $self->_subProcess( 'authInit', 'authLogout' );
                    };
                }
                if ($@) {
                    $self->lmLog(
                        "Error when calling authentication logout: $@",
                        'debug' );
                }
                return $self->{error} if $self->{error} > 0;

                # Collect logout services and build hidden iFrames
                if ( %{ $self->{logoutServices} } ) {

                    $self->lmLog(
                        "Create iFrames to forward logout to services",
                        'debug' );

                    $self->info( "<h3>" . $self->msg(PM_LOGOUT) . "</h3>" );

                    foreach ( keys %{ $self->{logoutServices} } ) {
                        my $logoutServiceName = $_;
                        my $logoutServiceUrl =
                          $self->{logoutServices}->{$logoutServiceName};

                        $self->lmLog(
"Find logout service $logoutServiceName ($logoutServiceUrl)",
                            'debug'
                        );

                        my $iframe =
                            "<iframe src=\"$logoutServiceUrl\""
                          . " alt=\"$logoutServiceName\" marginwidth=\"0\""
                          . " marginheight=\"0\" scrolling=\"no\" style=\"border: none;display: hidden;margin: 0\""
                          . " width=\"0\" height=\"0\" frameborder=\"0\">"
                          . "</iframe>";

                        $self->info($iframe);
                    }

                    # Redirect on logout page if no other target defined
                    if ( !$self->{urldc} and !$self->{postUrl} ) {
                        $self->{urldc} = $ENV{SCRIPT_NAME} . "?logout=1";
                    }
                }

                # Redirect or Post if asked by authLogout
                return $self->_subProcess(qw(autoRedirect))
                  if (  $self->{urldc}
                    and $self->{urldc} ne $self->{portal} );

                return $self->_subProcess(qw(autoPost))
                  if ( $self->{postUrl} );

                # Display logout message
                return PE_LOGOUT_OK;
            }

            # If the user wants to purge other sessions
            elsif ( $self->param('removeOther') ) {
                $self->{notifyDeleted} = 1;
                $self->{singleSession} = 1;
                $self->_sub( 'removeOther', $id );
            }

            # Special ajax request "ping" to check if session is available
            if ( $self->param('ping') ) {
                print $self->header( -type => 'application/json' )
                  . '{"auth":true}';
                $self->quit();
            }

            # Special ajax request "storeAppsListOrder"
            if ( $self->param('storeAppsListOrder') ) {
                my $order = $self->param('storeAppsListOrder');
                $self->lmLog( "Get new apps list order: $order", 'debug' );
                $self->updatePersistentSession( { appsListOrder => $order } );
                $self->quit();
            }

            $self->{id} = $id;

            # A session has been found => call existingSession
            my $r = $self->_sub( 'existingSession', $id, $self->{sessionInfo} );
            if ( $r == PE_DONE ) {
                $self->{error} = $self->_subProcess(
                    qw(checkNotification issuerDBInit authInit issuerForAuthUser authFinish autoRedirect)
                );
                return $self->{error} || PE_DONE;
            }
            else {
                return $r;
            }
        }
    }

    # Special ajax request "ping" to check if session is available
    if ( $self->param('ping') ) {
        print $self->header( -type => 'application/json' ) . '{"auth":false}';
        $self->quit();
    }

    # Display logout success if logout asked
    # and we do not have valid session
    return PE_LOGOUT_OK if $self->param('logout');

    # Else continue authentication process
    PE_OK;
}

## @method int existingSession()
# Launched by controlExistingSession() to know what to do with existing
# sessions.
# Can return:
# - PE_DONE: session is unchanged and process() return true
# - PE_OK: process() return false to display the form
#@return Lemonldap::NG::Portal constant
sub existingSession {
    my $self = shift;
    my $forceAuthn;

    # Check portalForceAuthn parameter
    # and authForce method
    eval { $forceAuthn = $self->_sub('authForce'); };
    if ($@) {
        $self->lmLog( "Error when calling authForce: $@", 'debug' );
    }

    $forceAuthn = 1 if ( $self->{portalForceAuthn} );

    if ($forceAuthn) {
        my $referer = $self->referer();
        my $id      = $self->{id};

        # Do not force authentication when password is modified
        return PE_DONE if $self->param('newpassword');

       # Do not force authentication if last successful authentication is recent
        my $last_authn_utime = $self->{sessionInfo}->{_lastAuthnUTime} || 0;
        if ( time() - $last_authn_utime < $self->{portalForceAuthnInterval} ) {
            $self->lmLog(
"Authentication is recent, so do not force authentication for session $id",
                'debug'
            );
            return PE_DONE;
        }

     # If coming from the portal follow the normal process to update the session
        if ( $referer ? ( $referer =~ m#$self->{portal}#i ) : 0 ) {
            $self->lmLog( "Portal referer detected for session $id", 'debug' );

            # Set flag to update session timestamp
            $self->{updateSession} = 1;

            # Process
            $self->{error} = $self->_subProcess(
                qw(issuerDBInit authInit issuerForUnAuthUser extractFormInfo
                  userDBInit getUser setAuthSessionInfo setSessionInfo
                  setMacros setGroups setPersistentSessionInfo
                  setLocalGroups authenticate authFinish userDBFinish store authPostStore)
            );
            return $self->{error} || PE_DONE;
        }
        else {
            $self->lmLog( "Force reauthentication for session $id", 'debug' );
            return PE_OK;
        }
    }

    # Else return PE_DONE
    PE_DONE;
}

# issuerDBInit(): must be implemented in IssuerDB* module

# authInit(): must be implemented in Auth* module

# issuerForUnAuthUser(): must be implemented in IssuerDB* module

##@apmethod int extractFormInfo()
# Extract data common to all authentication modules,
# and call extractFormInfo() in Auth* module
# Auth*::extractFormInfo set $self->{user} and in some cases
# authenticate user (done in authenticate() else)
#@return Lemonldap::NG::Portal constant
sub extractFormInfo {
    my $self = shift;
    return PE_OK if $self->{skipExtractFormInfo};
    $self->{checkLogins} = $self->param('checkLogins');
    return $self->SUPER::extractFormInfo;
}

# getUser(): must be implemented in UserDB* module

## @apmethod int setAuthSessionInfo()
# Set _auth
# call setAuthSessionInfo in Auth* module
#@return Lemonldap::NG::Portal constant
sub setAuthSessionInfo {
    my $self = shift;

    # Get the current authentication module
    $self->{sessionInfo}->{_auth} = $self->get_module("auth");

    return $self->SUPER::setAuthSessionInfo();
}

## @apmethod int passwordDBInit()
# Set _passwordDB
# call passwordDBInit in passwordDB* module
# @return Lemonldap::NG::Portal constant
sub passwordDBInit {
    my $self = shift;

    # Get the current password module
    $self->{sessionInfo}->{_passwordDB} = $self->get_module("password");

    return $self->SUPER::passwordDBInit();
}

## @apmethod int modifyPassword()
# Call modifyPassword from PasswordDB* module
# Continue auth process if password change is ok
# @return Lemonldap::NG::Portal constant
sub modifyPassword {
    my $self = shift;

    my $res = $self->SUPER::modifyPassword();

    if ( $res == PE_PASSWORD_OK ) {

        # Update password in session if needed
        $self->lmLog( "Update password in session for " . $self->{user},
            'debug' );

        my $infos;
        $infos->{_password} = $self->{newpassword};
        $self->updateSession($infos) if ( $self->{storePassword} );

        # Set a flag to ignore password change in Menu
        $self->{ignorePasswordChange} = 1;

        # Set a flag to allow sending a mail
        $self->{passwordWasChanged} = 1;

        #  Continue process if password change is ok
        return PE_OK;
    }

    return $res;
}

##@apmethod int setSessionInfo()
# Set ipAddr, startTime, updateTime, _utime and _userDB
# Call setSessionInfo() in UserDB* module
#@return Lemonldap::NG::Portal constant
sub setSessionInfo {
    my $self = shift;

    # Get the current user module
    $self->{sessionInfo}->{_userDB} = $self->get_module("user");

    # Store IP address from remote address or X-FORWARDED-FOR header
    $self->{sessionInfo}->{ipAddr} = $self->ipAddr;

    # Date and time
    if ( $self->{updateSession} ) {
        $self->{sessionInfo}->{updateTime} =
          strftime( "%Y%m%d%H%M%S", localtime() );
    }
    else {
        $self->{sessionInfo}->{_utime} ||= time();
        $self->{sessionInfo}->{startTime} =
          strftime( "%Y%m%d%H%M%S", localtime() );
    }

    # Get environment variables matching exportedVars
    foreach ( keys %{ $self->{exportedVars} } ) {
        if ( my $tmp = $ENV{ $self->{exportedVars}->{$_} } ) {
            $tmp =~ s/[\r\n]/ /gs;
            $self->{sessionInfo}->{$_} = $tmp;
            delete $self->{exportedVars}->{$_};
        }
    }

    # Store URL origin in session
    $self->{sessionInfo}->{_url} = $self->{urldc};

    # Call UserDB setSessionInfo
    if ( my $res = $self->SUPER::setSessionInfo() ) {
        return $res;
    }

    PE_OK;
}

##@apmethod int setMacros()
# Macro mechanism.
# * store macro results in $self->{sessionInfo}
#@return Lemonldap::NG::Portal constant
sub setMacros {
    my $self = shift;
    $self->{sessionInfo}->{groups} = '';
    $self->{sessionInfo}->{hGroups} = {};
    foreach ( sort keys %{ $self->{macros} } ) {
        $self->{sessionInfo}->{$_} =
          $self->safe->reval( $self->{macros}->{$_} );
    }
    PE_OK;
}

##@apmethod int setLocalGroups()
# Groups mechanism.
# * store all groups name that the user match in $self->{sessionInfo}->{groups}
#@return Lemonldap::NG::Portal constant
sub setLocalGroups {
    my $self = shift;
    foreach ( sort keys %{ $self->{groups} } ) {
        if ( $self->safe->reval( $self->{groups}->{$_} ) ) {
            $self->{sessionInfo}->{groups} .=
              $self->{multiValuesSeparator} . $_;
            $self->{sessionInfo}->{hGroups}->{$_}->{name} = $_;
        }
    }

    # Clear values separator at the beginning
    if ( $self->{sessionInfo}->{groups} ) {
        $self->{sessionInfo}->{groups} =~
          s/^\Q$self->{multiValuesSeparator}\E//;
    }
    PE_OK;
}

# setGroups(): must be implemented in UserDB* module

##@apmethod int setPersistentSessionInfo()
# Restore persistent session info
#@return Lemonldap::NG::Portal constant
sub setPersistentSessionInfo {
    my $self = shift;

    # Do not restore infos if session already opened
    unless ( $self->{id} ) {
        my $key = $self->{sessionInfo}->{ $self->{whatToTrace} };

        return PE_OK unless ( $key and length($key) );

        my $persistentSession =
          $self->getPersistentSession( $self->_md5hash($key) );

        if ($persistentSession) {
            $self->lmLog( "Persistent session found for $key", 'debug' );
            foreach my $k ( keys %{ $persistentSession->data } ) {

                # Do not restore some parameters
                next if $k =~ /^_session_id$/;
                next if $k =~ /^_session_kind$/;
                $self->lmLog( "Restore persistent parameter $k", 'debug' );
                $self->{sessionInfo}->{$k} = $persistentSession->data->{$k};
            }
        }
    }

    PE_OK;
}

## @apmethod sendPasswordMail
# Call sendPasswordMail from MailReset if option is configured
# @return Lemonldap::NG::Portal constant
sub sendPasswordMail {
    my $self = shift;

    if ( $self->{mailOnPasswordChange} && $self->{passwordWasChanged} ) {

        $self->lmLog( "Send password by mail requested", 'debug' );

        eval "require Lemonldap::NG::Portal::MailReset";
        &Lemonldap::NG::Portal::MailReset::smtpInit($self);
        &Lemonldap::NG::Portal::MailReset::sendPasswordMail($self);
    }

    # Never stop the process here
    return PE_OK;
}

##@apmethod int authenticate()
# Call authenticate() in Auth* module, and registerLogin()
# if authentication failed, userNotice() if it succeeded.
#@return Lemonldap::NG::Portal constant
sub authenticate {
    my $self = shift;
    if ( my $errorCode = $self->SUPER::authenticate() ) {
        $self->registerLogin($errorCode);
        return $errorCode;
    }

    # Log good authentication
    my $user = $self->{sessionInfo}->{ $self->{whatToTrace} };
    $self->_sub( 'userNotice',
        "Good authentication for $user by $self->{sessionInfo}->{_auth}" )
      if $user;

    # Set _lastAuthnUTime
    $self->{sessionInfo}->{_lastAuthnUTime} = time();

    PE_OK;
}

##@method registerLogin
# Store current login in login history
# @param $errorCode Code returned by authenticate()
sub registerLogin {
    my ( $self, $errorCode ) = @_;

    if ( $self->{loginHistoryEnabled} ) {
        my $history = $self->{sessionInfo}->{loginHistory} ||= {};

        my $type = ( $errorCode ? "failed" : "success" ) . "Login";
        $history->{$type} ||= [];
        $self->lmLog( "Current login saved into $type", "debug" );

        # Gather current login's parameters
        my $login = $self->_sumUpSession( $self->{sessionInfo}, 1 );
        $login->{error} = $self->error($errorCode)
          if ($errorCode);

        # Add current login into history
        unshift @{ $history->{$type} }, $login;

        # Forget oldest logins
        splice @{ $history->{$type} }, $self->{ $type . "Number" }
          if ( scalar @{ $history->{$type} } > $self->{ $type . "Number" } );

        # Save into persistent session
        $self->updatePersistentSession( { loginHistory => $history, } );
    }
}

##@apmethod int removeOther()
# check singleSession or singleIP parameters, and remove other sessions if needed
#@return Lemonldap::NG::Portal constant
sub removeOther {
    my ( $self, $current ) = @_;
    $self->{deleted}       = [];
    $self->{otherSessions} = [];

    my $moduleOptions = $self->{globalStorageOptions} || {};
    $moduleOptions->{backend} = $self->{globalStorage};
    my $module = "Lemonldap::NG::Common::Apache::Session";

    if (   $self->{singleSession}
        or $self->{singleIP}
        or $self->{notifyOther} )
    {
        my $sessions =
          $module->searchOn( $moduleOptions, $self->{whatToTrace},
            $self->{sessionInfo}->{ $self->{whatToTrace} } );
        foreach my $id ( keys %$sessions ) {
            next if ( $current and ( $current eq $id ) );
            my $session = $self->getApacheSession( $id, 1 ) or next;
            if (
                $self->{singleSession}
                or (    $self->{singleIP}
                    and $self->{sessionInfo}->{ipAddr} ne
                    $session->data->{ipAddr} )
              )
            {
                push @{ $self->{deleted} },
                  $self->_sumUpSession( $session->data );
                $self->_deleteSession( $session, 1 );
            }
            else {
                push @{ $self->{otherSessions} },
                  $self->_sumUpSession( $session->data );
            }
        }
    }
    if ( $self->{singleUserByIP} ) {
        my $sessions =
          $module->searchOn( $moduleOptions, 'ipAddr', $self->ipAddr );
        foreach my $id ( keys %$sessions ) {
            next if ( $current and $current eq $id );
            my $session = $self->getApacheSession( $id, 1 ) or next;
            unless ( $self->{sessionInfo}->{ $self->{whatToTrace} } eq
                $session->data->{ $self->{whatToTrace} } )
            {
                push @{ $self->{deleted} },
                  $self->_sumUpSession( $session->data );
                $self->_deleteSession( $session, 1 );
            }
        }
    }
    $self->info(
        $self->mkSessionArray(
            $self->{deleted}, $self->msg(PM_SESSIONS_DELETED), 1
        )
    ) if ( $self->{notifyDeleted} and @{ $self->{deleted} } );
    $self->info(
        $self->mkSessionArray( $self->{otherSessions},
            $self->msg(PM_OTHER_SESSIONS), 1 )
          . $self->_mkRemoveOtherLink()
    ) if ( $self->{notifyOther} and @{ $self->{otherSessions} } );

    $self->info(
        (
            $self->{sessionInfo}->{loginHistory}->{successLogin}
            ? $self->mkSessionArray(
                $self->{sessionInfo}->{loginHistory}->{successLogin},
                $self->msg(PM_LAST_LOGINS),
                0, 0
              )
            : ""
        )
        . (
            $self->{sessionInfo}->{loginHistory}->{failedLogin}
            ? $self->mkSessionArray(
                $self->{sessionInfo}->{loginHistory}->{failedLogin},
                $self->msg(PM_LAST_FAILED_LOGINS),
                0, 1
              )
            : ""
        )
    ) if ( $self->{checkLogins} );

    PE_OK;
}

##@method private hashref _sumUpSession(Lemonldap::NG::Common::Session session)
# put main session data into a hash ref
# @param hashref $session The session to sum up
# @return hashref
sub _sumUpSession {
    my ( $self, $session, $withoutUser ) = @_;
    my $res =
      $withoutUser
      ? {}
      : { user => $session->{ $self->{whatToTrace} } };
    $res->{$_} = $session->{$_}
      foreach ( "_utime", "ipAddr", keys %{ $self->{sessionDataToRemember} } );
    return $res;
}

##@method private string mkSessionArray(string title,array datas)
# Build an HTML array to display sessions
# @param $sessions Array ref of hash ref containing sessions datas
# @param $title Title of the array
# @param $displayUser To display "User" column
# @param $displaError To display "Error" column
# @return HTML string
sub mkSessionArray {
    my ( $self, $sessions, $title, $displayUser, $displayError ) = @_;

    return "" unless ( ref $sessions eq "ARRAY" and @$sessions );

    my $tmp = $title ? "<h3>$title</h3>" : "";
    $tmp .= "<table class=\"info\"><tbody>";

    $tmp .= "<tr>";
    $tmp .= "<th>" . $self->msg(PM_USER) . "</th>"
      if ($displayUser);
    $tmp .= "<th>" . $self->msg(PM_DATE) . "</th>";
    $tmp .= "<th>" . $self->msg(PM_IP) . "</th>";
    $tmp .= "<th>" . $self->{sessionDataToRemember}->{$_} . "</th>"
      foreach ( keys %{ $self->{sessionDataToRemember} } );
    $tmp .= '<th>' . $self->msg(PM_ERROR_MSG) . '</th>'
      if ($displayError);
    $tmp .= '</tr>';

    foreach my $session (@$sessions) {
        $tmp .= "<tr>";
        $tmp .= "<td>$session->{user}</td>" if ($displayUser);
        $tmp .=
"<td><script type=\"text/javascript\">var _date=new Date($session->{_utime}*1000);document.write(_date.toLocaleString());</script></td>";
        $tmp .= "<td>$session->{ipAddr}</td>";
        $tmp .= "<td>" . ( $session->{$_} || "" ) . "</td>"
          foreach ( keys %{ $self->{sessionDataToRemember} } );
        $tmp .= "<td>$session->{error}</td>" if ($displayError);
        $tmp .= "</tr>";
    }
    $tmp .= '</tbody></table>';
    return $tmp;
}

## @method private string _mkRemoveOtherLink()
# Build the removeOther link
# Last part of URL is built trough javascript
# @return removeOther link in HTML code
sub _mkRemoveOtherLink {
    my $self = shift;

    my $link = $self->{portal} . "?removeOther=1";

    return
        "<p class=\"removeOther\"><a href=\"$link\" onclick=\"_go=0\">"
      . $self->msg(PM_REMOVE_OTHER_SESSIONS)
      . "</a></p>";
}

##@apmethod int grantSession()
# Check grantSessionRule to allow session creation.
#@return Lemonldap::NG::Portal constant
sub grantSession {
    my ($self) = @_;

    if ( defined $self->{grantSessionRule} ) {

        # Eval grantSessionRule
        # Kept for backward compatibility with LL::NG 1.1.2 and previous
        my $grantSessionRule = $self->{grantSessionRule};

        unless ( $self->safe->reval($grantSessionRule) ) {
            $self->lmLog(
                "User " . $self->{user} . " was not granted to open session",
                'error' );
            $self->registerLogin(PE_SESSIONNOTGRANTED);
            return PE_SESSIONNOTGRANTED;
        }
    }

    # Eval grantSessionRules sorted by comments
    sub sortByComment {
        my $A = ( $a =~ /^.*?##(.*)$/ )[0];
        my $B = ( $b =~ /^.*?##(.*)$/ )[0];
        return !$A ? 1 : !$B ? -1 : $A cmp $B;
    }
    foreach ( sort sortByComment keys %{ $self->{grantSessionRules} } ) {
        $self->lmLog( "Grant session condition \"$_\" checked", "debug" );
        unless ( $self->safe->reval($_) ) {
            $self->lmLog(
                "User " . $self->{user} . " was not granted to open session",
                'error' );
            my $msg = $self->safe->reval( $self->{grantSessionRules}->{$_} );
            $msg = $self->{grantSessionRules}->{$_} if ($@);
            $self->{ "error_" . PE_SESSIONNOTGRANTED } = $msg if ($msg);
            $self->registerLogin(PE_SESSIONNOTGRANTED);
            return PE_SESSIONNOTGRANTED;
        }
    }

    my $user = $self->{sessionInfo}->{ $self->{whatToTrace} };
    $self->_sub( 'userNotice', "Session granted for $user" ) if ($user);
    $self->registerLogin(PE_OK);
    return PE_OK;
}

##@apmethod int store()
# Store user's datas in sessions database.
# Now, the user is known, authenticated and session variable are evaluated.
# It's time to store his parameters with Apache::Session::* module
#@return Lemonldap::NG::Portal constant
sub store {
    my ($self) = @_;

    # Now, user is authenticated => inform Apache
    $self->setApacheUser( $self->{sessionInfo}->{ $self->{whatToTrace} } );

    # Create second session for unsecure cookie
    if ( $self->{securedCookie} == 2 ) {
        my $session2 = $self->getApacheSession( undef, 1 );

        my %infos = %{ $self->{sessionInfo} };
        $infos{_httpSessionType} = 1;

        $session2->update( \%infos );

        $self->{sessionInfo}->{_httpSession} = $session2->id;
    }

    # Main session
    my $session = $self->getApacheSession( $self->{id} );
    return PE_APACHESESSIONERROR unless ($session);

    # Compute unsecure cookie value if needed
    if ( $self->{securedCookie} == 3 ) {
        $self->{sessionInfo}->{_httpSession} =
          $self->{cipher}->encryptHex( $self->{id}, "http" );
    }

    # Fill session
    my $infos = {};
    foreach my $k ( keys %{ $self->{sessionInfo} } ) {
        next unless defined $self->{sessionInfo}->{$k};
        my $displayValue = $self->{sessionInfo}->{$k};
        if ( $self->{hiddenAttributes} =~ /\b$k\b/ ) {
            $displayValue = '****';
        }
        $self->lmLog( "Store $displayValue in session key $k", 'debug' );
        $self->_dump($displayValue) if ref($displayValue);
        $infos->{$k} = $self->{sessionInfo}->{$k};
    }
    $session->update($infos);

    PE_OK;
}

## @apmethod int authFinish
# Call authFinish method from authentication module
# @return Lemonldap::NG::Portal constant
sub authFinish {
    my $self = shift;

    # Remove captcha session
    if ( $self->{captcha_check_code} ) {
        $self->removeCaptcha( $self->{captcha_check_code} );
    }

    eval { $self->{error} = $self->SUPER::authFinish; };
    if ($@) {
        $self->lmLog(
"Optional authFinish method not defined in current authentication module: $@",
            'debug'
        );
        return PE_OK;
    }

    return $self->{error};
}

## @apmethod int authPostStore
# Call authPostStore method from authentication module
# @return Lemonldap::NG::Portal constant
sub authPostStore {
    my $self = shift;

    eval { $self->{error} = $self->SUPER::authPostStore; };
    if ($@) {
        $self->lmLog(
"Optional authPostStore method not defined in current authentication module: $@",
            'debug'
        );
        return PE_OK;
    }

    return $self->{error};
}

## @apmethod int userDBFinish
# Call userDBFinish method from userDB module
# @return Lemonldap::NG::Portal constant
sub userDBFinish {
    my $self = shift;

    eval { $self->{error} = $self->SUPER::userDBFinish; };
    if ($@) {
        $self->lmLog(
"Optional userDBFinish method not defined in current userDB module: $@",
            'debug'
        );
        return PE_OK;
    }

    return $self->{error};
}

## @apmethod int passwordDBFinish
# Call passwordDBFinish method from passwordDB module
# @return Lemonldap::NG::Portal constant
sub passwordDBFinish {
    my $self = shift;

    eval { $self->{error} = $self->SUPER::passwordDBFinish; };
    if ($@) {
        $self->lmLog(
"Optional passwordDBFinish method not defined in current passwordDB module: $@",
            'debug'
        );
        return PE_OK;
    }

    return $self->{error};
}

##@apmethod int buildCookie()
# Build the Lemonldap::NG cookie.
#@return Lemonldap::NG::Portal constant
sub buildCookie {
    my $self = shift;
    push @{ $self->{cookie} },
      $self->cookie(
        -name     => $self->{cookieName},
        -value    => $self->{id},
        -domain   => $self->{domain},
        -path     => "/",
        -secure   => $self->{securedCookie},
        -httponly => $self->{httpOnly},
        -expires  => $self->{cookieExpiration},
        @_,
      );
    if ( $self->{securedCookie} >= 2 ) {
        push @{ $self->{cookie} },
          $self->cookie(
            -name     => $self->{cookieName} . "http",
            -value    => $self->{sessionInfo}->{_httpSession},
            -domain   => $self->{domain},
            -path     => "/",
            -secure   => 0,
            -httponly => $self->{httpOnly},
            -expires  => $self->{cookieExpiration},
            @_,
          );
    }
    PE_OK;
}

##@apmethod int checkNotification()
# Check if messages has to be notified.
# Call Lemonldap::NG::Common::Notification::getNotification().
#@return Lemonldap::NG::Portal constant
sub checkNotification {
    my $self = shift;
    if (    $self->{notification}
        and $self->{_notification} ||=
        $self->{notifObject}->getNotification($self) )
    {
        return PE_NOTIFICATION;
    }
    return PE_OK;
}

## @apmethod int issuerForAuthUser()
# Check IssuerDB activation rule
# Register used module in user session
# @return Lemonldap::NG::Portal constant
sub issuerForAuthUser {
    my $self = shift;

    # User information
    my $user = $self->{sessionInfo}->{ $self->{whatToTrace} } || 'unknown';

    # Get active module
    my $issuerDBtype = $self->get_module('issuer');

    # Eval activation rule
    my $rule = $self->{ 'issuerDB' . $issuerDBtype . 'Rule' };

    if ( defined $rule ) {

        $self->lmLog( "Applying rule: $rule", 'debug' );

        unless ( $self->safe->reval($rule) ) {
            $self->lmLog(
                "User $user was not allowed to use IssuerDB $issuerDBtype",
                'warn' );

            return PE_OK;
        }

    }
    else {
        $self->lmLog( "No rule found for IssuerDB $issuerDBtype", 'debug' );
    }

    $self->lmLog( "User $user allowed to use IssuerDB $issuerDBtype", 'debug' );

    # Register IssuerDB module in session
    $self->addSessionValue( '_issuerDB', $issuerDBtype, $self->{id} );

    # Call IssuerDB module method
    return $self->SUPER::issuerForAuthUser();
}

##@apmethod int autoRedirect()
# If the user was redirected to the portal, we will now redirect him
# to the requested URL.
#@return Lemonldap::NG::Portal constant
sub autoRedirect {
    my $self = shift;
    $self->clearHiddenFormValue();

    # Default redirection URL
    $self->{urldc} ||= $self->{portal}
      if ( $self->{mustRedirect} or $self->info() );

    # Display info before redirecting
    if ( $self->info() ) {
        $self->{infoFormMethod} = $self->param('method') || "get";
        $self->clearHiddenFormValue();
        my ($query_string) = ( $self->{urldc} =~ /.+?\?(.+)/ );
        if ($query_string) {
            $self->lmLog(
                "Transform query string $query_string into hidden form values",
                'debug'
            );
            my $query      = CGI->new($query_string);
            my $formFields = $query->Vars;
            foreach ( keys %$formFields ) {
                $self->setHiddenFormValue( $_, $formFields->{$_}, "", 0 );
            }
        }
        return PE_INFO;
    }

    # Redirection should be made if
    #  - urldc defined
    #  - lmError parameter is not defined
    if ( $self->{urldc} and !$self->param("lmError") ) {

        # Cross-domain mechanism
        if (    $self->{cda}
            and $self->{id}
            and $self->{urldc} !~ m#^https?://[^/]*$self->{domain}(:\d+)?/#oi
            and $self->isTrustedUrl( $self->{urldc} ) )
        {
            my $ssl = $self->{urldc} =~ /^https/;
            $self->lmLog( 'CDA request', 'debug' );
            $self->{urldc} .= ( $self->{urldc} =~ /\?/ ? '&' : '?' )
              . (
                ( $self->{securedCookie} < 2 or $ssl )
                ? $self->{cookieName} . "=" . $self->{id}
                : $self->{cookieName} . "http="
                  . $self->{sessionInfo}->{_httpSession}
              );
        }

        $self->updateStatus;

        if ( $self->safe->reval( $self->{jsRedirect} ) ) {
            $self->{redirectFormMethod} = "get";
            return PE_REDIRECT;
        }
        else {
            print $self->redirect(
                -status   => '303 See Other',
                -location => $self->{urldc},
            );
            $self->quit();
        }
    }
    PE_OK;
}

## @method void returnSOAPMessage()
# Print SOAP message
# @return void
sub returnSOAPMessage {
    my $self = shift;

    # Quit if no SOAP message
    $self->quit() unless $self->{SOAPMessage};

    # Print HTTP header and SOAP message
    binmode( STDOUT, ":bytes" );
    print $self->header( -type => 'application/xml' );
    print $self->{SOAPMessage};

    # Exit
    $self->quit();
}

## @method void autoPost()
# Transfer POST data with auto submit
# @return void
sub autoPost {
    my $self = shift;

    # Get URL and Form fields
    $self->{urldc} = $self->{postUrl};
    my $formFields = $self->{postFields};

    $self->clearHiddenFormValue();
    foreach ( keys %$formFields ) {
        $self->setHiddenFormValue( $_, $formFields->{$_}, "", 0 );
    }

    # Display info before redirecting
    if ( $self->info() ) {
        $self->{infoFormMethod} = $self->param('method') || "post";
        return PE_INFO;
    }

    $self->{redirectFormMethod} = "post";
    return PE_REDIRECT;
}

## @method HASHREF getCustomTemplateParameters()
# Find custom templates parameters
# @return Custom parameters
sub getCustomTemplateParameters {

    my $self            = shift;
    my $customTplParams = {};

    foreach ( keys %$self ) {
        next unless ( $_ =~ /^tpl_(.+)$/ );
        my $tplParam = $1;
        my $tplValue = $self->{ "tpl_" . $tplParam };
        $self->lmLog( "Set custom template parameter $tplParam with $tplValue",
            'debug' );

        $customTplParams->{$tplParam} = $tplValue;
    }

    return $customTplParams;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::Simple - Base module for building Lemonldap::NG compatible portals

=head1 SYNOPSIS

  use Lemonldap::NG::Portal::Simple;
  my $portal = new Lemonldap::NG::Portal::Simple(
         domain         => 'example.com',
         globalStorage  => 'Apache::Session::MySQL',
         globalStorageOptions => {
           DataSource   => 'dbi:mysql:database=dbname;host=127.0.0.1',
           UserName     => 'db_user',
           Password     => 'db_password',
           TableName    => 'sessions',
           LockDataSource   => 'dbi:mysql:database=dbname;host=127.0.0.1',
           LockUserName     => 'db_user',
           LockPassword     => 'db_password',
         },
         ldapServer     => 'ldap.domaine.com,ldap-backup.domaine.com',
         securedCookie  => 1,
         exportedVars  => {
           uid   => 'uid',
           cn    => 'cn',
           mail  => 'mail',
           appli => 'appli',
         },
         # Activate SOAP service
         Soap           => 1
    );
  
  if($portal->process()) {
    # Write here the menu with CGI methods. This page is displayed ONLY IF
    # the user was not redirected here.
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see L<CGI(3)>)
    print "...";

    # or redirect the user to the menu
    print $portal->redirect( -uri => 'https://portal/menu');
  }
  else {
    # Write here the html form used to authenticate with CGI methods.
    # $portal->error returns the error message if athentification failed
    # Warning: by defaut, input names are "user" and "password"
    print $portal->header('text/html; charset=utf-8'); # DON'T FORGET THIS (see L<CGI(3)>)
    print "...";
    print '<form method="POST">';
    # In your form, the following value is required for redirection
    print '<input type="hidden" name="url" value="'.$portal->param('url').'">';
    # Next, login and password
    print 'Login : <input name="user"><br>';
    print 'Password : <input name="password" type="password" autocomplete="off">';
    print '<input type="submit" value="go" />';
    print '</form>';
  }

SOAP mode authentication (client) :

  #!/usr/bin/perl -l
  
  use SOAP::Lite;
  use Data::Dumper;
  
  my $soap =
    SOAP::Lite->proxy('http://auth.example.com/')
    ->uri('urn:/Lemonldap::NG::Common::CGI::SOAPService');
  my $r = $soap->getCookies( 'user', 'password' );
  
  # Catch SOAP errors
  if ( $r->fault ) {
      print STDERR "SOAP Error: " . $r->fault->{faultstring};
  }
  else {
      my $res = $r->result();
  
      # If authentication failed, display error
      if ( $res->{error} ) {
          print STDERR "Error: " . $soap->error( $res->{error} )->result();
      }
  
      # print session-ID
      else {
          print "Cookie: lemonldap=" . $res->{cookies}->{lemonldap};
      }
  }

=head1 DESCRIPTION

Lemonldap::NG::Portal::Simple is the base module for building Lemonldap::NG
compatible portals. You can use it either by inheritance or by writing
anonymous methods like in the example above.

See L<Lemonldap::NG::Portal::SharedConf> for a complete example of use of
Lemonldap::Portal::* libraries.

=head1 METHODS

=head2 Constructor (new)

=head3 Args

=over

=item * ldapServer: server(s) used to retrieve session information and to valid
credentials (localhost by default). More than one server can be set here
separated by commas. The servers will be tested in the specifies order.
To use TLS, set "ldap+tls://server" and to use LDAPS, set "ldaps://server"
instead of server name. If you use TLS, you can set any of the
Net::LDAP->start_tls() sub like this:
  "ldap/tls://server/verify=none&capath=/etc/ssl"
You can also use caFile and caPath parameters.

=item * ldapPort: tcp port used by ldap server.

=item * ldapBase: base of the ldap directory.

=item * managerDn: dn to used to connect to ldap server. By default, anonymous
bind is used.

=item * managerPassword: password to used to connect to ldap server. By
default, anonymous bind is used.

=item * securedCookie: set it to 1 if you want to protect user cookies.

=item * cookieName: name of the cookie used by Lemonldap::NG (lemon by default).

=item * domain: cookie domain. You may have to give it else the SSO will work
only on your server.

=item * globalStorage: required: L<Apache::Session> library to used to store
session information.

=item * globalStorageOptions: parameters to bind to L<Apache::Session> module

=item * authentication: sheme to authenticate users (default: "ldap"). It can
be set to:

=over

=item * B<SSL>: See L<Lemonldap::NG::Portal::AuthSSL>.

=back

=item * caPath, caFile: if you use ldap+tls you can overwrite cafile or capath
options with those parameters. This is useful if you use a shared
configuration.

=item * ldapPpolicyControl: set it to 1 if you want to use LDAP Password Policy

=item * grantSessionRule: rule applied to grant session opening for a user. Can
use all exported attributes, macros, groups and custom functions.

=back

=head2 Methods that can be overloaded

All the functions above can be overloaded to adapt Lemonldap::NG to your
environment. They MUST return one of the exported constants (see above)
and are called in this order by process().

=head3 controlUrlOrigin

If the user was redirected by a Lemonldap::NG handler, stores the url that will be
used to redirect the user after authentication.

=head3 controlExistingSession

Controls if a previous session is always available. If true, it call the sub
C<existingSession> with two parameters: id and a scalar tied on Apache::Session
module choosed to store sessions. See below

=head3 existingSession

This sub is called only if a previous session exists and is available. By
defaults, it returns PE_OK so user is re-authenticated. You can overload it:
for example if existingSession just returns PE_DONE: authenticated users are
not re-authenticated and C<>process> returns true.

=head3 extractFormInfo

Method implemented into Lemonldap::NG::Portal::Auth* modules. By default
(ldap bind), converts form input into object variables ($self->{user} and
$self->{password}).

=head3 formateParams

Does nothing. To be overloaded if needed.

=head3 formateFilter

Creates the ldap filter using $self->{user}. By default :

  $self->{filter} = "(&(uid=" . $self->{user} . ")(objectClass=inetOrgPerson))";

If $self->{AuthLDAPFilter} is set, it is used instead of this. This is used by
Lemonldap::NG::Portal::Auth* modules to overload filter.

=head3 connectLDAP

Connects to LDAP server.

=head3 bind

Binds to the LDAP server using $self->{managerDn} and $self->{managerPassword}
if exist. Anonymous bind is provided else.

=head3 search

Retrieves the LDAP entry corresponding to the user using $self->{filter}.

=head3 setAuthSessionInfo

Same as setSessionInfo but implemented in Lemonldap::NG::Portal::Auth* modules.

=head3 setSessionInfo

Prepares variables to store in central cache (stored temporarily in
C<$self->{sessionInfo}>). It use C<exportedVars> entry (passed to the new sub)
if defined to know what to store else it stores uid, cn and mail attributes.

=head3 getSessionInfo

Pick up an information stored in session.

=head3 setGroups

Does nothing by default.

=head3 authenticate

Method implemented in Lemonldap::NG::Portal::Auth* modules. By default (ldap),
authenticates the user by rebinding to the LDAP server using the dn retrieved
with search() and the password.

=head3 grantSession

Use grantSessionRule parameter to allow session opening.

=head3 store

Stores information collected by setSessionInfo into the central cache.
The portal connects the cache using the L<Apache::Session> module passed by
the globalStorage parameters (see constructor).

=head3 unbind

Disconnects from the LDAP server.

=head3 buildCookie

Creates the Lemonldap::NG cookie.

=head3 log

Does nothing. To be overloaded if wanted.

=head3 autoRedirect

Redirects the user to the url stored by controlUrlOrigin().

=head2 Other methods

=head3 process

Main method.

=head3 error

Returns the error message corresponding to the error returned by the methods
described above

=head3 error_type

Give the type of the error (positive, warning or positive)

=head3 _bind( $ldap, $dn, $password )

Method used to bind to the ldap server.

=head3 header

Overloads the CGI::header method to add Lemonldap::NG cookie.

=head3 redirect

Overloads the CGI::redirect method to add Lemonldap::NG cookie.

=head2 EXPORT

=head3 Constants

=over 5

=item * B<PE_OK>: all is good

=item * B<PE_SESSIONEXPIRED>: the user session has expired

=item * B<PE_FORMEMPTY>: Nothing was entered in the login form

=item * B<PE_USERNOTFOUND>: the user was not found in the (ldap) directory

=item * B<PE_WRONGMANAGERACCOUNT>: the account used to bind to LDAP server in order to
find the user distinguished name (dn) was refused by the server

=item * B<PE_BADCREDENTIALS>: bad login or password

=item * B<PE_LDAPERROR>: abnormal error from ldap

=item * B<PE_APACHESESSIONERROR>: abnormal error from Apache::Session

=item * B<PE_FIRSTACCESS>: First access to the portal

=item * B<PE_BADCERTIFICATE>: Wrong certificate

=item * PE_PP_ACCOUNT_LOCKED: account locked

=item * PE_PP_PASSWORD_EXPIRED: password axpired

=item * PE_CERTIFICATEREQUIRED: certificate required

=item * PE_ERROR: unclassified error

=back

=head1 SEE ALSO

L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Portal::SharedConf>, L<CGI>,
L<http://lemonldap-ng.org/>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2006, 2007, 2008, 2009, 2010, 2012 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012 by Sandro Cazzaniga, E<lt>cazzaniga.sandro@gmail.comE<gt>

=item Copyright (C) 2012, 2012, 2013 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Copyright (C) 2006, 2008, 2009, 2010, 2011, 2012, 2012, 2013 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item Copyright (C) 2010, 2011 by Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
