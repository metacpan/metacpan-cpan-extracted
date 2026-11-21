package Mail::Send::DKIM;

# The signing half of bin/mail-dkim: given an object configured with the
# domains this host signs for, a message either comes back signed or comes back
# as undef and the caller sends it as it is.  Nothing here dies on a signing
# problem, because a missing key must never stop mail being delivered.

use strict;
use warnings;
# Not :all - that wraps the socket builtin send(), which this package's
# documented send() method would then redefine.  Sockets are not used here.
use autodie qw(:file :filesys :system);

use Carp qw(carp croak);
use Errno qw(ENOENT);
use File::Basename qw(basename);
use Mail::Address;
use Mail::DKIM::Signer;
use Object::Configure;
use Params::Get;
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Scalar::Util qw(looks_like_number);
# Helpers are private to this package, enforced at call time so that method
# dispatch ($self->_helper) is covered as well as plain function calls.
use Sub::Private { 'mode' => 'enforce' };
use Sub::Protected;
use Sys::Syslog ();

use version; our $VERSION = version->declare('0.004.0');

# What the signature is made with: the shape receiving sites expect.
Readonly my $ALGORITHM => 'rsa-sha256';
Readonly my $CANONICALIZATION => 'relaxed';

# Where keys are kept, and what a key file is called.
Readonly my $KEY_SUFFIX => '.private';
Readonly my $KEYFILE_NAME_SUFFIX => qr/\.(?:private|key|pem)\z/;
Readonly my $DEFAULT_KEYDIR_NAME => 'dkim';
Readonly my $DEFAULT_SENDMAIL => '/usr/sbin/sendmail';
Readonly my $DOMAIN_SEPARATOR => qr/[\s,]+/;
Readonly my $DOMAIN_SYNTAX => qr/\A[A-Za-z0-9.-]+\z/;

# The exit statuses of send(): sendmail's own, or ours when it never ran.
Readonly my $EXIT_ACCEPTED => 0;
Readonly my $EXIT_CANNOT_RUN => 1;

# The syslog line.  A missing value is logged as a dash so that every field
# is always present and the line can be split on spaces.
Readonly my $SYSLOG_IDENT => 'mail-dkim';
Readonly my $SYSLOG_OPTIONS => 'pid,ndelay';
Readonly my $SYSLOG_FACILITY => 'mail';
Readonly my $SYSLOG_LEVEL => 'info';
Readonly my $MISSING_VALUE => '-';
Readonly my @RECIPIENT_HEADERS => qw(To Cc Bcc);

# sendmail options that take a value, either attached (-fuser) or as the next
# argument (-f user).  Knowing them is what stops a value being taken for a
# recipient, or a letter inside a value being taken for a flag.
Readonly my $VALUE_OPTIONS => 'fBboprRVNLXAqFC';

# Every sentence this module can say.  An entry is a format with named
# placeholders, %{name}s or %{name}d, or a hash of such formats chosen by the
# arguments' "count" (zero, one, other) and/or "variant" (a gender or other
# context, alone or as "variant.count").  A language is added by passing a
# "messages" option to new(), which may be set from an Object::Configure file.
Readonly my %DEFAULT_MESSAGES => (
	'key_unreadable' => 'Mail::Send::DKIM: no readable key at %{keyfile}s; sending %{domain}s unsigned',
	'sign_failed' => 'Mail::Send::DKIM: cannot sign for %{domain}s (%{error}s); sending unsigned',
	'sendmail_failed' => 'Mail::Send::DKIM: cannot run %{sendmail}s: %{os_error}s',
	'keydir_unreadable' => 'Mail::Send::DKIM: cannot read %{keydir}s: %{os_error}s',
	'keys_ambiguous' => {
		'one' => 'Mail::Send::DKIM: %{keydir}s holds %{count}d key; name the selector to choose one',
		'other' => 'Mail::Send::DKIM: %{keydir}s holds %{count}d keys; name the selector to choose one',
	},
	'syslog_failed' => 'Mail::Send::DKIM: cannot write to syslog: %{error}s',
	'bad_arguments' => 'Mail::Send::DKIM: the arguments of a message must be a hash reference, not %{type}s',
	'unknown_message' => 'Mail::Send::DKIM: no message is defined for the key "%{key}s"',
	'missing_argument' => 'Mail::Send::DKIM: the message "%{key}s" needs the argument "%{argument}s"',
);

# The options new() accepts.  Anything else - Object::Configure adds some of its
# own - is ignored rather than refused.
Readonly my %NEW_SCHEMA => (
	'domains' => { 'type' => ['string', 'arrayref'], 'optional' => 1 },
	'signing_domain' => { 'type' => 'string', 'optional' => 1 },
	'keydir' => { 'type' => 'string', 'optional' => 1 },
	'selector' => { 'type' => 'string', 'optional' => 1 },
	'keyfile' => { 'type' => 'string', 'optional' => 1 },
	'sendmail' => { 'type' => 'string', 'optional' => 1 },
	'home' => { 'type' => 'string', 'optional' => 1 },
	'messages' => { 'type' => 'hashref', 'optional' => 1 },
);

=encoding utf-8

=head1 NAME

Mail::Send::DKIM - sign a message with DKIM and hand it to sendmail

=head1 VERSION

0.004.0

=head1 SYNOPSIS

	use Mail::Send::DKIM;

	my $dkim = Mail::Send::DKIM->new(
		domains => ['example.org'],
		keydir => "$ENV{HOME}/dkim",
	);

	my $signed = $dkim->sign($message);
	$message = $signed if(defined($signed));

	exit($dkim->send($message, '-t', '-f', 'alerts@example.org'));

More ways to use it:

	# 1. Settings from the environment (DKIM_DOMAINS, DKIM_KEYDIR, ...)
	#    This is how the mail-dkim program works.
	my $dkim = Mail::Send::DKIM->new();

	# 2. One key file that you name yourself, for a test
	my $dkim = Mail::Send::DKIM->new(
		domains => 'example.org example.net',
		keyfile => '/etc/dkim/2026.private',
	);

	# 3. Sign and send, then write a line to the system log
	my @sendmail_args = ('-t', '-f', 'alerts@example.org');
	my $signed = $dkim->sign($message);
	$message = $signed if(defined($signed));
	if($dkim->send($message, @sendmail_args) == 0) {
		$dkim->log_send($message, @sendmail_args);
	}

	# 4. Only ask whose mail it is, or which key would be used
	my $domain = Mail::Send::DKIM::from_domain($message);
	my $selector = $dkim->selector();

	# 5. Warnings in your own words
	my $dkim = Mail::Send::DKIM->new(
		messages => { key_unreadable => 'No key at %{keyfile}s' },
	);

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

B<DKIM_DOMAINS>, B<DKIM_SIGNING_DOMAIN>, B<DKIM_KEYDIR>, B<DKIM_SELECTOR>,
B<DKIM_KEYFILE> and B<SENDMAIL> are read by B<new> when the corresponding option is not given, so
the command line programs needs no configuration of its own.

