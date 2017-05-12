my $RCS_Id = '$Id: Procmail.pm,v 1.24 2004-09-19 12:34:56+02 jv Exp jv $ ';

# Author          : Johan Vromans
# Created On      : Tue Aug  8 13:53:22 2000
# Last Modified By: Johan Vromans
# Last Modified On:
# Update Count    : 254
# Status          : Unknown, Use with caution!

=head1 NAME

Mail::Procmail - Procmail-like facility for creating easy mail filters.

=head1 SYNOPSIS

    use Mail::Procmail;

    # Set up. Log everything up to log level 3.
    my $m_obj = pm_init ( loglevel  => 3 );

    # Pre-fetch some interesting headers.
    my $m_from		    = pm_gethdr("from");
    my $m_to		    = pm_gethdr("to");
    my $m_subject	    = pm_gethdr("subject");

    # Default mailbox.
    my $default = "/var/spool/mail/".getpwuid($>);

    pm_log(1, "Mail from $m_from");

    pm_ignore("Non-ASCII in subject")
      if $m_subject =~ /[\232-\355]{3}/;

    pm_resend("jojan")
      if $m_to =~ /jjk@/i;

    # Make sure I see these.
    pm_deliver($default, continue => 1)
      if $m_subject =~ /getopt(ions|(-|::)?long)/i;

    # And so on ...

    # Final delivery.
    pm_deliver($default);

=head1 DESCRIPTION

F<procmail> is a great mail filter program, but it has weird recipe
format. It's pattern matching capabilities are basic and often
insufficient. I wanted something flexible whereby I could filter my
mail using the power of Perl.

I've been considering to write a procmail replacement in Perl for a
while, but it was Simon Cozen's C<Mail::Audit> module, and his article
in The Perl Journal #18, that set it off.

I first started using Simon's great module, and then decided to write
my own since I liked certain things to be done differently. And I
couldn't wait for his updates.

C<Mail::Procmail> allows a piece of email to be logged, examined,
delivered into a mailbox, filtered, resent elsewhere, rejected, and so
on. It is designed to allow you to easily create filter programs to
stick in a F<.forward> or F<.procmailrc> file, or similar.

=head1 DIFFERENCES WITH MAIL::AUDIT

Note that several changes are due to personal preferences and do not
necessarily imply deficiencies in C<Mail::Audit>.

=over

=item General

Not object oriented. Procmail functionality typically involves one
single message. All (relevant) functions are exported.

=item Delivery

Each of the delivery methods is able to continue (except
I<pm_reject> and I<pm_ignore>).

Each of the delivery methods is able to pretend they did it
(for testing a new filter).

No default file argument for mailbox delivery, since this is system
dependent.

Each of the delivery methods logs the line number in the calling
program so one can deduce which 'rule' caused the delivery.

Message IDs can be checked to suppress duplicate messages.

System commands can be executed for their side-effects.

I<pm_ignore> logs a reason as well.

I<pm_reject> will fake a "No such user" status to the mail transfer agent.

=item Logging

The logger function is exported as well. Logging is possible to
a named file, STDOUT or STDERR.

Since several deliveries can take place in parallel, logging is
protected against concurrent access, and a timestamp/pid is included
in log messages.

A log reporting tool is included.

=item Robustness

Exit with TEMPFAIL instead of die in case of problems.

I<pm_pipe_to> ignores  SIGPIPE.

I<pm_pipe_to> returns the command exit status if continuation is selected.

Commands and pipes can be protected  against concurrent access using
lockfiles.

=back

=head1 EXPORTED ROUTINES

Note that most delivery routines exit the program unless the attribute
"continue=>1" is passed.

Also, the delivery routines log the line number in the calling program
so it is easy to find out which 'rule' caused a specific delivery to
take place.

=cut

################ Common stuff ################

package Mail::Procmail;

$VERSION = "1.08";

use strict;
use 5.005;
use vars qw(@ISA @EXPORT $pm_hostname);

my $verbose = 0;		# verbose processing
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

my $logfile;			# log file
my $loglevel;			# log level

use Fcntl qw(:DEFAULT :flock);

