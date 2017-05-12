package Kolab::LDAP::Backend::ad;

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
use Kolab;
use Kolab::Util;
use Kolab::LDAP;
use Net::LDAP;
use Net::LDAP::Control;
use vars qw($ldap $cyrus);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [ qw(
    &startup
    &run
    ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = sprintf('%d.%02d', q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);

sub startup { 1; }

sub shutdown
{
    Kolab::log('AD', 'Shutting down');
    exit(0);
}

sub abort
{
    Kolab::log('AD', 'Aborting');
    exit(1);
}

sub changeCallback
{
    Kolab::log('AD', 'Change notification received', KOLAB_DEBUG);

    ###   $_[0]   isa     Net::LDAP::Message
    ###   $_[1]   shouldbea   Net::LDAP::Entry

    my $mesg = shift || 0;
    my $entry = shift || 0;

    my $issearch = $mesg->isa("Net::LDAP::Search");

    if (!$issearch) {
    Kolab::log('AD', 'mesg is not a search object, testing code...', KOLAB_DEBUG);
    if ($mesg->code == 88) {
        Kolab::log('AD', 'changeCallback() -> Exit code received, returning', KOLAB_DEBUG);
        return;
    } elsif ($mesg->code) {
        Kolab::log('AD', "mesg->code = `" . $mesg->code . "', mesg->msg = `" . $mesg->error . "'", KOLAB_DEBUG);
        &abort;
    }
    } else {
    Kolab::log('AD', 'mesg is a search object, not testing code', KOLAB_DEBUG);
    }

    if (!$entry) {
    Kolab::log('AD', 'changeCallback() called with a null entry', KOLAB_DEBUG);
    return;
    } elsif (!$entry->isa("Net::LDAP::Entry")) {
    Kolab::log('AD', 'changeCallback() called with an invalid entry', KOLAB_DEBUG);
    return;
    }

    if (!Kolab::LDAP::isObject($entry, $Kolab::config{'user_object_class'})) {
    Kolab::log('AD', "Entry is not a `" . $Kolab::config{'user_object_class'} . "', returning", KOLAB_DEBUG);
    return;
    }

    my $deleted = $entry->get_value($Kolab::config{'user_field_deleted'}) || 0;
    if ($deleted) {
    Kolab::LDAP::deleteObject($ldap, $cyrus, $entry);
    return;
    }

    Kolab::LDAP::createObject($ldap, $cyrus, $entry);
}

sub run
{
    # This should be called from a separate thread, as we set our
    # own interrupt handlers here

    $SIG{'INT'} = \&shutdown;
    $SIG{'TERM'} = \&shutdown;

    END {
    alarm 0;
    Kolab::LDAP::destroy($ldap);
    }

    my $mesg;

    Kolab::log('AD', 'Listener starting up');

    $cyrus = Kolab::Cyrus::create;

    Kolab::log('AD', 'Cyrus connection established', KOLAB_DEBUG);

    while (1) {
    Kolab::log('AD', 'Creating LDAP connection to AD server', KOLAB_DEBUG);

    $ldap = Kolab::LDAP::create(
        $Kolab::config{'user_ldap_ip'},
        $Kolab::config{'user_ldap_port'},
        $Kolab::config{'user_bind_dn'},
        $Kolab::config{'user_bind_pw'},
        1
    );

    if (!$ldap) {
        Kolab::log('AD', 'Sleeping 5 seconds...');
        sleep 5;
        next;
    }

    Kolab::log('AD', 'LDAP connection established', KOLAB_DEBUG);

    Kolab::LDAP::ensureAsync($ldap);

    Kolab::log('AD', 'Async checked', KOLAB_DEBUG);

    my $ctrl = Net::LDAP::Control->new(
        type    => '1.2.840.113556.1.4.528',
        critical    => 'true'
    );

    Kolab::log('AD', 'Control created', KOLAB_DEBUG);

    my @userdns = split(/;/, $Kolab::config{'user_dn_list'});
    my $userdn;

    Kolab::log('AD', 'User DN list = ' . $Kolab::config{'user_dn_list'}, KOLAB_DEBUG);

    if (length(@userdns) == 0) {
    Kolab::log('AD', 'No user DNs specified, exiting', KOLAB_ERROR);
    exit(1);
    }

    foreach $userdn (@userdns) {
        Kolab::log('AD', "Registering change notification on DN `$userdn'");

        $mesg = $ldap->search (
        base    => $userdn,
        scope       => 'one',
        control     => [ $ctrl ],
        callback    => \&changeCallback,
        filter      => '(objectClass=*)',
        attrs   => [
            '*',
            $Kolab::config{'user_field_guid'},
            $Kolab::config{'user_field_modified'},
            $Kolab::config{'user_field_quota'},
            $Kolab::config{'user_field_deleted'},
        ],
        );

        Kolab::log('AD', "Change notification registered on `$userdn'");
    }

    eval {
        local $SIG{ALRM} = sub {
        alarm 0;
        Kolab::log('AD', 'Connection refresh period expired; tearing down connection');

        Kolab::LDAP::destroy($ldap);
        next;
        };

        Kolab::log('AD', 'Waiting for changes (refresh period = ' . $Kolab::config{'conn_refresh_period'} . ' minutes)...');
        alarm $Kolab::config{'conn_refresh_period'} * 60;
        $mesg->sync;
        alarm 0;
    };
    }

    1;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Kolab::LDAP::Backend::ad - Perl extension for an Active Directory backend

=head1 ABSTRACT

  Kolab::LDAP::Backend::ad handles an Active Directory backend to the
  kolab daemon.

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
