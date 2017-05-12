package Kolab::Cyrus;

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
use Cyrus::IMAP::Admin;
use Kolab::Util;
use Kolab;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [ qw(
        &create
        &createUid
        &createMailbox
        &deleteMailbox
        &setQuota
        &setACL
    ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = sprintf('%d.%02d', q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);

sub create
{
    Kolab::log('Y', 'Connecting to local Cyrus admin interface');

    my $cyrus = Cyrus::IMAP::Admin->new('localhost');

    if (!$cyrus) {
        Kolab::log('Y', 'Unable to connect to local Cyrus admin interface', KOLAB_ERROR);
        exit(1);
    }

    if (!$cyrus->authenticate(
        'User'          => $Kolab::config{'cyrus_admin'},
        'Password'      => $Kolab::config{'cyrus_admin_pw'},
        'mechanisms'    => 'plaintext',
    )) {
        Kolab::log('Y', "Unable to authenticate with Cyrus admin interface, Error = `" . $cyrus->error . "'", KOLAB_ERROR);
        exit(1);
    }

    return $cyrus;
}

sub createUid
{
    my $user = shift;
    my $sf = shift || 0;
    return 'user' . ($sf ? '.' : '/') . $user;
}

sub createMailbox
{
    my $cyrus = shift;
    my $uid = shift;
    my $sf = shift || 0;
    my $cyruid = &createUid($uid, $sf);

    my $mailbox = ($cyrus->list($cyruid))[0];
    if ($uid && ($uid ne $Kolab::config{'cyrus_admin'}) && ($uid ne "freebusy") && ($uid ne "nobody") && !defined($mailbox)) {
        Kolab::log('Y', "Creating mailbox `$cyruid'");
        if (!$cyrus->create($cyruid)) {
            Kolab::log('Y', "Unable to create mailbox `$cyruid', Error = `" . $cyrus->error . "'", KOLAB_WARN);
        }
    }
}

sub setQuota
{
    my $cyrus = shift;
    my $uid = shift;
    my $quota = shift || 0;
    my $sf = shift || 0;
    my $cyruid = &createUid($uid, $sf);

    if ($quota > 0) {
        (my $root, my %quota) = $cyrus->quotaroot($cyruid);
        my $setquota = $quota{'STORAGE'}[1];
        if (!defined($setquota) || ($setquota != $quota)) {
            Kolab::log('Y', "Setting quota of mailbox `$cyruid' to $quota");
            if (!$cyrus->setquota($cyruid, 'STORAGE', $quota)) {
                Kolab::log('Y', "Unable to set quota for mailbox `$cyruid', Error = `" . $cyrus->error . "'", KOLAB_WARN);
            }
        }
    }
}

sub deleteMailbox
{
    my $cyrus = shift;
    my $uid = shift;
    my $sf = shift || 0;
    my $cyruid = &createUid($uid, $sf);

    Kolab::log('Y', "Removing mailbox `$cyruid'");
    if (!$cyrus->setacl($cyruid, $Kolab::config{'cyrus_admin'}, 'c')) {
        Kolab::log('Y', "Unable to reset ACL of mailbox `$cyruid', Error = `" . $cyrus->error . "'", KOLAB_WARN);
    }
    if (!$cyrus->delete($cyruid)) {
        Kolab::log('Y', "Unable to remove mailbox `$cyruid', Error = `" . $cyrus->error . "'", KOLAB_WARN);
    }
}

sub setACL
{
    my $cyrus = shift;
    my $uid = shift;
    my $sf = shift || 0;
    my $cyruid = &createUid($uid, $sf);

    Kolab::log('Y', "Setting up ACL of mailbox `$cyruid'");
    my $prefix = $Kolab::config{'prefix'};
    my @acls = `$prefix/etc/kolab/workaround.sh $cyruid $Kolab::config{'bind_pw'} | sed -e /localhost/d`;
    my ($user, $entry, $acl);
    Kolab::log('Y', "Removing users from ACL of $cyruid", KOLAB_DEBUG);
    foreach $acl (@acls) {
        $acl = trim($acl);
        ($user, ) = split(/ /, $acl);
        Kolab::log('Y', "Removing `$user' from the ACL of mailbox `$cyruid'");
        if (!$cyrus->deleteacl($cyruid, $user)) {
            Kolab::log('Y', "Unable to remove `$user' from the ACL of mailbox `$cyruid', Error = `" . $cyrus->error . "'", KOLAB_WARN);
        }
    }

    Kolab::log('Y', "Add users from ACL of $cyruid", KOLAB_DEBUG);
    my $newacl = shift;
    foreach $entry (@$newacl) {
        Kolab::log('Y', "Setting up ACL `$entry'", KOLAB_DEBUG);
        ($user, $acl) = split(/ /, $entry , 2);
        Kolab::log('Y', "Split `$user' and `$acl'", KOLAB_DEBUG);
        $user = trim($user);
        $acl = trim($acl);
        Kolab::log('Y', "Setting the ACL of user `$user' in mailbox `$cyruid' to $acl");
        if (!$cyrus->setacl($cyruid, $user, $acl)) {
            Kolab::log('Y', "Unable to set the ACL of user `$user' in mailbox `$cyruid' to $acl, Error = `" . $cyrus->error . "'", KOLAB_WARN);
        }
    }
    Kolab::log('Y', "Finished modifying ACL of $cyruid", KOLAB_DEBUG);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Kolab::Cyrus - Perl extension for interfacing with the Kolab Cyrus
admin module.

=head1 ABSTRACT

  Kolab::Cyrus contains cyrus-related functions, such as
  adding/deleting mailboxes, etc.

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