use constant REJECTED	=> 67;	# fake "no such user"
use constant TEMPFAIL	=> 75;
use constant DELIVERED	=> 0;

use Sys::Hostname;
$pm_hostname = hostname;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
	     pm_init
	     pm_gethdr
	     pm_gethdr_raw
	     pm_body
	     pm_deliver
	     pm_reject
	     pm_resend
	     pm_pipe_to
	     pm_command
	     pm_ignore
	     pm_dupcheck
	     pm_lockfile
	     pm_unlockfile
	     pm_log
	     pm_report
	     $pm_hostname
	    );

################ The Process ################

use Mail::Internet;
use LockFile::Simple;

use Carp;

my $m_obj;			# the Mail::Internet object
my $m_head;			# its Mail::Header object

=head2 pm_init

This routine performs the basic initialisation. It must be called once.

Example:

    pm_init (logfile => "my.log", loglevel => 3, test => 1);

Attributes:

=over

=item *

fh

An open file handle to read the message from. Defaults to STDIN.

=item *

logfile

The name of a file to log messages to. Each message will have a timestamp
attached.

The attribute may be 'STDOUT' or 'STDERR' to achieve logging to
standard output or error respectively.

=item *

loglevel

The amount of information that will be logged.

=item *

test

If true, no actual delivery will be done. Suitable to test a new setup.
Note that file locks are done, so lockfiles may be created and deleted.

=item *

debug

Provide some debugging info.

=item *

trace

Provide some tracing info, eventually.

=item *

verbose

Produce verbose information, eventually.

=back

=cut

sub pm_init {

    my %atts = (
		logfile   => '',
		loglevel  => 0,
		fh	  => undef,
		verbose   => 0,
		trace     => 0,
		debug     => 0,
		test      => 0,
		@_);
    $debug     = delete $atts{debug};
    $trace     = delete $atts{trace};
    $test      = delete $atts{test};
    $verbose   = delete $atts{verbose};
    $logfile   = delete $atts{logfile};
    $loglevel  = delete $atts{loglevel};
    my $fh     = delete $atts{fh} || \*STDIN;

    $trace |= ($debug || $test);

    croak("Unprocessed attributes: ".join(" ",sort keys %atts))
      if %atts;

    $m_obj = Mail::Internet->new($fh);
    $m_head = $m_obj->head;  # Mail::Header

    $m_obj;
}

=head2 pm_gethdr

This routine fetches the contents of a header. The result will have
excess whitepace tidied up.

The header is reported using warn() if the debug attribute was passed
(with a true value) to pm_init();

Example:

    $m_rcvd = pm_gethdr("received");	# get first (or only) Received: header
    $m_rcvd = pm_gethdr("received",2);	# get 3rd Received: header
    @m_rcvd = pm_gethdr("received");	# get all Received: headers

=cut

sub pm_gethdr {
    my ($hdr, $ix) = @_;
    my @ret;
    foreach my $val ( $m_head->get($hdr, $ix) ) {
	last unless defined $val;
	for ( $val ) {
	    s/^\s+//;
	    s/\s+$//;
	    s/\s+/ /g;
	    s/[\r\n]+$//;
	}
	if ( $debug ) {
	    $hdr =~ s/-(.)/"-".ucfirst($1)/ge;
	    warn (ucfirst($hdr), ": ", $val, "\n");
	}
	return $val unless wantarray;
	push (@ret, $val);
    }
    wantarray ? @ret : '';
}

=head2 pm_gethdr_raw

Like pm_gethdr, but without whitespace cleanup.

=cut

sub pm_gethdr_raw {
    my ($hdr, $ix) = @_;
    my @ret;
    foreach my $val ( $m_head->get($hdr, $ix) ) {
	last unless defined $val;
	if ( $debug ) {
	    $hdr =~ s/-(.)/"-".ucfirst($1)/ge;
	    warn (ucfirst($hdr), ": ", $val, "\n");
	}
	return $val unless wantarray;
	push (@ret, $val);
    }
    wantarray ? @ret : '';
}

=head2 pm_body

This routine fetches the body of a message, as a reference to an array
of lines.

