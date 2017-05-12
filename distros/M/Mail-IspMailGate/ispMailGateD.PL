#!/usr/bin/perl

use lib "lib";
use vars qw($script);

use Config ();
use Mail::IspMailGate::Config ();


my $cfg = $Mail::IspMailGate::Config::config;
sub Substitute ($) {
    my $s = shift;
    return $cfg->{$s} if exists $cfg->{$s};
    return $Config::Config{$s} if exists $Config::Config{$s};
    die "Unknown variable: $s";
}
$script =~ s/\~(\w+)\~/Substitute($1)/eg;

if (!open(FILE, ">ispMailGateD")) {
    die "Cannot open ispMailGate for writing: $!";
}



if (!(print FILE $script)  ||  !close(FILE)) {
    die "Error while writing $script: $!";
}


BEGIN { $script = <<'SCRIPT' };
~startperl~
#
#    ispMailGate - delivery agent for filtering and scanning E-Mail
#
#
#    This program is designed for being included into a sendmail
#    configuration as a delivery agent. Mail is filtered by the
#    agent and fed into sendmail again for continued processing.
#
#    Currently available filters include
#
#        - a virus scanner (requires apropriate external binary)
#        - PGP en-/decryption
#        - compressing and decompressing with gzip or other external
#          binaries
#
#
#    Authors:    Amar Subramanian
#                Grundstr. 32
#                72810 Gomaringen
#                Germany
#
#                Email: amar@neckar-alb.de
#                Phone: +49 7072 920696
#
#         and    Jochen Wiedmann
#                Am Eisteich 9
#                72555 Metzingen
#                Germany
#
#                Email: joe@ispsoft.de
#                Phone: +49 7123 14887
#
#
#    Version history: 04-Apr-1998	Initial version
#                                       (Amar and Jochen)
#
############################################################################


require 5.005;
use strict;

use Sys::Syslog ();
use Mail::IspMailGate ();
use Getopt::Long ();


delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
$ENV{'PATH'} = '/bin:/usr/bin';

my $debugging = 0;
my @args = @ARGV;


sub ErrExit ($) {
    my($str) = shift;
    Sys::Syslog::syslog('err', $str);
    print STDERR $str;
    exit 1;
}


############################################################################
#
#    Name:    Usage
#
#    Purpose: Print usage message
#
#    Inputs:  None
#
#    Result:  Nothing, exits with error status
#
############################################################################

sub Usage () {
    my $cfg = $Mail::IspMailGate::Config::config;
    my $tmpDir = $cfg->{'tmp_dir'};
    my $pidFile = $cfg->{'pid_file'};
    my $facility = $cfg->{'facility'};
    my $unixSock = $cfg->{'unix_sock'};
    my $mailHost = $cfg->{'mail_host'};

    print << "EOF";
Usage:
  $0 [options] -s|-server|--server
  $0 [options] -f sender recipient1 [... recipientN]

Possible options are:
  --debug		Turn on debugging mode
  --nomails		Do not send mails, but print them to stdout. This is
			mainly useful for debugging purposes.
  --server		Run as a server; default is reading a single mail from
			stdin.
  --tmp-dir=<dir>	Set directory for temporary files; defaults to
			$tmpDir.
  --mail-host=<h>	Use the given host for delivery; defaults to
			$mailHost.

Server-mode options are:
  --facility=<f>	Set syslog facility; defaults to $facility.
  --pid-file		Set path of PID file; defaults to $pidFile.
  --unix-sock		Set path of Unix socket; defaults to $unixSock.
  --nofork		Suppress forking. For debugging only.
EOF

    exit(1);
}


############################################################################
#
#    Name:    ReadClientArray
#
#    Purpose: Read an array of strings from the client
#
#    Inputs:  $sock - Socket to read from
#
#    Returns: Array read by the client; aborts in case of trouble
#
############################################################################

sub ReadClientArray ($) {
    my($sock) = @_;
    my($argSize);
    if (read($sock, $argSize, 32)  &&  $argSize =~ /^(\d+)/) {
	$argSize = $1;
    } else {
	ErrExit("Error while reading array size from client: $!");
    }
    my($argString) = '';
    while (length($argString) < $argSize) {
	my($result) = read($sock, $argString, $argSize - length($argString),
			   length($argString));
	if (!$result) {
	    ErrExit("Error while reading array data: $!");
	}
    }

    # Remove a trailing \0\n from $argString
    $argString =~ s/\0?\n$//s;
    split(/\0/, $argString);
}


