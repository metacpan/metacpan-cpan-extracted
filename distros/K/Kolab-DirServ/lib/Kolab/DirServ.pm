package Kolab::DirServ;

##
## Copyright (c) 2003  Code Fusion cc
## Writen by Stephan Buys <s.buys@codefusion.co.za>
##
## This  program is free  software; you can redistribute  it and/or
## modify it  under the terms of the GNU  General Public License as
## published by the  Free Software Foundation; either version 2, or
## (at your option) any later version.
##
## This program is  distributed in the hope that it will be useful,
## but WITHOUT  ANY WARRANTY; without even the  implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
## General Public License for more details.
##
## You can view the  GNU General Public License, online, at the GNU
## Project's homepage; see <http://www.gnu.org/licenses/gpl.html>.
##

use 5.008;
use strict;
use warnings;
use Kolab;
use Kolab::Util;
#use Kolab::LDAP;
use Kolab::Mailer;
use MIME::Entity;
use MIME::Parser;
use MIME::Body;
use Net::LDAP;
use Net::LDAP::LDIF;
use Net::LDAP::Entry;
use Mail::IMAPClient;
use URI;
use IO::File;
use POSIX qw(tmpnam);
use vars qw(@peers);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [ qw(
        @peers
        &reloadPeers
        &genericRequest
        &notifyNew
        &notifyModify
        &notifyRemove
        &handleNotifications
    )
] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = sprintf('%d.%02d', q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);

sub reloadPeers
{
    @peers = readList($Kolab::config{'prefix'} . "/etc/kolab/addressbook.peers");

    foreach my $peer (@peers) {
        Kolab::log('DS', "Using peer $peer", KOLAB_DEBUG);
    }
}

reloadPeers();

sub genericRequest
{
    #print "Sending generic request: Type:\n";
    return 0 if length(@peers) == 0;

    my $notify = shift;
    my $entry = $notify->clone;
    my $request = shift;

    $entry->delete('userpassword');
    $entry->delete('uid');
    $entry->delete($Kolab::config{'user_field_guid'});
    $entry->delete($Kolab::config{'user_field_modified'});

    $entry->add(
        'objectClass'   => 'kolabPerson',
        'homeServer'    => $Kolab::config{'dirserv_home_server'},
    );

    Kolab::log('DS', "About to send $request", KOLAB_DEBUG);

    my $fh = IO::File->new_tmpfile;
    return 0 if !defined $fh;

    #foreach my $a ($entry->attributes) {
    #    print "$a : ";
    #    my $vals = $entry->get_value($a, 'asref' => 1);
    #    foreach my $val (@$vals) {
    #        print "$val,"
    #    }
    #    print "\n";
    #}

    my $ldif = Net::LDAP::LDIF->new($fh);#, "w+", onerror => 'undef');
    if (!$ldif) { die "unable to create ldif obj" ; }
    $ldif->write_entry($entry);
    #$ldif->dump;

    my (@stats, $data);
    @stats = stat($fh);
        seek($fh, 0, 0);
        read($fh, $data, $stats[7]);
        #print "Read " . $stats[7] . " bytes, data = $data";

    foreach my $peer (@peers) {
        Kolab::Mailer::sendMultipart(
            $Kolab::config{'dirserv_notify_from'},
            $peer,
            $request,
            $fh
        );
    }
    $fh->close();

    return 1;
}

sub notifyNew
{
    return genericRequest($_[0], "new alias");
}

sub notifyModify
{
    return genericRequest($_[0], "modify alias");
}

sub notifyRemove
{
    return genericRequest($_[0], "remove alias");
}

sub printEntry {
    my $entry = shift;
    foreach my $a ($entry->attributes) {
         print "$a : ";
         my $vals = $entry->get_value($a, 'asref' => 1);
         foreach my $val (@$vals) {
             print "$val,"
         }
        print "\n";
  }
}

sub scrubEntry {
    my $entry = shift;
    foreach my $attr ($$entry->attributes) {
        #print $attr,"\n";
        my $value = $$entry->get_value($attr, 'asref' => 1);
        my @newvalues;
        foreach my $element (@$value) {
           $element = trim($element);
           push(@newvalues, ($element));
        }
       $$entry->replace($attr, \@newvalues);
   }
}

