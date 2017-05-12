package Kolab::LDAP;

##
##  Copyright (c) 2003  Code Fusion cc
##
##    Writen by Stuart Bingë  <s.binge@codefusion.co.za>
##
##  This  program is free  software; you can redistribute  it and/or
##  modify it  under the terms of the GNU  General Public License as
##  published by the  Free Software Foundation; either version 2, or
##  (at your option) any later version.
##
##  This program is  distributed in the hope that it will be useful,
##  but WITHOUT  ANY WARRANTY; without even the  implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
##  General Public License for more details.
##
##  You can view the  GNU General Public License, online, at the GNU
##  Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.
##

use 5.008;
use strict;
use warnings;
use Net::LDAP;
use DB_File;
use Kolab;
use Kolab::Util;
use Kolab::Cyrus;
use Kolab::DirServ;
use vars qw(%uid_db %gyard_db %newuid_db %gyard_ts_db);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [ qw(
        &startup
        &shutdown
        &create
        &destroy
        &ensureAsync
        &isObject
        &isDeleted
        &createObject
        &deleteObject
        &sync
    ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '1.02';

sub startup
{
    Kolab::log('L', 'Starting up');

    Kolab::log('L', 'Opening mailbox uid cache DB');

    if (!dbmopen(%uid_db, $Kolab::config{'prefix'} . '/var/kolab/mailbox-uidcache.db', 0666)) {
        Kolab::log('L', 'Unable to open mailbox uid cache DB', KOLAB_ERROR);
        exit(1);
    }

    Kolab::log('L', 'Opening graveyard uid/timestamp cache DB');

    if (!dbmopen(%gyard_db, $Kolab::config{'prefix'} . '/var/kolab/graveyard-uidcache.db', 0666)) {
        Kolab::log('L', 'Unable to open graveyard uid cache DB', KOLAB_ERROR);
        exit(1);
    }

    if (!dbmopen(%gyard_ts_db, $Kolab::config{'prefix'} . '/var/kolab/graveyard-tscache.db', 0666)) {
        Kolab::log('L', 'Unable to open graveyard timestamp cache DB', KOLAB_ERROR);
        exit(1);
    }
}

sub shutdown
{
    Kolab::log('L', 'Shutting down');

    dbmclose(%uid_db);
    dbmclose(%gyard_db);
}

sub create
{
    my $ip = shift;
    my $pt = shift;
    my $dn = shift;
    my $pw = shift;
    my $as = shift || 0;

    Kolab::log('L', "Connecting to LDAP server `$ip:$pt'");

    my $ldap = Net::LDAP->new(
        $ip,
        port    => $pt,
        version => 3,
        timeout => 5,
        async   => $as,
    );
    if (!$ldap) {
        Kolab::log('L', "Unable to connect to LDAP server `$ip:$pt'", KOLAB_ERROR);
        if ($as) { return 0; } else { exit(1); }
    }

    Kolab::log('L', "Binding to `$dn'");
    my $ldapmesg = $ldap->bind(
        $dn,
        password    => $pw
    );
    if ($ldapmesg->code) {
        Kolab::log('L', "Unable to bind to `$dn', LDAP Error = `" . $ldapmesg->error . "'", KOLAB_ERROR);
        if ($as) { return 0; } else { exit(1); }
    }

    return $ldap;
}

sub destroy
{
    my $ldap = shift;

    if (defined($ldap) && $ldap->isa('Net::LDAP')) {
        $ldap->abandon;
        $ldap->unbind;
        $ldap->disconnect;
    }
}

sub ensureAsync
{
    my $ldap = shift || 0;

    if ($ldap && !$ldap->async) {
        Kolab::log('L', 'LDAP operations are not asynchronous', KOLAB_ERROR);
        exit(1);
    }

    Kolab::log('L', 'LDAP operations are asynchronous', KOLAB_DEBUG);
}

sub isObject
{
    my $object = shift;
    my $class = shift;

    my $classes = $object->get_value('objectClass', asref => 1);
    return 0 if !defined($classes);
    foreach my $oc (@$classes) {
        if ($oc =~ /$class/i) {
            return 1;
        }
    }
    return 0;
}

sub isDeleted
{
    my $object = shift;
    my $p = shift || 'user';
    my $del = $object->get_value($Kolab::config{$p . '_field_deleted'}) || '';
    return ($del =~ /true/i);
}

sub createObject
{
    my $ldap = shift;
    my $cyrus = shift;
    my $object = shift;
    my $sync = shift || 0;
    my $p = shift || 'user';
    my $doacls = shift || 0;
    my $objuidfield = shift || ($p eq 'user' ? 'mail' : ($p eq 'sf' ? 'cn' : ''));

    Kolab::log('L', "Kolab::LDAP::createObject() called with obj uid field `$objuidfield' for obj type `$p'", KOLAB_DEBUG);

    my $uid = trim($object->get_value($objuidfield)) || 0;
    if (!$uid) {
        Kolab::log('L', "Kolab::LDAP::createObject() called with null id attribute `$objuidfield', returning", KOLAB_DEBUG);
        return;
    }

    Kolab::log('L', "Synchronising object `$uid'", KOLAB_DEBUG);

    my $guid = $object->get_value($Kolab::config{$p . '_field_guid'});
    Kolab::log('L', "GUID attribute `" . $Kolab::config{$p . '_field_guid'} . "' is `$guid'", KOLAB_DEBUG);
    my $olduid = $uid_db{$guid} || '';
    if ($olduid) {
        # We have records of the object
        $newuid_db{$guid} = $olduid if ($sync);
        if ($olduid ne $uid) {
            # The mailbox changed; bitch
            Kolab::log('L', "Object `$uid' already exists as `$olduid'; refusing to create", KOLAB_WARN);
        }
        # Nothing changed; nothing to do
        #Kolab::DirServ::genericRequest($object, "modify alias");
    } else {
        # No official records - check the graveyard
        my $oldgyarduid = $gyard_db{$guid} || '';
        if ($oldgyarduid) {
            # The object needs to be resurrected!
            if ($oldgyarduid ne $uid) {
                Kolab::log('L', "Resurrected object `$uid' already exists as `$oldgyarduid'; refusing to create", KOLAB_WARN);
            } else {
                Kolab::log('L', "Object `$uid' has been resurrected", KOLAB_DEBUG);
            }

            # Remove the object from the graveyard
            if ($sync) { $newuid_db{$guid} = $oldgyarduid; } else { $uid_db{$guid} = $oldgyarduid; }
            delete $gyard_db{$guid};
            delete $gyard_ts_db{$guid};
        } else {
            Kolab::log('L', "Creating user `$uid' corresponding to GUID `$guid'", KOLAB_DEBUG);
            # We have a object that we have no previous record of, so create everything
            if ($sync) { $newuid_db{$guid} = $uid; } else { $uid_db{$guid} = $uid; }
            Kolab::Cyrus::createMailbox($cyrus, $uid, ($p eq 'sf' ? 1 : 0));

            Kolab::DirServ::genericRequest($object, "new alias") if $p eq 'user';
        }
    }

    if ($doacls) {
        my $acls = $object->get_value('acl', 'asref' => 1);
        Kolab::Cyrus::setACL($cyrus, $uid, ($p eq 'sf' ? 1 : 0), $acls);
    }

    my $quota = $object->get_value($Kolab::config{$p . '_field_quota'});
    Kolab::Cyrus::setQuota($cyrus, $uid, $quota);
}

sub deleteObject
{
    # This should only ever be called if the object is specifically flagged for
    # deletion, as we nuke the mailbox
    #
    # The graveyard code will handle the case of an object `going missing'.

    my $ldap = shift;
    my $cyrus = shift;
    my $object = shift;
    my $remfromldap = shift || 0;
    my $p = shift || 'user';

    if ($remfromldap) {
        my $dn = $object->dn;
        Kolab::log('L', "Removing DN `$dn'");
        my $mesg = $ldap->delete($dn);
        if ($mesg->code) {
            Kolab::log('L', "Unable to remove DN `$dn'", KOLAB_WARN);
        }
    }

    my $guid = $object->get_value($Kolab::config{$p . '_field_guid'});
    my $uid = $uid_db{$guid} || 0;
    if (!$uid) {
        Kolab::Util::log('L', 'Deleted object not found in mboxcache, returning', KOLAB_DEBUG);
        return;
    }

    Kolab::DirServ::genericRequest($object, "remove alias") if $p eq 'user';

    Kolab::Cyrus::deleteMailbox($cyrus, $uid, ($p eq 'sf' ? 1 : 0));
    delete $uid_db{$guid};
    return;
}

sub sync
{
    Kolab::log('L', 'Synchronising');

    my $cyrus = Kolab::Cyrus::create;
    %newuid_db = ();

    syncBasic($cyrus, 'user', '(mail=*)', 0);
    syncBasic($cyrus, 'sf', '', 1);

    # Check that all mailboxes correspond to LDAP objects
    Kolab::log('L', 'Synchronising mailboxes');

    my @mailboxes = $cyrus->list('*');
    my %objects;
    my $mailbox;
    foreach $mailbox (@mailboxes) {
        my $u = ${@{$mailbox}}[0];
        $u =~ /user[\/\.]([^\/]*)\/?.*/;
        $objects{$1} = 1 if ($1);
    }

    my $guid;
    foreach $guid (keys %newuid_db) {
        delete $objects{$newuid_db{$guid}} if (exists $objects{$newuid_db{$guid}});
    }

    # Any mailboxes left should be sent to the graveyard; these are mailboxes
    # without a corresponding LDAP object, yet we were never informed of their
    # deletion, i.e. either we missed the deletion notification or there was
    # an error when iterating through the objects (Lost connection, invalid DNs)
    foreach $guid (keys %uid_db) {
        if (exists $objects{$uid_db{$guid}}) {
            $gyard_db{$guid} = $uid_db{$guid};
            $gyard_ts_db{$guid} = time;
        }
    }

    my $now = time;
    my $period = $Kolab::config{'gyard_deletion_period'} * 60;
    Kolab::log('L', 'Gravekeeping (period = ' . $Kolab::config{'gyard_deletion_period'} . ' minutes)');
    foreach $guid (keys %gyard_ts_db) {
        if ($now - $gyard_ts_db{$guid} > $period) {
            Kolab::log('L', "Gravekeeper deleting mailbox `" . $gyard_db{$guid} . "'");
            Kolab::Cyrus::deleteMailbox($cyrus, $gyard_db{$guid}, 0);
            delete $gyard_ts_db{$guid};
            delete $gyard_db{$guid};
        }
    }

    %uid_db = %newuid_db;

    Kolab::log('L', 'Finished synchronisation');
}

sub syncBasic
{
    my $cyrus = shift;
    my $p = shift || 'user';
    my $add = shift || ($p eq 'user' ? '(mail=*)' : '');
    my $doacls = shift || 0;

    Kolab::log('L', "Synchronising `$p' objects");

    my $ldap = &create(
        $Kolab::config{$p . '_ldap_ip'},
        $Kolab::config{$p . '_ldap_port'},
        $Kolab::config{$p . '_bind_dn'},
        $Kolab::config{$p . '_bind_pw'}
    );

    my $ldapmesg;
    my $ldapobject;

    my @dnlist = split(/;/, $Kolab::config{$p . '_dn_list'});
    my $dn;

    foreach $dn (@dnlist) {
        Kolab::log('L', "Synchronising `$p' DN `$dn'");

        # First of all, remove any objects explicitly marked for deletion
        $ldapmesg = $ldap->search(
            base    => $dn,
            scope   => 'one',
            filter  => '(&(objectClass=' . $Kolab::config{$p . '_object_class'} . ")$add(" . $Kolab::config{$p . '_field_deleted'} . '=TRUE))',
            attrs   => [
                '*',
                $Kolab::config{$p . '_field_guid'},
                $Kolab::config{$p . '_field_modified'},
                $Kolab::config{$p . '_field_quota'},
                $Kolab::config{$p . '_field_deleted'},
            ],
        );

        if ($ldapmesg->code <= 0) {
            foreach $ldapobject ($ldapmesg->entries) {
                deleteObject($ldap, $cyrus, $ldapobject, 1, $p);
            }
        } else {
            Kolab::log('L', "Unable to locate deleted `$p' objects in DN `$dn'", KOLAB_WARN);
        }

        # Now check that all objects in LDAP have corresponding mailboxes
        # This also resurrects any missing users, if neccessary
        $ldapmesg = $ldap->search(
            base    => $dn,
            scope   => 'one',
            filter  => '(&(objectClass=' . $Kolab::config{$p . '_object_class'} . ")$add)",
            attrs   => [
                '*',
                $Kolab::config{$p . '_field_guid'},
                $Kolab::config{$p . '_field_modified'},
                $Kolab::config{$p . '_field_quota'},
                $Kolab::config{$p . '_field_deleted'},
            ],
        );

        if ($ldapmesg->code <= 0) {
            foreach $ldapobject ($ldapmesg->entries) {
                createObject($ldap, $cyrus, $ldapobject, 1, $p, $doacls);
            }
        } else {
            Kolab::log('L', "Unable to locate `$p' objects in DN `$dn'", KOLAB_WARN);
        }

        Kolab::log('L', "Finished synchronising `$p' DN `$dn'");
    }

    &destroy($ldap);

    Kolab::log('L', "Finished `$p' object synchronisation");
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Kolab::LDAP - Perl extension for generic LDAP code

=head1 ABSTRACT

  Kolab::LDAP contains functions used to create/delete objects,
  as well as synchronise LDAP and Cyrus.

=head1 AUTHOR

Stuart Bingë, E<lt>s.binge@codefusion.co.zaE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003  Code Fusion cc

This  program is free  software; you can redistribute  it and/or
modify it  under the terms of the GNU  General Public License as
published by the  Free Software Foundation; either version 2, or
(at your option) any later version.

This program is  distributed in the hope that it will be useful,
but WITHOUT  ANY WARRANTY; without even the  implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You can view the  GNU General Public License, online, at the GNU
Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.

=cut
