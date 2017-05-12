package Mail::SpamCannibal::DNSBLserver;
use vars qw($VERSION);
$VERSION = do { q|char version[] = "dnsbls 0.55, 1-27-14";| =~ /(\d+)\.(\d+)/; sprintf("%d.%02d",$1,$2)};
# returns $VERSION which is non-zero
__END__

=head1 NAME

dnsbls -- a lightweight nameserver based on BDB

distributed as perl module Mail::SpamCannibal::DNSBLserver

=head1 SYNOPSIS

  dnsbls [options]...

=head1 DESCRIPTION and OPERATION

There is no perl module for C<dnsbls>. This is a documentation shell.

See L<IPTables::IPv4::DBTarpit::Tools>
to manipulate and examine the C<dnsbls> database(s).

C<dnsbls> is a B<C> daemon that is a specialized name server providing
DNSBL domain name services for the B<Mail::SpamCannibal> set of programs from their
database implemented using the Berkeley DB database found 
in all Linux distributions. C<dnsbls> is configured for 
B<concurrent> use of the database, allowing similtaneous access and update 
of the database by other applications.

C<dnsbls> returns A, NS, MX, TXT, SOA, and optionally AXFR records about its
immediate environment and numeric records in its B<tarpit> and B<blcontrib>
databases. Ordinary A, NS, MX, and SOA records are returned for the
environment while unique A and TXT records are returned when queried about
numeric hosts.

=over 4

=item * DNS query format

The DNS query format for numeric hosts follows the convention used by other
DNSBL servers. The IP address of the target host is reversed and the zone name
of the DNSBL server zone is appended. For example, if you want to see if
172.16.12.34 is listed in the bl.spamcannibal.com zone, you would look up the A
record for 34.12.16.172.bl.spamcannibal.com

  query about	172.16.12.34
  look up	34.12.16.172.bl.spamcannibal.com

=item * DNS answer format

If the IP address is not listed in the database, the DNSBL server will report
that the A record is non-existent. If the IP is listed in the database, an A
record will be returned with a value of 127.xxx.xxx.xxx

  127.0.0.2	added by this installation for spam violations
  127.0.0.X	added because it was found on another DNSBL list

TXT records are available for each numeric record returned. For return
records of 127.0.0.2, a default message is returned that was specified with
the command line -e option (more below). If the IP address is listed in the
B<blcontrib> database, then the text message found there is returned in the
TXT message.

Typically, rather than query for an A record, a query for type ANY will
return both the A record and the TXT record if the target IP address is
found in the DNSBL's databases.

=back

=head1 INSTALLATION

To build the C<dnsbls> daemon  type the following:

  perl Makefile.PL
  make
  make test
  make install

B<To restore the default directory configurations type:>

  rm config.db

B<Adjust the permissions for "dnsbls" and its installation directories.
This is not done automatically since it may involve system directories.>  

  Copy <install/directory>/config/dnsbls.conf.sample
  to   <install/directory>/config/dnsbls.conf

  and edit the configuration to fit your site.
  
The Berkeley DB environment and databases can be created automatically.
However it is recommend that you use the B<initdb.pl> script in the 
..../Mail/SpamCannibal distribution directory. Adjust the permissions 
of the files and directories so that they
are accessible by the various applications that will be using the
information in the databases.

Lastly, copy B<rc.dnsbls> to your startup directory so it is executed
at boot up as:

  rc.dnsbls start

Because the C<dnsbls> daemon has only concurrent access to the
database, applications should not be written which use  db->cursor
operations these can block dameon access for normal put and sync operations.
Instead, use repetitive read-by-record-number operations to gain sequential access
to the data.

=head2 sc_zoneload

The script sc_zoneload can be used to load a BIND zone file or a file
created by the BIND 'dig' utility or the Net::DNS::ToolKit - dig.pl utility
into the B<dnsbls> database. Please note that 
B<ALL 127.0.0.2 RESPONSES ARE CONVERTED TO 127.0.0.3> unless the -e
switch is used with this utility. See "DNS query format" above. 

=head1 DEPENDENCIES

  Berkeley DB 2.6.4 http://www.sleepycat.com/

	for testing and sc_zoneload support

  Net::DNS::Codes, version 0.06

  Net::DNS::ToolKit, version 0.07

  IPTables::IPv4::DBTarpit::Tools, version 0.11