sub handleNotifications
{
    my $server = shift;
    my $user = shift;
    my $password = shift;

    my ($imap, $ldap);

    if (!($imap = Mail::IMAPClient->new(
        Server      => $server,
        User        => $user,
        Port        => 143,
        Password    => $password,
        Peek        => 1
    ))) {
        Kolab::log('DS', "Unable to open IMAP connection to `$server'", KOLAB_ERROR);
        return 0;
    }

    if (!$imap->Status) {
        Kolab::log('DS', "Unable to connect to IMAP server", KOLAB_ERROR);
        return 0;
    }

    #if (!($ldap = Kolab::LDAP::create(
    #    $Kolab::config{'ldap_ip'},
    #    $Kolab::config{'ldap_port'},
    #    $Kolab::config{'bind_dn'},
    #    $Kolab::config{'bind_pw'}
    #))) {
    #    return 1;
    #}

    $ldap = Net::LDAP->new(
        $Kolab::config{'ldap_ip'},
        port    => $Kolab::config{'ldap_port'},
    );
    if (!$ldap) {
        Kolab::log('DS', "Unable to connect to LDAP server", KOLAB_ERROR);
        return 0;
    }

    my $ldapmesg = $ldap->bind(
        $Kolab::config{'bind_dn'},
        password    => $Kolab::config{'bind_pw'}
    );
    if ($ldapmesg->code) {
        Kolab::log('DS', "Unable to bind to LDAP server, Error = `" . $ldapmesg->error . "'", KOLAB_ERROR);
        return 0;
    }

    my $parser = new MIME::Parser;

    # Use IDLE instead of polling
    my @folders = $imap->folders;

    foreach my $folder (@folders){
        next if $folder =~ /^\./;
        $imap->select($folder);

        my @messagelist = $imap->search('UNDELETED');
        foreach my $message (@messagelist) {
            my $data = $imap->message_string($message);
            warn "Empty message data for $folder/$message" unless defined $data && length $data;

            $parser->output_under("/tmp");
            my $entity = $parser->parse_data($data);
            my $subject = $entity->head->get('Subject',0);
            $subject = trim($subject);

            #Sanity check
            if ($subject =~ /new alias/ && $entity->is_multipart) {
                #print $entity->parts;
                my ($name,$fh);
                my $part = $entity->parts(0);
                my $bodyh = $part->bodyhandle;

                $fh = IO::File->new_tmpfile;
                return 0 if !defined $fh;

                $bodyh->print(\*$fh);
                seek($fh,0,0);

                my $ldif = Net::LDAP::LDIF->new( $fh, "r", onerror => 'undef' );
                while ( not $ldif->eof() ) {
                    my $entry = $ldif->read_entry();
                    my $cn = $entry->get_value('cn'); #,".$Kolab::config{'bind_dn'});
                    $cn = trim($cn);
                    $cn = "cn=$cn".",cn=external,".$Kolab::config{'base_dn'};
                    $entry->dn($cn);

                    if ( !$ldif->error() ) {
		        scrubEntry(\$entry);

                        my $result = $entry->update($ldap);
                        $result->code && warn "failed to add entry: ", $result->error ;
                    }
                    #print "$subject ",$entry->dn(),"\n";
                }
                $fh->close();
            } elsif ($subject =~ /modify alias/ && $entity->is_multipart) {
#                 #print $entity->parts;
#                 my ($name,$fh);
#                 my $part = $entity->parts(0);
#                 my $bodyh = $part->bodyhandle;
#
#                 $fh = IO::File->new_tmpfile;
#                 return 0 if !defined $fh;
#
#                 $bodyh->print(\*$fh);
#                 seek($fh,0,0);
#
#                 my $ldif = Net::LDAP::LDIF->new( $fh, "r", onerror => 'undef' );
#                 while ( not $ldif->eof() ) {
#                     my $entry = $ldif->read_entry();
#                     my $cn = $entry->get_value('cn'); #,".$Kolab::config{'bind_dn'});
#                     $cn = trim($cn);
#                     $cn = "cn=$cn".",cn=external,".$Kolab::config{'base_dn'};
#                     $entry->dn($cn);
#                     $entry->changetype('modify');
#
#                     if ( !$ldif->error() ) {
#                         foreach my $attr ($entry->attributes) {
#                             #print $attr,"\n";
#                             my $value = $entry->get_value($attr);
#                             $value = trim($value);
#                             $entry->replace($attr,$value);
#                             #print join("\n ",$attr, $entry->get_value($attr)),"\n";
#                         }
#                         my $result = $entry->update($ldap);
#                         if ($result->code) {
#                                 warn "failed to add entry: ", $result->error ;
#                             $entry->changetype('add');
#                             $result = $entry->update($ldap);
#                             $result->code && warn "failed to add entry: ", $result->error ;
#                         }
#                     }
#                     #print "$subject ",$entry->dn(),"\n";
#                 }
#                 $fh->close();
                #print $entity->parts;
                my ($name,$fh);
                my $part = $entity->parts(0);
                my $bodyh = $part->bodyhandle;

                $fh = IO::File->new_tmpfile;
                return 0 if !defined $fh;

                $bodyh->print(\*$fh);
                seek($fh,0,0);

                my $ldif = Net::LDAP::LDIF->new( $fh, "r", onerror => 'undef' );
                while ( not $ldif->eof() ) {
                    my $entry = $ldif->read_entry();
                    my $cn = $entry->get_value('cn'); #,".$Kolab::config{'bind_dn'});
                    $cn = trim($cn);
                    $cn = "cn=$cn".",cn=external,".$Kolab::config{'base_dn'};
                    $entry->dn($cn);
                    $entry->changetype('modify');

                    if ( !$ldif->error() ) {
		        scrubEntry(\$entry);

			my $result = $entry->update($ldap);
                        if ($result->code) {
                             warn "failed to modify entry, trying to add : ", $result->error ;
                             $entry->changetype('add');
                             $result = $entry->update($ldap);
                             $result->code && warn "failed to add entry: ", $result->error ;
                         }
                    }
                    #print "$subject ",$entry->dn(),"\n";
                }
                $fh->close();
            } elsif ($subject =~ /remove alias/ && $entity->is_multipart) {
                #print $entity->parts;
#                 my ($name,$fh);
#                 my $part = $entity->parts(0);
#                 my $bodyh = $part->bodyhandle;
#                 #trim($bodyh);
#                 #print $bodyh;
#                 my $IO = $bodyh->open("r")      || die "open body: $!";
#                 while (defined($_ = $IO->getline)) {
#                     my $line = $_;
#                     $line = trim($line);
#                     if (/(.*) : (.*)/) {
#                         if ($1 eq "cn") {
#                             my $cn = trim($2);
#                             #print "cn=$cn,cn=external,".$Kolab::config{'base_dn'},"\n";
#                             my $result = $ldap->delete("cn=$cn,cn=external,".$Kolab::config{'base_dn'});
#                             $result->code && warn "failed to delete entry: ", $result->error ;
#                         }
#                     }
#                 }
#                 $IO->close                  || die "close I/O handle: $!";
#                 #print $subject,"\n";

                my ($name,$fh);
                my $part = $entity->parts(0);
                my $bodyh = $part->bodyhandle;

                $fh = IO::File->new_tmpfile;
                return 0 if !defined $fh;

                $bodyh->print(\*$fh);
                seek($fh,0,0);

                my $ldif = Net::LDAP::LDIF->new( $fh, "r", onerror => 'undef' );
                while ( not $ldif->eof() ) {
                    my $entry = $ldif->read_entry();
                    my $cn = $entry->get_value('cn'); #,".$Kolab::config{'bind_dn'});
                    $cn = trim($cn);
                    $cn = "cn=$cn".",cn=external,".$Kolab::config{'base_dn'};
                    $entry->dn($cn);
                    $entry->changetype('delete');

                    if ( !$ldif->error() ) {
		        scrubEntry(\$entry);
                        my $result = $entry->update($ldap);
                        $result->code && warn "failed to delete entry: ", $result->error ;
                    }
                }
                $fh->close();

            }


        }
        $imap->set_flag("Deleted",@messagelist);
        $imap->close or die "Could not close :$folder\n";
    }

    if (defined($ldap) && $ldap->isa('Net::LDAP')) {
        $ldap->abandon;
        $ldap->unbind;
        $ldap->disconnect;
    }

    return 1;
}

