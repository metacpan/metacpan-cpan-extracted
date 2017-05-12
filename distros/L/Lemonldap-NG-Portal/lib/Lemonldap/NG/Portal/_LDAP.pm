##@file
# LDAP common functions

##@class
# LDAP common functions
package Lemonldap::NG::Portal::_LDAP;

use Net::LDAP;    #inherits
use Net::LDAP::Util qw(escape_filter_value);
use Exporter;
use base qw(Exporter Net::LDAP);
use Lemonldap::NG::Portal::Simple;
use Encode;
use Unicode::String qw(utf8);
use strict;

our @EXPORT   = qw(ldap);
our $VERSION  = '1.4.11';
our $ppLoaded = 0;

BEGIN {
    eval {
        require threads::shared;
        threads::shared::share($ppLoaded);
    };
}

## @cmethod Lemonldap::NG::Portal::_LDAP new(Lemonldap::NG::Portal::Simple portal)
# Build a Net::LDAP object using parameters issued from $portal
# @return Lemonldap::NG::Portal::_LDAP object
sub new {
    my $class  = shift;
    my $portal = shift;
    my $self;
    unless ($portal) {
        $class->abort("$class : portal argument required !");
    }
    my $useTls = 0;
    my $tlsParam;
    my @servers = ();
    foreach my $server ( split /[\s,]+/, $portal->{ldapServer} ) {
        if ( $server =~ m{^ldap\+tls://([^/]+)/?\??(.*)$} ) {
            $useTls   = 1;
            $server   = $1;
            $tlsParam = $2 || "";
        }
        else {
            $useTls = 0;
        }
        push @servers, $server;
    }
    $self = Net::LDAP->new(
        \@servers,
        onerror => undef,
        ( $portal->{ldapPort}    ? ( port    => $portal->{ldapPort} )    : () ),
        ( $portal->{ldapTimeout} ? ( timeout => $portal->{ldapTimeout} ) : () ),
        ( $portal->{ldapVersion} ? ( version => $portal->{ldapVersion} ) : () ),
        ( $portal->{ldapRaw}     ? ( raw     => $portal->{ldapRaw} )     : () ),
    );
    unless ($self) {
        $portal->lmLog( $@, 'error' );
        return 0;
    }
    bless $self, $class;
    if ($useTls) {
        my %h = split( /[&=]/, $tlsParam );
        $h{cafile} = $portal->{caFile} if ( $portal->{caFile} );
        $h{capath} = $portal->{caPath} if ( $portal->{caPath} );
        my $mesg = $self->start_tls(%h);
        if ( $mesg->code ) {
            $portal->lmLog( 'StartTLS failed', 'error' );
            return 0;
        }
    }
    $self->{portal} = $portal;

    # Setting default LDAP password storage encoding to utf-8
    $self->{portal}->{ldapPwdEnc} ||= 'utf-8';
    return $self;
}

## @method Net::LDAP::Message bind(string dn, hash args)
# Reimplementation of Net::LDAP::bind(). Connection is done :
# - with $dn and $args->{password} as dn/password if defined,
# - or with Lemonldap::NG account,
# - or with an anonymous bind.
# @param $dn LDAP distinguish name
# @param %args See Net::LDAP(3) manpage for more
# @return Net::LDAP::Message
sub bind {
    my $self = shift;
    my $mesg;
    my ( $dn, %args ) = splice @_;
    unless ($dn) {
        $dn = $self->{portal}->{managerDn};
        $args{password} = $self->{portal}->{managerPassword};
    }
    if ( $dn && $args{password} ) {
        if ( $self->{portal}->{ldapPwdEnc} ne 'utf-8' ) {
            eval {
                my $tmp = encode(
                    $self->{portal}->{ldapPwdEnc},
                    decode( 'utf-8', $args{password} )
                );
                $args{password} = $tmp;
            };
            print STDERR "$@\n" if ($@);
        }
        $mesg = $self->SUPER::bind( $dn, %args );
    }
    else {
        $mesg = $self->SUPER::bind();
    }
    return $mesg;
}

## @method Net::LDAP::Message unbind()
# Reimplementation of Net::LDAP::unbind() to force call to disconnect()
# @return Net::LDAP::Message
sub unbind {
    my $self     = shift;
    my $ldap_uri = $self->{portal}->{ldapServer};
    eval { $ldap_uri = $self->uri; };

    $self->{portal}->lmLog( "Unbind and disconnect from $ldap_uri", 'debug' );

    my $mesg = $self->SUPER::unbind();
    $self->SUPER::disconnect();

    return $mesg;
}

## @method private boolean loadPP ()
# Load Net::LDAP::Control::PasswordPolicy
# @return true if succeed.
sub loadPP {
    my $self = shift;
    return 1 if ($ppLoaded);

    # Minimal version of Net::LDAP required
    if ( $Net::LDAP::VERSION < 0.38 ) {
        $self->{portal}->abort(
"Module Net::LDAP is too old for password policy, please install version 0.38 or higher"
        );
    }

    # Require Perl module
    eval { require Net::LDAP::Control::PasswordPolicy };
    if ($@) {
        $self->{portal}->lmLog(
            "Module Net::LDAP::Control::PasswordPolicy not found in @INC",
            'error' );
        return 0;
    }
    $ppLoaded = 1;
}

## @method protected int userBind(string dn, hash args)
# Call bind() with dn/password and return
# @param $dn LDAP distinguish name
# @param %args See Net::LDAP(3) manpage for more
# @return Lemonldap::NG portal error code
sub userBind {
    my $self = shift;

    if ( $self->{portal}->{ldapPpolicyControl} ) {

        # Create Control object
        my $pp = Net::LDAP::Control::PasswordPolicy->new();

        # Bind with user credentials
        my $mesg = $self->bind( @_, control => [$pp] );

        # Get server control response
        my ($resp) = $mesg->control("1.3.6.1.4.1.42.2.27.8.5.1");

        # Return direct unless control resonse
        unless ( defined $resp ) {
            if ( $mesg->code == 49 ) {
                $self->{portal}->_sub( 'userError',
                    "Bad password for $self->{portal}->{user}" );
                return PE_BADCREDENTIALS;
            }
            return ( $mesg->code == 0 ? PE_OK : PE_LDAPERROR );
        }

        # Check for ppolicy error
        my $pp_error = $resp->pp_error;
        if ( defined $pp_error ) {
            $self->{portal}->_sub( 'userError',
                "Password policy error $pp_error for $self->{portal}->{user}" );
            return [
                PE_PP_PASSWORD_EXPIRED,
                PE_PP_ACCOUNT_LOCKED,
                PE_PP_CHANGE_AFTER_RESET,
                PE_PP_PASSWORD_MOD_NOT_ALLOWED,
                PE_PP_MUST_SUPPLY_OLD_PASSWORD,
                PE_PP_INSUFFICIENT_PASSWORD_QUALITY,
                PE_PP_PASSWORD_TOO_SHORT,
                PE_PP_PASSWORD_TOO_YOUNG,
                PE_PP_PASSWORD_IN_HISTORY,
            ]->[$pp_error];
        }
        elsif ( $mesg->code == 0 ) {

            # Get expiration warning and graces
            if ( $resp->grace_authentications_remaining ) {
                $self->{portal}->info( "<h3>"
                      . $resp->grace_authentications_remaining . " "
                      . $self->{portal}->msg(PM_PP_GRACE)
                      . "</h3>" );
            }
            if ( $resp->time_before_expiration ) {
                $self->{portal}->info(
                    "<h3>"
                      . sprintf(
                        $self->{portal}->msg(PM_PP_EXP_WARNING),
                        $self->{portal}
                          ->convertSec( $resp->time_before_expiration )
                      )
                      . "</h3>"
                );
            }

            return PE_OK;
        }
    }
    else {
        my $mesg = $self->bind(@_);
        if ( $mesg->code == 0 ) {
            return PE_OK;
        }
    }
    $self->{portal}
      ->_sub( 'userError', "Bad password for $self->{portal}->{user}" );
    return PE_BADCREDENTIALS;
}

## @method int userModifyPassword(string dn, string newpassword, string confirmpassword, string oldpassword, boolean ad)
# Change user's password.
# @param $dn DN
# @param $newpassword New password
# @param $confirmpassword New password
# @param $oldpassword Current password
# @param $ad Active Directory mode
# @return Lemonldap::NG::Portal constant
sub userModifyPassword {
    my ( $self, $dn, $newpassword, $confirmpassword, $oldpassword, $ad ) =
      splice @_;
    my $ppolicyControl     = $self->{portal}->{ldapPpolicyControl};
    my $setPassword        = $self->{portal}->{ldapSetPassword};
    my $asUser             = $self->{portal}->{ldapChangePasswordAsUser};
    my $requireOldPassword = $self->{portal}->{portalRequireOldPassword};
    my $passwordAttribute  = "userPassword";
    my $err;
    my $mesg;

    # Verify confirmation password matching
    unless ( $newpassword eq $confirmpassword ) {
        $self->{portal}->lmLog(
"Password $newpassword and password $confirmpassword are not the same",
            'debug'
        );
        return PE_PASSWORD_MISMATCH;
    }

    # Adjust configuration for AD
    if ($ad) {
        $ppolicyControl    = 0;
        $setPassword       = 0;
        $passwordAttribute = "unicodePwd";

        # Encode password for AD
        $newpassword = utf8( chr(34) . $newpassword . chr(34) )->utf16le();
        if ( $oldpassword and $asUser ) {
            $oldpassword = utf8( chr(34) . $oldpassword . chr(34) )->utf16le();
        }
        $self->{portal}->lmLog( "Active Directory mode enabled", 'debug' );

    }

    # First case: no ppolicy
    if ( !$ppolicyControl ) {

        if ($setPassword) {

            # Bind as user if oldpassword and ldapChangePasswordAsUser
            if ( $oldpassword and $asUser ) {

                $mesg = $self->bind( $dn, password => $oldpassword );
                if ( $mesg->code != 0 ) {
                    $self->{portal}->lmLog( "Bad old password", 'debug' );
                    return PE_BADOLDPASSWORD;
                }
            }

            # Use SetPassword extended operation
            require Net::LDAP::Extension::SetPassword;
            $mesg =
              ($oldpassword)
              ? $self->set_password(
                user      => $dn,
                oldpasswd => $oldpassword,
                newpasswd => $newpassword
              )
              : $self->set_password(
                user      => $dn,
                newpasswd => $newpassword
              );

            # Catch the "Unwilling to perform" error
            if ( $mesg->code == 53 ) {
                $self->{portal}->lmLog( "Bad old password", 'debug' );
                return PE_BADOLDPASSWORD;
            }
        }
        else {

            # AD specific
            # Change password as user with a delete/add modification
            if ( $ad and $oldpassword and $asUser ) {
                $mesg = $self->modify(
                    $dn,
                    changes => [
                        delete => [ $passwordAttribute => $oldpassword ],
                        add    => [ $passwordAttribute => $newpassword ]
                    ]
                );
            }

            else {
                if ($requireOldPassword) {

                    return PE_MUST_SUPPLY_OLD_PASSWORD if ( !$oldpassword );

                    # Check old password with a bind
                    $mesg = $self->bind( $dn, password => $oldpassword );

                    # For AD password expiration to work:
                    # ppolicy must be desactivated,
                    # and "change as user" must be desactivated
                    if ($ad) {
                        if ( $mesg->error =~ /LdapErr: .* data ([^,]+),.*/ ) {

# extended data message code:
# 532: password expired (but provided password is correct)
# 773: must change password at next connection (but provided password is correct)
# 52e: password is incorrect
                            unless ( ( $1 eq '532' ) || ( $1 eq '773' ) ) {
                                $self->{portal}
                                  ->lmLog( "Bad old password", 'warn' );
                                return PE_BADOLDPASSWORD;
                            }
                        }

                   # if error message has not been catched, then it IS a success
                    }
                    else
                    {   # this is not AD, a 0 error code means good old password
                        if ( $mesg->code != 0 ) {
                            $self->{portal}
                              ->lmLog( "Bad old password", 'warn' );
                            return PE_BADOLDPASSWORD;
                        }
                    }

          # Rebind as Manager only if user is not granted to change its password
                    $self->bind() unless $asUser;
                }

                # Use standard modification
                $mesg =
                  $self->modify( $dn,
                    replace => { $passwordAttribute => $newpassword } );
            }
        }
        $self->{portal}
          ->lmLog( "Modification return code: " . $mesg->code, 'debug' );
        return PE_WRONGMANAGERACCOUNT
          if ( $mesg->code == 50 || $mesg->code == 8 );
        return PE_PP_INSUFFICIENT_PASSWORD_QUALITY
          if ( $mesg->code == 53 && $ad );
        return PE_PP_PASSWORD_MOD_NOT_ALLOWED
          if ( $mesg->code == 19 && $ad );
        return PE_LDAPERROR unless ( $mesg->code == 0 );
        $self->{portal}
          ->_sub( 'userNotice', "Password changed $self->{portal}->{user}" );

        # Rebind as manager for next LDAP operations if we were bound as user
        $self->bind() if $asUser;

        return PE_PASSWORD_OK;
    }
    else {

        # Create Control object
        my $pp = Net::LDAP::Control::PasswordPolicy->new;

        if ($setPassword) {

            # Bind as user if oldpassword and ldapChangePasswordAsUser
            if ( $oldpassword and $asUser ) {
                $mesg = $self->bind( $dn, password => $oldpassword );
                if ( $mesg->code != 0 ) {
                    $self->{portal}->lmLog( "Bad old password", 'debug' );
                    return PE_BADOLDPASSWORD;
                }
            }

# Use SetPassword extended operation
# Warning: need a patch on Perl-LDAP
# See http://groups.google.com/group/perl.ldap/browse_thread/thread/5703a41ccb17b221/377a68f872cc2bb4?lnk=gst&q=setpassword#377a68f872cc2bb4
            use Net::LDAP::Extension::SetPassword;
            $mesg =
              ($oldpassword)
              ? $self->set_password(
                user      => $dn,
                oldpasswd => $oldpassword,
                newpasswd => $newpassword,
                control   => [$pp]
              )
              : $self->set_password(
                user      => $dn,
                newpasswd => $newpassword,
                control   => [$pp]
              );

            # Catch the "Unwilling to perform" error
            if ( $mesg->code == 53 ) {
                $self->{portal}->lmLog( "Bad old password", 'debug' );
                return PE_BADOLDPASSWORD;
            }
        }
        else {
            if ($oldpassword) {

                # Check old password with a bind
                $mesg = $self->bind( $dn, password => $oldpassword );
                if ( $mesg->code != 0 ) {
                    $self->{portal}->lmLog( "Bad old password", 'debug' );
                    return PE_BADOLDPASSWORD;
                }

          # Rebind as Manager only if user is not granted to change its password
                $self->bind()
                  unless $asUser;
            }

            # Use standard modification
            $mesg = $self->modify(
                $dn,
                replace => { $passwordAttribute => $newpassword },
                control => [$pp]
            );
        }

        # Get server control response
        my ($resp) = $mesg->control("1.3.6.1.4.1.42.2.27.8.5.1");

        $self->{portal}
          ->lmLog( "Modification return code: " . $mesg->code, 'debug' );
        return PE_WRONGMANAGERACCOUNT
          if ( $mesg->code == 50 || $mesg->code == 8 );
        if ( $mesg->code == 0 ) {
            $self->{portal}->_sub( 'userNotice',
                "Password changed $self->{portal}->{user}" );

           # Rebind as manager for next LDAP operations if we were bound as user
            $self->bind() if $asUser;

            return PE_PASSWORD_OK;
        }

        if ( defined $resp ) {
            my $pp_error = $resp->pp_error;
            if ( defined $pp_error ) {
                $self->{portal}->_sub( 'userError',
"Password policy error $pp_error for $self->{portal}->{user}"
                );
                return [
                    PE_PP_PASSWORD_EXPIRED,
                    PE_PP_ACCOUNT_LOCKED,
                    PE_PP_CHANGE_AFTER_RESET,
                    PE_PP_PASSWORD_MOD_NOT_ALLOWED,
                    PE_PP_MUST_SUPPLY_OLD_PASSWORD,
                    PE_PP_INSUFFICIENT_PASSWORD_QUALITY,
                    PE_PP_PASSWORD_TOO_SHORT,
                    PE_PP_PASSWORD_TOO_YOUNG,
                    PE_PP_PASSWORD_IN_HISTORY,
                ]->[$pp_error];
            }
        }
        else {
            return PE_LDAPERROR;
        }
    }
}

## @method protected Lemonldap::NG::Portal::_LDAP ldap()
# @return Lemonldap::NG::Portal::_LDAP object
sub ldap {
    my $self = shift;
    return $self->{ldap}
      if ( ref( $self->{ldap} ) and $self->{flags}->{ldapActive} );
    if ( $self->{ldap} = Lemonldap::NG::Portal::_LDAP->new($self)
        and my $mesg = $self->{ldap}->bind )
    {
        if ( $mesg->code != 0 ) {
            $self->lmLog( "LDAP error: " . $mesg->error, 'error' );
            $self->{ldap}->unbind;
        }
        else {
            if ( $self->{ldapPpolicyControl}
                and not $self->{ldap}->loadPP() )
            {
                $self->lmLog( "LDAP password policy error", 'error' );
                $self->{ldap}->unbind;
            }
            else {
                $self->{flags}->{ldapActive} = 1;
                return $self->{ldap};
            }
        }
    }
    else {
        $self->lmLog( "LDAP error: $@", 'error' );
    }
    return 0;
}

## @method string searchGroups(string base, string key, string value, string attributes)
# Get groups from LDAP directory
# @param base LDAP search base
# @param key Attribute name in group containing searched value
# @param value Searched value
# @param attributes to get from found groups (array ref)
# @return hashRef groups
sub searchGroups {
    my ( $self, $base, $key, $value, $attributes ) = splice @_;

    my $portal = $self->{portal};
    my $groups = {};

    # Creating search filter
    my $searchFilter =
      "(&(objectClass=" . $portal->{ldapGroupObjectClass} . ")(|";
    foreach ( split( $portal->{multiValuesSeparator}, $value ) ) {
        $searchFilter .= "(" . $key . "=" . escape_filter_value($_) . ")";
    }
    $searchFilter .= "))";

    $portal->lmLog( "Group search filter: $searchFilter", 'debug' );

    # Search
    my $mesg = $self->search(
        base   => $base,
        filter => $searchFilter,
        attrs  => $attributes,
    );

    # Browse results
    if ( $mesg->code() == 0 ) {

        foreach my $entry ( $mesg->all_entries ) {

            $portal->lmLog( "Matching group " . $entry->dn() . " found",
                'debug' );

            # If recursive search is activated, do it here
            if ( $portal->{ldapGroupRecursive} ) {

                # Get searched value
                my $group_value =
                  $self->getLdapValue( $entry,
                    $portal->{ldapGroupAttributeNameGroup} );

                # Launch group search
                if ($group_value) {

                    $portal->lmLog( "Recursive search for $group_value",
                        'debug' );

                    my $recursive_groups =
                      $self->searchGroups( $base, $key, $group_value,
                        $attributes );

                    my %allGroups = ( %$groups, %$recursive_groups )
                      if ( ref $recursive_groups );
                    $groups = \%allGroups;
                }
            }

            # Use first attribute as group name
            my $groupName = $entry->get_value( $attributes->[0] );
            $groups->{$groupName}->{name} = $groupName;

            # Now parse attributes
            foreach (@$attributes) {

                # Next if group attribute value
                next if ( $_ eq $portal->{ldapGroupAttributeValueGroup} );

                my $data = $entry->get_value( $_, asref => 1 );

                if ($data) {
                    $portal->lmLog( "Store values of $_ in group $groupName",
                        'debug' );
                    $groups->{$groupName}->{$_} = $data;
                }
            }
        }
    }

    return $groups;
}

## @method string getLdapValue(Net::LDAP::Entry entry, string attribute)
# Get the dn, or the attribute value with a separator for multi-valuated attributes
# @param entry LDAP entry
# @param attribute Attribute name
# @return string value
sub getLdapValue {
    my ( $self, $entry, $attribute ) = splice @_;

    return $entry->dn() if ( $attribute eq "dn" );

    my $value;

    foreach ( $entry->get_value($attribute) ) {
        $value .= $_;
        $value .= $self->{portal}->{multiValuesSeparator};
    }

    $value =~ s/\Q$self->{portal}->{multiValuesSeparator}\E$//;

    return $value;
}

1;