############################################################################
#
#    This is main().
#
############################################################################

sub catchChilds {
    my $pid = wait;
    $SIG{CHLD} = \&catchChilds;
}

sub Main ($$$$$) {
    my($fh, $from, $recipients, $attr, $host) = @_;
    my($parser) = Mail::IspMailGate->new($attr);
    $parser->Main($fh, $from, $recipients, $host);
}

{
    #
    #   Process command line arguments
    #
    my($arg, $daemon, $from);
    my $cfg = $Mail::IspMailGate::Config::config;
    my $unixSock = $cfg->{'unix_sock'};
    my $facility = $cfg->{'facility'};
    my $pidFile = $cfg->{'pid_file'};
    my $mails = 1;
    my $fork = 1;
    my $tmpDir = $cfg->{'tmp_dir'};
    my @args = @ARGV;
    my $deliveryHost = $cfg->{'mail_host'};

    Getopt::Long::GetOptions('server', \$daemon,
			     'unix-sock', \$unixSock,
			     'facility', \$facility,
			     'mails!', \$mails,
                             'fork!', \$fork,
                             'pid-file=s', \$pidFile,
                             'tmp-dir=s', \$tmpDir,
                             'from=s', \$from,
			     'debug', \$debugging,
			     'help', \&Usage,
			     'mail-host', \$deliveryHost
                            );
    my @recipients = @ARGV;

    if ($daemon && (@recipients || $from)) {
	print("Option --server is not compatible with --from or recipient",
	      " lists.\n");
	Usage();
    }
    if (!$daemon  &&  !@recipients) {
	print("Missing recipients.\n");
	Usage();
    }

    if ($deliveryHost eq 'ispmailgate') {
	$deliveryHost = undef;
    }

    my $uid = $cfg->{'mail_user'};
    if ($uid !~ /^\-?\d+$/  &&
	!defined($uid = ((getpwnam($uid))[2]))) {
	ErrExit("Unknown user: $cfg->{'mail_user'}");
    }
    my $gid = $cfg->{'mail_group'};
    if ($gid !~ /^\-?\d+$/  &&
	!defined($gid = ((getgrnam($gid))[2]))) {
	ErrExit("Unknown group: $cfg->{'mail_group'}");
    }

    if (defined(&Sys::Syslog::setlogsock)) {
	# This fails on some Solaris systems ...
        eval { Sys::Syslog::setlogsock('unix'); };
    }
    &Sys::Syslog::openlog('ispMailGateD', 'pid', $facility);

    my($attr) =
        { 'debug' => $debugging,
          'noMails' => !$mails,
	  'tmpDir' => $tmpDir
	};

    if (!$daemon) {
	$) = $gid;
	$( = $gid;
	$> = $uid;
	$< = $uid;
	Sys::Syslog::syslog('debug',
                            "Command line arguments: " . join(" ", @args))
	    if ($debugging);
	Main(\*STDIN, $from, \@recipients, $attr, $deliveryHost);
	exit(0);
    }

    #
    #   This is the servers main part
    #
    Sys::Syslog::syslog('notice', "ispMailGateD starting");
    if (!socket(SERVER, &Socket::AF_UNIX(), &Socket::SOCK_STREAM(), 0)) {
	ErrExit("Cannot create socket: $!");
    }
    unlink $unixSock;
    if (!bind(SERVER, &Socket::sockaddr_un($unixSock))) {
	ErrExit("Cannot bind: $!");
    }
    if (!listen(SERVER, &Socket::SOMAXCONN)) {
	ErrExit("Cannot listen: $!");
    }
    if (!chown $uid, $gid, $unixSock) {
	ErrExit("Cannot change ownership of $unixSock: $!");
    }
    if (!chmod 0660, $unixSock) {
	ErrExit("Cannot change mode of $unixSock: $!");
    }

    if ($fork) {
	$SIG{CHLD} = \&catchChilds;

	# Detach from the shell, as good as possible
	my $pid;
	ErrExit("Cannot fork(): $!") unless defined($pid = fork());
	exit 0 if $pid;

	if (open(PID, ">$pidFile")) {
	    print PID "$$";
	    close(PID);
	}

	open(STDOUT, ">/dev/null");
	open(STDERR, ">&STDOUT");
	open(STDIN, "</dev/null");
    }

    $) = $gid;
    $( = $gid;
    $> = $uid;
    $< = $uid;

    &Sys::Syslog::syslog('debug',
			 'Waiting for connections at %s', $unixSock)
        if $debugging;

    while (accept(CLIENT, SERVER)) {
	&Sys::Syslog::syslog('debug', 'Server accepting child')
	    if $debugging;

	#
	#  Fork a child
	#
	if ($fork) {
	    my $pid;
	    if (!defined($pid = fork())) {
		Sys::Syslog::syslog('err', "Cannot fork: $!");
		print STDERR "Cannot fork: $!";
		next;
	    } elsif ($pid) {
		#
		#  This is the parent
		#
		close(CLIENT);
		next;
	    }
	}

	#
	#  This is the child, read the environment array
	#
	my($path) = $ENV{'PATH'};
	%ENV = ();
	my($arg);
	foreach $arg (ReadClientArray(\*CLIENT)) {
	    if ($arg =~ /(.*?)=(.*)/) {
		$ENV{$1} = $2;
	    }
	}
	delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
	$ENV{'PATH'} = $path;

	# Read the argument array
	my($from, $getFrom);
	my($recipients) = [];
	foreach $arg (ReadClientArray(\*CLIENT)) {
	    if ($getFrom) {
		$from = $arg;
		undef $getFrom;
	    } else {
		if ($arg eq '-f') {
		    $getFrom = 1;
		} else {
		    push(@$recipients, $arg);
		}
	    }
	}
	if (!@$recipients) {
	    ErrExit('Missing recipients');
	}
	if (!$from) {
	    ErrExit('Missing sender');
	}

	Main(\*CLIENT, $from, $recipients, $attr, $deliveryHost);
	exit(0);
    }

    ErrExit("No connection: $!");
}
__END__


