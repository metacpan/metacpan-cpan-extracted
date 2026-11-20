package Mail::Send::DKIM;

# The signing half of bin/mail-dkim: given an object configured with the
# domains this host signs for, a message either comes back signed or comes back
# as undef and the caller sends it as it is.  Nothing here dies on a signing
# problem, because a missing key must never stop mail being delivered.

use strict;
use warnings;

use Mail::DKIM::Signer;
use Params::Get;
use Sys::Syslog ();
use Object::Configure;

use version; our $VERSION = version->declare('0.002.0');

=head1 NAME

Mail::Send::DKIM - sign a message with DKIM and hand it to sendmail

=head1 VERSION

0.002.0

=head1 SYNOPSIS

	use Mail::Send::DKIM;

	my $dkim = Mail::Send::DKIM->new(
		domains => ['example.org'],
		keydir => "$ENV{HOME}/dkim",
	);

	my $signed = $dkim->sign($message);
	$message = $signed if(defined($signed));

	exit($dkim->send($message, '-t', '-f', 'alerts@example.org'));

=head1 DESCRIPTION

Signs a message with DKIM when its C<From:> domain is one this host signs for,
and hands it to sendmail with whatever arguments sendmail should have.  The
signed form is C<rsa-sha256> with C<relaxed> canonicalization, which is the
shape receiving sites expect.

The signature covers the message in the form DKIM defines, where every line
ends CRLF.  What is handed to sendmail is the local form instead: LF line
endings, and no carriage return anywhere, whatever arrived.  A CR would be data
to the MTA that keeps the message - Postfix and Exim both write the CRLF of
SMTP themselves - so a message that had travelled with CRLF in it would reach
the receiver with the CRs doubled and fail the signature it had just been given.

Nothing here dies because a key is missing: signing either produces a signed
message or produces nothing and says why on standard error, so a caller can
always fall back to sending the message as it is.

=head1 PLATFORMS

Windows is not supported.  L<Mail::DKIM> needs L<Crypt::OpenSSL::RSA>, and that
module and its prerequisites, L<Crypt::OpenSSL::Random> and
L<Crypt::OpenSSL::Bignum>, do not link on Windows: Strawberry Perl's static
OpenSSL needs the C<crypt32> library, which their F<Makefile.PL> files do not
ask for.  F<Makefile.PL> stops with C<OS unsupported> there, rather than failing
part-way through the install.

=head1 ENVIRONMENT

B<DKIM_DOMAINS>, B<DKIM_KEYDIR>, B<DKIM_SELECTOR>, B<DKIM_KEYFILE> and
B<SENDMAIL> are read by B<new> when the corresponding option is not given, so
the command line programs needs no configuration of its own.

=head1 PROGRAMS

The distribution is named after this module and installs four programs with
it, each with a page of its own: C<perldoc bin/mail-dkim>,
C<perldoc bin/dmarc-report.pl>, C<perldoc bin/dmarc-check-mail.pl> and
C<perldoc bin/dmarc-weekly.sh> in a checkout, and the same pages as manual
pages once installed.

=over 4

=item L<mail-dkim|https://github.com/nigelhorne/Mail-Send-DKIM/blob/master/bin/mail-dkim>

The front end to this module: a message on standard input is signed when its
C<From:> domain is one named in C<DKIM_DOMAINS>, and handed to sendmail(1) with
the arguments it was given.  Put it where a script or a crontab calls sendmail
and the mail is signed without the script being changed.  Its page has the
environment variables, the key layout and the exit status.

=item L<dmarc-report|https://github.com/nigelhorne/Mail-Send-DKIM/blob/master/bin/dmarc-report.pl>

Reads a directory of DMARC aggregate reports and says who sent mail for each
domain, marking every source that is not an expected one (C<DMARC_EXPECTED>),
every expected one whose mail did not authenticate, and every message that was
quarantined or rejected by policy despite passing.  The exit status is non-zero
when anything needs looking at.  Its page has the options.

=item L<dmarc-weekly.sh|https://github.com/nigelhorne/Mail-Send-DKIM/blob/master/bin/dmarc-weekly.sh>

The cron wrapper around it: silent when the week is clean, a mail with the full
output when it is not, and the reports moved aside to an archive afterwards.
C<DRY_RUN=1> rehearses a run and C<--crontab> prints the line to paste into a
crontab; see L</A CRONTAB ENTRY> below.

=item L<dmarc-check-mail.pl|https://github.com/nigelhorne/Mail-Send-DKIM/blob/master/bin/dmarc-check-mail.pl>

