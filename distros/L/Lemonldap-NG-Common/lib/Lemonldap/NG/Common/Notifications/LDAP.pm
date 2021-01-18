## @file
# LDAP storage methods for notifications

## @class
# LDAP storage methods for notifications

package Lemonldap::NG::Common::Notifications::LDAP;

use strict;
use Mouse;
use Time::Local;
use MIME::Base64 qw/encode_base64url/;
use Net::LDAP;
use utf8;

our $VERSION = '2.0.8';

extends 'Lemonldap::NG::Common::Notifications';

sub import {
    shift;
    return Lemonldap::NG::Common::Notifications->import(@_);
}

has ldapServer => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{ldapServer};
    }
);

has ldapPort => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{ldapPort};
    }
);

has ldapCAFile => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{ldapCAFile};
    }
);

has ldapCAPath => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{ldapCAPath};
    }
);

has ldapVerify => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{ldapVerify};
    }
);

has ldapConfBase => (
    is      => 'ro',
    trigger => sub {
        if ( my $table = $_[0]->{table} ) {
            $_[0]->{ldapConfBase} =~ s/^\w+=\w+(,.*)$/ou=$table$1/;
        }
    }
);

has ldapBindDN => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{managerDn};
    }
);

has ldapBindPassword => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->conf->{managerPassword};
    }
);

# Returns notifications corresponding to the user $uid.
# If $ref is set, returns only notification corresponding to this reference.
sub get {
    my ( $self, $uid, $ref ) = @_;
    return () unless ($uid);

    my $filter =
        '(&(objectClass=applicationProcess)(!(description={done}*))'
      . "(description={uid}$uid)"
      . ( $ref ? '(description={ref}' . $ref . ')' : '' ) . ')';
    my @entries = _search( $self, $filter );

    my $result;
    foreach my $entry (@entries) {
        my @notifValues = $entry->get_value('description');
        my $f           = {};
        foreach (@notifValues) {
            my ( $k, $v ) = ( $_ =~ /\{(.*?)\}(.*)/smg );
            $v = decodeLdapValue($v);
            $f->{$k} = $v;
        }
        my $xml = $f->{xml};
        utf8::encode($xml);
        my $identifier =
          &getIdentifier( $self, $f->{uid}, $f->{ref}, $f->{date} );
        $result->{$identifier} = "$xml";
        $self->logger->info("notification $identifier found");

    }
    return $result;
}

# Returns accepted notifications corresponding to the user $uid.
# If $ref is set, returns only notification corresponding to this reference.
sub getAccepted {
    my ( $self, $uid, $ref ) = @_;
    return () unless ($uid);

    my $filter =
        '(&(objectClass=applicationProcess)(description={done}*)'
      . "(description={uid}$uid)(description={ref}$ref))";
    my @entries = _search( $self, $filter );

    my $result;
    foreach my $entry (@entries) {
        my @notifValues = $entry->get_value('description');
        my $f           = {};
        foreach (@notifValues) {
            my ( $k, $v ) = ( $_ =~ /\{(.*?)\}(.*)/smg );
            $v = decodeLdapValue($v);
            $f->{$k} = $v;
        }
        my $xml = $f->{xml};
        utf8::encode($xml);
        my $identifier =
          &getIdentifier( $self, $f->{uid}, $f->{ref}, $f->{date} );
        $result->{$identifier} = "$xml";
        $self->logger->info("notification $identifier found");

    }
    return $result;
}

## @method hashref getAll()
# Return all pending notifications.
# @return hashref where keys are internal reference and values are hashref with
# keys date, uid, ref and condition.
sub getAll {
    my $self    = shift;
    my @entries = $self->_search(
        '(&(objectClass=applicationProcess)(!(description={done}*)))');
    my $result = {};
    foreach my $entry (@entries) {
        my @notifValues = $entry->get_value('description');
        my $f           = {};
        foreach (@notifValues) {
            my ( $k, $v ) = ( $_ =~ /\{(.*?)\}(.*)/smg );
            $v = decodeLdapValue($v);
            $f->{$k} = $v;
        }
        $result->{"$f->{date}#$f->{uid}#$f->{ref}"} = {
            date => $f->{date},
            uid  => $f->{uid},
            ref  => $f->{ref},
            cond => $f->{condition},
        };
    }
    return $result;
}