Example:

    $body = pm_body();			# ref of lines
    $body = join("", @{pm_body()});	# as one string

=cut

sub pm_body {
    $m_obj->body;
}

=head2 pm_deliver

This routine performs delivery to a Unix style mbox file, or maildir.

In case of an mbox file, the file is locked first by acquiring
exclusive access. Note that older style locking, with a lockfile with
C<.lock> extension, is I<not> supported.

Example:

    pm_deliver("/var/spool/mail/".getpwuid($>));

Attributes:

=over

=item *

continue

If true, processing will continue after delivery. Otherwise the
program will exit with a DELIVERED status.

=back

=cut

sub _pm_msg_size {
    length($m_obj->head->as_string || '') + length(join("", @{$m_obj->body}));
}

sub pm_deliver {
    my ($target, %atts) = @_;
    my $line = (caller(0))[2];
    pm_log(2, "deliver[$line]: $target "._pm_msg_size());

    # Is it a Maildir?
    if ( -d "$target/tmp" && -d "$target/new" ) {
	my $msg_file = "/${\time}.$$.$pm_hostname";
	my $tmp_path = "$target/tmp/$msg_file";
	my $new_path = "$target/new/$msg_file";
	pm_log(3,"Looks like maildir, writing to $new_path");

	# since mutt won't add a lines tag to maildir messages,
	# we'll add it here
	unless ( pm_gethdr("lines") ) {
	    my $body = $m_obj->body;
	    my $num_lines = @$body;
	    $m_head->add("Lines", $num_lines);
	    pm_log(4,"Adding Lines: $num_lines header");
	}
	my $tmp = _new_fh();
	unless (open ($tmp, ">$tmp_path") ) {
	    pm_log(0,"Couldn't open $tmp_path! $!");
	    exit TEMPFAIL;
	}
	print $tmp ($m_obj->as_mbox_string);
	close($tmp);

	unless ( $test ) {
	    unless (link($tmp_path, $new_path) ) {
		pm_log(0,"Couldn't link $tmp_path to $new_path : $!");
		exit TEMPFAIL;
	    }
	}
	unlink($tmp_path) or pm_log(1,"Couldn't unlink $tmp_path: $!");
    }
    else {
	# It's an mbox, I hope.
	my $fh = _new_fh();
	unless (open($fh, ">>$target")) {
	    pm_log(0,"Couldn't open $target! $!");
	    exit TEMPFAIL;
	}
	flock($fh, LOCK_EX)
	    or pm_log(1,"Couldn't get exclusive lock on $target");
	seek($fh, 0, 2);	# make sure we're still at the end
	print $fh ($m_obj->as_mbox_string) unless $test;
	flock($fh, LOCK_UN)
	    or pm_log(1,"Couldn't unlock on $target");
	close($fh);
    }
    exit DELIVERED unless $atts{continue};
}


=head2 pm_pipe_to

This routine performs delivery to a command via a pipe.

Return the command exit status if the continue attribute is supplied.
If execution is skipped due to test mode, the return value will be 0.
See also attribute C<testalso> below.

If the name of a lockfile is supplied, multiple deliveries are throttled.

Example:

    pm_pipe_to("my_filter", lockfile => "/tmp/pm.lock");

Attributes:

=over

=item *

lockfile

The name of a file that is used to guard against multiple deliveries.
The program will try to exclusively create this file before proceding.
Upon completion, the lock file will be removed.

=item *

continue

If true, processing will continue after delivery. Otherwise the
program will exit with a DELIVERED status, I<even when the command
failed>.

=item *

testalso

Do this, even in test mode.

=back

=cut