=head1 OPTIONS - short version

 Options:
  -z    : Zone Name: bl.domain.com      [default: this hostname]
  -n    : Name Servers: abc.domain.com (Note 1)
  -N   : same as -n, but sets host name (Note 1)
  -a    : NS Address xxx.xxx.xxx.xxx    [default: lookup via DNS]
 ...there can be more than one set of entrys
  -n    : Another NS dul.domain.com (up to 15)
  -a    : eth0 NS Address yyy.yyy.yyy.yyy
  -a    : eth1 another NS Address (up to 10)
  -m    : 10 mark preference for MX entry (Note 2)

  -s    : 60 : SOA negative caching interval
  -u    : 43200 : SOA update/refresh interval
  -y    : 3600  : SOA retry interval
  -x    : 86400 : SOA expire
  -t    : 10800 : SOA ttl/minimum

  -c    : SOA zone contact: contact@somewhere.com

  -e    : ERROR: this RBL's error message  "http://....."
  -b    : Block AXFR transfers
  -L    : Limit zonefile build transfer rate (default 200,000 cps)
  -C    : Continuity (default allow zonefile discontinuity)
  -r    : Alternate DB root directory   [default: /var/run/dbtarpit]
  -i    : Alternate tarpit DB file      [default: tarpit]
  -j    : Alternate contrib DB file     [default: blcontrib]
  -k    : Alternate evidence DB file    [default: evidence]

  -p    : Port number [default: 53]
  -d    : Do NOT detach process.
  -l    : Log activity to syslog (Note 3)
  -v    : Verbose logging to syslog
  -o    : Output to stdout instead of syslog (Note 4)
  -V    : Print version information and exit
  -T    : Test mode - Print out debug info and exit
  -P    : Enable promiscious reporting of contributed entries (Note 5)
  -g    : Internal test flag - tcpmode, see ns.c, t/ns.t, CTest.pm::t_mode
  -h    : Print this help information
  -?    : Print this help information
Note 1:
  Name servers must be specified on the command line since this is the server
  that will ultimately answer requests for NS information about this zone.
  If the name server is another host, you don't have to specify the IP
  address(es). If not specified on the command line, IP address(es) will be
  retrieved via a DNS query. Your resolver must work! Use the -N switch to set
  to SOA host name as well as the IP address reported for the dnsbls host.
  If not set in this manner, it will default to the host name.
  Multiple NS entries may be made (up to 15), each with multiple IP addresses
  (up to 10). IP address entries must follow their NS entry and appear before
  the next subsequent NS entry. Continuation lines may be used as a convenience
  if the line length gets too long
Note 2:
  MX (mail server) records are entered in the same manner as NS records.
  The -m (NN) option is specified on the command line following either the
  name entry, -n foo.bar.com, or address entry, -a xx.xx.xx.xx, if used. 
Note 3:
  'kill -USR1 <dnsbls_PID>' to toggle logging on and off.
  If logging was not enabled at start this sets the '-l' flag
  If logging (-l | -v) are set this saves the value and turns off logging
  If logging is presently toggled off it restores the saved level (-l | -v)
Note 4:
  This sends log information to stdout rather than to syslog.  This option
  also implies and sets the -d option (Do NOT detach process).
Note 5:
  Entries contributed to the tarpit by remote DNSBL's are not normally
  reported by this DNSBL server. To do so would allow the addition of
  a blocked host to a network of contributing tarpit based DNSBL servers
  that could never be removed due to feed back between the servers.
  ENABLE this option only after careful consideration.

=head1 OPTIONS - long version

=over 4

=item * -z bl.domain.name

Specify the Zone Name for which this server is authoratative. If not
specified, the hostname of the server is used.

  i.e. thishost.foo.bar.com

=item * -n ns1.nsdomain.com

Specify one or more NS or MX servers that for this zone.
If the server is not THIS host, is not necessary to specify the IP
address(es). If the IP address(es) are not specified on the command line with
the -a option, they will be retrieved via a DNS query. Your resolver must
work!

Multiple NS or MX entries may be made (up to 15), each with multiple
IP addresses (up to 10 each). See the entry for option -a below.

=item * -N ns.nsdomain.com

Same as the -n switch, but also sets the host name for the SOA record as
well and the name and IP address reported for the dnsbls host.

