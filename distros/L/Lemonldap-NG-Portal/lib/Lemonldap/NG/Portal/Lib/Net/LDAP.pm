##@file
# Extends Net::LDAP
package Lemonldap::NG::Portal::Lib::Net::LDAP;

use strict;
use Net::LDAP;    #inherits
use Net::LDAP::Util qw(escape_filter_value);
use base qw(Net::LDAP);
use Lemonldap::NG::Portal::Main::Constants ':all';
use Net::LDAP::Control::PasswordPolicy;
use Encode;
use Unicode::String qw(utf8);
use Scalar::Util 'weaken';
use IO::Socket::Timeout;
use utf8;

our $VERSION = '2.0.15';

# INITIALIZATION

# Build a Net::LDAP object using parameters issued from $portal
sub new {
    my ( $class, $args ) = @_;
    my $portal = $args->{p}    or die "$class: p argument is required!";
    my $conf   = $args->{conf} or die "$class: conf argument is required!";
    my ( $self, @servers, %tlsParams );
    my $useStartTls = 0;

    foreach my $server ( split /[\s,]+/, $conf->{ldapServer} ) {
        if ( $server =~ m{^ldap\+tls://([^/]+)/?\??(.*)$} ) {
            $useStartTls = 1;
            $server      = $1;
            %tlsParams   = split( /[&=]/, $2 || "" );
        }
        elsif ( $server =~ m{^(ldaps://[^/]+)/?\??(.*)$} ) {
            $useStartTls = 0;
            $server      = $1;
            %tlsParams   = split( /[&=]/, $2 || "" );
        }
        else {
            $useStartTls = 0;
        }
        push @servers, $server;
    }
    $tlsParams{cafile} ||= $conf->{ldapCAFile} if $conf->{ldapCAFile};
    $tlsParams{capath} ||= $conf->{ldapCAPath} if $conf->{ldapCAPath};
    $tlsParams{verify} ||= $conf->{ldapVerify} if $conf->{ldapVerify};
    $self = Net::LDAP->new(
        \@servers,
        onerror   => undef,
        keepalive => 1,
        %tlsParams,
        ( $conf->{ldapPort}    ? ( port    => $conf->{ldapPort} )    : () ),
        ( $conf->{ldapTimeout} ? ( timeout => $conf->{ldapTimeout} ) : () ),
        ( $conf->{ldapVersion} ? ( version => $conf->{ldapVersion} ) : () ),
        ( $conf->{ldapRaw}     ? ( raw     => $conf->{ldapRaw} )     : () ),
    );
    unless ($self) {
        $portal->logger->error( "LDAP initialization error: " . $@ );
        return 0;
    }
    elsif ( $Net::LDAP::VERSION < '0.64' ) {

        # CentOS7 has a bug in which IO::Socket::SSL will return a broken
        # socket when certificate validation fails. Net::LDAP does not catch
        # it, and the process ends up crashing.
        # As a precaution, make sure the underlying socket is doing fine:
        if (    $self->socket->isa('IO::Socket::SSL')
            and $self->socket->errstr < 0 )
        {
            $portal->logger->error(
                "LDAP SSL connection failed: " . $self->socket->errstr );
            return 0;
        }
    }
    bless $self, $class;

    # Set socket timeouts
    my $socket = $self->socket;
    IO::Socket::Timeout->enable_timeouts_on($socket);
    $socket->read_timeout( $conf->{ldapIOTimeout} );
    $socket->write_timeout( $conf->{ldapIOTimeout} );

    if ($useStartTls) {
        my $mesg = $self->start_tls(%tlsParams);
        if ( $mesg->code ) {
            $portal->logger->error( 'LDAP StartTLS failed: ' . $mesg->error );
            return 0;
        }
    }
    $self->{portal} = $portal;
    $self->{conf}   = $conf;
    weaken $self->{portal};

    # Setting default LDAP password storage encoding to utf-8
    return $self;
}

# RUNNING METHODS

## @method Net::LDAP::Message bind(string dn, hash args)
# Reimplementation of Net::LDAP::bind(). Connection is done :
# - with $dn and $args->{password} as dn/password if defined,
# - or with Lemonldap::NG account,
# - or with an anonymous bind.
# @param $dn LDAP distinguish name
# @param %args See Net::LDAP(3) manpage for more
# @return Net::LDAP::Message
sub bind {
    my ( $self, $dn, %args ) = @_;
    my $mesg;

    $self->{portal}->logger->debug("Call bind for $dn") if $dn;
    unless ($dn) {
        $dn = $self->{conf}->{managerDn};
        $args{password} =
          decode( 'utf-8', $self->{conf}->{managerPassword} );
    }
    if ( $dn && $args{password} ) {
        if ( $self->{conf}->{ldapPwdEnc} ne 'utf-8' ) {
            eval {
                my $tmp = encode(
                    $self->{conf}->{ldapPwdEnc},
                    decode( 'utf-8', $args{password} )
                );
                $args{password} = $tmp;
            };
            print STDERR "$@\n" if ($@);
        }

        if ( $self->{conf}->{ldapPpolicyControl} ) {
            my $pp = Net::LDAP::Control::PasswordPolicy->new();
            $args{control} = [$pp];
        }

        $mesg = $self->SUPER::bind( $dn, %args );

        if ( $mesg->code ) {
            my ($resp) = $mesg->control("1.3.6.1.4.1.42.2.27.8.5.1");

            # Check for ppolicy error
            my $pp_error = $resp->pp_error if ( defined($resp) );
            if ( defined $pp_error ) {
                my $ppolicy_error = [
                    "password expired",
                    "account locked",
                    "change after reset",
                    "password mod not allowed",
                    "supply old password",
                    "insufficient password quality",
                    "password too short",
                    "password too young",
                    "password in history"
                ]->[$pp_error];

                $self->{portal}
                  ->logger->error( "Error when binding to LDAP server: "
                      . $mesg->error
                      . " | extended ppolicy control response error: $ppolicy_error"
                  );
            }
            else {
                $self->{portal}->logger->error(
                    "Error when binding to LDAP server: " . $mesg->error );
            }
        }
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
    my $ldap_uri = $self->uri;

    $self->{portal}->logger->debug("Unbind and disconnect from $ldap_uri");

    my $mesg = $self->SUPER::unbind();
    $self->SUPER::disconnect();

    return $mesg;
}

## @method protected int userBind(string dn, hash args)
# Call bind() with dn/password and return
# @param $dn LDAP distinguish name
# @param %args See Net::LDAP(3) manpage for more
# @return Lemonldap::NG portal error code
sub userBind {
    my $self = shift;
    my $req  = shift;

    if ( $self->{conf}->{ldapPpolicyControl} ) {

        # Create Control object
        my $pp = Net::LDAP::Control::PasswordPolicy->new();

        # Bind with user credentials
        my $mesg = $self->bind( @_, control => [$pp] );

        # Get server control response
        my ($resp) = $mesg->control("1.3.6.1.4.1.42.2.27.8.5.1");

        # Return direct unless control response
        unless ( defined $resp ) {
            if ( $mesg->code == 49 ) {
                $self->{portal}->userLogger->warn(
                    "Bad password for $req->{user} (" . $req->address . ")" );
                return PE_BADCREDENTIALS;
            }
            elsif ( $mesg->code == 0 ) {
                return PE_OK;
            }
            else {
                $self->{portal}->logger->error( "Bind failed with error "
                      . $mesg->code . ": "
                      . $mesg->error );
                return PE_LDAPERROR;
            }
        }

        # Check for ppolicy error
        my $pp_error = $resp->pp_error;
        if ( defined $pp_error ) {
            $self->{portal}->userLogger->error(
                "Password policy error $pp_error for " . $req->user );
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
                $self->{portal}->logger->debug(
                    "LDAP password policy - grace authentications remaining: "
                      . $resp->grace_authentications_remaining );
                $req->info(
                    $self->{portal}->loadTemplate(
                        $req,
                        'ldapPpGrace',
                        params => {
                            number => $resp->grace_authentications_remaining
                        }
                    )
                );
            }

            if ( $resp->time_before_expiration ) {
                $self->{portal}->logger->debug(
                    "LDAP password policy - time before expiration: "
                      . $resp->time_before_expiration );
                $req->info(
                    $self->{portal}->loadTemplate(
                        $req,
                        'simpleInfo',
                        params => {
                            trspan => 'pwdWillExpire,'
                              . join(
                                ',',
                                $self->convertSec(
                                    $resp->time_before_expiration
                                )
                              )
                        }
                    )
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
        else {
            $req->data->{ldapError} = $mesg->error;
        }
    }
    $self->{portal}->userLogger->warn(
        "Bad password for $req->{user} (" . $req->address . ")" );
    return PE_BADCREDENTIALS;
}

## @method int userModifyPassword(string dn, string newpassword, string oldpassword, boolean ad, boolean requireOldPassword)
# Change user's password.
# @param $dn DN
# @param $newpassword New password
# @param $oldpassword Current password
# @param $ad Active Directory mode
# @param $requireOldPassword Old password is needed to update
# @return Lemonldap::NG::Portal constant
sub userModifyPassword {
    my ( $self, $dn, $newpassword, $oldpassword, $ad, $requireOldPassword ) =
      @_;
    my $ppolicyControl    = $self->{conf}->{ldapPpolicyControl};
    my $setPassword       = $self->{conf}->{ldapSetPassword};
    my $asUser            = $self->{conf}->{ldapChangePasswordAsUser};
    my $passwordAttribute = "userPassword";
    my $err;
    my $mesg;

    utf8::downgrade($dn);
    $self->{portal}->logger->debug("Call modify password for $dn");

    # Adjust configuration for AD
    if ($ad) {
        $ppolicyControl    = 0;
        $setPassword       = 0;
        $passwordAttribute = "unicodePwd";

        # Encode password for AD
        $newpassword = utf8( chr(34) . $newpassword . chr(34) )->utf16le();
        if ( $oldpassword and $asUser ) {
            $oldpassword =
              utf8( chr(34) . $oldpassword . chr(34) )->utf16le();
        }
        $self->{portal}->logger->debug("Active Directory mode enabled");

    }

    # First case: no ppolicy
    if ( !$ppolicyControl ) {

        if ($setPassword) {

            # Bind as user if oldpassword and ldapChangePasswordAsUser
            if ( $oldpassword and $asUser ) {

                $mesg = $self->bind( $dn, password => $oldpassword );
                if ( $mesg->code != 0 ) {
                    $self->{portal}->userLogger->notice("Bad old password");
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
                $self->{portal}->userLogger->notice("Bad old password");
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
                                  ->userLogger->warn("Bad old password");
                                return PE_BADOLDPASSWORD;
                            }
                        }

                   # if error message has not been catched, then it IS a success
                    }
                    else
                    {   # this is not AD, a 0 error code means good old password
                        if ( $mesg->code != 0 ) {
                            $self->{portal}
                              ->userLogger->warn('Bad old password');
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
          ->logger->debug( 'Modification return code: ' . $mesg->code );
        $self->{portal}
          ->logger->debug( 'Modification return error: ' . $mesg->error );

        # Manage specific errors for IBM Tivoli DS
        if ( $self->{conf}->{ldapITDS} ) {
            my $itds_code = $self->getITDSError($mesg);
            return $itds_code unless ( $itds_code == PE_PASSWORD_OK );
        }

        # Manage specific errors for Active Directory
        if ($ad) {
            return PE_PP_INSUFFICIENT_PASSWORD_QUALITY
              if ( $mesg->code == 53 );
            return PE_PP_PASSWORD_MOD_NOT_ALLOWED
              if ( $mesg->code == 19 );
        }

        # Standard errors
        return PE_WRONGMANAGERACCOUNT
          if ( $mesg->code == 50 || $mesg->code == 8 );
        unless ( $mesg->code == 0 ) {
            $self->{portal}
              ->logger->error( "Password modification failed with LDAP error "
                  . $mesg->code . ": "
                  . $mesg->error );
            return PE_LDAPERROR;
        }

        $self->{portal}->logger->notice("Password changed for $dn");

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

                $mesg = $self->bind(
                    $dn,
                    password => $oldpassword,
                    control  => [$pp]
                );
                my ($bind_resp) = $mesg->control("1.3.6.1.4.1.42.2.27.8.5.1");

                unless ( defined $bind_resp ) {
                    if ( $mesg->code != 0 ) {
                        $self->{portal}->logger->debug("Bad old password");
                        return PE_BADOLDPASSWORD;
                    }
                }
                else {

                    # Check if password is expired
                    my $pp_error = $bind_resp->pp_error;
                    if (    defined $pp_error
                        and $pp_error == 0
                        and $self->{conf}->{ldapAllowResetExpiredPassword} )
                    {
                        $self->{portal}->logger->debug(
"Password is expired but user is allowed to change it"
                        );
                    }
                    else {
                        if ( $mesg->code != 0 ) {
                            $self->{portal}->logger->debug("Bad old password");
                            return PE_BADOLDPASSWORD;
                        }
                    }
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
                $self->{portal}->logger->debug("Bad old password");
                return PE_BADOLDPASSWORD;
            }
        }
        else {
            if ($oldpassword) {

                # Check old password with a bind
                $mesg = $self->bind(
                    $dn,
                    password => $oldpassword,
                    control  => [$pp]
                );
                my ($bind_resp) = $mesg->control("1.3.6.1.4.1.42.2.27.8.5.1");

                unless ( defined $bind_resp ) {
                    if ( $mesg->code != 0 ) {
                        $self->{portal}->logger->debug("Bad old password");
                        return PE_BADOLDPASSWORD;
                    }
                }
                else {

                    # Check if password is expired
                    my $pp_error = $bind_resp->pp_error;
                    if (    defined $pp_error
                        and $pp_error == 0
                        and $self->{conf}->{ldapAllowResetExpiredPassword} )
                    {
                        $self->{portal}->logger->debug(
"Password is expired but user is allowed to change it"
                        );
                    }
                    else {
                        if ( $mesg->code != 0 ) {
                            $self->{portal}->logger->debug("Bad old password");
                            return PE_BADOLDPASSWORD;
                        }
                    }
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
          ->logger->debug( "Modification return code: " . $mesg->code );
        return PE_WRONGMANAGERACCOUNT
          if ( $mesg->code == 50 || $mesg->code == 8 );
        if ( $mesg->code == 0 ) {
            $self->{portal}->logger->notice("Password changed for $dn");

           # Rebind as manager for next LDAP operations if we were bound as user
            $self->bind() if $asUser;

            return PE_PASSWORD_OK;
        }

        if ( defined $resp ) {
            my $pp_error = $resp->pp_error;
            if ( defined $pp_error ) {
                $self->{portal}
                  ->logger->error("Password policy error $pp_error");
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
            $self->{portal}->logger->error(
                "Missing PPolicy control from server response. Code: "
                  . $mesg->code );
            return PE_LDAPERROR;
        }
    }
}

## @method string searchGroups(string base, string key, string value, string attributes, hashref dupcheck)
# Get groups from LDAP directory
# @param base LDAP search base
# @param key Attribute name in group containing searched value
# @param value Searched value
# @param attributes to get from found groups (array ref)
# @param dupcheck to get from found groups (hash ref)
# @return hashRef groups
sub searchGroups {
    my ( $self, $base, $key, $value, $attributes, $dupcheck ) = @_;

    $dupcheck ||= {};
    my $groups = {};

    # Creating search filter
    my $searchFilter =
      "(&(objectClass=" . $self->{conf}->{ldapGroupObjectClass} . ")(|";
    foreach ( split( $self->{conf}->{multiValuesSeparator}, $value ) ) {
        $searchFilter .= "(" . $key . "=" . escape_filter_value($_) . ")";
    }
    $searchFilter .= "))";

    $self->{portal}->logger->debug("Group search filter: $searchFilter");

    # Search
    my $mesg = $self->search(
        base   => $base,
        filter => $searchFilter,
        attrs  => $attributes,
    );

    # Browse results
    if ( $mesg->code() == 0 ) {

        foreach my $entry ( $mesg->all_entries ) {

            $self->{portal}
              ->logger->debug( "Matching group " . $entry->dn() . " found" );

            # If recursive search is activated, do it here
            if ( $self->{conf}->{ldapGroupRecursive} ) {

                # Get searched value
                my $group_value =
                  $self->getLdapValue( $entry,
                    $self->{conf}->{ldapGroupAttributeNameGroup} );

                # Launch group search
                if ($group_value) {
                    if ( $self->{conf}->{ldapGroupDecodeSearchedValue} ) {
                        utf8::decode($group_value);
                    }

                    if ( $dupcheck->{$group_value} ) {
                        $self->{portal}->logger->debug(
"Disable search for $group_value, as it was already searched"
                        );
                    }
                    else {
                        $dupcheck->{$group_value} = 1;
                        $self->{portal}
                          ->logger->debug("Recursive search for $group_value");

                        my $recursive_groups =
                          $self->searchGroups( $base, $key, $group_value,
                            $attributes, $dupcheck );

                        my %allGroups = ( %$groups, %$recursive_groups )
                          if ( ref $recursive_groups );
                        $groups = \%allGroups;

                    }
                }
            }

            # Use first attribute as group name
            my $groupName = $entry->get_value( $attributes->[0] );
            $groups->{$groupName}->{name} = $groupName;

            # Now parse attributes
            foreach (@$attributes) {

                # Next if group attribute value
                next
                  if ( $_ eq $self->{conf}->{ldapGroupAttributeValueGroup} );

                my $data = $entry->get_value( $_, asref => 1 );

                if ($data) {
                    $self->{portal}
                      ->logger->debug("Store values of $_ in group $groupName");
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
    my ( $self, $entry, $attribute ) = @_;

    return $entry->dn() if ( $attribute eq "dn" );

    return join(
        $self->{conf}->{multiValuesSeparator},
        $entry->get_value($attribute)
    );
}

# Convert seconds to hours, minutes, seconds
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

## @method int getITDSError(Net::LDAP::Message mesg)
# Check error message to return according error code
# @param mesg Modification return message
# @return portal error code
sub getITDSError {
    my ( $self, $mesg ) = @_;

    return PE_PP_MUST_SUPPLY_OLD_PASSWORD
      if ( $mesg->code == 53 && $mesg->error =~ /Must supply old password/i );
    return PE_PP_CHANGE_AFTER_RESET
      if ( $mesg->code == 53
        && $mesg->error =~ /Password must be changed after reset/i );
    return PE_PP_PASSWORD_MOD_NOT_ALLOWED
      if ( $mesg->code == 53
        && $mesg->error =~ /Password may not be modified/i );
    return PE_PP_PASSWORD_TOO_YOUNG
      if ( $mesg->code == 19 && $mesg->error =~ /Password too young/i );
    return PE_PP_PASSWORD_TOO_SHORT
      if ( $mesg->code == 19 && $mesg->error =~ /Password too short/i );
    return PE_PP_PASSWORD_IN_HISTORY
      if ( $mesg->code == 19 && $mesg->error =~ /Password in History/i );
    return PE_PP_INSUFFICIENT_PASSWORD_QUALITY if ( $mesg->code == 19 );

    return PE_PASSWORD_OK;
}

1;