sub pm_pipe_to {
    my ($target, %atts) = @_;
    my $line = (caller(0))[2];
    pm_log(2, "pipe_to[$line]: $target "._pm_msg_size());

    my $lock;
    my $lockfile = $atts{lockfile};
    $lock = pm_lockfile($lockfile) if $lockfile;
    local ($SIG{PIPE}) = 'IGNORE';
    my $ret = 0;
    eval {
	$ret = undef;
	my $pipe = _new_fh();
	open ($pipe, "|".$target)
	  && $m_obj->print($pipe)
	    && close ($pipe);
	$ret = $?;
    } unless $test && !$atts{testalso};

    pm_unlockfile($lock);
    $ret = 0 if $ret < 0;	# broken pipe
    pm_log (2, "pipe_to[$line]: command result = ".
	    (defined $ret ? sprintf("0x%x", $ret) : "undef").
	    ($! ? ", \$! = $!" : "").
	    ($@ ? ", \$@ = $@" : ""))
      unless defined $ret && $ret == 0;
    return $ret if $atts{continue};
    exit DELIVERED;
}

=head2 pm_command

Executes a system command for its side effects.

If the name of a lockfile is supplied, multiple executes are
throttled. This would be required if the command manipulates external
data in an otherwise unprotected manner.

Example:

    pm_command("grep foo some.dat > /tmp/pm.dat",
               lockfile => "/tmp/pm.dat.lock");

Attributes:

=over

=item *

lockfile

The name of a file that is used to guard against multiple executions.
The program will try to exclusively create this file before proceding.
Upon completion, the lock file will be removed.

testalso

Do this, even in test mode.

=back

=cut

sub pm_command {
    my ($target, %atts) = @_;
    my $line = (caller(0))[2];
    pm_log(2, "command[$line]: $target "._pm_msg_size());

    my $lock;
    my $lockfile = $atts{lockfile};
    $lock = pm_lockfile($lockfile) if $lockfile;
    my $ret = 0;
    $ret = system($target) unless $atts{testalso};
    pm_unlockfile($lock);
    pm_log (2, "command[$line]: command result = ".
	    (defined $ret ? sprintf("0x%x", $ret) : "undef"))
      unless defined $ret && $ret == 0;
    $ret;
}

=head2 pm_resend

Send this message through to some other user.

Example:

    pm_resend("root");

Attributes:

=over

=item *

continue

If true, processing will continue after delivery. Otherwise the
program will exit with a DELIVERED status.

=back

=cut

sub pm_resend {
    my ($target, %atts) = @_;
    my $line = (caller(0))[2];
    pm_log(2, "resend[$line]: $target "._pm_msg_size());
    $m_obj->smtpsend(To => $target) unless $test;
    exit DELIVERED unless $atts{continue};
}

=head2 pm_reject

Reject a message. The sender will get a mail back with the reason for
the rejection (unless stderr has been redirected).

Example:

    pm_reject("Non-existent address");

=cut

sub pm_reject {
    my $reason = shift;
    my $line = (caller(0))[2];
    pm_log(2, "reject[$line]: $reason "._pm_msg_size());
    print STDERR ($reason, "\n") unless lc $logfile eq 'stderr';
    exit REJECTED;
}


=head2 pm_ignore

Ignore a message. The program will do nothing and just exit with a
DELIVERED status. A descriptive text may be passed to log the reason
for ignoring.

Example:

    pm_ignore("Another make money fast message");

=cut

sub pm_ignore {
    my $reason = shift;
    my $line = (caller(0))[2];
    pm_log(2, "ignore[$line]: $reason "._pm_msg_size());
    exit DELIVERED;
}

=head2 pm_dupcheck

Check for duplicate messages. Reject the message if its message ID has
already been received.

Example:

    pm_dupcheck(scalar(pm_gethdr("message-id")));

Attributes:

=over

=item *

dbm

The name of a DBM file (created if necessary) to store the message IDs.
The default name is C<.msgids> in the HOME directory.

=item *

retain

The amount of time, in days, that subsequent identical message IDs are
considered duplicates. Each new occurrence will refresh the time stamp.
The default value is 14 days.

=item *

continue

If true, the routine will return true or false depending on the
message ID being duplicate. Otherwise, if it was duplicate, the
program will exit with a DELIVERED status.

=back

I<Warning: In the current implementation, the DBM file will grow
unlimited. A separate tool will be supplied to expire old message IDs.>

=cut