=head1 NAME

ispMailGate - a general purpose filtering MDA for sendmail


=head1 WARNING! WARNING! WARNING!

This is an alpha release! What you are using now is tested by using a
comparatively small test suite in our local environment. You are perhaps
planning to include this software in a production environment. We don't
discourage to do so, but we strongly advise you to be extremely careful.
In particular, start by filtering only mails for a very small number of email
adresses, perhaps your own and something similar. That is, be extremely
cautios when modifying your sendmail configuration.

See INSTALLATION and SENDMAIL CONFIGURATION below for a detailed description
of your sendmail setup.


=head1 SYNOPSIS

For running standalone:

    ispMailGateD -f <sender> <recipient1> [... <recipientN>]

For running as a daemon:

    ispMailGateD -s [-d] [-t <tmpdir>] [-a <facility>] [-p <pidfile>]
        [-u <unixsock>]


=head1 DESCRIPTION

IspMailGate is a general purpose email filtering system. The program gets
included into a sendmail configuration as a delivery agent (MDA) and the
usual sendmail rules can be applied for deciding which emails to feed into
ispMailGate. The true filters are implemented as modules, so its easy to
extend the possibilities of ispMailGate. Current modules offer automatic
compression and decompression, encryption, decryption and certification
with PGP or virus scanning.

The program can run in a usual standalone mode, but that's not recommended,
except for debugging and similar tasks. The recommended mode will be
running the program as a server, completely independent from sendmail.
A small C program (called a wrapper) will instead be configured as
sendmails MDA. This wrapper connects to the server via a well known Unix
socket (by default ~unix_sock~), passes its command line arguments and
standard input to the server and disconnects. Obviously this second
solution has much better performance as you load the Perl interpreter
only once.


=head2 Command Line Interface

The following options affect ispMailGate's behaviour:

=over 4

=item --facility=<fac>

Advices the ispMailGate to use syslog facility <fac>. By default syslog
entries are written as facility ~facility~.

=item --debug

The program runs in debugging mode, logging information into the syslog.
Perhaps more information than you like ... :-)

=item --from=<sender>

Sets a mails sender.

=item --server

Tells the program not to run in standalone mode and instead detach from
the shell to enter server mode. This mode is currently not usable, as
the wrapper is not yet available.

=item --tmp-dir=<dir>

Sets the programs directory for temporary files to <dir>. When unpacking
a complex and big multipart mail, the ispMailGate may need surprisingly
much space. By default ~tmp_dir~ is used.

=item --unix-sock=<sock>