Sends one message, signed with this module, to a mailbox that can be read, so
that the C<Authentication-Results> header at the far end shows what receivers
make of this host's mail before the DMARC policy is tightened.  C<--plain>
sends the same message unsigned, which is what a cron job without the module
looks like.

=back

The three DMARC programs are the reason the module exists: they report on the
mail it signs, and the weekly one sends its own report through it.

=head1 METHODS

=head2 B<new> %options

=over 4

=item C<domains>

The domains to sign for, either an array reference or a string of them
separated by commas or spaces.  Defaults to C<$ENV{DKIM_DOMAINS}>.  A message
from any other domain is left alone.

=item C<keydir>

Where the private keys are.  Defaults to C<$ENV{DKIM_KEYDIR}>, or F<~/dkim>.
The value is used as it stands: a relative path is taken from the working
directory, and C<~> is not expanded - the shell does that, and only when the
assignment is written unquoted.

=item C<selector>

The selector the key is published under, which names the key file
F<< <keydir>/<selector>.private >>.  Defaults to C<$ENV{DKIM_SELECTOR}>; with
neither set, the key file's own name is the selector when B<keyfile> is given,
and otherwise the only F<*.private> file in B<keydir> is used and its name is
the selector.

=item C<keyfile>

The private key to sign with, when it does not live at
F<< <keydir>/<selector>.private >> - a tester given one key to try, for
instance.  Defaults to C<$ENV{DKIM_KEYFILE}>.  It is used as it stands, and
the selector comes from its name unless one is given.

=item C<sendmail>

The program B<send> hands the message to.  Defaults to C<$ENV{SENDMAIL}>, or
F</usr/sbin/sendmail>.

=back

=cut

sub new
{
	my $class = shift;

	# Handle hash or hashref arguments
	my $params = Params::Get::get_params(undef, \@_) // {};

	$params = Object::Configure::configure($class, $params);

	my $home = $params->{home} || $ENV{'HOME'} || (getpwuid($<))[7] || '.';

	my $domains = $params->{'domains'} // $ENV{'DKIM_DOMAINS'} // '';
	my @domains = ref($domains) eq 'ARRAY' ? @$domains : split(/[\s,]+/, $domains);

	my $self = {
		'domains' => { map { lc($_) => 1 } grep { length } @domains },
		'keydir' => $params->{'keydir'} // $ENV{'DKIM_KEYDIR'} // "$home/dkim",
		'selector' => $params->{'selector'} // $ENV{'DKIM_SELECTOR'},
		'keyfile' => $params->{'keyfile'} // $ENV{'DKIM_KEYFILE'},
		'sendmail' => $params->{'sendmail'} // $ENV{'SENDMAIL'} // '/usr/sbin/sendmail',
	};

	return bless($self, $class);
}

=head2 B<sign> $message

Returns the message with a C<DKIM-Signature> header added, or C<undef> when
there is nothing to do or nothing that can be done: the domain is not one of
B<domains>, there is no C<From:> header, no key can be found or read, or the
signer failed.  The reasons are warnings on standard error; the message itself
is never altered in the undef case, so the caller sends it unchanged.
Carriage returns are folded to LF on the way, so what comes back is in the
local form.

=cut

sub sign
{
	my $self = shift;

	my $params = Params::Get::get_params('message', \@_);
	my $message = $params->{message};

	my $domain = from_domain($message);
	return unless(defined($domain));
	return unless($self->{'domains'}->{$domain});

	my $selector = $self->selector;
	return unless(defined($selector));

	# A key file named outright needs neither the directory nor the naming
	# convention; otherwise the key is <keydir>/<selector>.private.
	my $keyfile = $self->{'keyfile'} // $self->{'keydir'} . "/$selector.private";
	unless(-r $keyfile) {
		warn "Mail::Send::DKIM: no readable key at $keyfile; sending $domain unsigned";
		return;
	}

	# DKIM hashes the message in the form it travels in, where every line
	# ends CRLF, so the signature is made over a CRLF copy of what arrived.
	(my $wire = _local($message)) =~ s/\n/\r\n/g;

	my $signed;
	eval {
		my $signer = Mail::DKIM::Signer->new(
			Algorithm => 'rsa-sha256',
			Method => 'relaxed',
			Domain => $domain,
			Selector => $selector,
			KeyFile => $keyfile,
		);
		$signer->PRINT($wire);
		$signer->CLOSE;
		$signed = $signer->signature->as_string . "\n" . _local($message);
		1;
	} or do {
		my $error = $@ || 'unknown error';
		chomp($error);
		warn "Mail::Send::DKIM: cannot sign for $domain ($error); sending unsigned";
		return;
	};

	return $signed;
}

=head2 B<send> $message, @arguments