sub pm_dupcheck {
    my ($msgid) = shift;
    my (%atts) = (dbm => $ENV{HOME}."/.msgids",
		  retain => 14,
		  @_);
    my $dbm = $atts{dbm};

    my %msgid;
    my $dup = 0;
    if ( dbmopen(%msgid, $dbm, 0660) ) {
	my $tmp;
	if ( defined($tmp = $msgid{$msgid}) ) {
	    if ( ($msgid{$msgid} = time) - $tmp < $atts{retain}*24*60*60 ) {
		my $line = (caller(0))[2];
		pm_log(2, "dup[$line]: $msgid "._pm_msg_size());
		$dup++;
	    }
	}
	else {
	    $msgid{$msgid} = time;
	}
	dbmclose(%msgid)
	  or pm_log(0, "Error closing $dbm: $!");
    }
    else {
	pm_log(0, "Error opening $dbm: $!");
    }
    exit DELIVERED
      if $dup && !$atts{continue};
    $dup;
}

=head2 pm_lockfile

The program will try to get an exclusive lock using this file.

Example:

    $lock_id = pm_lockfile("my.mailbox.lock");

The lock id is returned, or undef on failure.

=cut

my $lockmgr;
sub pm_lockfile {
    my ($file) = @_;

    $lockmgr = LockFile::Simple->make(-hold => 600, -stale => 1,
				      -autoclean => 1, 
				      -wfunc => sub { pm_log(2,@_) },
				      -efunc => sub { pm_log(0,@_) },
				     )
      unless $lockmgr;

    $lockmgr->lock($file, "%f");
}

=head2 pm_unlockfile

Unlocks a lock acquired earlier using pm_lockfile().

Example:

    pm_unlockfile($lock_id);

If unlocking succeeds, the lock file is removed.

=cut

sub pm_unlockfile {
    shift->release if $_[0];
}

=head2 pm_log

Logging facility. If pm_init() was supplied the name of a log file,
this file will be opened, created if necessary. Every log message
written will get a timestamp attached. The log level (first argument)
must be less than or equal to the loglevel attribute used with
pm_init(). If not, this message will be skipped.

Example:

    pm_log(2,"Retrying");

=cut

my $logfh;
sub pm_log {
    return unless $logfile;
    return if shift > $loglevel;

    # Use sysopen/syswrite for atomicity.
    unless ( $logfh ) {
	$logfh = _new_fh();
	print STDERR ("Opening logfile $logfile\n") if $debug;
	if ( lc($logfile) eq "stderr" ) {
	    open ($logfh, ">&STDERR");
	}
	elsif ( lc($logfile) eq "stdout" || $logfile eq "-" ) {
	    open ($logfh, ">&STDOUT");
	}
	else {
	    sysopen ($logfh, $logfile, O_WRONLY|O_CREAT|O_APPEND)
	      || print STDERR ("$logfile: $!\n");
	}
    }
    my @tm = localtime;
    my $msg = sprintf ("%04d%02d%02d%02d%02d%02d.%05d %s\n",
		       $tm[5]+1900, $tm[4]+1, $tm[3], $tm[2], $tm[1], $tm[0],
		       $$, "@_");
    print STDERR ($msg) if $debug;
    syswrite ($logfh, $msg);
}

sub _new_fh {
    return if $] >= 5.006;	# 5.6 will take care itself
    require IO::File;
    IO::File->new();
}

################ Reporting ################

=head2 pm_report

pm_report() produces a summary report from log files from
Mail::Procmail applications.

Example:

    pm_report(logfile => "pmlog");

The report shows the deliveries, and the rules that caused the
deliveries. For example:

  393  393  deliver[203]  /home/jv/Mail/perl5-porters.spool
  370  370  deliver[203]  /home/jv/Mail/perl6-language.spool
  174  174  deliver[203]  /home/jv/Mail/perl6-internals.spool
  160   81  deliver[311]  /var/spool/mail/jv
	46  deliver[337]
	23  deliver[363]
	10  deliver[165]

The first column is the total number of deliveries for this target.
The second column is the number of deliveries triggered by the
indicated rule. If more rules apply to a target, this line is followed
by additional lines with an empty first and last column.

Attributes:

=over

=item *

logfile

The name of the logfile to process.

=back