Tells the server to listen on file <sock> for unix socket connections.
By default the server uses ~unix_sock~.

=back


=head1 INSTALLATION

=head2 Requirements

To start with the requirements: You need

1.) A running sendmail (recommended: 8.9.3 or later); if you don't have
sendmail or an older version, you find the current release at

    ftp://ftp.sendmail.org/pub/sendmail

2.) A late version of Perl (5.005 or later); if you don't
have Perl, get it from any CPAN mirror, for example

    ftp://ftp.funet.fi/pub/languages/perl/CPAN/src/5.0

3.) The MIME-tools module (version 4.116 or later), its prerequired
modules (MailTools, MIME-Base64 and IO-Stringy) and the IO::Tee
module (version 0.61 or later). All these modules are available from
any CPAN mirror, for example

    ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/Mail
    ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/MIME
    ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/IO

Installing a Perl module is quite easy, btw. Either you use the
automatic CPAN interface (requires an Internet connection or
something similar) by executing

    perl -MCPAN -e shell

or you fetch the modules with FTP, extract the tar.gz files, go into
the distribution directory (for example MIME-tools-4.116) and do a

    perl Makefile.PL
    make
    make test
    make install

You'll like it! :-)

=head2 System preparation

Although ispMailGate is usually started as root, because certain
initialization settings need root permissions, it must not continue
running as root. Instead it impersonates itself to the same UID and
GID that sendmail uses for delivering mails. In what follows, I
assume UID I<daemon> and GID <mail>, as used on a Red Hat Linux
box.

IspMailGate needs its own directory for creating temporary files.
Usually this could be C</var/spool/ispmailgate> or something
similar. Make sure that the daemon user from above, (but noone else)
has access to this directory:

    mkdir /var/spool/ispmailgate
    chown daemon /var/spool/ispmailgate
    chgrp mail /var/spool/ispmailgate
    chmod 700 /var/spool/ispmailgate

=head2 Program installation

The program is installable like any other Perl module. Indeed, you
can even use the automatic CPAN installation. If you are not used
to CPAN installation or cannot use the CPAN shell, you need to
perform a manual installation: First, fetch the archive from any
CPAN mirror, for example

    ftp://ftp.funet.fi/pub/languages/perl/CPAN/authors/id/JWIED

and extract the archive with

    gzip -cd Mail-IspMailGate-<version>.tar.gz | tar xf -

After that, do a

    cd Mail-IspMailGate-<version>

and do a

    perl Makefile.PL
    make
    make test		# You need to be root here!
    make install	# You need to be root here!

While running "perl Makefile.PL", you'll be prompted a lot of questions.
In general you can answer them by simply hitting return, the defaults
should be fine. The questions are explained in the section CONFIGURATION
FILE below, because your answers are used for creating this config file.
L<CONFIGURATION FILE>.

If "make test" reports any errors, let me know.


=head1 SENDMAIL CONFIGURATION

To understand the required sendmail configuration, let's first take
a look at the following diagram:

	+----------------+
	| Incoming       |
	| mail for       |
	| joe@ispsoft.de |
	+----------------+

	    |
	    | Port 25
	    | (SMTP)
	    |

	+----------------------+        +---------------------+
	|                      |        |                     |
	|  Sendmail, with      |        |  IspMailGate        |
	|  IspMailGate support |  ----> |  receives and       |
	|  integrated          |        |  processes the mail |
	|                      |        |                     |
	+----------------------+        +---------------------+

	   V					|
						|
        +---------------------------+	        | Port 26
	| mailertable:              |	        |
	| ispsoft.de => ispmailgate |           |
	+---------------------------+	        |

				      +-----------------------+
        +-------------------------+   |			      |
        | Other mailertable:      |   |  Second sendmail,     |
        | ispsoft.de => mailhost  | < |  without IspMailGate, |
        +-------------------------+   |  other mailertable    |
				      |                       |
				      +-----------------------+

The idea is that we have two sendmail instances: The first one is
accepting mails from the outside world (it could well be smapd
or another SMTP wrapper).

Mails accepted by the first instance will optionally be piped into
IspMailGate, depending on your mailertable or whatever method you
choose for selecting a delivery agent.

As soon as IspMailGate has processed your mails, they cannot be
delivered to the same sendmail: Sendmail would detect the same
recipients as before, and feed the mail back into IspMailGate.
The immediate result would be an endless loop.

