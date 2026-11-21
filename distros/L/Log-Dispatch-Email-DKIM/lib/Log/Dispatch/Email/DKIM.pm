package Log::Dispatch::Email::DKIM;

use strict;
use warnings;
use autodie qw(:all);

use base 'Log::Dispatch::Email';

use Carp qw(carp croak);
use Email::Address::XS;
use File::Basename qw(basename);
use File::HomeDir;
use File::Spec;
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Scalar::Util qw(looks_like_number);

# Private helpers are really private (a call from outside this package croaks,
# which also works for $self->_helper() dispatch); the one protected method,
# i18n(), may be called by a subclass that wants to reword the messages.
use Sub::Private { 'mode' => 'enforce' };
use Sub::Protected;

=encoding utf8

=head1 NAME

Log::Dispatch::Email::DKIM - Log::Dispatch appender that DKIM-signs its mail

=head1 VERSION

Version 0.001.0

=cut

use version; our $VERSION = version->declare('0.001.0');

# Everything that was once a literal in the code lives here, so that it is
# named once and can be changed (or, for the messages, translated) in one place.
Readonly my $DEFAULT_SENDMAIL => '/usr/sbin/sendmail';
Readonly my $KEY_FILE_SUFFIX => '.private';
Readonly my $KEY_DIR_NAME => 'dkim';
Readonly my $KEY_FILE_RE => qr/\A(.+)\Q$KEY_FILE_SUFFIX\E\z/;
Readonly my $LINE_BREAKS_RE => qr/[\r\n]+/;

# The environment variable that overrides each setting
Readonly my %ENV_VAR => (
	'domain' => 'DKIM_DOMAIN',
	'selector' => 'DKIM_SELECTOR',
	'keyfile' => 'DKIM_KEYFILE',
	'keydir' => 'DKIM_KEYDIR',
	'sendmail' => 'DKIM_SENDMAIL',
);

# Input schema for send_email().  Log::Dispatch hands over more than the
# message (level, name and so on) when the appender is unbuffered, so unknown
# parameters are ignored rather than rejected.
Readonly my $SEND_EMAIL_SCHEMA => {
	'message' => { 'type' => 'string', 'min' => 0 },
};

# The message catalogue.  An entry is [ $sprintf_format, @names_of_arguments ],
# or a hash of such entries for the variants of a message: 'one' and 'other'
# are chosen by the 'count' argument, and any other key by the 'gender'
# argument (see i18n()).  It is a package variable, not a Readonly, so that a
# site can translate it with local() or by assigning to a key.
our %MESSAGES = (
	'no_recipient' => ['To whom should I be sending this e-mail?'],
	'no_sender' => ['DKIM: no valid From address to send as; message not sent'],
	'no_key' => ['DKIM: no DKIM key for %s; sending unsigned', 'domain'],
	'unknown_domain' => ['unknown domain'],
	'send_failed' => ['DKIM: sendmail failed for %s', 'sender'],
	'unknown_setting' => ['DKIM: unknown setting %s', 'setting'],
	'no_message' => ['message is required'],
	'bad_arguments' => ['DKIM: invalid arguments to %s: %s', 'routine', 'reason'],
);

=head1 SYNOPSIS

Pattern 1: from a log4perl configuration file.

    log4perl.appender.A2=Log::Dispatch::Email::DKIM
    log4perl.appender.A2.from=webmaster@example.com
    log4perl.appender.A2.to=admin@example.com
    log4perl.appender.A2.subject=Error in shop/index.fcgi

Pattern 2: directly from Log::Dispatch, sending each message at once.

    use Log::Dispatch;

    my $log = Log::Dispatch->new(
        outputs => [ [
            'Email::DKIM',
            'min_level' => 'error',
            'from' => 'webmaster@example.com',
            'to' => ['admin@example.com'],
            'subject' => 'Error in shop/index.fcgi',
            'buffered' => 0,
        ] ],
    );
    $log->error("Something went wrong\n");

Pattern 3: choose the key and the selector with environment variables (for
example in the web server settings).

    SetEnv DKIM_KEYFILE /home/site/dkim/202611.private
    SetEnv DKIM_SELECTOR 202611