If no logfile attribute is passed, pm_report() reads all files
supplied on the command line. This makes it straighforward to run from
the command line:

    $ perl -MMail::Procmail -e 'pm_report()' syslog/pm_logs/*

=cut

sub pm_report {

    my (%atts) = @_;
    my $logfile = delete($atts{logfile});

    local (@ARGV) = $logfile ? ($logfile) : @ARGV;

    my %tally;			# master array with data
    my $max1 = 0;		# max. delivery
    my $max2 = 0;		# max. delivery / rule
    my $max3 = 0;		# max length of rules
    my $recs = 0;		# records in file
    my $msgs = 0;		# messages
    my $dlvr = 0;		# deliveries

    while ( <> ) {
	$recs++;

	# Tally number of incoming messages.
	$msgs++, next if /^\d+\.\d+ Mail from/;

	# Skip non-deliveries.
	next unless /^\d+\.\d+ (\w+\[[^\]]+\]):\s+(.+)/;
	$dlvr++;

	# Update stats and keep track of max values.
	my $t;
	$max1 = $t if ($t = ++$tally{$2}->[0]) > $max1;
	$max2 = $t if ($t = ++$tally{$2}->[1]->{$1}) > $max2;
	$max3 = $t if ($t = length($1)) > $max3;
    }

    print STDOUT ("$recs records, $msgs messages, $dlvr deliveries.\n\n");

    # Construct format for report.
    $max1 = length($max1);
    $max2 = length($max2);
    my $fmt = "%${max1}s  %${max2}s  %-${max3}s  %s\n";

    # Sort on number of deliveries per target.
    foreach my $dest ( sort { $b->[1] <=> $a->[1] }
		          map { [ $_, $tally{$_}->[0], $tally{$_}->[1] ] }
			     keys %tally ) {
	my $first = 1;
	# Sort on deliveries per rule.
	foreach my $rule ( sort { $b->[1] <=> $a->[1] }
			      map { [ $_, $dest->[2]->{$_} ] }
			         keys %{$dest->[2]} ) {
	    printf STDOUT ($fmt,
			   ($first ? $dest->[1] : ""),
			   $rule->[1],
			   $rule->[0],
			   ($first ? $dest->[0] : ""));
	    $first = 0;
	}
    }

}

=head1 USING WITH PROCMAIL

The following lines at the start of .procmailrc will cause a copy of
each incoming message to be saved in $HOME/syslog/mail, after which
the procmail-pl is run as a TRAP program (see the procmailrc
documentation). As a result, procmail will transfer the exit status of
procmail-pl to the mail transfer agent that invoked procmail (e.g.,
sendmail, or postfix).

    LOGFILE=$HOME/syslog/procmail
    VERBOSE=off
    LOGABSTRACT=off
    EXITCODE=
    TRAP=$HOME/bin/procmail-pl

    :0:
    $HOME/syslog/mail

B<WARNING>: procmail seems to have problems when $HOME/syslog/mail
gets too big (over 50Mb). If you want to maintain a huge archive, you
can specify excess extents, like this:

    :0:
    $HOME/syslog/mail-ext1

    :0:
    $HOME/syslog/mail-ext2

=head1 EXAMPLE

An extensive example can be found in the examples directory of the
C<Mail::Procmail> kit.

=head1 SEE ALSO

L<Mail::Internet>

L<LockFile::Simple>

procmail documentation.

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy <jvromans@squirrel.nl>

Some parts are shamelessly stolen from Mail::Audit by Simon Cozens
<simon@cpan.org>, who admitted that he stole most of it from programs
by Tom Christiansen.

=head1 COPYRIGHT and DISCLAIMER

This program is Copyright 2000,2004 by Squirrel Consultancy. All
rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either: a) the GNU General Public License as
published by the Free Software Foundation; either version 1, or (at
your option) any later version, or b) the "Artistic License" which
comes with Perl.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the
GNU General Public License or the Artistic License for more details.

=cut

1;

# Local Variables:
# compile-command: "perl -wc -Mlib=$HOME/lib/perl5 Procmail.pm && install -m 0555 Procmail.pm $HOME/lib/perl5/Mail/Procmail.pm"
# End:
