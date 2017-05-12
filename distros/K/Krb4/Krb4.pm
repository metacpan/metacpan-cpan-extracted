# Copyright (c) 1999 Jeff Horwitz (jeff@smashing.org).  All rights reserved.
# This module is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself. 

package Authen::Krb4;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require 5.002;
require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(

);
$VERSION = '1.1';

sub KOPT_DONT_MK_REQ { 0x00000001; }
sub KOPT_DO_MUTUAL { 0x00000002; }
sub KOPT_DONT_CANON { 0x00000004; }

$Authen::Krb4::error=0;

bootstrap Authen::Krb4 $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Authen::Krb4 - Perl extension for Kerberos 4

=head1 SYNOPSIS

use Authen::Krb4;

=head1 DESCRIPTION

Authen::Krb4 is an object oriented extension to Perl 5 which implements
several user-level Kerberos 4 functions.  With this module, you can create
Kerberized clients and servers written in Perl.  It is compatible with
both AFS and MIT Kerberos.

=head2 VARIABLES & FUNCTIONS

NOTE: No methods or variables are exported, so each variable and function
should be preceded by 'Authen::Krb4::'

=over 4

=item error

Contains the error code of the most recent Kerberos function call.

=item get_phost(alias)

Returns the instance name of the host 'alias'

=item get_lrealm(n)

Returns the nth realm of the host machine.  n is zero by default.

=item realmofhost(host)

Returns the realm of the machine 'host'.

=item mk_req(service,instance,realm,checksum)

Returns an Authen::Krb4::Ticket object for the specified service, instance,
and realm.  It will return undef if there was an error.

=item rd_req(ticket,service,instance,fn)

Returns an Authen::Krb4::AuthDat object, which contains information obtained
from the ticket, or undef upon failure.  Ticket is a variable of the class
Authen::Krb4::Ticket, which can be obtained from mk_req().  fn is a path to
the appropriate srvtab.  /etc/srvtab will be used if fn is null.

=item get_cred(service,instance,realm)

Search the caller's ticket file for a ticket for the service and
instance in the given realm.  Returns a Authen::Krb4::Creds object, or undef
upon failure.  This method can be used to extract a ticket's session key.

=item get_key_sched(session)

Returns the key schedule for the session key 'session', which can be
obtained from rd_req() or get_cred().  The key schedule is an
Authen::Krb4::KeySchedule object.

=item mk_priv(in,schedule,key,sender,receiver)

Encrypts the data stored in 'in' and returns the encrypted data.  sender
and receiver should be in standard internet format, which can be achieved
using the inet_aton and sockaddr_in functions in the Socket module.

=item rd_priv(in,schedule,key,sender,receiver)

Decrypts the variable 'in' and returns the original data.  Other
parameters are as described in mk_priv()

=item sendauth(options,fh,service,inst,realm,checksum,laddr,faddr,version)

Obtains a ticket for the specified service, instance, and realm, and
writes it to the socket 'fh'.  Use recvauth to read the ticket on the
server.  'laddr' is the packed network address of the client, and 'faddr' 
is the packed network address of the server.  'options' can be any of the
following:

     Authen::Krb4::KOPT_DONT_MK_REQ
     Authen::Krb4::KOPT_DO_MUTUAL
     Authen::Krb4::KOPT_DONT_CANON

Use KOPT_DO_MUTUAL if you plan to do any encryption.  This function returns
a list containing the service ticket, the credentials, and the key schedule.

=item recvauth(options,fh,service,inst,faddr,laddr,fn)

Reads a ticket/authenticator pair from the socket 'fh'.  'options' can be
set as described above.  'faddr' is the packed network address of the
client, and 'laddr' is the packed network address of the server.  This
function returns a list containing the ticket, an AuthDat object, the key
schedule, and the version string.

=item get_pw_in_tkt(user,inst,realm,service,srealm,lifetime,password)

Tries to get an initial ticket for 'user' using 'password'.  This function
is especially useful for verifying a user's password. See the Kerberos
documentation for details.

=item get_svc_in_tkt(user,inst,realm,service,srealm,lifetime,srvtab)

Tries to get an initial ticket for 'user' using the private key stored in
'srvtab'.

=item read_service_key(user,inst,realm,kvno,srvtab)

Extracts the private key from a srvtab and returns it.  Use a kvno of 0
to extract the first matching entry.

=item dest_tkt()

Destroys the ticket file, much like kdestroy.

=item get_err_txt(n)

Returns a string containing a textual description of the kerberos error
number n.

=back

=head2 CLASSES & METHODS

There are four classes in the Authen::Krb4 module, Ticket, AuthDat, Creds,
and KeySchedule.  They are all simply abstractions of Kerberos 4 structures.  
You almost never need to worry about creating new objects--the functions
which return these objects create them for you (is this the best thing to 
do?).  The one exception is when you need to construct a Ticket object for
rd_req().  See below for details.

=over 4

=item Ticket

Contains a ticket for a specified service, instance, and realm.

=item * new(dat)

Returns a new Ticket object containing the data in 'dat'.  You must create
a new Ticket object on the server side for passing to rd_req().

=item * dat

The data contained in the ticket.  Looks like junk to the naked eye.

=item * length

The length of the data contained in 'dat'.

=item AuthDat

Contains the contents of the AUTH_DAT structure returned by rd_req().  See
below for the goodies.

=item * pname

Returns the principal's name.

=item * pinst

Returns the principal's instance.

=item * prealm

Returns the principal's realm.

=item * session

The session key.  Pass this to get_key_sched() to obtain a key schedule
for encryption.

=item * k_flags

Flags from the ticket.

=item * checksum

The checksum from the ticket.  See mk_req().

=item * life

Life of the ticket.

=item * time_sec

The time the ticket was issued.  localtime() can convert this to a nicer
format.

=item * address

The address in the ticket.  Useful for mutual authentication.

=item * reply

Reply to send to the client (not implemented yet).

=item Creds

Contains information retreived from your ticket file.

=item * service

The service name.

=item * instance

The instance

=item * realm

The realm

=item * session

Returns the session key.  Pass this to get_key_sched() to obtain a key
schedule for encryption.

=item * lifetime

The lifetime of the ticket.

=item * kvno

The key version number.

=item * ticket

The ticket itself.

=item * issue_date

The date the ticket was issued.

=item * pname

The name of the principal.

=item * pinst

The instance of the principal.

=item KeySchedule

You don't need to fool around with this.

=back

=head1 AUTHOR

Jeff Horwitz <jeff@smashing.org>

=head1 SEE ALSO

perl(1).

=cut