## @method hashref getExisting()
# Return all notifications.
# @return hashref where keys are internal reference and values are hashref with
# keys date, uid, ref and condition.
sub getExisting {
    my $self    = shift;
    my @entries = $self->_search('objectClass=applicationProcess');
    my $result  = {};
    foreach my $entry (@entries) {
        my @notifValues = $entry->get_value('description');
        my $f           = {};
        foreach (@notifValues) {
            my ( $k, $v ) = ( $_ =~ /\{(.*?)\}(.*)/smg );
            $v = decodeLdapValue($v);
            $f->{$k} = $v;
        }
        $result->{"$f->{date}#$f->{uid}#$f->{ref}"} = {
            date => $f->{date},
            uid  => $f->{uid},
            ref  => $f->{ref},
            cond => $f->{condition},
        };
    }
    return $result;
}

## @method boolean delete(string myref)
# Mark a notification as done.
# @param $myref identifier returned by get() or getAll()
sub delete {
    my ( $self, $myref ) = @_;
    my ( $d, $u, $r );
    unless ( ( $d, $u, $r ) = ( $myref =~ /^([^#]+)#(.+?)#(.+)$/ ) ) {
        $self->logger->warn("Bad reference $myref");
        return 0;
    }
    my @ts = localtime();
    $ts[5] += 1900;
    $ts[4]++;
    return _modify(
        $self,
        '(&(objectClass=applicationProcess)'
          . "(description={uid}$u)"
          . "(description={ref}$r)"
          . "(description={date}$d)"
          . '(!(description={done}*)))',
        "description",
        "{done}$ts[5]-$ts[4]-$ts[3] $ts[2]:$ts[1]"
    );
}

## @method boolean purge(string myref, boolean force)
# Purge notification (really delete record)
# @param $myref identifier returned by get or getAll
# @param $force force purge for not deleted session
# @return true if something was deleted
sub purge {
    my ( $self, $myref, $force ) = @_;
    my ( $d, $u, $r );
    unless ( ( $d, $u, $r ) = ( $myref =~ /^([^#]+)#(.+?)#(.+)$/ ) ) {
        $self->logger->warn("Bad reference $myref");
        return 0;
    }

    my $clause = ( $force ? '' : '(description={done}*)' );
    return $self->_delete( '(&(objectClass=applicationProcess)'
          . "(description={uid}$u)"
          . "(description={ref}$r)"
          . "(description={date}$d)"
          . "$clause)" );
}

# Insert a new notification
# @param date Date
# @param uid UID
# @param ref Reference of the notification
# @param condition Condition for the notification
# @param xml XML notification
# @return true if succeed
sub newNotif {
    my ( $self, $date, $uid, $ref, $condition, $xml ) = @_;
    my $fns = $self->conf->{fileNameSeparator};
    $fns ||= '_';
    my @t = split( /\D+/, $date );
    $t[1]--;
    eval {
        timelocal( $t[5] || 0, $t[4] || 0, $t[3] || 0, $t[2], $t[1], $t[0] );
    };
    return ( 0, "Bad date" ) if ($@);
    $date =~ s/-//g;
    return ( 0, "Bad date" ) unless ( $date =~ /^\d{8}/ );
    my $cn = "${date}${fns}${uid}${fns}" . encode_base64url( $ref, '' );
    $cn .= "${fns}" . encode_base64url( $condition, '' ) if $condition;

    my $fields =
      $condition =~ /.+/
      ? {
        "date" => "$date",
        "uid"  => "$uid",
        "ref"  => "$ref",
        "xml"  => "$xml",
        "cond" => "$condition",
      }
      : {
        "date" => "$date",
        "uid"  => "$uid",
        "ref"  => "$ref",
        "xml"  => "$xml",
      };

    return _store( $self, $cn, $fields );
}

## @method hashref getDone()
# Returns a list of notifications that have been done
# @return hashref where keys are internal reference and values are hashref with
# keys notified, uid and ref.
sub getDone {
    my ($self) = @_;
    my @entries = _search( $self,
        '(&(objectClass=applicationProcess)(description={done}*))' );

    my $result = {};
    foreach my $entry (@entries) {
        my @notifValues = $entry->get_value('description');
        my $f           = {};
        foreach (@notifValues) {
            my ( $k, $v ) = ( $_ =~ /\{(.*?)\}(.*)/smg );
            $v = decodeLdapValue($v);
            $f->{$k} = $v;
        }
        my @t = split( /\D+/, $f->{done} );
        $t[1]--;
        my $done =
          eval { timelocal( $t[5], $t[4], $t[3], $t[2], $t[1], $t[0] ) };
        if ($@) {
            $self->logger->warn("Bad date: $f->{done}");
            return {};
        }
        $result->{"$f->{date}#$f->{uid}#$f->{ref}"} =
          { notified => $done, uid => $f->{uid}, ref => $f->{ref}, };
    }

    # $ldap->unbind() && delete $self->{ldap};
    return $result;
}

## @method object private _ldap()
# Return the ldap object (build it if needed).
# @param filter The LDAP filter to apply
# @return list of entries returned by the LDAP search (set of Net::LDAP::Entry)
sub _search {
    my ( $self, $filter ) = @_;

    my $ldap = _ldap($self);

    my $search = $ldap->search(
        base   => $self->{ldapConfBase},
        filter => "$filter",
        scope  => 'sub',
        attrs  => ['description'],
    );

    if ( $search->code ) {
        $self->logger->error( "search error: " . $search->error() );
        return ();
    }

    return $search->entries();
}

## @method object private _delete()
# Deletes the all entries found by the given LDAP filter
# @param filter The LDAP filter to apply
# @return 1 if operation success, else 0
sub _delete {
    my ( $self, $filter ) = @_;

    my @entries = _search( $self, "$filter" );
    my $mesg    = {};
    foreach my $entry (@entries) {
        $mesg = $self->{ldap}->delete( $entry->dn() );
        $mesg->code && return 0;
    }

    # $ldap->unbind() && delete $self->{ldap};
    return 1;
}

## @method object private _modify()
# add the given attribute value to all entries found by LDAP filter
# @param filter The LDAP filter to apply
# @param attr : name of the attribute to modify
# @param value : new value to add
# @return 1 if operation success, else 0
sub _modify {
    my ( $self, $filter, $attr, $value ) = @_;

    my @entries = _search( $self, "$filter" );

    my $mesg = {};
    foreach my $entry (@entries) {
        $mesg =
          $self->{ldap}
          ->modify( $entry->dn(), add => { "$attr" => "$value", }, );
        $mesg->code && return 0;
    }

    # $ldap->unbind() && delete $self->{ldap};
    return 1;
}

## @method object private _store()
# creates the notification defined by dn: cn=$cn,$ldapConfBase and $fields
# stored in the description attribute
# @param cn : cn value, used as a dn component
# @param fields : set of values to store in description attribute
# @return 1 if operation success, else 0
sub _store {
    my ( $self, $cn, $fields ) = @_;
    my $ldap = _ldap($self) or return 0;

    my $notifName = "$cn";
    my $notifDN   = "cn=$notifName," . $self->{ldapConfBase};

    # Store values as {key}value
    my @notifValues;
    foreach my $k ( keys %$fields ) {
        my $v = encodeLdapValue( $fields->{$k} );
        push @notifValues, "{$k}$v";
    }

    my $add = $ldap->add(
        $notifDN,
        attrs => [
            objectClass => [ 'top', 'applicationProcess' ],
            cn          => $notifName,
            description => \@notifValues,
        ]
    );

    if ( $add->code ) {
        $self->logger->error( $add->error );
        return 0;
    }

    #$ldap->unbind() && delete $self->{ldap};
    return 1;
}

## @method object private encodeLdapValue()
# encode ldap value in utf8 (try to encode to latin1, and if it fails, encode to utf8)
# @param value value to encode
# @return value encoded in utf8
sub encodeLdapValue {
    my $value = shift;

    eval {
        my $safevalue = $value;
        Encode::from_to( $safevalue, "utf8", "iso-8859-1", Encode::FB_CROAK );
    };
    if ($@) {
        Encode::from_to( $value, "iso-8859-1", "utf8", Encode::FB_CROAK );
    }

    return $value;

}

## @method object private decodeLdapValue()
# decode ldap value from utf8 to latin1
# @param value value to decode
# @return value decoded in latin1
sub decodeLdapValue {
    my $value = shift;

    Encode::from_to( $value, "utf8", "iso-8859-1", Encode::FB_CROAK );

    return $value;

}

## @method object private _ldap()
# Return the ldap object (build it if needed).
# @return ldap handle object
sub _ldap {
    my $self = shift;

    return $self->{ldap} if ( $self->{ldap} );

    # Parse servers configuration
    my $useTls = 0;
    my $tlsParam;
    my @servers = ();
    foreach my $server ( split /[\s,]+/, $self->ldapServer ) {
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

    # Connect
    my $ldap = Net::LDAP->new(
        \@servers,
        onerror   => undef,
        keepalive => 1,
        ( $self->ldapPort   ? ( port   => $self->ldapPort )   : () ),
        ( $self->ldapVerify ? ( verify => $self->ldapVerify ) : () ),
        ( $self->ldapCAFile ? ( cafile => $self->ldapCAFile ) : () ),
        ( $self->ldapCAPath ? ( capath => $self->ldapCAPath ) : () ),
    );

    unless ($ldap) {
        use Data::Dumper;
        die 'connexion failed: ' . $@;
    }
    elsif ( $Net::LDAP::VERSION < '0.64' ) {

        # CentOS7 has a bug in which IO::Socket::SSL will return a broken
        # socket when certificate validation fails. Net::LDAP does not catch
        # it, and the process ends up crashing.
        # As a precaution, make sure the underlying socket is doing fine:
        if (    $ldap->socket->isa('IO::Socket::SSL')
            and $ldap->socket->errstr < 0 )
        {
            die "SSL connection error: " . $ldap->socket->errstr;
        }
    }

    # Start TLS if needed
    if ($useTls) {
        my %h = split( /[&=]/, $tlsParam );
        $h{cafile} ||= $self->ldapCAFile if ( $self->ldapCAFile );
        $h{capath} ||= $self->ldapCAPath if ( $self->ldapCAPath );
        $h{verify} ||= $self->ldapVerify if ( $self->ldapVerify );
        my $start_tls = $ldap->start_tls(%h);
        if ( $start_tls->code ) {
            die 'tls failed: ' . $start_tls->error;
        }
    }

    # Bind with credentials
    my $bind =
      $ldap->bind( $self->ldapBindDN, password => $self->ldapBindPassword );
    if ( $bind->code ) {
        die 'bind failed: ' . $bind->error;
    }

    $self->{ldap} = $ldap;
    return $ldap;
}

## @method string getIdentifier(string uid, string ref, string date)
# Get notification identifier
# @param $uid uid
# @param $ref ref
# @param $date date
# @return the notification identifier
sub getIdentifier {
    my ( $self, $uid, $ref, $date ) = @_;
    return $date . "#" . $uid . "#" . $ref;
}

1;

