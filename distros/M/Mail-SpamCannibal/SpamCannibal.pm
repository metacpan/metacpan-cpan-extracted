#!/usr/bin/perl
package Mail::SpamCannibal;

use strict;
#use diagnostics;
use vars qw($VERSION);

$VERSION = do { my @r = (q$Revision: 1.08 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub DESTROY {};

1;
__END__

=head1 NAME

Mail::SpamCannibal - A tool to stop SPAM

=head1 SYNOPSIS

none, this is a documentation shell

=head1 DESCRIPTION

B<Mail::SpamCannibal> provides a collection of tools and utilities to help
stop spam. This process comprises several steps and uses a combination of
daemons, cron scripts and scripts activated by incoming mail.

=head2 DAEMONS

=over 2

=item * dbtarpit

A tarpit daemon that interfaces directly to Linux IPtables to monitor port
25 access and allow or deny (and tarpit) connections based on the
information in the spamcannibal database. Additionally, dbtarpit logs the IP
address of every connection host to its 'archive' database for later
processing by sc_BLcheck.pl.

See: B<IPTables::IPv4::DBTables>

=item * dnsbls

A blacklist DNS daemon that uses the spamcannibal databases as its
information source. 

See: B<Mail::SpamCannibal::DNSBLserver>

=item * bdbaccess

A local and remote database access provider that services non-privileged
tasks with information from the spamcannibal databases. This daemon can
provide local service via a unix domain socket, or remote service. For
remote service, the bdbaccess can be run as a standalone daemon or from
inetd with tcp wrapper to restrict access.

See: B<Mail::SpamCannibal::BDBaccess>

=back

=head2 SCRIPTS

=over 2

=item * sc_BLcheck.pl

This script is run periodically by CRON and checks the list of host IP
addresses found in the spamcannibal 'archive' database. sc_BLcheck's config
file contains a list of DNSBL servers against which these addresses are
checked and if matched, the address is placed in the dbtarpit 'tarpit'
database to deny connection. A record of the reason for denial based on the
DNSBLS response is placed in the spamcannibal 'blcontrib' (blacklist
contrib) database for use by the web interface and sc_BLpreen.pl.

Also see sc_BlackList.conf.sample in the spamcannibal config directory.

=item * sc_BLpreen.pl

This script is run periodically by CRON and checks the IP addresses found
in the spamcannibal 'blcontrib' database. Each address is verified against
the origination DNSBL and purged from the database after a configurable
timeout if the DNSBL goes down or if the DNSBL no longer blacklists the
address. Because this is a HIGH load task, checks are only performed on IP
addresses that are found in the 'tarpit' database that have recently
attempted contact. Recent is defined as sometime within the last 5 intervals
(or one day, whichever is greater) for the sc_BLpreen.pl CRON task. 'tarpit' 
entries that are older than this are not checked for removal. NOTE that 
this is harmless. Any contact by a sending mail server will update the tarpit 
time tag resulting in a check being performed at the next CRON interval and 
the entry being removed if the IP address is no longer in the external DNSBL.

Also see sc_BlackList.conf.sample in the spamcannibal config directory.

=item * sc_mailcheck.pl

This script is a robot mail recipient set up in the spamcannibal user's
.forward file. Secure mail with a message body containing the headers and
spam content of a 'spam' message sent from your desktop is parsed to extract
the origination MTA. The IP address of the MTA is added to the spamcannibal
'tarpit' database and the 'spam' content is added to the spamcannibal
'evidence' database for use by the web interface.

Also see sc_mailfilter.conf.sample in the spamcannibal config directory

=item * sc_admin.pl

This script provides the site administrator with direct access to the fields
in the SpamCannibal databases for manual updates, deletes or other tasks
that can not be performed with the administrative web tools or one of the
other automatic scripts. In particular, sc_admin.pl is needed to modify or
delete records in the 127.0.0.0/8 range. These addresses are used by
SpamCannibal for bookeeping and dnsbl test addresses and are more or less
ignored by all the scripts and tools except sc_admin.pl

=item * sc_initdb.pl

This script initializes the SpamCannibal Berkeley DB environment and
databases. It also sets the permissions on the SpamCannibal environment
directory and database files.

Run with the '-R' switch to recover the Berkeley DB environment. All other
threads must be stopped prior to using this switch. 
See the document 'pods/recover.pod' or '/docs/recover.html' for more information.

=item * sc_recoverdb.pl

This script verifies and/or recovers and writes a new DB file. You must
move/copy the new DB file over the old one. An existing database file can be
verified for integrity and/or a new one can be created from the old one to
recover good records from a corrupted file.
See the document 'pods/recover.pod' or '/docs/recover.html' for more information.

=item * sc_remote.pl

This script provides remote access via B<sc_remotewrap> for the web admin program
B<sc_session.pl> to a SpamCannibal installation on a remote host.

=item * sc_session.pl

This script provides the web admin routines with privileged access via
B<sc_sesswrap> to the SpamCannibal database in a secured sandbox.

=item * sc_cleanup.pl

This script examines the databases and removes records that do not have the
appropriate corresponding matching records in sister database files.

It should be run periodically to keep things tidy.

=item * sc_country_origin.pl

This script prints a sorted list (by count) of countries of origin (by
country code) and the number of IP addresses that appear in the 'tarpit'
database.

=back

Each of the above scripts has 'help'

  scriptname.pl -h

=head2 WEB APPLICATIONS

=over 2

=item * cannibal.cgi

This cgi script may be use directly as Perl cgi or in its alter ego,
'cannibal.plx' as a mod-perl enabled script to provide public access to the
spamcannibal database. This allows the public to see if their IP address is
in the spamcannibal database, do a WHOIS lookup on a particular IP address
or contact the site administrator.

=item * admin.cgi

(this is really ln -s cannibal.cgi admin.cgi)

'admin.cgi' provides administrative functions to view, add and remove
information to/from the spamcannibal database. It is highly recommend that
this be run over a secure link with https as the password and token system
is insecure otherwise. You can do it, but you've been warned.

The administrator may add or remove other administrators and each
administrator my manage his/her password. This feature can be disabled. The
password systems uses passwords compatible with 'crypt' and htpasswd.

Spamcannibal installs with a single adminstrative user 'admin' with a blank
password.

=item * spam_report.cgi

Interface to the optional LaBrea::Tarpit statistics reporting module. this
web script provides a view of the current state and recent operations of the
SpamCannibal tarpit daemon and is a recommended part of any installation.

=back

=head1 OTHER MODULES IN THIS PACKAGE

=over 2

=item * Mail::SpamCannibal::SiteConfig

When called, returns a hash containing the site configuration information

=item * Mail::SpamCannibal::BDBclient

Interface utilities for bdbaccess daemon

=item * Mail::SpamCannibal::GoodPrivacy

Interface to PGP or openPGP (use by sc_mailfilter.pl)

=item * Mail::SpamCannibal::LaBreaDaemon

An interface module to the routines and functions in LaBrea::Tarpit

=item * Mail::SpamCannibal::ParseMessage

Utilities to extract headers, MTA's, and messages from text.

=item * Mail::SpamCannibal::Password

Utilities to manage password encryption and decryption

=item * Mail::SpamCannibal::PidUtil

Utility module to check if a job is running and to create and manage pid
files.

=item * Mail::SpamCannibal::SMTPsend

A module built on Perl Socket that can send mail. It does its own MX
resolution and does not rely on the host MTA.

=item * Mail::SpamCannibal::ScriptSupport

A collection of utilities use by the spamcannibal scripts and web cgi
routines.

=item * Mail::SpamCannibal::Session

Web service administrative session manager routines to provide security for
administrative access to the spamcannibal database.

=item * Mail::SpamCannibal::WebService

Utilities to support web services for cgi and mod-perl

=item * Mail::SpamCannibal::WhoisIP

Utility module to lookup an IP address owner anywhere in the world

=back

=head1 BUGS

  During perl Makefile.PL I have the following errors:

  WARNING: HTMLSCRIPTPODS is not a known parameter.
  WARNING: INST_HTMLLIBDIR is not a known parameter.
  WARNING: EXTRA_META is not a known parameter.
  WARNING: INSTALLHTMLSITELIBDIR is not a known parameter.
  WARNING: HTMLLIBPODS is not a known parameter.

  These warnings are normal for version ExtUtils-MakeMaker-6.44 
  (Feb 28, 2008) and later. Usually these can be safely ignored 
  since the missing "internals" only affect the expansion of 
  documents into SpamCannibal's web tree and the SpamCannibal 
  installer also has a built-in workaround to compensate for the 
  missing internals of the newer ExtUtils-MakeMaker.

=head1 COPYRIGHT

Copyright 2003 - 2014, Michael Robinton <michael@bizsystems.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=cut

1;