Instead we configure another instance of sendmail, running for
example on port 26, which accepts mails by IspMailGate. This
second sendmail will typically be protected to the outside
world, for example by using a packet filter.

Of course it is possible to replace the second sendmail with
a mail server running on another machine. However, I discourage
you to do so, because IspMailGate has no integrated spooling
system: If the foreign host would be down, you mail would be
lost forever! However, you can easily configure the second
sendmail for delivery to the same host, this time using a
safe spooling system.


=head2 Details

Before reading on, you should have some basic knowledge on sendmail
configuration. In particular you should be used to work with

=over

=item sendmail.mc

the m4 macro file that is used to create sendmail.cf (If you
had the impression that hacking sendmail.cf is the method
of choice for configuring sendmail, your knowledge of sendmail
is a little bit too basic :-)

=item mailertable

the file that is used for selecting delivery agents, based on
a domain name

=item sendmail.cw

the file that is used for selecting "local" domains.

=back

All these files are described in the file cf/README from the
sendmail distribution. The same file is available online as
sendmail documentation on http://www.sendmail.org. I strongly
encourage you to read about it.

In what follows I assume that we have two hosts: I<gate.ispsoft.de>
is a firewall running IspMailGate and two instances of sendmail.
I<mail.ispsoft.de> is the real mail server. Mail for the domain
I<ispsoft.de> shall be checked by IspMailGate, passed to the
second instance of sendmail and finally delivered to the real
mail server.

Furthermore I assume that the cf files from the sendmail distribution
are in F</usr/lib/sendmail-cf>. This is the case on a Red Hat Linux box,
if you have installed the RPM package I<sendmail-cf>. It may be
F</usr/share/sendmail> with SuSE Linux or anything else on another
system.

First of all we copy the file examples/ispmailgate.m4 from the
IspMailGate distribution to F</usr/lib/sendmail-cf/mailer>.
Then we create the following files:

=over