Pattern 4: in a test, send to a script that saves the message instead of
to sendmail.

    local $ENV{'DKIM_SENDMAIL'} = '/tmp/capture-script';
    $log->error("Test message\n");

=head1 DESCRIPTION

Sends a log message the way L<Log::Dispatch::Email::Sendmail> does, but signs
it with L<Mail::Send::DKIM> first, so the message carries a C<DKIM-Signature>
for the domain it claims to come from.  An unsigned C<webmaster@> message and
a forgery are indistinguishable in a DMARC report; signing is what tells them
apart, and what lets the copy a mailing list forwards still authenticate.

The signing key is found rather than configured.  C<Log::Dispatch> validates
each appender's arguments and passes on only C<name>, C<min_level>,
C<max_level>, C<callbacks> and C<newline>, so a C<keyfile=> line in the
log4perl configuration never reaches this object.  Instead the domain is taken
from the C<from> address and the selector from the key's file name.

=head1 CONFIGURATION

The defaults suit this host: the key in C<~/dkim/*.private> with the highest
name is used, and its name is the selector.  Each can be overridden in the
environment, which is also how a test points it at a capture script.  An
empty variable counts as unset.

=over 4

=item C<DKIM_DOMAIN> - the domain put in the signature (its C<d=> tag), instead of the one in C<from>

=item C<DKIM_SELECTOR> - the DKIM selector, instead of the key's file name

=item C<DKIM_KEYFILE> - the private key to sign with

=item C<DKIM_KEYDIR> - where to look for C<*.private> (default C<~/dkim>)

=item C<DKIM_SENDMAIL> - the sendmail to hand the message to (then C<SENDMAIL>)

=back

C<DKIM_DOMAIN> changes only the domain in the signature.  Whether a message is
signed at all is still decided by the domain in C<from>, so a message from an
address this host has no key for is sent unsigned whatever C<DKIM_DOMAIN> says.
C<DKIM_SENDMAIL> wins over C<SENDMAIL>, the variable L<Mail::Send::DKIM> and
its C<mail-dkim> programme read, so a host that sets only C<SENDMAIL> gets the
same sendmail from both.  With neither set, F</usr/sbin/sendmail> is used.

The home directory comes from L<File::HomeDir>, so it is found even when the
process (a CGI script, say) has no C<HOME> in its environment.

=head1 COMMON PITFALLS

=over 4

=item *

B<Buffering is on by default.>  Log::Dispatch::Email collects messages and
sends ONE e-mail when the program ends (or when C<flush> is called).  Set
C<< buffered => 0 >> to send one e-mail for each message.

=item *

B<You cannot give the appender a key file in its settings.>  Log::Dispatch
throws away settings it does not know.  Use the environment variables in
L</CONFIGURATION> instead.

=item *

B<An empty environment variable means "not set".>  C<DKIM_DOMAIN=""> does
not turn anything off.

=item *

B<The signing domain comes from C<from>.>  If C<from> is
C<webmaster@example.com> the message is signed for C<example.com>.  Your DKIM
key must belong to that domain, or the receiver will not accept the signature.

=item *

B<The highest file name wins, not the newest file.>  Of C<202611.private> and
C<202701.private>, the second is used.  If you keep an old key with a larger
name, it will be used.

=item *

B<A missing key is not an error.>  The e-mail is still sent, without a
signature, and you only get a warning.  Watch for the warning.

=item *

B<C<undef> is not a message.>  C<send_email(message =E<gt> undef)> stops with
an error.  An empty string is accepted.

=item *

B<A missing C<to> or an unusable C<from> loses the message.>  Nothing is sent
and one line is written to STDERR.  It is not a warning, so a warning handler
will not see it.

=item *

B<Private routines cannot be called from outside.>  Names that start with an
underscore croak if you call them.  Under C<prove> the check is switched off
(C<HARNESS_ACTIVE>), so a test can pass where real code would fail.

=item *

B<The message catalogue is shared by the whole program.>  Changing
C<%Log::Dispatch::Email::DKIM::MESSAGES> changes the words for every
appender.  Use C<local> to limit the change.

=back

=head1 ENCODING

This module does not convert text.  It passes the bytes it is given to
sendmail and it adds no C<Content-Type> or C<charset> header.

=over 4

=item B<Message body>

Give it UTF-8 B<bytes> (text that is already encoded, for example with
C<Encode::encode('UTF-8', $text)>).  Non-ASCII letters and emojis then reach
sendmail unchanged.  Because no charset is declared, a mail program may show
them wrongly.

If you give it a Perl character string that holds a character above code
point 255 (an emoji, for example), Perl warns C<Wide character in print> and
sends UTF-8.  If all the characters are below 256 (an accented letter, for
example), they are sent as single Latin-1 bytes.  Do not mix the two kinds.

=item B<Subject>

The same rule applies.  The subject is NOT converted to the C<=?UTF-8?...?=>
form that older mail systems need.  Use ASCII for a safe subject.  A non-ASCII
subject is sent as raw UTF-8, which only works with receivers that accept it.

=item B<From and To addresses>

Use ASCII.  A display name such as C<"Web Master"> is allowed, but it is not
encoded either.

=item B<Environment variables and file names>

These are byte strings from the operating system.  Use ASCII for the selector
and domain.  A key directory with non-ASCII letters in its name works, because
it is read as bytes.

=item B<Line breaks>

In C<to>, C<from> and C<subject>, any line break is replaced by one space.  In
the body, every line break is changed to a carriage return and line feed,
which DKIM needs.

=back

=head1 METHODS

=head2 send_email

=head3 Purpose

Builds the message, signs it and hands it to sendmail(1).  Log::Dispatch
calls this itself, once per message when unbuffered and once per flush when
buffered, so applications do not normally call it.

=head3 Args

A hash or hash reference with C<message>, the text of the message body.  Any
other key (C<level>, C<name>, ...) is ignored.

=head3 Returns

C<$self>, so calls can be chained.  The outcome of the delivery is reported
by warning, not by the return value, because Log::Dispatch ignores it.

=head3 Side Effects

Runs sendmail(1).  While it runs, STDERR is pointed at the null device
because some sendmail implementations write a warning there that would corrupt
CGI output.

A missing or unreadable key is not an error: it warns and sends the message
unsigned, which is what L<Mail::Send::DKIM> does for a signing problem of any
kind.  A line break in the subject, From or To is replaced by a space, so a
logged value cannot add a header of its own.

When there is no recipient, or the C<from> address cannot be parsed, nothing
is sent and the problem is written straight to STDERR, not warned: a warning
could be routed back into this appender and loop.  C<from> may carry a
display name (C<"Web Master" E<lt>webmaster@example.comE<gt>>); the bare
address is used as the sendmail envelope sender and as the signing domain.

=head3 Usage

    $appender->send_email(message => "Something went wrong\n");

=head3 EXAMPLE

    use Log::Dispatch;

    my $log = Log::Dispatch->new(
        outputs => [ [
            'Email::DKIM',
            'min_level' => 'error',
            'from' => 'webmaster@example.com',
            'to' => ['admin@example.com'],
            'subject' => 'Error in shop/index.fcgi',
        ] ],
    );

    # Sent, signed with the highest ~/dkim/*.private, when $log goes away
    $log->error("Something went wrong\n");

    # Test a different key and a capture script instead of sendmail
    local $ENV{'DKIM_KEYFILE'} = '/tmp/keys/202611.private';
    local $ENV{'DKIM_SENDMAIL'} = '/tmp/capture';

=head3 API SPECIFICATION

=head4 INPUT

    {
        message => { type => 'string', min => 0 },
    }

Unknown keys are ignored.

=head4 OUTPUT

    { type => 'object', isa => 'Log::Dispatch::Email::DKIM' }

=head3 MESSAGES

=over 4

=item C<DKIM: no DKIM key for DOMAIN; sending unsigned> (warning)

No readable key, domain or selector could be found.  The message is sent
without a signature.  Put a C<SELECTOR.private> key in C<~/dkim>, or set
C<DKIM_KEYFILE> or C<DKIM_KEYDIR>.

=item C<DKIM: sendmail failed for SENDER> (warning)

sendmail(1) could not be run or exited with a failure (a non-zero exit
status).  Check C<DKIM_SENDMAIL> and the mail queue.  When sendmail could not
be started at all, L<Mail::Send::DKIM> also warns C<cannot run PROGRAM: REASON>,
where REASON is the operating system's own error text, in the current locale.

=item C<To whom should I be sending this e-mail?> (STDERR)

The appender has no recipient, so nothing was sent.  Give it a C<to>.

=item C<DKIM: no valid From address to send as; message not sent> (STDERR)

C<from> is missing or is not an address.  Give it a C<from> such as
C<webmaster@example.com>.

=item C<DKIM: invalid arguments to send_email: REASON> (fatal)

The arguments were not a message.  Pass C<< message => $text >>; REASON is the validator's complaint, or
C<message is required>.

=back

=head3 PSEUDOCODE

    validate the arguments (croak if there is no message)
    parse From into an address (undef if it is not one)
    if there is no recipient or no address
        write the reason to STDERR and stop
    find domain, selector and keyfile (environment, then From, then ~/dkim)
    warn if any is missing or the keyfile is unreadable
    build the message with a sanitised To, From and Subject
    run sendmail with STDERR on the null device
    warn if it failed
    return self

=cut

sub send_email
{
	my $self = shift;

	my $args = $self->_validated_arguments('send_email', \@_);
	my $sender = $self->_parse_address($self->{'from'});

	# Neither case can be reported with carp: it could come back here.  An
	# empty list is as good as no recipient: sendmail -t would be given "To: ".
	my $recipients = $self->{'to'};
	if(ref($recipients) ne 'ARRAY' || !@{$recipients}) {
		$self->_say_to_stderr('no_recipient');
	} elsif(!$sender) {
		$self->_say_to_stderr('no_sender');
	} else {
		$self->_deliver($sender, $args->{'message'});
	}

	return $self;
}

=head2 i18n

=head3 Purpose

Turns a message key into text for the user, so that every warning and error
this class raises can be translated or reworded by a subclass or by assigning
to C<%Log::Dispatch::Email::DKIM::MESSAGES>.  Protected: callable from
this class and its subclasses only.

=head3 Args

The message key, then an optional hash reference of arguments.  C<count>
selects the C<one> or C<other> variant of a message, and C<gender> selects the
variant of that name, with C<other> as the fallback.

=head3 Returns

The message text.  An unknown key returns the key itself, so a missing
translation is visible rather than fatal.

=head3 Side Effects

None.

=head3 Usage

    my $text = $self->i18n('no_key', { 'domain' => 'example.com' });

=head3 EXAMPLE

    # A catalogue entry is [ $sprintf_format, @argument_names ], or a hash
    # of variants of one
    local $Log::Dispatch::Email::DKIM::MESSAGES{'files'} = {
        'one' => ['%s file', 'count'],
        'other' => ['%s files', 'count'],
    };
    $self->i18n('files', { 'count' => 2 });	# "2 files"

=head3 API SPECIFICATION

=head4 INPUT

    {
        key => { type => 'string', min => 1 },
        args => { type => 'hashref', optional => 1 },
    }

=head4 OUTPUT

    { type => 'string' }

=head3 MESSAGES

None of its own.  An unknown key is returned as the text.

=head3 PSEUDOCODE

    look the key up; if absent, return the key
    if the entry is a hash of variants, choose one by gender, then count
    format the entry with its named arguments

=cut

sub i18n :Protected
{
	my ($self, $key, $args) = @_;

	$args ||= {};
	my $entry = defined($MESSAGES{$key}) ? $self->_choose_variant($MESSAGES{$key}, $args) : undef;

	# No such key, or a message with no usable variant: show the key, so the
	# gap is visible rather than fatal
	return defined($entry) ? sprintf($entry->[0], map { $args->{$_} // q{} } @{$entry}[1 .. $#{$entry}]) : $key;
}

# Purpose: pick the wording for a message that has variants.
# Entry: $entry is an array reference (returned as it is) or a hash reference
#	of variants; $args is a hash reference.
# Exit: an array reference [ $format, @names ], or undef if a hash of variants
#	has none that applies.  The variant named by $args->{gender} wins, then
#	'one' when $args->{count} is the number 1, then 'other'.  A count that is
#	not a number is not 1.
# Side effects: none.
sub _choose_variant :Private
{
	my ($self, $entry, $args) = @_;

	if(ref($entry) eq 'HASH') {
		my $count = $args->{'count'};
		my $is_one = defined($count) && looks_like_number($count) && $count == 1;
		my @wanted = grep { defined } ($args->{'gender'}, $is_one ? 'one' : undef, 'other');
		my ($found) = grep { exists $entry->{$_} } @wanted;
		$entry = defined($found) ? $entry->{$found} : undef;
	}

	return $entry;
}

# Purpose: raise a warning in the user's words.
# Entry: $key and $args as for i18n().
# Exit: $self, for chaining.
# Side effects: a carp(), reported from the caller's point of view.
sub _warn_user :Private
{
	my ($self, $key, $args) = @_;

	carp($self->i18n($key, $args));

	return $self;
}

# Purpose: report a problem that must not go through the warn() machinery.
# Entry: $key and $args as for i18n().
# Exit: $self, for chaining.
# Side effects: a line on STDERR.  Not a warning, because a warn handler may
#	log it, which would send it back through this appender.
sub _say_to_stderr :Private
{
	my ($self, $key, $args) = @_;

	print STDERR $self->i18n($key, $args), "\n";

	return $self;
}

# Purpose: normalise and check the arguments of a public routine.
# Entry: $routine is its name (for the message); $arguments is an array
#	reference to its @_, in any form Params::Get understands.
# Exit: a hash reference of the validated arguments.  Croaks, in the user's
#	words, if they do not match $SEND_EMAIL_SCHEMA.
# Side effects: none.
sub _validated_arguments :Private
{
	my ($self, $routine, $arguments) = @_;

	my $validated = eval {
		validate_strict(
			'schema' => $SEND_EMAIL_SCHEMA,
			'input' => get_params(undef, $arguments),
			'unknown_parameter_handler' => 'ignore',
		);
	};

	# validate_strict() lets an undef through a required parameter, by design,
	# so a missing message is checked for as well
	my $reason = $@ || (defined($validated->{'message'}) ? q{} : $self->i18n('no_message'));
	if(length($reason)) {
		# The reason ends in a newline when it came from a die(); drop it so the
		# message stays on one line, with croak's own location after it
		chomp($reason);
		croak($self->i18n('bad_arguments', { 'routine' => $routine, 'reason' => $reason }));
	}

	return $validated;
}

# Purpose: read an address into its parts.
# Entry: $text is a From-style address, with or without a display name.
# Exit: an Email::Address::XS object, or undef if $text holds no valid
#	address.  Email::Address::XS, not a regex, because a display name may
#	itself contain an '@'.
# Side effects: none.
sub _parse_address :Private
{
	my ($self, $text) = @_;

	# Warnings are silenced here (Email::Address::XS carps about junk), for the
	# same reason _say_to_stderr() avoids warn(): one could loop back to us
	local $SIG{'__WARN__'} = sub { };
	my ($address) = (defined($text) && length($text)) ? Email::Address::XS->parse($text) : ();

	return ($address && $address->is_valid()) ? $address : undef;
}

# Purpose: make a value safe to use as the text of one header line.
# Entry: $value is a string.
# Exit: the string with each run of line breaks replaced by one space, so it
#	cannot end its own header and begin another (header injection).
# Side effects: none.
sub _one_line :Private
{
	my ($self, $value) = @_;

	$value =~ s/$LINE_BREAKS_RE/ /g;

	return $value;
}

# Purpose: read an override from the environment.
# Entry: $setting is a key of %ENV_VAR; anything else croaks.
# Exit: the variable's value, or undef if it is unset or empty.
# Side effects: none.
sub _from_environment :Private
{
	my ($self, $setting) = @_;

	# A misspelt setting is a bug in this module; do not read $ENV{undef}
	croak($self->i18n('unknown_setting', { 'setting' => $setting })) unless(exists($ENV_VAR{$setting}));

	my $value = $ENV{$ENV_VAR{$setting}};

	return (defined($value) && length($value)) ? $value : undef;
}

# Purpose: the sendmail named by the SENDMAIL variable that Mail::Send::DKIM
#	also reads.
# Exit: its value, or undef if it is unset or empty.
# Side effects: none.
sub _plain_sendmail :Private
{
	my $value = $ENV{'SENDMAIL'};

	return (defined($value) && length($value)) ? $value : undef;
}

# Purpose: find the private key to sign with.
# Entry: none; consults DKIM_KEYFILE, DKIM_KEYDIR and the home
#	directory.
# Exit: the path of DKIM_KEYFILE, or else of the highest-named
#	*.private in the key directory, or undef if there is none.
# Side effects: reads a directory.  A directory listing is used instead of
#	glob() because glob() splits on spaces and expands '[' and '*'.
sub _find_key_file :Private
{
	my $self = shift;

	my $keyfile = $self->_from_environment('keyfile');
	return $keyfile if(defined($keyfile));

	my $dir = $self->_from_environment('keydir');
	if(!defined($dir)) {
		my $home = File::HomeDir->my_home();
		$dir = File::Spec->catdir($home, $KEY_DIR_NAME) if(defined($home));
	}

	if(defined($dir) && -d $dir) {
		# Only regular files count (a directory called x.private is no key).  A
		# directory that cannot be read, or that vanishes now, means "no key",
		# which sends the mail unsigned, not an exception from the logger.
		my @names = eval {
			opendir(my $handle, $dir);
			my @found = sort grep { /\Q$KEY_FILE_SUFFIX\E\z/ && -f File::Spec->catfile($dir, $_) } readdir($handle);
			closedir($handle);
			@found;
		};
		$keyfile = File::Spec->catfile($dir, $names[-1]) if(@names);
	}

	return $keyfile;
}

# Purpose: work out how to sign this message.
# Entry: $sender is the Email::Address::XS of the From address.
# Exit: a hash reference { domain, selector, keyfile }; any may be undef.
#	The domain is the one From: claims, because a signature for any other
#	domain would not align with the message; the selector is the key's file
#	name.  The environment overrides each.
# Side effects: reads a directory (see _find_key_file).
sub _signing_key :Private
{
	my ($self, $sender) = @_;

	my $keyfile = $self->_find_key_file();
	my $selector = $self->_from_environment('selector');

	if(!defined($selector) && defined($keyfile) && basename($keyfile) =~ $KEY_FILE_RE) {
		$selector = $1;
	}

	return {
		'domain' => $self->_from_environment('domain') // $sender->host(),
		'selector' => $selector,
		'keyfile' => $keyfile,
	};
}

# Purpose: run a piece of code with STDERR discarded.
# Entry: $code is a code reference.
# Exit: whatever $code returns (in scalar context).
# Side effects: some sendmail implementations write a warning to STDERR that
#	breaks CGI output, so STDERR is the null device while $code runs and is
#	restored after, as Log::Dispatch::Email::Sendmail does.  If the null
#	device cannot be opened $code runs anyway: a noisy message beats a lost one.
sub _without_stderr :Private
{
	my ($self, $code) = @_;

	my $result;
	{
		local *STDERR;
		eval { open(STDERR, '>', File::Spec->devnull()); 1 };
		$result = $code->();
	}

	return $result;
}

# Purpose: sign and send one message.
# Entry: $sender is an Email::Address::XS; $message is the body text;
#	$self->{to} is a non-empty array reference.
# Exit: $self, for chaining.
# Side effects: runs sendmail(1); warns if the message is unsigned or the
#	send failed.
sub _deliver :Private
{
	my ($self, $sender, $message) = @_;

	my $key = $self->_signing_key($sender);

	# Unsigned mail is still sent, but whoever reads the log should hear of it
	my $signed = (defined($key->{'domain'}) && defined($key->{'selector'}) && defined($key->{'keyfile'}) && -r $key->{'keyfile'});
	if(!$signed) {
		$self->_warn_user('no_key', { 'domain' => $key->{'domain'} // $self->i18n('unknown_domain') });
	}

	require Mail::Send::DKIM;

	my $dkim = Mail::Send::DKIM->new(
		# Which messages to sign is decided by the From: domain; the signature
		# is for the signing domain, which DKIM_DOMAIN may change
		'domains' => [ $sender->host() ],
		'signing_domain' => $key->{'domain'},
		'selector' => $key->{'selector'},
		'keyfile' => $key->{'keyfile'},
		'sendmail' => $self->_from_environment('sendmail') // _plain_sendmail() // $DEFAULT_SENDMAIL,
	);

	my $text = join("\n",
		'To: ' . $self->_one_line(join(',', @{$self->{'to'}})),
		'From: ' . $self->_one_line($self->{'from'}),
		'Subject: ' . $self->_one_line($self->{'subject'}),
	) . "\n\n" . $message;

	# sign() returns undef when it cannot sign, and the message goes unsigned
	if($signed) {
		my $signed_text = $dkim->sign($text);
		$text = $signed_text if(defined($signed_text));
	}

	# The envelope sender is the bare address: a display name would be
	# refused as an invalid sendmail -f argument
	my $status = $self->_without_stderr(sub { $dkim->send($text, '-t', '-f', $sender->address()) });
	$self->_warn_user('send_failed', { 'sender' => $sender->address() }) if($status);

	return $self;
}

=head1 EXAMPLES

A complete log4perl configuration file, which logs everything to a file and
emails anything of level C<WARN> or above.  Save it as, say,
F<myapp.l4pconf> and load it with C<Log::Log4perl-E<gt>init('myapp.l4pconf')>.

    log4perl.logger.myapp=TRACE, A1, A2

    log4perl.appender.A1=Log::Dispatch::File
    log4perl.appender.A1.Filter=RangeAll
    log4perl.appender.A1.filename=/tmp/myapp.log
    log4perl.appender.A1.mode=append
    log4perl.appender.A1.layout=Log::Log4perl::Layout::PatternLayout
    log4perl.appender.A1.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n

    log4perl.appender.A2=Log::Dispatch::Email::DKIM
    log4perl.appender.A2.Filter=RangeError
    log4perl.appender.A2.from=webmaster@example.com
    log4perl.appender.A2.to=admin@example.com
    log4perl.appender.A2.subject=Error in myapp
    log4perl.appender.A2.layout=Log::Log4perl::Layout::PatternLayout
    log4perl.appender.A2.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n

    log4perl.filter.RangeAll=Log::Log4perl::Filter::LevelRange
    log4perl.filter.RangeAll.LevelMin=TRACE
    log4perl.filter.RangeAll.LevelMax=FATAL
    log4perl.filter.RangeAll.AcceptOnMatch=true

    log4perl.filter.RangeError=Log::Log4perl::Filter::LevelRange
    log4perl.filter.RangeError.LevelMin=WARN
    log4perl.filter.RangeError.LevelMax=FATAL
    log4perl.filter.RangeError.AcceptOnMatch=true

=head1 LIMITATIONS

=over 4

=item *

The message catalogue is a package variable and C<i18n> is protected, because
C<Log::Dispatch> constructs the appender and does not pass on extra
arguments, so there is no object configuration to carry a locale.
L<Object::Configure> is therefore not used: there is nowhere for it to hook
in.  A site changes the wording by assigning to
C<%Log::Dispatch::Email::DKIM::MESSAGES>, which is global to the process.

=item *

The key is found by convention (C<~/dkim/*.private>, highest name wins) and
the environment, not configured per appender, for the same reason.  Two
appenders in one process cannot sign with different keys.

=item *

The key with the highest I<name> is used, not the newest or the one that
matches the published DNS record.  Leave a retired key in the directory and,
if it sorts last, it is the one that signs.

=item *

The message goes out only once: if sendmail(1) fails the message is lost, not
queued for retry, and the only record is the warning.

=item *

A C<from> with no valid address, or a missing recipient, loses the message.
This used to be a fatal error from the underlying mailer, which a logger should
not raise.

=item *

No MIME headers are added: the body has no declared charset and the subject
is not encoded.  See L</ENCODING>.

=item *

Redirecting STDERR is process-wide for the duration of the send, so output
written by another thread meanwhile is lost.

=item *

The plural and gender support in C<i18n> selects a variant by key; it does
not know the plural rules of any language beyond one against other.  Use
L<Locale::Maketext> if you need more.

=back

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Log-Dispatch-Email-DKIM/coverage/>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 FORMAL SPECIFICATION

The notation is Z.  C<Config> is what an appender holds after C<new>.  A
message is signed only when a readable key, a domain and a selector are all
found.

    [STRING, ADDRESS, PATH]

    ┌─ Config ─────────────────────────────────────────────────
    │ from : STRING
    │ to : seq STRING
    │ subject : STRING
    │ buffered : 𝔹
    │ buffer : seq STRING
    ├──────────────────────────────────────────────────────────
    │ buffered = false ⇒ buffer = ⟨ ⟩
    └──────────────────────────────────────────────────────────

=head2 send_email

    ┌─ SendEmail ──────────────────────────────────────────────
    │ Ξ Config
    │ message? : STRING
    │ sender : ADDRESS ⇸ ADDRESS        (the parse of from)
    │ key : PATH ⇸ PATH                 (the key file, if any)
    │ sent! : 𝔹
    │ signed! : 𝔹
    ├──────────────────────────────────────────────────────────
    │ message? is defined
    │ sent! = (to ≠ ⟨ ⟩ ∧ sender ≠ ∅ ∧ sendmail succeeds)
    │ signed! = (sent! ∧ key ≠ ∅ ∧ readable(key) ∧ domain defined
    │            ∧ selector defined)
    │ sent! ∧ ¬ signed! ⇒ one warning "no DKIM key"
    │ to ≠ ⟨ ⟩ ∧ sender ≠ ∅ ∧ ¬ sent! ⇒ one warning "sendmail failed"
    │ (to = ⟨ ⟩ ∨ sender = ∅) ⇒ one line on STDERR and no warning
    └──────────────────────────────────────────────────────────

=head2 i18n

    ┌─ I18n ───────────────────────────────────────────────────
    │ Ξ Config
    │ catalogue : STRING ⇸ (ENTRY ∪ (STRING ⇸ ENTRY))
    │ key? : STRING
    │ args? : STRING ⇸ STRING
    │ text! : STRING
    ├──────────────────────────────────────────────────────────
    │ key? ∉ dom catalogue ⇒ text! = key?
    │ key? ∈ dom catalogue ⇒
    │     text! = sprintf(format(entry), args?(names(entry)))
    │ a name missing from args? is replaced by the empty string
    └──────────────────────────────────────────────────────────

=head1 STATE DIAGRAM

An appender is always in one of these states:

    EMPTY      no message is waiting
    PENDING    one or more messages wait in the buffer
    SENDING    send_email is running
    GONE       the object has been destroyed

                       new
                        |
                        v
                  +-----------+  log, buffered=1   +-----------+
                  |           |------------------->|           |--+
                  |   EMPTY   |                    |  PENDING  |  | log,
                  |           |                    |           |<-+ buffered=1
                  +-----------+                    +-----------+
                    |   ^   |                           |
        log,        |   |   | destroy                   | flush, or
        buffered=0  |   |   v                           | destroy
                    |   |  +------+                     |
                    |   |  | GONE |                     |
                    v   |  +------+                     |
                  +-----------+                         |
                  |           |<------------------------+
                  |  SENDING  |
                  |           |
                  +-----------+
                    send_email ends: back to EMPTY (the buffer is cleared)

The same changes in a table:

    From     Trigger                  To       Action or side effect
    -------  -----------------------  -------  -----------------------------
    (none)   new                      EMPTY    Checks the settings.  Makes an
                                               empty buffer if buffered = 1.
    EMPTY    log, buffered = 1        PENDING  Adds the text to the buffer.
    PENDING  log, buffered = 1        PENDING  Adds the text to the buffer.
    EMPTY    log, buffered = 0        SENDING  Calls send_email at once.
    PENDING  flush                    SENDING  Joins the buffer into one text
                                               and calls send_email.
    PENDING  object destroyed         SENDING  Same as flush.
    SENDING  send_email ends          EMPTY    The buffer is cleared.  The
                                               result is one of:
                                               - signed and sent: no output
                                               - no key: sent, one warning
                                               - sendmail failed: one warning
                                               - no to, or bad from: nothing
                                                 sent, one line on STDERR
                                               - no message: croaks and the
                                                 buffer is NOT cleared
    EMPTY    object destroyed         GONE     Nothing is sent.
    PENDING  program is ending        GONE     Log::Dispatch::Email warns
             (global destruction)              that messages were not sent.

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1; # End of Log-Dispatch-Email-DKIM