=head1 PROGRAMS

The distribution is named after this module and installs five programs with
it, each with a page of its own: C<perldoc bin/mail-dkim>,
C<perldoc bin/dmarc-report.pl>, C<perldoc bin/dmarc-summary>,
C<perldoc bin/dmarc-check-mail.pl> and C<perldoc bin/dmarc-weekly.sh> in a
checkout, and the same pages as manual pages once installed.

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

=item L<dmarc-summary|https://github.com/nigelhorne/Mail-Send-DKIM/blob/master/bin/dmarc-summary>

The shorter reading of the same reports: a line per source address with its
DKIM and SPF verdicts, the disposition applied, whether the address is one of
ours and who owns it, over every report in F<~/Downloads>, plain or gzipped.
Where B<dmarc-report.pl> decides whether anything needs acting on and says so
in its exit status, this one is for reading.

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

The four DMARC programs are the reason the module exists: they report on the
mail it signs, and the weekly one sends its own report through it.

=head1 METHODS

=head2 B<new> %options

=over 4

=item C<domains>

The domains to sign for, either an array reference or a string of them
separated by commas or spaces.  Defaults to C<$ENV{DKIM_DOMAINS}>.  A message
from any other domain is left alone.

=item C<signing_domain>

The domain put in the signature (its C<d=> tag), when it is not the domain in
the C<From:> header - for a host that signs with the key of a parent or
organisational domain, say.  Defaults to C<$ENV{DKIM_SIGNING_DOMAIN}>; with
neither set, the C<From:> domain is used.  Which messages are signed is still
decided by B<domains>, which is matched against the C<From:> domain.  The
receiver finds the public key at
F<< <selector>._domainkey.<signing_domain> >>, and DMARC accepts the signature
only if that domain aligns with the C<From:> domain.

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

=item C<home>

The directory the default B<keydir> is made from, as F<< <home>/dkim >>.
Defaults to C<$ENV{HOME}>, then the home directory in the password file entry,
then the current directory.  It matters only when B<keydir> is not given.

=item C<messages>

A hash reference of message formats that replace or add to the ones this
module speaks with, keyed by message key, for a language other than English or
wording of your own.  See B<i18n> for the format.  Because B<new> reads its
options through L<Object::Configure>, the same hash can come from a
configuration file.

=back

=head3 PURPOSE

Builds the signer.  No file is read and no program is run here, so a mistake
in B<keydir> or B<keyfile> shows when a message is signed, not when the object
is made.

=head3 EXAMPLE

	# Everything from the environment: DKIM_DOMAINS, DKIM_KEYDIR, ...
	my $dkim = Mail::Send::DKIM->new();

	# Everything given, a list of domains, a named key and a test sendmail
	my $dkim = Mail::Send::DKIM->new(
		domains => 'example.org, example.net',
		keyfile => '/etc/dkim/2026.private',
		sendmail => '/usr/local/bin/capture-sendmail',
	);

	# A message in another language
	my $dkim = Mail::Send::DKIM->new(
		messages => { sendmail_failed => 'sendmail %{sendmail}s: %{os_error}s' },
	);

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict)

	{
		domains => { type => ['string', 'arrayref'], optional => 1 },
		signing_domain => { type => 'string', optional => 1 },
		keydir => { type => 'string', optional => 1 },
		selector => { type => 'string', optional => 1 },
		keyfile => { type => 'string', optional => 1 },
		sendmail => { type => 'string', optional => 1 },
		home => { type => 'string', optional => 1 },
		messages => { type => 'hashref', optional => 1 },
	}

Options not listed are ignored.  The options may be given as a hash or as a
hash reference.

=head4 Output (Return::Set)

	{ type => 'object', isa => 'Mail::Send::DKIM' }

=head3 MESSAGES

An option of the wrong type is refused with the message of
L<Params::Validate::Strict>, which names the option.  Nothing else is said.

=head3 PSEUDOCODE

	options = get_params(args)
	options = Object::Configure(options)       # config files, environment
	options = validate(options, NEW_SCHEMA)    # croak on a wrong type
	home    = options.home or $HOME or passwd entry or "."
	domains = split(options.domains or $DKIM_DOMAINS), lower-cased, as a set
	messages = defaults overlaid with options.messages
	return object(domains, keydir, selector, keyfile, sendmail, messages)

=cut