Pipes the message to B<sendmail> with the arguments given - C<-t>, C<-f> and
the rest are sendmail's own - and returns C<0> when sendmail accepted the
message, sendmail's exit status when it did not, and C<1> when sendmail cannot
be run at all.  The message is normalised to LF first, so nothing that arrived
with CRLF - signed or passed through unsigned - carries a carriage return to
the MTA.

=cut

sub send
{
	my ($self, $message, @args) = @_;

	open(my $sendmail, '|-', $self->{'sendmail'}, @args) or do {
		warn "Mail::Send::DKIM: cannot run $self->{'sendmail'}: $!";
		return 1;
	};
	print $sendmail _local($message);

	return 0 if(close($sendmail));

	my $status = $? >> 8;

	return $status || 1;
}

=head2 B<log_send> $message, @arguments

Records in syslog, under the identity C<mail-dkim> and the C<mail> facility,
the sender, the recipients and the subject of a message that has been sent.
The arguments are those given to B<send>.  The sender is the address after
C<-f> when there is one, and the address in the C<From:> header otherwise.  The
recipients are the arguments that are not options and, when C<-t> was given,
the addresses in the C<To:>, C<Cc:> and C<Bcc:> headers too.  A value that is
missing is logged as C<->, and control characters in the subject are replaced
by spaces so that a message cannot forge a log line.

Returns true when the line was written.  Logging never stands between a message
and its recipient: a syslog that cannot be reached is a warning, and a false
return.

=cut

sub log_send
{
	my ($self, $message, @args) = @_;

	my $sender;
	my @recipients;
	my $tflag;
	my $skip;	# the argument after an option that takes a value
	foreach my $arg (@args) {
		if($skip) {
			$sender = $arg if($skip eq 'f');
			$skip = 0;
			next;
		}
		if($arg =~ /\A-f(.+)/s) {
			$sender = $1;
		} elsif($arg eq '-f') {
			$skip = 'f';
		} elsif($arg =~ /\A-[BboprRVNLXAqFC]\z/) {
			$skip = 'x';
		} elsif($arg eq '--') {
			next;
		} elsif($arg =~ /\A-/) {
			$tflag = 1 if($arg =~ /\A-[A-Za-z]*t/);
		} else {
			push(@recipients, $arg);
		}
	}
	$sender //= _addresses(_header($message, 'From'));
	push(@recipients, map { _addresses(_header($message, $_)) } qw(To Cc Bcc)) if($tflag);

	my $subject = _header($message, 'Subject');
	$subject = '-' unless(defined($subject) && length($subject));
	$subject =~ s/[[:cntrl:]]/ /g;

	my $line = sprintf('sender=%s recipient=%s subject=%s',
		$sender || '-', @recipients ? join(',', @recipients) : '-', $subject);
	$line =~ s/[[:cntrl:]]/ /g;

	my $ok = eval {
		Sys::Syslog::openlog('mail-dkim', 'pid,ndelay', 'mail');
		Sys::Syslog::syslog('info', '%s', $line);
		Sys::Syslog::closelog();
		1;
	};
	warn "Mail::Send::DKIM: cannot write to syslog: $@" unless($ok);

	return $ok ? 1 : 0;
}

# The unfolded value of the first header of that name, or undef.
sub _header
{
	my ($message, $name) = @_;

	my ($head) = $message =~ /\A(.*?)\r?\n\r?\n/s;
	$head = $message unless(defined($head));
	$head =~ s/\r?\n[ \t]+/ /g;

	return $head =~ /^\Q$name\E:[ \t]*(.*?)\s*$/mi ? $1 : undef;
}