=item * -a 172.16.2.3

Specifiy the IP address for an NS or MX command line option.
IP address entries must follow their NS or MX entry and appear before 
the next subsequent NS or MX entry on the command line.

If an IP address is not specified for an NS or MX record, it will be
retrieved using a DNS query.

Continuation lines may be used as a convenience if the line 
length gets too long.

  i.e.
  dnsbls -n ns1.spamcannibal.com -a 172.16.2.123 \
	-a 192.168.3.4

=item * -m 123

Mark the name entry as an MX server and specify the preference.

  i.e.
  dnsbls -n mx1.spamcannibal.com -m 10 -a 172.16.2.124
  -m    : 10 mark preference for MX entry (Note 2)

=item * -s nnnn

Set the negative caching interval/minimum TTL for the SOA record itself. The minimum of 
this value and the TTL/minimum (option -t below) determine the minimum
caching interval for authoratitive NXDOMAIN answers

	default 0

=item * -u nnnnn

Set the Update/refresh interval for the SOA record (seconds).

	default	43200

=item * -y nnnnn

Set the retrY interval for the SOA record (seconds).

	default	3600

=item * -x nnnnn

Set the eXpire interval for the SOA record (seconds).

	default	86400

=item * -t nnnnn

Set the TTL/minimum for the SOA record (seconds).

	default	10800

=item * -c contact@somewhere.com

Set the Contact name for the SOA record (an email address). The @ sign will
be replaced by a period (.) automagically. Default if not specified is
root@(zone name).

=item * -e "usually some Error message"

Specify the default message for TXT record for numeric queries that are
found in the B<tarpit> database but not found in the B<blcontrib> database.
The message may be up to 255 characters in length.
Usually something like this:

  "ERROR: connection tarpited. See: http://www.my.blacklist.org"

=item * -b

Block AXFR transfers. Prevents C<dnsbls> from answering AXFR requests. If you
wish to allow zone transfers or zone transfers to approved domains, it is
recommended that you run C<dnsbls> behind a firewall and use a standard DNS
server as a secondary to provide service to the internet.

=item * -L

Limit the rate at which zonefile generation occurs to prevent
over-utilization of the host system by the B<dnsbls> daemon. 

	default 200,000 characters per second

This feature may be disabled by setting it to '0'

  i.e.   ... -L 0

=item * -C (new but deprecated)

For very large zones and multiple daemons constantly adding
and removing records, it is very difficult to get a contiguous
zone dump where the starting and ending serial number is constant.
Instead, re-sync the cursor to ignore BerkeleyDB's behavior of
renumbering the records after an insert or delete. This allows
a zone dump to proceed when record values that have already
been read are deleted or inserts are made to the area the cursor
has already transversed. More specifically, records ahead of the
cursor will appear in the zone file as they are transversed, records
altered behind the cursor are not seen so effectively the zone is
frozen for dump purposes at the instant the cursor transverse it.
With "Continuity" set true, a single unperterbed snapshot of the
database is dumped to the zone file. However, this method will fail
if records are added or removed during the dump. The dump will
automatically retry 3 times. The practical aspect of this change
is that it is as if the zone was read a minute or two earlier in
the case of similtaneous database updates.

The old -C behavior is not desirable for large zones because it is not
practical for the database to remain static long enough for a
complete zone dump. The behavior is deprecated, the -C flag is
provided to retain the old behavior if for some strange reason
you find it desirable.

=item * -r /path

Set the database root (aka) path to db environment home 

  (default: /var/run/dbtarpit)

=item * -i filename

Set the tarpit database name (default: tarpit)

=item * -j filename

Set the contrib database name (default: blcontrib)

=item * -k filename

Set the evidence database name (default: evidence)

=item * -h

Print the "short" help information and exit.

=item * -?

Print the "short" help information and exit.

=item * -p 53

Set the port number that C<dnsbls> listens on. Default, standard DNS port 53.

=item * -d

Some people want to run C<dnsbls> under the control of another process. This
keeps C<dnsbls> from detaching and running as a daemon.

=item * -l

Logs any C<dnsbls> activity to syslog.

=item * -v

Logs verbosely to syslog.

=item * -o

This gives you the option to have C<dnsbls> log information go to
stdout instead of the syslog. This option also sets "-d".

=item * -V

Print version information and exit.

=item * -T

This prints a bunch of diagnostic information an exits.

=item * -P

Enable promiscious reporting of entries contributed to a tarpit based DNSBL
server by remote DNSBL's. These entries are not normally reported by this DNSBL server
because to do so could allow the addition of a blocked host to a network of contributing  
tarpit based DNSBL servers that could never be removed due to
feed back between the servers. ENABLE this option only after
careful consideration.

=item * -g

Undocumented option used during development and testing. If your curiosity
is just killing you then read the comments about is_tcp and tcpmode in ns.c,
t/ns.t, and CTest.pm -- function t_mode.

=back

=head1 SIGNALS

  HUP	logged if logging enabled, no action
  TERM	daemon exits
  QUIT	daemon exits
  INT	daemon exits
  USR1	toggle logging
  USR2	dump a zonfile to database home directory
	with the name "[zonename].in". During
	the dump, a temporary file named
	"[zonename].in.tmp" is created

=head1 DATABASE CONFIGURATION FILE [optional]

Usually used to increase database cache size.

Most of the configuration information that can be specified to 
DB_ENV methods can also be specified using a configuration file. 
If an environment home directory has been specified (done by default or
with the -r option to C<dnsbls>) any file named DB_CONFIG in the 
database home directory will be read for lines of the format NAME VALUE.

One or more whitespace characters are used to delimit the two parts of 
the line, and trailing whitespace characters are discarded. All empty 
lines or lines whose first character is a whitespace or hash (#) 
character will be ignored. Each line must specify both the NAME and the 
VALUE of the pair. The specific NAME VALUE pairs are documented in the 
Berkeley DB manual for the corresponding methods.

See: http://www.sleepycat.com/docs/ref/env/db_config.html

=head1 DATABASE FORMAT

B<dnsbls> and B<IPTables::IPv4::DBTarpit::Tools> use the Berkeley DB
database. The database is of type BTREE, opened for concurrent access and
sequential record access. These database files have similar formats.

  Files: tarpit, blcontrib

  Key:	32 bit packed network address as produced by inet_aton
  Data:	tarpit
	32 bit unsigned integer, number of seconds since 1-1-70

	blcontrib
	32 bit packed network address as produced by inet_aton
	which is the return code (127.xxx.xxx.xxx IP address)
	returned as the A record for the query followed by a 
	null byte, followed by a null terminated ascii string
	usually containing the "ERROR" message to be issued by
	an querying mail server. Additional data are appended 
	the record after the the second null for use by other
	members of the spamcannibal tool suite.

  example: 'blcontrib'

    $data = pack("a4 x A* x",inet_aton('127.0.0.3'),
	"Error: blacklisted by http://www.some-bl.com";

    ($netaddr,$txt) = unpack("("a4 x a*",$data);

  Database creation hints for 'C' api:

  * environment flags	*
    u_int32_t eflags = DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL;
  * db flags *
    u_int32_t dflags = DB_CREATE;
    u_int32_t info = DB_RECNUM;
    DBTYPE type = DB_BTREE;
    int mode = 0664;

environment and database open statements vary depending on the version of
BerkeleyDB used. See the code in bdb.c for specifics.

  Database creation hints for Perl api:

    my %env = (
        -Home   => $self->{dbhome},
        -Flags  => DB_CREATE | DB_INIT_CDB | DB_INIT_MPOOL,
    );

    $self->{"_db_${db}"}  = new BerkeleyDB::Btree
          -Filename     => $self->{dbfilename},
          -Flags        => DB_CREATE,
          -Property     => DB_RECNUM,
          -Env          => $self->{env}
          or die "Cannot open database $db: $! $BerkeleyDB::Error\n" ;

NOTE:  (in BIG LETTERS!)

Berkeley DB provides a "1" based numbering system for record numbers. i.e.
the first record number is "1". By contrast, perl-BerkeleyDB is a "0" based
numbering system with the first record number in the same database
designated as "0". This means that a database read and written with the 'C' api 
will have its record numbers begin with "1" while the same database accessed with 
perl-BerkeleyDB will have record numbers starting with "0".

The IP address 127.0.0.0 is used in the "tarpit" database to store the
serial number of the current SOA reported.

=head1 * STANDALONE SCRIPT EXAMPLES

DNSBLserver may be used as a standalone DNS server by adding and removing data
from the 'tarpit' and 'blcontrib' databases. DNSBL reports entries found in
both 'tarpit' + 'blcontrib' only if the "promiscous" (-P) flag is enabled on
startup. 

  i.e. rc.dnsbls start -P

However, the 'blcontrib' database is optional and is used only to
provide custom 'A' and 'TXT' record responses for listed IP addresses.

'tarpit' contains the IP addresses of black listed. If there is no
corresponding entry in 'blcontrib', then DNSBLserver will report an 'A'
record of 127.0.0.2 and a TXT record returning the required default ERROR message that
was supplied when the daemon was started.

If there is a corresponding 'blcontrib' for a 'tarpit' entry, then
DNSBLserver will report 'A' and 'TXT' records based on the content of the
'blcontrib' record. This may be set to "anything", however, the server will
not respond to queries about this IP address unless the "promiscous" (-P)
flag is set on the command line at start up. The only exception is that the
server always reports 127.xxx.xxx.xxx entries.

These code snippets demonstrate how to insert data into the DNSBLS database.
See the sc_admin.pl script in the Mail::SpamCannibal distribution for a more
comprehensive example.

The following assumptions are made:

  The database environment directory
  dbhome	/var/run/dbtarpit

  primary database name 'tarpit'

  secondary database name 'blcontrib'

  #!/usr/bin/perl
  # script snippet to insert data

  use IPTables::IPv4::DBTarpit::Tools qw(
	inet_aton
  );
  my %db_config = (
	dbhome	=> '/var/run/dbtarpit',
	dbfile  => ['tarpit'],
	txtfile	=> ['blcontrib'],
  }
  my $tool = new IPTables::IPv4::DBTarpit::Tools %db_config;
  # add IP with time stamp NOW
  $tool->touch('tarpit',inet_aton('111.222.33.44'));
  # unneeded if db_close follows immediately
  $tool->sync('tarpit');

  # or add custom time stamp
  # $tool->touch('tarpit',inet_aton(111.222.33.44),1059928115);

  ###
  # to add custom 'A' and 'TXT' response
  $tool->put('blcontrib',inet_aton('111.222.33.44'),
	pack("a4 x A* x",inet_aton('127.0.0.6'),
	"Error: for removal see foo.bar.com")));
  # unneeded if db_close follows immediately
  $tool->sync('blcontrib');

  ###
  # to delete a record
  $tool->remove('tarpit',inet_aton('111.222.33.44'));
  # unneeded if db_close follows immediately
  $tool->sync('tarpit');
  $tool->remove('blcontrib',inet_aton('111.222.33.44'));
  # unneeded if db_close follows immediately
  $tool->sync('blcontrib');

  $tool->db_close();

Addition of an IP address to the data base where one already exists simply
overwrites the old one. Attempted removal of a non-existent entry is
harmless.

All of the above functions are also available in the 'C' library interface.
See the man (1) pages for libdbtarpit.

=head1 APPLICATIONS

... aahhh! now you come to the fun part.

See L<Mail::SpamCannibal>

Used with C<dbtarpit>, it "eats" the spammer for lunch. In less graphic
terms, SpamCannibal is a set of tools that helps you identify the
originating mail server for the spam message and add the offender's IP
address to the tarpit. There are "trolling" tools to allow you to check the
DNSBL databases for hits against C<dbtarpit's> archive database and a host of
other goodies to help make life difficult for spammers. And of course, there
is this DNSBL server which will allow you to provide information about what IP
addresses are in your spam tarpit.

What happens to the spammer when his host hits the tarpit? Well... when a
mass mailer hits the tarpit, the thread that is sending mail freezes and
will not deliver any further spam until it is detached (usually manually)
from the tarpit. Mail sending programs deliver a large number of addresses
to the remote receiver which accepts the mail for those domains for which
they have records while ignoring the rest. Tarpitting the sender has the
effect of not only stopping the delivery of spam for YOUR domain, but all
other domains which may be in the sending thread's output stream. Sure it's 
only one thread, but if there are lots of spam tarpits then lots of spam 
threads will get trapped and the cost of sending spam will rise. That's a
GOOD thing :-)

I'm sure you can think of many other applications, but this one is on the
top of my list.

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

L<IPTables::IPv4::DBTarpit::Tools>

=cut

1;