1;
__END__

=head1 NAME

Kolab::DirServ - A Perl Module that handles Address book
synchronisation between Kolab servers.

=head1 SYNOPSIS

  use Kolab::DirServ;
  use Net::LDAP::Entry;

  #send notification of a new mailbox
  $entry = Net::LDAP::Entry->new(...);
  &notify_new_alias( $entry );

  #handle updates recieved
  &handle_notifications( "address", "IMAP User", "User Password" );

=head1 ABSTRACT

  The Kolab::DirServ module provides a mechanism for Kolab servers to
  publish address book data to a list of peers. These peers recieve
  notification of new, updated and removed mailboxes and update their
  address books accordingly.

=head1 DESCRIPTION

The Kolab::DirServ module recieves Net::LDAP::Entry entries, converts
them to LDIF format and sends them to a list of mailboxes in LDIF
format.
The list of peers and other configuration parameters is provided
through the Kolab::DirServ::Config module.

=head2 EXPORT

  &notify_new_alias( $entry )

    Recieves a Net::LDAP::Entry object.
    Send a new alias notification to each of the address book peers in
    a LDIF MIME attachment.

  &notify_remove_alias( $entry )

    Recieves a Net::LDAP::Entry object.
    Send a notification to each of the address book peers to remove an
    entry from their address books.

  &notify_modify_alias( $entry )

    Recieves a Net::LDAP::Entry object.
    Send updated information to each of the address book peers. Each
    peer then updates the corresponding address book entry with the
    updated information.

  &handle_notifications( $server, $user, $password )

    Connects to specified IMAP server and retrieves all messages from
    the specified mailbox. The messages are cleared from the mailbox
    after they are handled. This process runs periodically on a peer.

=head1 SEE ALSO

kolab-devel mailing list: <kolab-devel@lists.intevation.org>

Kolab website: http://kolab.kroupware.org

=head1 AUTHOR

Stephan Buys, s.buys@codefusion.co.za

Please report any bugs, or post any suggestions, to the kolab-devel
mailing list <kolab-devel@lists.intevation.de>.


=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Stephan Buys

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