# The addresses in a header value: the one in angle brackets when there is
# one, else the bare address, for each of the comma separated items.
sub _addresses
{
	my $value = shift;

	return unless(defined($value));

	my @found;
	foreach my $item (split(/,(?=(?:[^"]*"[^"]*")*[^"]*\z)/, $value)) {
		if($item =~ /<([^>]*)>/) {
			push(@found, $1);
		} elsif($item =~ /([^\s<>()"]+\@[^\s<>()"]+)/) {
			push(@found, $1);
		}
	}

	return wantarray ? @found : $found[0];
}

#
# What is handed to sendmail is the local form of the message: LF line endings
# and no carriage return anywhere, whatever arrived.  A CR is data to the MTA
# that keeps the message - Postfix's sendmail_fix_line_endings and Exim both
# write the CRLF of SMTP themselves - so one that survived would reach the
# receiver doubled, and the message would fail the signature it was just given.
sub _local
{
	my $message = shift;

	$message =~ s/\r\n/\n/g;
	$message =~ s/\r//g;

	return $message;
}

=head2 B<from_domain> $message

The domain of the address in the first C<From:> header, in lower case, or
C<undef> when there is no such header.  Folded headers and display names are
understood.

=cut

#
# The domain an address is at, from the first From: header.  A header field can
# be folded over several lines, so the continuation lines are joined first, and
# a display name is dropped in favour of the address in angle brackets.
sub from_domain
{
	my $message = shift;

	my ($head) = $message =~ /\A(.*?)\r?\n\r?\n/s;
	$head = $message unless(defined($head));
	$head =~ s/\r?\n[ \t]+/ /g;
	return unless($head =~ /^From:[ \t]*(.*?)\s*$/mi);

	my $value = $1;
	my ($address) = $value =~ /<([^>]*)>/;
	$address = $value unless(defined($address));

	# An address can be followed by a comment, so the domain is the last
	# thing that looks like one rather than the end of the string.
	my @domains = $address =~ /\@([A-Za-z0-9.-]+)/g;
	return unless(@domains);

	return lc($domains[-1]);
}

=head2 B<selector>

The selector the message will be signed under: the one given to B<new> or read
from C<DKIM_SELECTOR>, otherwise the name of the B<keyfile> when one is given,
otherwise the name of the only F<*.private> file in B<keydir>.  C<undef> when it
cannot be decided - no key, or several keys and no name - and the reason is a
warning on standard error.  B<sign> asks this before doing anything else.

=cut

# The key file is <keydir>/<selector>.private.  With no selector named the
# selector is the name of the only key in the directory, which is the usual
# case: one key, published for every domain this host sends as.  Anything
# ambiguous is a warning rather than a guess.
sub selector
{
	my $self = shift;

	my $selector = $self->{'selector'};
	return $selector if(defined($selector) && length($selector));

	# A named key file carries its selector in its name, which is the layout
	# the keys are kept in: <keydir>/<selector>.private.
	if(defined($self->{'keyfile'})) {
		(my $from_name = $self->{'keyfile'}) =~ s{.*[\\/]}{};
		$from_name =~ s/\.(?:private|key|pem)\z//;
		return $from_name if(length($from_name));
	}

	opendir(my $dh, $self->{'keydir'}) or do {
		warn "Mail::Send::DKIM: cannot read $self->{'keydir'}: $!";
		return;
	};
	my @keys = sort grep { /\.private\z/ } readdir($dh);
	closedir($dh);

	unless(@keys == 1) {
		warn sprintf("Mail::Send::DKIM: %s holds %d key(s); name the selector to choose one",
			$self->{'keydir'}, scalar(@keys));
		return;
	}

	(my $found = $keys[0]) =~ s/\.private\z//;

	return $found;
}

1;

__END__

=head1 A CRONTAB ENTRY

A job that sends mail from cron is where an unsigned message is least likely to
be noticed, so that is usually where this module earns its keep: the program
that ships with it, F<mail-dkim>, is put where the job would have called
sendmail(1), and the job itself is not changed.

The weekly summary in this distribution is such a job, and its mail goes out
through F<mail-dkim>.  A crontab line for it looks like this, with the values of
the machine it runs on:

	0 6 * * 1 DMARC_EXPECTED=192.0.2.10 MAIL_TO=alerts@example.org \
		PERL=/usr/bin/perl /usr/local/bin/dmarc-weekly.sh

The three settings are not optional, because cron starts a job with almost no
environment.  C<DMARC_EXPECTED> is what makes a sender nobody expected a
finding, and the run stops with a usage error without it, since guessing would
excuse every sender.  C<MAIL_TO> is where a week that needs looking at is
mailed, and is also the address the alert is sent as unless C<MAIL_FROM> says
otherwise.  C<PERL> has to be an absolute path to a perl that has
C<XML::PP>, as cron's C<PATH> usually holds only the system one; F<--crontab>
fills it in with the first perl on the machine that can load the module.
C<DMARC_DIR> and C<DMARC_ARCHIVE_DIR> are left out of the line because they
default to C<~/Downloads> and C<~/dmarc-archive>.

F<dmarc-weekly.sh --crontab> prints that line with the path and the perl filled
in for the machine it runs on, which is more use than an example carrying
somebody else's values; for that reason no example crontab file is shipped or
installed.  A job of your own takes the same shape with F<mail-dkim> in place of
the wrapper: C<DKIM_DOMAINS> and C<DKIM_KEYDIR> say what to sign for, and the
arguments given to it are passed to sendmail(1) as they are.

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/Mail-Send-DKIM/coverage/>

=back

L<Mail::DKIM::Signer>, which does the signing underneath, and L</PROGRAMS>
above for the programs this distribution installs beside the module.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