sub new
{
	my $class = shift;

	# Handle hash or hashref arguments
	my $params = Params::Get::get_params(undef, \@_) // {};

	$params = Object::Configure::configure($class, $params);
	$params = validate_strict(
		'schema' => \%NEW_SCHEMA,
		'input' => $params,
		'unknown_parameter_handler' => 'ignore',
	);

	my $home = $params->{'home'} || $ENV{'HOME'} || (getpwuid($<))[7] || '.';

	my $self = {
		'domains' => _domain_set($params->{'domains'} // $ENV{'DKIM_DOMAINS'}),
		'signing_domain' => _signing_domain($params->{'signing_domain'} // $ENV{'DKIM_SIGNING_DOMAIN'}),
		'keydir' => $params->{'keydir'} // $ENV{'DKIM_KEYDIR'} // "$home/$DEFAULT_KEYDIR_NAME",
		'selector' => $params->{'selector'} // $ENV{'DKIM_SELECTOR'},
		'keyfile' => $params->{'keyfile'} // $ENV{'DKIM_KEYFILE'},
		'sendmail' => $params->{'sendmail'} // $ENV{'SENDMAIL'} // $DEFAULT_SENDMAIL,
		# Shallow overlay: a caller's entry replaces the default one whole.
		'messages' => { %DEFAULT_MESSAGES, %{ $params->{'messages'} // {} } },
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

=head3 PURPOSE

Signs the message when, and only when, a key for its C<From:> domain can be
found and used.  Nothing is raised for a failure to sign: the caller sends the
message as it is.

The key must be a regular file that can be read.  A directory whose name ends
in F<.private> is not a key, and is reported as one that cannot be read.

=head3 EXAMPLE

	my $signed = $dkim->sign($message);
	$message = $signed if(defined($signed));

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict)

	{ message => { type => 'string' } }

An undefined message is treated as an empty one, which has no C<From:>.  It
may be given positionally or as C<< message => $text >>.

=head4 Output (Return::Set)

	{ type => 'string', optional => 1 }

The signed message in the local form, or C<undef>.

=head3 MESSAGES

	Message key       Text                                      Meaning and resolution
	key_unreadable    no readable key at FILE; sending DOMAIN   The key file is absent or not
	                  unsigned                                  readable: fix the path or the mode.
	sign_failed       cannot sign for DOMAIN (REASON); ...      Mail::DKIM refused the key or
	                                                            the message: see REASON.
	keydir_unreadable, keys_ambiguous                           As for selector, below.

Each is a warning, and the return is C<undef>.

=cut

sub sign
{
	my $self = shift;

	my $params = Params::Get::get_params('message', \@_);
	my $message = validate_strict('schema' => { 'message' => { 'type' => 'string' } }, 'input' => $params)->{'message'} // '';

	my $domain = from_domain($message);

	# Only a domain this host signs for is worth looking for a key.
	return (defined($domain) && $self->{'domains'}->{$domain}) ? $self->_sign_for($domain, $message) : undef;
}

# Purpose:        Find the key for a domain we sign for and sign with it.
# Entry criteria: $domain is a lower-case domain in the signing set; $message
#                 is the message as it arrived.
# Exit status:    The signed message in the local form, or undef - after a
#                 warning that says why - when there is no usable key.
# Side effects:   Reads the key file; may warn.
sub _sign_for :Private
{
	my ($self, $domain, $message) = @_;

	my $selector = $self->selector();
	my $signed;

	if(defined($selector)) {
		# A key file named outright needs neither the directory nor the naming
		# convention; otherwise the key is <keydir>/<selector>.private.
		my $keyfile = $self->{'keyfile'} // "$self->{'keydir'}/$selector$KEY_SUFFIX";

		# A directory is readable too, but it is not a key.
		if(-f $keyfile && -r $keyfile) {
			$signed = $self->_dkim_sign($self->{'signing_domain'} // $domain, $selector, $keyfile, $message);
		} else {
			$self->_say('key_unreadable', { 'keyfile' => $keyfile, 'domain' => $domain });
		}
	}

	return $signed;
}

# Purpose:        Make the DKIM signature and put it on the front of the message.
# Entry criteria: $keyfile is readable; $selector and $domain are not empty.
# Exit status:    The signed message in the local form, or undef after a warning
#                 when Mail::DKIM could not sign (a key it cannot load, say).
# Side effects:   May warn.  Nothing is raised: a failure to sign must not
#                 become a failure to deliver.
sub _dkim_sign :Private
{
	my ($self, $domain, $selector, $keyfile, $message) = @_;

	# eval sets $@, which belongs to the caller.
	local $@ = '';

	# DKIM hashes the message in the form it travels in, where every line
	# ends CRLF, so the signature is made over a CRLF copy of what arrived,
	# while what is returned has the local line endings.
	my $local = _local($message);
	(my $wire = $local) =~ s/\n/\r\n/g;

	my $signed = eval {
		my $signer = Mail::DKIM::Signer->new(
			'Algorithm' => $ALGORITHM,
			'Method' => $CANONICALIZATION,
			'Domain' => $domain,
			'Selector' => $selector,
			'KeyFile' => $keyfile,
		);
		$signer->PRINT($wire);
		$signer->CLOSE();

		$signer->signature->as_string() . "\n" . $local;
	};
	$self->_say('sign_failed', { 'domain' => $domain, 'error' => _trim_error($@ || 'unknown error') }) unless(defined($signed));

	return $signed;
}

=head2 B<send> $message, @arguments

Pipes the message to B<sendmail> with the arguments given - C<-t>, C<-f> and
the rest are sendmail's own - and returns C<0> when sendmail accepted the
message, sendmail's exit status when it did not, and C<1> when sendmail cannot
be run at all.  The message is normalised to LF first, so nothing that arrived
with CRLF - signed or passed through unsigned - carries a carriage return to
the MTA.

=head3 PURPOSE

Delivers the message to the local MTA and reports what the MTA said.

A B<sendmail> that is an empty string is the same failure as a program that is
not there: the return is C<1> and the message is C<sendmail_failed>.  The
caller's C<$@>, C<$?> and C<$SIG{PIPE}> are the same after the call as before
it.

=head3 EXAMPLE

	my $status = $dkim->send($message, '-t', '-f', 'alerts@example.org');
	exit($status);

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict)

	{
		message => { type => 'string' },
		arguments => { type => 'arrayref', optional => 1 },   # the rest of @_
	}

=head4 Output (Return::Set)

	{ type => 'integer', min => 0, max => 255 }

=head3 MESSAGES

	Message key        Meaning and resolution
	sendmail_failed    The sendmail program could not be started (not found,
	                   not executable): fix the sendmail option or SENDMAIL.
	                   The return is 1.

A sendmail that exits before it has read the whole message does not stop the
caller with SIGPIPE: its exit status is returned.

=head3 PSEUDOCODE

	ignore SIGPIPE's default action (a handler, so sendmail does not inherit it)
	open a pipe to sendmail with the arguments, as a list so no shell is involved
	if that fails: warn sendmail_failed, return 1
	write the local form of the message, then close the pipe
	if the write and the close both succeeded: return 0
	return sendmail's exit status, or 1 when that would have been 0

=cut

# send() is the documented name of this method, though perl has a builtin of that
# name: the builtin is for sockets, which this package does not use.
sub send ## no critic (Subroutines::ProhibitBuiltinHomonyms)
{
	my ($self, $message, @args) = @_;

	# A sendmail that cannot be run, or that refuses the message, is a status
	# for the caller, not an exception, so autodie stands aside for the pipe.
	no autodie qw(open close);
	# perl would add its own "Can't exec" to the warning given below.
	no warnings 'exec';
	# A sendmail that refuses a message may exit before reading it, and the
	# write would then kill us with SIGPIPE before its status could be read.
	# A handler, not IGNORE: an ignored signal is also ignored by the child.
	local $SIG{'PIPE'} = sub { };
	# close() leaves sendmail's wait status in $?, which belongs to the caller.
	local $? = 0;

	my $status = $EXIT_CANNOT_RUN;

	# An empty name would make perl complain about the open itself, not about the program.
	if(length($self->{'sendmail'}) && open(my $sendmail, '|-', $self->{'sendmail'}, @args)) {
		my $written = print {$sendmail} _local($message // '');

		# close() waits for sendmail; its exit status is in $? afterwards.
		$status = close($sendmail) ? ($written ? $EXIT_ACCEPTED : $EXIT_CANNOT_RUN) : (($? >> 8) || $EXIT_CANNOT_RUN);
	} else {
		local $! = ENOENT unless(length($self->{'sendmail'}));
		$self->_say('sendmail_failed', { 'sendmail' => $self->{'sendmail'}, 'os_error' => "$!" });
	}

	return $status;
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

=head3 PURPOSE

Leaves a trace, in the system log, of every message that was passed on.

The arguments are read the way sendmail reads them.  These options take a
value, which is the rest of the argument or else the next argument, and the
value is never a recipient: C<-f -F -o -b -p -r -R -V -N -L -X -A -q -C -B>.
Only C<-f> is used.  A C<-f> with an empty value is a null sender, and is
logged as C<->.  C<-t> counts when it is alone or in a group of flags
(C<-ti>), but not when it is inside a value, as in C<-FNigelTest>, and not in
C<-bt>.  An empty argument names nobody.  The members of an empty group, such
as C<undisclosed-recipients:;>, are not recipients.

=head3 EXAMPLE

	$dkim->log_send($message, '-t', '-f', 'alerts@example.org')
		if($dkim->send($message, '-t', '-f', 'alerts@example.org') == 0);

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict)

	{
		message => { type => 'string' },
		arguments => { type => 'arrayref', optional => 1 },
	}

=head4 Output (Return::Set)

	{ type => 'boolean' }

=head3 MESSAGES

	Message key        Meaning and resolution
	syslog_failed      openlog or syslog failed: check that a syslog daemon is
	                   running and its socket is reachable.  The return is 0.

=head3 PSEUDOCODE

	parse the arguments into (sender, recipients, whether -t was given), where an
	    option that takes a value, attached or separate, never yields a recipient
	parse the headers of the message once
	sender   = the -f value, else the first address of From
	if -t was given: add the addresses of To, Cc and Bcc to the recipients
	subject  = the Subject, or "-"
	make the line, replace control characters by spaces
	write it to syslog; if that fails, warn syslog_failed and return 0
	return 1

=cut

sub log_send
{
	my ($self, $message, @args) = @_;

	my $parsed = _parse_sendmail_args(\@args);
	my $headers = _parse_headers($message // '');

	my @recipients = @{ $parsed->{'recipients'} };
	# With -t sendmail reads the recipients from the headers as well.
	push(@recipients, map { @{ _addresses($headers->{lc($_)}) } } @RECIPIENT_HEADERS) if($parsed->{'reads_headers'});

	my $subject = $headers->{'subject'};
	$subject = $MISSING_VALUE unless(defined($subject) && length($subject));

	# -f wins over the From: header, and an empty -f (a bounce) stays empty.
	my $sender = $parsed->{'sender'} // _addresses($headers->{'from'})->[0];

	my $line = sprintf('sender=%s recipient=%s subject=%s',
		$sender || $MISSING_VALUE,
		@recipients ? join(',', @recipients) : $MISSING_VALUE,
		$subject);

	# The subject and the addresses come from the message, so a line break in
	# any of them would otherwise let it forge a second log line.
	$line =~ s/[[:cntrl:]]/ /g;

	return $self->_write_syslog($line) ? 1 : 0;
}

# Purpose:        Split the arguments sendmail was given into what the log needs.
# Entry criteria: $args is an array reference of the arguments, as given.
# Exit status:    A hash reference: sender (the -f value, or absent),
#                 recipients (array reference), reads_headers (true for -t).
# Side effects:   None.
sub _parse_sendmail_args :Private
{
	my $args = shift;

	my %parsed = ('recipients' => []);
	# The letter of an option that is still waiting for its value.
	my $pending;

	foreach my $arg (@{$args}) {
		if(defined($pending)) {
			# The value of -f is the sender; the others are not logged.
			$parsed{'sender'} = $arg if($pending eq 'f');
			undef($pending);
		} elsif($arg eq '--') {
			next;
		} elsif($arg =~ /\A-([$VALUE_OPTIONS])(.*)\z/s) {
			# Like getopt, the rest of the argument is the value when there is any.
			my ($letter, $attached) = ($1, $2);
			if(length($attached)) {
				$parsed{'sender'} = $attached if($letter eq 'f');
			} else {
				$pending = $letter;
			}
		} elsif($arg =~ /\A-(.*)\z/s) {
			# A cluster of flags, such as -ti, none of which takes a value.
			$parsed{'reads_headers'} = 1 if($1 =~ /t/);
		} elsif(length($arg)) {
			# An empty argument names nobody.
			push(@{ $parsed{'recipients'} }, $arg);
		}
	}

	return \%parsed;
}

# Purpose:        Send one line to syslog.
# Entry criteria: $line holds no control characters.
# Exit status:    True when syslog took the line, false - after a warning -
#                 when it could not be reached.
# Side effects:   Opens and closes the syslog connection.
sub _write_syslog :Private
{
	my ($self, $line) = @_;

	# eval sets $@, which belongs to the caller.
	local $@ = '';

	my $written = eval {
		Sys::Syslog::openlog($SYSLOG_IDENT, $SYSLOG_OPTIONS, $SYSLOG_FACILITY);
		Sys::Syslog::syslog($SYSLOG_LEVEL, '%s', $line);
		1;
	};
	my $error = $@;

	# The connection is closed whether or not the line went in, and a failure
	# to close it must not turn a line that was written into a failure.
	eval { Sys::Syslog::closelog(); 1 }; ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)

	$self->_say('syslog_failed', { 'error' => _trim_error($error) }) unless($written);

	return $written;
}

# Purpose:        Read the header block of a message into a hash.
# Entry criteria: $message is a string, with LF or CRLF line endings.
# Exit status:    A hash reference from lower-case header name to the unfolded
#                 value of the first header of that name.  A message with no
#                 blank line is all header.
# Side effects:   None.
sub _parse_headers :Private
{
	my $message = shift;

	my ($block) = $message =~ /\A(.*?)\r?\n\r?\n/s;
	$block //= $message;

	# A header can be folded over several lines; join them back.
	$block =~ s/\r?\n[ \t]+/ /g;

	my %headers;
	foreach my $line (split(/\r?\n/, $block)) {
		$headers{lc($1)} //= $2 if($line =~ /\A([^\s:]+):[ \t]*(.*?)\s*\z/);
	}

	return \%headers;
}

# Purpose:        Parse a header value into addresses.
# Entry criteria: $value is a string.
# Exit status:    The list of Mail::Address objects, in order, as many as could
#                 be made of it.
# Side effects:   None.  The parser's complaints about a malformed header are
#                 dropped: a header is the sender's to get wrong, and a
#                 warning in the log for it would be noise.
sub _parse_addresses :Private
{
	my $value = shift;

	local $SIG{'__WARN__'} = sub { };

	return Mail::Address->parse($value);
}

# Purpose:        The addresses in a header value.
# Entry criteria: $value is a header value, or undef.
# Exit status:    An array reference of the addresses, in order; empty when
#                 there are none.  Display names and comments are dropped.
# Side effects:   None.
sub _addresses :Private
{
	my $value = shift;

	# A group with no members, "undisclosed-recipients:;", comes back as its name.
	return defined($value) ? [ grep { length && !/:\z/ } map { $_->address() // '' } _parse_addresses($value) ] : [];
}

=head2 B<from_domain> $message

The domain of the address in the first C<From:> header, in lower case, or
C<undef> when there is no such header.  Folded headers and display names are
understood.

=head3 PURPOSE

Says whose domain a message claims to be from, which is what decides whether
it is signed.  The address is read by L<Mail::Address>, so quoted display
names, comments and groups are handled by a parser that has seen them before.
Only a plain host name is accepted as a domain (letters, digits, dots and
hyphens).

A C<From:> header that holds a control character, other than a tab, gives
C<undef>.  A NUL or an escape character can make two programs read two
different addresses from the same header, so no domain is trusted from it.

=head3 EXAMPLE

	my $domain = Mail::Send::DKIM::from_domain($message);	# 'example.org'
	my $same = $dkim->from_domain($message);

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict)

	{ message => { type => 'string' } }

It may be called as a function or as a method.

=head4 Output (Return::Set)

	{ type => 'string', optional => 1, matches => qr/\A[a-z0-9.-]+\z/ }

=head3 MESSAGES

None: a message without a usable From: is not an error, the answer is C<undef>.

=cut

sub from_domain
{
	# Called as a method, the first argument is the object, not the message.
	shift if(@_ > 1);
	my $message = validate_strict('schema' => { 'message' => { 'type' => 'string' } }, 'input' => { 'message' => $_[0] })->{'message'} // '';

	my $from = _parse_headers($message)->{'from'};
	my $host;

	# A control character in the header, a NUL especially, can make two
	# parsers read two different addresses, so no domain is trusted from it.
	if(defined($from) && $from !~ /[\x00-\x08\x0b-\x1f\x7f]/) {
		# The first address is the author; display names and comments around
		# it are Mail::Address's to deal with, not ours.
		my ($address) = _parse_addresses($from);
		$host = $address->host() if(defined($address));
	}

	# Only a plain host name is a domain; the result is put in the signature.
	return (defined($host) && $host =~ $DOMAIN_SYNTAX) ? lc($host) : undef;
}

=head2 B<selector>

The selector the message will be signed under: the one given to B<new> or read
from C<DKIM_SELECTOR>, otherwise the name of the B<keyfile> when one is given,
otherwise the name of the only F<*.private> file in B<keydir>.  C<undef> when it
cannot be decided - no key, or several keys and no name - and the reason is a
warning on standard error.  B<sign> asks this before doing anything else.

=head3 PURPOSE

Settles which of the keys is to be used, once, in one place.

A key in B<keydir> is a regular file with a name in front of F<.private>.
A directory with such a name, and a file that is only F<.private>, are not
keys and are not counted.  A selector that is an empty string is the same as
none.

=head3 EXAMPLE

	my $selector = $dkim->selector();
	die 'no usable key' unless(defined($selector));

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict)

	{}

=head4 Output (Return::Set)

	{ type => 'string', optional => 1 }

=head3 MESSAGES

	Message key         Meaning and resolution
	keydir_unreadable   keydir cannot be opened: create it, or fix the mode or
	                    the keydir option.
	keys_ambiguous      keydir holds no key, or more than one, and no selector
	                    was named: add the key, or set DKIM_SELECTOR.

=head3 PSEUDOCODE

	if a selector was given: return it
	if a key file was given: return its name without .private, .key or .pem
	list the *.private files in keydir (a warning and undef if it cannot be read)
	if there is not exactly one: warn, return undef
	return its name without .private

=cut

sub selector
{
	my $self = shift;

	my $selector = $self->{'selector'};
	return $selector if(defined($selector) && length($selector));

	# A named key file carries its selector in its name, which is the layout
	# the keys are kept in: <keydir>/<selector>.private.
	if(defined($self->{'keyfile'})) {
		($selector = basename($self->{'keyfile'})) =~ s/$KEYFILE_NAME_SUFFIX//;
		return $selector if(length($selector));
	}

	my $keys = $self->_private_keys();
	# undef, as the POD says: a bare return would be an empty list when the
	# result is used in a list, as in a hash of options.
	return undef unless(defined($keys)); ## no critic (Subroutines::ProhibitExplicitReturnUndef)

	unless(@{$keys} == 1) {
		$self->_say('keys_ambiguous', { 'keydir' => $self->{'keydir'}, 'count' => scalar(@{$keys}) });
		return undef; ## no critic (Subroutines::ProhibitExplicitReturnUndef)
	}

	($selector = $keys->[0]) =~ s/\Q$KEY_SUFFIX\E\z//;

	return $selector;
}

# Purpose:        List the keys in the key directory.
# Entry criteria: $self->{keydir} is set.
# Exit status:    An array reference of the names of the files ending .private, sorted;
#                 undef, after a warning, when the directory cannot be read.
# Side effects:   Reads a directory; may warn.
sub _private_keys :Private
{
	my $self = shift;

	# An unreadable directory is a warning and an unsigned message, so autodie
	# stands aside.
	no autodie qw(opendir closedir);

	my $keys;
	if(opendir(my $dh, $self->{'keydir'})) {
		# A key is a file with a name before the suffix: a directory called
		# x.private, or a file called just .private, is not one.
		$keys = [ sort grep { /\A.+\Q$KEY_SUFFIX\E\z/s && -f "$self->{'keydir'}/$_" } readdir($dh) ];
		closedir($dh);
	} else {
		$self->_say('keydir_unreadable', { 'keydir' => $self->{'keydir'}, 'os_error' => "$!" });
	}

	return $keys;
}

=head2 B<i18n> $key, \%arguments

Returns the text of a message, in the language this object speaks, with the
arguments put in.  This is the one place any sentence is made, so a caller can
change every message by giving B<new> a C<messages> option.

A message is a format whose placeholders are named, C<%{name}s> or
C<%{name}d>, and which may carry the usual C<sprintf> width and flags
(C<%{name}-8s>).  It may instead be a hash of formats, from which one is chosen
by the arguments: C<count> selects C<zero>, C<one> or C<other> (C<other> when
there is no better one), and C<variant> - a grammatical gender, for instance -
selects the entry of that name, or C<variant.one>, C<variant.other> and so on
when the choice is both.  An argument a format asks for and was not given is an
error, not an empty string.  An argument that is given as C<undef> is an empty
string (C<0> in a C<%{name}d>).  A C<count> that is not a number selects no
plural form.  C<%%> is a percent sign, and any other C<%> that is not part of a
placeholder is plain text.  An entry that is an empty hash says nothing.

Croaks if C<$key> is not a message that is defined.

=head3 EXAMPLE

	my $text = $dkim->i18n('keys_ambiguous', { keydir => '/etc/dkim', count => 2 });
	# '... /etc/dkim holds 2 keys; name the selector to choose one'

	my $french = Mail::Send::DKIM->new(messages => {
		'keys_ambiguous' => {
			'one' => '%{keydir}s contient %{count}d cle',
			'other' => '%{keydir}s contient %{count}d cles',
		},
	});

=head3 API SPECIFICATION

=head4 Input (Params::Validate::Strict)

	{
		key => { type => 'string' },
		arguments => { type => 'hashref', optional => 1 },
	}

=head4 Output (Return::Set)

	{ type => 'string' }

=head3 MESSAGES

	Message key        Meaning and resolution
	unknown_message    The key is not in the catalogue: fix the caller, or add it to messages.
	bad_arguments      The arguments were not a hash reference: pass { name => value }.
	missing_argument   A placeholder has no argument: pass it.

=cut


sub i18n
{
	my ($self, $key, $args) = @_;

	$args //= {};
	$key //= '';
	croak($self->i18n('bad_arguments', { 'type' => ref($args) || 'a plain value' })) unless(ref($args) eq 'HASH');

	# The default catalogue is the fallback, so a caller's catalogue cannot
	# take away the message that reports a missing message.
	my $entry = $self->{'messages'}->{$key} // $DEFAULT_MESSAGES{$key};
	croak($self->i18n('unknown_message', { 'key' => $key })) unless(defined($entry));

	return $self->_interpolate($key, _choose_format($entry, $args), $args);
}

# Purpose:        Pick the format of a message that has variants.
# Entry criteria: $entry is a string, or a hash reference of formats keyed by
#                 zero, one, other, a variant name, or "variant.count".
# Exit status:    The format.  The most specific variant that exists wins, and
#                 "other" is the fall-back, then any entry at all.
# Side effects:   None.
sub _choose_format :Private
{
	my ($entry, $args) = @_;

	my $format = $entry;

	if(ref($entry) eq 'HASH') {
		my $variant = $args->{'variant'};
		my $count = $args->{'count'};
		# A count that is not a number selects no plural form.
		my $plural = !looks_like_number($count // '') ? undef : ($count == 0 ? 'zero' : ($count == 1 ? 'one' : 'other'));

		my @candidates = (
			(defined($variant) && defined($plural) ? "$variant.$plural" : ()),
			(defined($variant) ? $variant : ()),
			(defined($plural) ? $plural : ()),
			'other',
		);
		my ($chosen) = grep { exists($entry->{$_}) } @candidates;
		# An empty entry says nothing, rather than failing.
		my $name = $chosen // (sort keys %{$entry})[0];
		$format = defined($name) ? ($entry->{$name} // '') : '';
	}

	return $format;
}

# Purpose:        Put the arguments into a format with named placeholders.
# Entry criteria: $format uses %{name}s / %{name}d placeholders, and %% for a
#                 percent sign.  Anything else in it is plain text.
# Exit status:    The text.  Croaks, with the missing_argument message, if a
#                 placeholder has no argument.
# Side effects:   None.
sub _interpolate :Private
{
	my ($self, $key, $format, $args) = @_;

	# Only the placeholders are handed to sprintf, one at a time, so a stray
	# percent sign in the text, or in a value, can never be taken for a
	# directive of its own.
	my $text = '';
	foreach my $part (split(/(%\{\w+\}[-+ 0#]*\d*(?:\.\d+)?[sd])/, $format)) {
		if($part =~ /\A%\{(\w+)\}(.+)\z/s) {
			my ($name, $spec) = ($1, $2);
			croak($self->i18n('missing_argument', { 'key' => $key, 'argument' => $name })) unless(exists($args->{$name}));

			# A value that is not a number is a caller's mistake in a %d, not worth a warning.
			no warnings 'numeric';
			$text .= sprintf("%$spec", $args->{$name} // ($spec =~ /d\z/ ? 0 : ''));
		} else {
			(my $plain = $part) =~ s/%%/%/g;
			$text .= $plain;
		}
	}

	return $text;
}

# Purpose:        Make the form of a message that is handed to sendmail.
# Entry criteria: $message is a string.
# Exit status:    The message with LF line endings and no carriage return
#                 anywhere, whatever arrived.  A CR is data to the MTA that
#                 keeps the message - Postfix's sendmail_fix_line_endings and
#                 Exim both write the CRLF of SMTP themselves - so one that
#                 survived would reach the receiver doubled, and the message
#                 would fail the signature it was just given.
# Side effects:   None.
sub _local :Private
{
	my $message = shift;

	$message =~ tr/\r//d;

	return $message;
}

# Purpose:        Normalise the domain to put in the signature.
# Entry criteria: $domain is a string or undef.
# Exit status:    The lower-case domain, or undef when none is given (an empty
#                 or blank value counts as none).
sub _signing_domain :Private
{
	my $domain = shift;

	return undef unless(defined($domain) && $domain =~ /\S/);	## no critic (ProhibitExplicitReturnUndef)
	$domain =~ s/\A\s+|\s+\z//g;

	return lc($domain);
}

# Purpose:        Make the set of domains this host signs for.
# Entry criteria: $domains is an array reference, a string separated by commas
#                 or spaces, or undef.
# Exit status:    A hash reference whose keys are the lower-case domains.
# Side effects:   None.
sub _domain_set :Private
{
	my $domains = shift;

	my @domains = ref($domains) eq 'ARRAY' ? @{$domains} : split($DOMAIN_SEPARATOR, $domains // '');

	return { map { lc($_) => 1 } grep { defined && length } @domains };
}

# Purpose:        Tidy an error for use inside a sentence.
# Entry criteria: $text is a string, perhaps with a trailing newline.
# Exit status:    The text without its trailing whitespace.
# Side effects:   None.
sub _trim_error :Private
{
	my $text = shift;

	$text =~ s/\s+\z//;

	return $text;
}

# Purpose:        Warn, in the language of this object.
# Entry criteria: $key is in the message catalogue.
# Exit status:    $self, so calls can be chained.
# Side effects:   A warning on standard error, reported where the caller of this
#                 module called it, by Carp.  Protected, so that a subclass may
#                 say things in the same way.
sub _say :Protected
{
	my ($self, $key, $args) = @_;

	carp($self->i18n($key, $args));

	return $self;
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

=head1 COMMON PITFALLS

=over 4

=item * B<sign> returns C<undef> to mean "nothing was signed"

It does not die and it does not return an empty string.  Always test with
C<defined>.  The reason is a warning on standard error, except when the
message simply is not from one of your domains: that is normal and says
nothing.  Keep the original message and send it if B<sign> gave you C<undef>.

=item * An C<undef> option means "not given"

C<< new(keydir => undef) >> is the same as leaving C<keydir> out: the
environment variable, then the built-in default, is used.  An empty string is
a value: C<< domains => '' >> means "sign for no domain", and nothing is
signed.

=item * Replacing a message replaces all of it

The C<messages> option is merged one level deep.  A key you give replaces the
whole entry for that key.  If the English entry has the forms C<one> and
C<other> and you give only C<other>, the C<one> form is gone: it does not fall
back to English.  Give every form you need.

=item * Every placeholder needs a value

A message such as C<%{error}s> is filled from the arguments given to B<i18n>.
A placeholder with no value is an error (a croak), not an empty space.  The
placeholder style is C<%{name}s>, not C<%s>.

=item * Exit status C<0> means "accepted", not "delivered"

B<send> only knows that sendmail took the message.  A later failure is the
mail system's to report.  Call B<log_send> only after a C<0>.

=item * The signed message is not the same text as the one you gave

Carriage returns are removed, so the result has LF line endings.  This is on
purpose, and B<send> does the same.  Do not compare the two with C<eq>.

=item * Only the first C<From:> header counts

A message with two C<From:> headers is signed for the domain of the first one.

=item * Several keys, no name

If the key directory holds more than one F<*.private> file and you give no
B<selector>, nothing is signed, and there is a warning.  Name the selector.

=item * C<~> is not expanded

C<< keydir => '~/dkim' >> means a directory that is really called C<~>.  Use
the full path, or C<$ENV{HOME}>.

=item * Private and protected methods

Names that start with an underscore cannot be called from outside the package.
Under a test harness (C<HARNESS_ACTIVE> is set) the check is switched off, so
that tests can reach them.

=back

=head1 ENCODING

The module works on B<bytes>, not on decoded characters, because DKIM signs
bytes.

=over 4

=item * The message

Give B<sign>, B<send>, B<log_send> and B<from_domain> a message that is
already encoded, normally as UTF-8 bytes.  Non-ASCII text and emojis in the
subject or the body are safe in that form.  Mail systems usually expect a
non-ASCII header to be MIME encoded (for example C<=?UTF-8?B?...?=>), and that
is your job, not this module's.

If the message is a Perl string holding characters above code point 255 (an
emoji that has been decoded, for example), B<sign> cannot sign it: there is a
warning and it returns C<undef>.  B<send> would write it as UTF-8 and Perl
would warn "Wide character".  Call C<Encode::encode('UTF-8', $text)> first.

=item * Domains and selectors

ASCII only.  The domain taken from C<From:> must be letters, digits, dots and
hyphens, or it is treated as no domain.  An internationalised domain name must
be written in its C<xn--> form.  Selectors are used as file names and in DNS,
so use letters, digits and hyphens.

=item * File names

B<keydir>, B<keyfile> and B<sendmail> are passed to the operating system as
they are.  Non-ASCII names work if the bytes are what the file system holds.

=item * The log line

B<log_send> writes the sender, recipients and subject as they are.  UTF-8 bytes
and emojis are kept.  Control characters, such as a line break, are replaced by
a space.

=item * Message texts

The text given in C<messages> may contain any characters, emojis included.
Warnings go to standard error: put a UTF-8 layer on it
(C<binmode(STDERR, ':encoding(UTF-8)')>) when the text is not ASCII, or Perl
will warn "Wide character".  The text of an operating system error comes from
the locale of the process.

=back

=head1 LIMITATIONS

These are the weaknesses of the design, set down so that they are chosen rather
than found.

=over 4

=item * One key for every domain

A single selector and key serve every domain in C<domains>.  A host that signs
for several customers with a key each cannot say so; it needs one object per
key.

=item * Only the From: domain is looked at

A message is signed when its first C<From:> domain is ours.  A message with two
C<From:> headers is signed with the first one's domain, and the signature does
not oversign the header, so a second C<From:> can be added later without
breaking it.  Refusing such a message would be the safer rule.

=item * The key is not checked

That the key file is readable is checked; its mode is not, and nor is whether
the public half is published in DNS.  A key that is readable by others is not
reported.

=item * The whole message is in memory

The message is a string, held two or three times over while it is signed.  A
very large message costs that much memory; a stream would not.

=item * Sending cannot be interrupted

B<send> waits for sendmail as long as sendmail takes.  There is no timeout.

=item * A bare carriage return is removed

The local form has no CR at all, as specified, so a lone CR inside a line is
deleted instead of becoming a line break, and the two halves of the line join.

=item * Addresses are RFC 822

L<Mail::Address> is a lenient RFC 822 parser.  Internationalised addresses and
domain names are not understood, and a From: domain that is not plain ASCII is
treated as having none.

=item * The messages are English, with English plurals

The catalogue is English.  C<count> knows C<zero>, C<one> and C<other>, which is
not enough for languages with more plural forms; a translation that needs them
would be better served by L<Locale::Maketext>, which this module does not use
to avoid a language class for six sentences.  The text of an operating system
error follows the locale of the process that raised it, which this module does
not control.

=item * log_send reads sendmail's options approximately

B<log_send> knows which of sendmail's options take a value, but not every
MTA's.  An option it has not heard of that takes a value would have that value
logged as a recipient.

=item * rsa-sha256 only

There is one signature, C<rsa-sha256> with C<relaxed> canonicalization.  Ed25519
and a second signature are not offered.

=item * Windows

L</PLATFORMS> applies.

=item * Private means private, except under a test harness

The helpers whose names begin with an underscore are enforced private
(L<Sub::Private>) and the message writer is protected (L<Sub::Protected>), at
the cost of a check on every call.  A subclass cannot replace a private helper.

Both modules skip their checks whenever the environment variable
C<HARNESS_ACTIVE> is set, which is how white-box tests reach the helpers.  A
program that runs with that variable set, by accident or from inside a test
harness, loses the protection without a word.  The helpers do nothing harmful
when called, so the guarantee is then only a convention.

=back

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

=item * L<Test Dashboard|https://nigelhorne.github.io/Mail-Send-DKIM/coverage/>

=back

L<Mail::DKIM::Signer>, which does the signing underneath, and L</PROGRAMS>
above for the programs this distribution installs beside the module.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 FORMAL SPECIFICATION

These are mathematical descriptions, in the Z notation, of what each routine
does.  You do not need them to use the module.  Each one is explained in plain
words first.  A name followed by C<?> is an input and a name followed by C<!>
is an output.  The few symbols used mean this:

	Ξ  the object is not changed        ⊥  no value (undef)
	⇸  a partial map (some keys only)   ⇒  "if this, then that"
	∈  is a member of                   ⁀  joined to (concatenation)
	ℕ  a whole number, 0 or more        𝔹  true or false

=head2 new

The new object holds the set of domains (in lower case), the key directory,
the optional selector and key file, the sendmail program and the messages.
Each comes from the option, else the environment, else a default.

	┌─ New ───────────────────────────────────────────────
	│ opts? : STRING ⇸ VALUE
	│ self! : Signer
	├─────────────────────────────────────────────────────
	│ self!.domains  = { lower(d) | d ∈ split(opts?.domains ∨ DKIM_DOMAINS) ∧ d ≠ "" }
	│ self!.signing_domain = lower(opts?.signing_domain ∨ DKIM_SIGNING_DOMAIN), or absent
	│ self!.keydir   = opts?.keydir ∨ DKIM_KEYDIR ∨ home ⁀ "/dkim"
	│ self!.sendmail = opts?.sendmail ∨ SENDMAIL ∨ "/usr/sbin/sendmail"
	│ self!.selector, self!.keyfile follow the same rule, and may be absent
	└─────────────────────────────────────────────────────

=head2 sign

The result is the signed message when the From: domain is one of ours and a
key can be used.  In every other case the result is undefined, and nothing
else changes.

	┌─ Sign ──────────────────────────────────────────────
	│ ΞSigner
	│ message? : STRING
	│ signed!  : STRING ∪ {⊥}
	├─────────────────────────────────────────────────────
	│ d = fromDomain(message?)
	│ d ∈ domains ∧ keyUsable(d) ∧ signerSucceeds(d) ⇒
	│     signed! = signature(d, crlf(message?)) ⁀ "\n" ⁀ local(message?)
	│ ¬(d ∈ domains ∧ keyUsable(d) ∧ signerSucceeds(d)) ⇒ signed! = ⊥
	└─────────────────────────────────────────────────────

=head2 send

The result is 1 if sendmail cannot be run, 0 if sendmail accepts the message,
and otherwise sendmail's own exit status (1 if that status would be 0).

	┌─ Send ──────────────────────────────────────────────
	│ ΞSigner
	│ message? : STRING;  args? : seq STRING;  status! : ℕ
	├─────────────────────────────────────────────────────
	│ ¬runnable(sendmail)                      ⇒ status! = 1
	│ runnable(sendmail) ∧ accepted(local(message?)) ⇒ status! = 0
	│ runnable(sendmail) ∧ ¬accepted(local(message?)) ⇒
	│     status! = exitStatus(sendmail) ∨ 1  (1 when that status would be 0)
	└─────────────────────────────────────────────────────

=head2 log_send

One line is written to the system log.  The result is true if that worked and false if it did not.

	┌─ LogSend ───────────────────────────────────────────
	│ message? : STRING;  args? : seq STRING;  written! : 𝔹
	├─────────────────────────────────────────────────────
	│ sender     = valueOf(-f, args?) ∨ firstAddress(From)
	│ recipients = nonOptions(args?) ⁀ (headerAddresses(To, Cc, Bcc) ◁ "-t" ∈ flags(args?))
	│ line = "sender=" ⁀ (sender ∨ "-") ⁀ " recipient=" ⁀ (join "," recipients ∨ "-")
	│        ⁀ " subject=" ⁀ (subject ∨ "-")        (control characters made spaces)
	│ written! = line reached syslog
	└─────────────────────────────────────────────────────

=head2 from_domain

The result is the lower-case host of the first address of the first From:
header, if it is a plain host name.  Otherwise it is undefined.

	┌─ FromDomain ────────────────────────────────────────
	│ message? : STRING;  domain! : STRING ∪ {⊥}
	├─────────────────────────────────────────────────────
	│ first(From, headers(message?)) = ⊥ ⇒ domain! = ⊥
	│ a = firstAddress(first(From, headers(message?)))
	│ host(a) matches [A-Za-z0-9.-]+ ⇒ domain! = lower(host(a))
	│ otherwise domain! = ⊥
	└─────────────────────────────────────────────────────

=head2 selector

The result is the selector, chosen in this order: the one given, the name of
the key file, the name of the only key in the key directory.  Otherwise it is
undefined.

	┌─ Selector ──────────────────────────────────────────
	│ ΞSigner;  selector! : STRING ∪ {⊥}
	├─────────────────────────────────────────────────────
	│ selector ≠ ⊥ ∧ selector ≠ ""    ⇒ selector! = selector
	│ keyfile ≠ ⊥ ∧ name(keyfile) ≠ "" ⇒ selector! = strip(name(keyfile))
	│ #privateKeys(keydir) = 1         ⇒ selector! = strip(the one)
	│ otherwise                          selector! = ⊥
	└─────────────────────────────────────────────────────

=head2 i18n

The result is the text of the message, with the arguments put in.  The message must exist.

	┌─ I18n ──────────────────────────────────────────────
	│ ΞSigner;  key? : STRING;  args? : STRING ⇸ VALUE;  text! : STRING
	├─────────────────────────────────────────────────────
	│ key? ∈ dom messages
	│ text! = format(choose(messages(key?), args?.count, args?.variant), args?)
	└─────────────────────────────────────────────────────

=head1 STATE DIAGRAM

The object itself has one state.  B<new> builds it, and nothing afterwards
changes it: B<sign>, B<send>, B<log_send>, B<selector> and B<i18n> only read it.
What changes is the state of B<a message> as it passes through the calls.  This
is the diagram of that journey.

	                      +-----------+
	  message arrives --> |  RECEIVED |
	                      +-----------+
	                            |
	                         sign()
	          +-----------------+------------------+
	          |                 |                  |
	  domain not ours      no usable key      key works
	  or no From:          or signer fails         |
	          |                 |                  v
	          |                 |            +-----------+
	          |                 |            |  SIGNED   |
	          |                 |            +-----------+
	          v                 v                  |
	      +----------------------+                 |
	      |       UNSIGNED       |                 |
	      +----------------------+                 |
	                 |                             |
	                 +-------------+---------------+
	                               |
	                            send()
	          +--------------------+---------------------+
	          |                    |                     |
	  cannot run sendmail   sendmail exits non-0   sendmail exits 0
	          |                    |                     |
	          v                    v                     v
	   +-------------+      +-------------+       +-------------+
	   | UNSENDABLE  |      |   REFUSED   |       |  ACCEPTED   |
	   |  (status 1) |      | (status n)  |       |  (status 0) |
	   +-------------+      +-------------+       +-------------+
	                                                     |
	                                                 log_send()
	                                          +----------+----------+
	                                          |                     |
	                                    syslog works          syslog fails
	                                          |                     |
	                                          v                     v
	                                    +-----------+         +-----------+
	                                    |  LOGGED   |         | NOT LOGGED|
	                                    +-----------+         +-----------+

Each change, what causes it and what happens:

	From        Trigger and condition               To          Action or side effect
	RECEIVED    sign(); From: domain not in the     UNSIGNED    Returns undef.  No warning.
	            domains, or there is no From:
	RECEIVED    sign(); no key, key not readable,   UNSIGNED    Returns undef.  One warning on
	            several keys and no selector, or                standard error (key_unreadable,
	            the signer fails                                keydir_unreadable, keys_ambiguous
	                                                            or sign_failed).
	RECEIVED    sign(); the key works               SIGNED      Returns the message with a
	                                                            DKIM-Signature header first, in
	                                                            the local (LF) form.
	SIGNED or   send(); sendmail cannot be run      UNSENDABLE  Returns 1.  One warning
	UNSIGNED                                                    (sendmail_failed).
	SIGNED or   send(); sendmail exits non-zero     REFUSED     Returns sendmail's status (1 if
	UNSIGNED    (it may stop reading early)                     that would be 0).  No signal.
	SIGNED or   send(); sendmail exits 0            ACCEPTED    Returns 0.  The message, in the
	UNSIGNED                                                    local form, was written to
	                                                            sendmail.
	ACCEPTED    log_send(); syslog works            LOGGED      Returns 1.  One line in syslog
	                                                            (identity mail-dkim, facility
	                                                            mail).
	ACCEPTED    log_send(); syslog fails            NOT LOGGED  Returns 0.  One warning
	                                                            (syslog_failed).

An UNSIGNED message is still sent: signing must never stop mail being
delivered.  UNSENDABLE, REFUSED, LOGGED and NOT LOGGED are the end of the
journey.  The calls B<from_domain>, B<selector> and B<i18n> are questions that
do not move the message anywhere.

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
