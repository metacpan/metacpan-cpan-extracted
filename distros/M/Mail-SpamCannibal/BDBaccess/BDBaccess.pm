package Mail::SpamCannibal::BDBaccess;
use vars qw($VERSION);
$VERSION = do { q|char version[] = "bdbaccess 0.25, 1-14-14";| =~ /(\d+)\.(\d+)/; sprintf("%d.%02d",$1,$2)};
# returns $VERSION which is non-zero
__END__

=head1 NAME

bdbaccess -- safe Berkeley DB reader

distributed as perl module Mail::SpamCannibal::BDBaccess

=head1 SYNOPSIS

  bdbaccess [options]...

=head1 DESCRIPTION

There is no perl module for C<bdbaccess>. This is a documentation shell.

See L<IPTables::IPv4::DBTarpit::Tools>
to manipulate and examine the C<bdbaccess> database(s).

C<bdbaccess> is a B<C> daemon that provides access to Berkeley DB files via
a unix domain socket. C<bdbaccess> is configured for 
B<concurrent> use of the database, allowing similtaneous access and update 
of the database by other applications.

An application can access the data from a database opened by C<bdbaccess>
using one of the following methods:

  Open the domain socket.
  Send a query of the form:

	how, number, name

  where:
	how is a single byte
	= 0 for access by key
	= 1 - 255 for access by record number

  and:
  	number is 32 bits
  how = 0, number is a packed network address
  how = 1-255, number is a record number or zero

  and:
	name is the database to access
	TERMINATED with a NULL "\0"

NOTE: the key, be it a network address or a record number, should be in
network order. B<inet_aton> produces packed addresses in the correct
order, however record numbers must be packed correctly and natively are 
dependent on whether your host has a big endian or litte endian operating system.

C<bdbaccess> will respond in one of 3 modes depending on the access request.

MODE 1: For requests where B<how = 0 or 1>, The response will be as follows:

  key, data

where key is a 32 bit packed network address
and data contains either a 32 bit integer or
a string depending on the database queried.

If there is a database error, inlcuding the
record not being found, the key will return
INADDR_NONE, which is equivalent to
inet_aton('255.255.255.255'), and the data
will contain the integer value of the 
BerkeleyDB failure code

MODE 2: For any request where B<how is 1 or greater>, specifiying a record number of
zero (0) - which does not exist - will result in:

RETRIEVING DATABASE STATISTICS and VERSION NUMBER

The first record number in a Berkeley DB is record number ONE (1), there is
no record ZERO (0). If the bdbaccess daemon is queried by record for record
ZERO, it will return the version number of the underlying database in a form
that can be unpacked by inet_ntoa. The returned data record will contain the
number of keys or unique records currently in the database. Both of these
will be 32 bit fields.

  version number, number of keys

MODE 3: For any request where B<how is 1 or greater> and the record number specified
is one (1) or more, the bdbaccess daemon will return:

  uchar number, key1, key2, ... keyN

where "uchar number" is an 8 bit field containing the number of keys
returned, followed by N 32 bit fields containing packed network addresses.
The first key returned will be from the record number specified in the
query, followed by number+1, and so on...
The daemon will return "how" records or what is available if
it is less than the number requested (zero is a good anwser).

=head1 INSTALLATION

To build the C<bdbaccess> daemon, first install
IPTables::IPv4::DBTarpit, then type the following:

  perl Makefile.PL
  make
  make test
  make install

B<To restore the default directory configurations type:>

  rm config.db

B<Adjust the permissions for "bdbaccess" and its installation directories.
This is not done automatically since it may involve system directories.>

The Berkeley DB environment and databases can be created automatically.
However it is recommend that you use the B<initdb.pl> script in the    
..../Mail/SpamCannibal distribution directory. Adjust the permissions  
of the files and directories so that they
are accessible by the various applications that will be using the
information in the databases.

Lastly, copy B<rc.bdbaccess> to your startup directory so it is executed 
at boot up as:

  rc.bdbaccess start

Because the C<bdbaccess> daemon has only concurrent access to the
database, applications should not be written which use  db->cursor
operations these can block dameon access for normal put and sync operations. 
Instead, use repetitive read-by-record-number operations to gain sequential access  
to the data as provided in IPTables::IPv4::DBTarpit::Tools.

=head1 DEPENDENCIES

  Berkeley DB 2.6.4 or better http://www.sleepycat.com/

  IPTables::IPv4::DBTarpit, version 0.10

=head1 OPTIONS - short version

 Options:
  -r    : Alternate DB root directory   [default: /var/run/dbtarpit]

  -f    : Database file name
  -f    : Another db file name (up to 10 total)

  -s    : socket name [default 'bdbread'] (Note 1)
  -p	: port number to listen on (Note 1)
  -i	: use inetd (Note 1)

  -d    : Do NOT detach process.
  -l    : Log activity to syslog (Note 2)
  -o    : Output to stdout instead of syslog (Note 3)
  -V    : Print version information and exit
  -T    : Test mode - Print out debug info and exit
  -h    : Print this help information
  -?    : Print this help information

 Note 1:
  bdbaccess can be configured to listen on EITHER a unix
  domain socket or a port. If listening on a port, it can be
  run as a stand-alone daemon or from inetd. The listening
  modes are mutually exclusive.
 Note 2:
  'kill -USR1 <bdbaccess_PID>' to toggle logging on and off.
  If logging was not enabled at start this sets the '-l' flag
  If logging (-l | -v) are set this saves the value and turns off
  logging. If logging is presently toggled off it restores the 
  saved level (-l | -v)
 Note 3:
  This sends log information to stdout rather than to syslog.
  This option also implies and sets the -d option (Do NOT detach
  process).

=head1 OPTIONS - long version

=over 4

=item * -r /path

Set the database root aka path to db environment home 

  (default: /var/run/dbtarpit)

=item * -f filename

Database to open. Up to 10 of names may be specified on the command line.
There are no defaults, all databases that bdbaccess responds for must be
specified when the daemon is started.

=item * -h

Print the "short" help information and exit.

=item * -?

Print the "short" help information and exit.

=item * -d

Some people want to run C<bdbaccess> under the control of another process. This
keeps C<bdbaccess> from detaching and running as a daemon.

=item * -l

Logs any C<bdbaccess> activity to syslog.

=item * -o

This gives you the option to have C<bdbaccess> log information go to
stdout instead of the syslog. This option also sets "-d".

=item * -V

Print version information and exit.

=item * -T

This prints a bunch of diagnostic information an exits.

=back

=head1 DATABASE CONFIGURATION FILE [optional]

Usually used to increase database cache size.

Most of the configuration information that can be specified to 
DB_ENV methods can also be specified using a configuration file. 
If an environment home directory has been specified (done by default or
with the -r option to C<bdbaccess>) any file named DB_CONFIG in the 
database home directory will be read for lines of the format NAME VALUE.

One or more whitespace characters are used to delimit the two parts of 
the line, and trailing whitespace characters are discarded. All empty 
lines or lines whose first character is a whitespace or hash (#) 
character will be ignored. Each line must specify both the NAME and the 
VALUE of the pair. The specific NAME VALUE pairs are documented in the 
Berkeley DB manual for the corresponding methods.

See: http://www.sleepycat.com/docs/ref/env/db_config.html

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT AND LICENCE

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

=head1 SEE ALSO

L<IPTables::IPv4::DBTarpit::Tools> L<Mail::SpamCannibal::BDBclient>

=cut

1;