=item  /etc/mail/sendmail.mc

  divert(-1)
  include(`/usr/lib/sendmail-cf/m4/cf.m4')
  define(`confCW_FILE', `/etc/mail/sendmail.cw')
  define(`ALIAS_FILE', `/etc/mail/aliases')
  define(`QUEUE_DIR', `/var/spool/mqueue')
  OSTYPE(`linux')
  FEATURE(use_cw_file)
  FEATURE(mailertable, `hash -o /etc/mail/mailertable')
  FEATURE(virtusertable, `hash -o /etc/mail/virtusertable')
  FEATURE(access_db)
  MAILER(local)
  MAILER(smtp)
  MAILER(ispmailgate)

=item /etc/mail2/sendmail.mc

  divert(-1)
  include(`/usr/lib/sendmail-cf/m4/cf.m4')
  define(`confCW_FILE', `/etc/mail/sendmail.cw')
  define(`ALIAS_FILE', `/etc/mail/aliases')
  define(`QUEUE_DIR', `/var/spool/mqueue2')
  define(`confDAEMON_OPTIONS', `port=26')
  OSTYPE(`linux')
  FEATURE(use_cw_file)
  FEATURE(mailertable, `hash -o /etc/mail2/mailertable')
  FEATURE(virtusertable, `hash -o /etc/mail/virtusertable')
  FEATURE(access_db)
  MAILER(local)
  MAILER(smtp)

You see, this is almost the same file, with three exceptions:

=over

=item 1.)

The first sendmail is running on the default port 25, because it has
no special port settings. The second sendmail is running on port 26.

=item 2.)

The first sendmail is using F</etc/mail/mailertable>, the second has
F</etc/mail2/mailertable>.

=item 3.)

The second sendmail doesn't have a mailer ispmailgate.

=item 4.)

The first sendmail is using another spool directory, F</var/spool/mqueue2>.
(I am not sure, whether this is required, however it doesn't harm, so let's
be on the safe side.)

=back

=item /etc/mail/mailertable

  ispsoft.de	ispmailgate:ispsoft.de

=item /etc/mail2/mailertable

  ispsoft.de	ispmailgate:mail.ispsoft.de

You see, the only difference between these two instances of mailertable
is that the domain I<ispsoft.de> is treated different.

=back

Finally we have to execute some commands to get this configuration
running:

	mkdir /var/spool/mqueue2
	# The following should match the settings of
	# /var/spool/mqueue exactly.
	chown root /var/spool/mqueue2
	chgrp root /var/spool/mqueue2
	chmod 755 /var/spool/mqueue

	cd /etc/mail
	m4 sendmail.mc >sendmail.cf
	makemap hash mailertable <mailertable
	cd /etc/mail2
	m4 sendmail.mc >sendmail.cf
	makemap hash mailertable <mailertable

The above is fine for Linux. On other operating systems you might
need to use GNU m4 rather than the builtin m4 and replace the map
type I<hash> with I<dbm>. In particular this applies to Solaris.

Finally, kill any running sendmail and start the new versions
with

	chmod 755 /etc/mail /etc/mail2
	chmod 644 /etc/mail/sendmail.cf /etc/mail2/sendmail.cf
	/usr/sbin/sendmail -C /etc/mail/sendmail.cf -bd -q1h
	/usr/sbin/sendmail -C /etc/mail2/sendmail.cf -bd -q1h

(The chmod commands because sendmail is I<really> picky about
group writable files and directories.)


=head1 CONFIGURATION FILE

The program depends on a local configuration file, read as the
Mail::IspMailGate::Config module. In other words, this configuration file
is pure Perl code defining certain variables under the name space
Mail::IspMailGate::Config. The module is read from the file
~installsitelib~/Mail/IspMailGate/Config.pm.

The following variables are meaningful to the program:

=over 4

=item VERSION

The programs version; do not modify without a good reason.

=item tmp_dir

Set's the default directory for creating temporary files, currently
~tmp_dir~. You can modify this with the C<--tmpdir> directive, see
above.

=item unix_sock

The unix socket that the client connects to, currently ~unix_sock~.
You can use the C<--unixsock> argument for overwriting the default.

=item pid_file

The PID file where a running server stores its PID, currently ~pid_file~.
You can use the C<--pidfile> argument for overwriting the default.

=item mail_user

=item mail_group

IspMailGate is running as this user and group, by default
~mail_user~ and ~mail_group~.

=item mail_host

The host to use for passing mails after processing them by the
mail filter. By default 'localhost' is used, in other words, the
mails are immediately passed back to sendmail.

To omit a possible loop problem, sendmail must be ready for handling
email addresses like user@domain.ispmailgate. For such addresses it
must rip off the .ispmailgate and guarantee not to feed the mails
back into ispMailGate. See L<SENDMAIL CONFIGURATION> below.

=item recipients

An array ref with list of possible recipients/senders and filter lists
that describe how to handle mails being sent from the senders to the
recipients.

Each element of the list is a hash ref with the following elements:

=over 4

=item recipient

A regular expression (Perl regular expression, that is) for matching
the recipient address. An empty string matches any recipient.

=item sender

A regular expression (Perl regular expression, again) for matching
the sender address. An empty string matches any sender.

=item filters

An array ref to a list of filters. A mail will be fed into that list
(from the left to the right) and the final result will be returned to
sendmail. See L<Mail::IspMailGate::Filter(3)> for a description of
creating filters.

=back

The recipient list will be read top to bottom, the first match decides
which rule to choose. See the example configuration below for some
example rules.

=item default_filter

If no element of the recipients list matches an emails senders and
recipients, the filters from this variable will be choosen. By default
it contains a dummy filter:

  $cfg->{'default_filter'} = ['Mail::IspMailGate::Filter::Dummy'];

=item packer

This variable belongs to the Packer module. See
L<Mail::IspMailGate::Packer(3)> for details.

=item virscan

These belong to the VirScan module. See L<Mail::IspMailGate::VirScan(3)>
for details.

=item pgp

This variable belong to the PGP module. See L<Mail::IspMailGate::PGP(3)> for
details.

=back


=head2 Example Configuration

It might help to look at a commented example of the configuration file:

    package Mail::IspMailGate::Config;

    $Mail::IspMailGate::Config::config = bless( {
    # Config file version
      'VERSION' => '1.100',
    # Path of external virus scanner or empty
      'antivir_path' => '/usr/bin/antivir',
    # List of filters to use by default
      'default_filter' => [
        'Mail::IspMailGate::Filter::Dummy'
      ],
    # Facility to use for syslog
      'facility' => 'mail',
    # Path of the gzip binary (for extracting .gz files) or empty
      'gzip_path' => '/usr/bin/gzip',
    # Path of the LhA binary (for extracting .lha files) or empty
      'lha_path' => '',
    # GID under which sendmail is executing external binaries
      'mail_group' => 'mail',
    # Mail host (with optional :port) to use for final delivery
      'mail_host' => 'localhost:26',
    # UID under which sendmail is executing external binaries
      'mail_user' => 'daemon',
    # Configuration of the packer
      'packer' => {
        'gzip' => {
          'neg' => '$gzip_path -cd',
          'pos' => '$gzip_path -c'
        }
      },
    # PID file to use for the server
      'pid_file' => '/var/run/ispmailgate.pid',
    # E-Mail address of the administrator
      'postmaster' => '[A',
    # List of senders/recipients and associated filters
      'recipients' => [
        {
          'filters' => [
            'Mail::IspMailGate::Filter::VirScan'
          ],
          'recipient' => '[@\\.]ispsoft.de$'
        }
      ],
    # Path of the tar binary (for extracting .tar files) or empty
      'tar_path' => '/usr/bin/gtar',
    # Directory to use for temporary files
      'tmp_dir' => '/var/spool/ispmailgate',
    # Path of the unarj binary (for extracting .arj files) or empty
      'unarj_path' => '',
    # Path of the Unix socket to connect to a server
      'unix_sock' => '/var/run/ispmailgate.sock',
    # Domain to assume for email adresses without @domain
      'unqualified_domain' => 'ispsoft.de',
    # Path of the unzip binary (for extracting .zip files) or empty
      'unzip_path' => '/usr/bin/unzip',
    # Configuration of the virus scanner
      'virscan' => {
        'scanner' => '$antivir_path -rs -nolnk -noboot $ipaths',
        'deflater' => [
          {
            'cmd' => '$gzip_path -cd $ipath | $tar_path -xf -C $odir',
            'pattern' => '\\.(?:tgz|tar\\.gz|tar\\.[zZ])$'
          },
          {
            'cmd' => '$gzip_path -cd $ipath >$opath',
            'pattern' => '\\.(?:gz|[zZ])$'
          },
          {
            'cmd' => '$gzip_path -cd $ipath >$opath',
            'pattern' => '\\.tar$'
          },
          {
            'cmd' => '$unzip_path $ifile -d $odir',
            'pattern' => '\\.zip$'
          },
          {
            'cmd' => '$gzip_path -cd $ipath | $tar_path -xf -C $odir',
            'pattern' => '\\.(?:tgz|tar\\.gz|tar\\.[zZ])$'
          },
          {
            'cmd' => '$gzip_path -cd $ipath >$opath',
            'pattern' => '\\.(?:gz|[zZ])$'
          },
          {
            'cmd' => '$gzip_path -cd $ipath >$opath',
            'pattern' => '\\.tar$'
          },
          {
            'cmd' => '$unzip_path $ifile -d $odir',
            'pattern' => '\\.zip$'
          },
          {
            'cmd' => '$gzip_path -cd $ipath | $tar_path -xf -C $odir',
            'pattern' => '\\.(?:tgz|tar\\.gz|tar\\.[zZ])$'
          },
          {
            'cmd' => '$gzip_path -cd $ipath >$opath',
            'pattern' => '\\.(?:gz|[zZ])$'
          },
          {
            'cmd' => '$gzip_path -cd $ipath >$opath',
            'pattern' => '\\.tar$'
          },
          {
            'cmd' => '$unzip_path $ifile -d $odir',
            'pattern' => '\\.zip$'
          }
        ]
      },
    }, 'Mail::IspMailGate::Install' );


=head1 AUTHORS AND COPYRIGHT

This module is

    Copyright (C) 1998         Amar Subramanian
                               Grundstr. 32
                               72810 Gomaringen
                               Germany

                               Email: amar@neckar-alb.de
                               Phone: +49 7072 920696


                       and     Jochen Wiedmann
                               Am Eisteich 9
                               72555 Metzingen
                               Germany

                               Email: joe@ispsoft.de
                               Phone: +49 7123 14887

    All Rights Reserved.

You may distribute under the terms of either the GNU General
Public License or the Artistic License, as specified in the
Perl README file.


=head1 SEE ALSO

L<Mail::IspMailGate::Filter(3)>, L<Mail::IspMailGate::Packer(3)>,
L<Mail::IspMailGate::VirScan(3)>, L<Mail::IspMailGate::PGP(3)> and
L<MIME::Entity(3)>


SCRIPT
