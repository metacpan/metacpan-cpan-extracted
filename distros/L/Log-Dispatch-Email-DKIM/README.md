## Name

Log::Dispatch::Email::DKIM - Log::Dispatch appender that DKIM-signs its mail

## Version

Version 0.001.0

## Synopsis

Pattern 1: from a log4perl configuration file.

```
log4perl.appender.A2=Log::Dispatch::Email::DKIM
log4perl.appender.A2.from=webmaster@example.com
log4perl.appender.A2.to=admin@example.com
log4perl.appender.A2.subject=Error in shop/index.fcgi
```

Pattern 2: directly from Log::Dispatch, sending each message at once.

```perl
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
```

Pattern 3: choose the key and the selector with environment variables (for
example in the web server settings).

```
SetEnv DKIM_KEYFILE /home/site/dkim/202611.private
SetEnv DKIM_SELECTOR 202611
```

Pattern 4: in a test, send to a script that saves the message instead of
to sendmail.

```
local $ENV{'DKIM_SENDMAIL'} = '/tmp/capture-script';
$log->error("Test message\n");
```

## Description

Sends a log message the way [Log::Dispatch::Email::Sendmail](https://metacpan.org/pod/Log%3A%3ADispatch%3A%3AEmail%3A%3ASendmail) does, but signs
it with [Mail::Send::DKIM](https://metacpan.org/pod/Mail%3A%3ASend%3A%3ADKIM) first, so the message carries a `DKIM-Signature`
for the domain it claims to come from.  An unsigned `webmaster@` message and
a forgery are indistinguishable in a DMARC report; signing is what tells them
apart, and what lets the copy a mailing list forwards still authenticate.

The signing key is found rather than configured.  `Log::Dispatch` validates
each appender's arguments and passes on only `name`, `min_level`,
`max_level`, `callbacks` and `newline`, so a `keyfile=` line in the
log4perl configuration never reaches this object.  Instead the domain is taken
from the `from` address and the selector from the key's file name.

## Configuration

The defaults suit this host: the key in `~/dkim/*.private` with the highest
name is used, and its name is the selector.  Each can be overridden in the
environment, which is also how a test points it at a capture script.  An
empty variable counts as unset.

- `DKIM_DOMAIN` - the domain put in the signature (its `d=` tag), instead of the one in `from`
- `DKIM_SELECTOR` - the DKIM selector, instead of the key's file name
- `DKIM_KEYFILE` - the private key to sign with
- `DKIM_KEYDIR` - where to look for `*.private` (default `~/dkim`)
- `DKIM_SENDMAIL` - the sendmail to hand the message to (then `SENDMAIL`)

`DKIM_DOMAIN` changes only the domain in the signature.  Whether a message is
signed at all is still decided by the domain in `from`, so a message from an
address this host has no key for is sent unsigned whatever `DKIM_DOMAIN` says.
`DKIM_SENDMAIL` wins over `SENDMAIL`, the variable [Mail::Send::DKIM](https://metacpan.org/pod/Mail%3A%3ASend%3A%3ADKIM) and
its `mail-dkim` programme read, so a host that sets only `SENDMAIL` gets the
same sendmail from both.  With neither set, `/usr/sbin/sendmail` is used.

The home directory comes from [File::HomeDir](https://metacpan.org/pod/File%3A%3AHomeDir), so it is found even when the
process (a CGI script, say) has no `HOME` in its environment.

## Common Pitfalls

- **Buffering is on by default.**  Log::Dispatch::Email collects messages and
sends ONE e-mail when the program ends (or when `flush` is called).  Set
`buffered => 0` to send one e-mail for each message.
- **You cannot give the appender a key file in its settings.**  Log::Dispatch
throws away settings it does not know.  Use the environment variables in
["CONFIGURATION"](#configuration) instead.
- **An empty environment variable means "not set".**  `DKIM_DOMAIN=""` does
not turn anything off.
- **The signing domain comes from `from`.**  If `from` is
`webmaster@example.com` the message is signed for `example.com`.  Your DKIM
key must belong to that domain, or the receiver will not accept the signature.
- **The highest file name wins, not the newest file.**  Of `202611.private` and
`202701.private`, the second is used.  If you keep an old key with a larger
name, it will be used.
- **A missing key is not an error.**  The e-mail is still sent, without a
signature, and you only get a warning.  Watch for the warning.
- **`undef` is not a message.**  `send_email(message => undef)` stops with
an error.  An empty string is accepted.
- **A missing `to` or an unusable `from` loses the message.**  Nothing is sent
and one line is written to STDERR.  It is not a warning, so a warning handler
will not see it.
- **Private routines cannot be called from outside.**  Names that start with an
underscore croak if you call them.  Under `prove` the check is switched off
(`HARNESS_ACTIVE`), so a test can pass where real code would fail.
- **The message catalogue is shared by the whole program.**  Changing
`%Log::Dispatch::Email::DKIM::MESSAGES` changes the words for every
appender.  Use `local` to limit the change.

## Encoding

This module does not convert text.  It passes the bytes it is given to
sendmail and it adds no `Content-Type` or `charset` header.

- **Message body**

    Give it UTF-8 **bytes** (text that is already encoded, for example with
    `Encode::encode('UTF-8', $text)`).  Non-ASCII letters and emojis then reach
    sendmail unchanged.  Because no charset is declared, a mail program may show
    them wrongly.

    If you give it a Perl character string that holds a character above code
    point 255 (an emoji, for example), Perl warns `Wide character in print` and
    sends UTF-8.  If all the characters are below 256 (an accented letter, for
    example), they are sent as single Latin-1 bytes.  Do not mix the two kinds.

- **Subject**

    The same rule applies.  The subject is NOT converted to the `=?UTF-8?...?=`
    form that older mail systems need.  Use ASCII for a safe subject.  A non-ASCII
    subject is sent as raw UTF-8, which only works with receivers that accept it.

- **From and To addresses**

    Use ASCII.  A display name such as `"Web Master"` is allowed, but it is not
    encoded either.

- **Environment variables and file names**

    These are byte strings from the operating system.  Use ASCII for the selector
    and domain.  A key directory with non-ASCII letters in its name works, because
    it is read as bytes.

- **Line breaks**

    In `to`, `from` and `subject`, any line break is replaced by one space.  In
    the body, every line break is changed to a carriage return and line feed,
    which DKIM needs.

## Methods

### Send\_Email

#### Purpose

Builds the message, signs it and hands it to sendmail(1).  Log::Dispatch
calls this itself, once per message when unbuffered and once per flush when
buffered, so applications do not normally call it.

#### Args

A hash or hash reference with `message`, the text of the message body.  Any
other key (`level`, `name`, ...) is ignored.

#### Returns

`$self`, so calls can be chained.  The outcome of the delivery is reported
by warning, not by the return value, because Log::Dispatch ignores it.

#### Side Effects

Runs sendmail(1).  While it runs, STDERR is pointed at the null device
because some sendmail implementations write a warning there that would corrupt
CGI output.

A missing or unreadable key is not an error: it warns and sends the message
unsigned, which is what [Mail::Send::DKIM](https://metacpan.org/pod/Mail%3A%3ASend%3A%3ADKIM) does for a signing problem of any
kind.  A line break in the subject, From or To is replaced by a space, so a
logged value cannot add a header of its own.

When there is no recipient, or the `from` address cannot be parsed, nothing
is sent and the problem is written straight to STDERR, not warned: a warning
could be routed back into this appender and loop.  `from` may carry a
display name (`"Web Master" <webmaster@example.com>`); the bare
address is used as the sendmail envelope sender and as the signing domain.

#### Usage

```perl
$appender->send_email(message => "Something went wrong\n");
```

#### Example

```perl
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
```

#### Api Specification

##### Input

```perl
{
    message => { type => 'string', min => 0 },
}
```

Unknown keys are ignored.

##### Output

```perl
{ type => 'object', isa => 'Log::Dispatch::Email::DKIM' }
```

#### Messages

- `DKIM: no DKIM key for DOMAIN; sending unsigned` (warning)

    No readable key, domain or selector could be found.  The message is sent
    without a signature.  Put a `SELECTOR.private` key in `~/dkim`, or set
    `DKIM_KEYFILE` or `DKIM_KEYDIR`.

- `DKIM: sendmail failed for SENDER` (warning)

    sendmail(1) could not be run or exited with a failure (a non-zero exit
    status).  Check `DKIM_SENDMAIL` and the mail queue.  When sendmail could not
    be started at all, [Mail::Send::DKIM](https://metacpan.org/pod/Mail%3A%3ASend%3A%3ADKIM) also warns `cannot run PROGRAM: REASON`,
    where REASON is the operating system's own error text, in the current locale.

- `To whom should I be sending this e-mail?` (STDERR)

    The appender has no recipient, so nothing was sent.  Give it a `to`.

- `DKIM: no valid From address to send as; message not sent` (STDERR)

    `from` is missing or is not an address.  Give it a `from` such as
    `webmaster@example.com`.

- `DKIM: invalid arguments to send_email: REASON` (fatal)

    The arguments were not a message.  Pass `message => $text`; REASON is the validator's complaint, or
    `message is required`.

#### Pseudocode

```
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
```

### i18n

#### Purpose

Turns a message key into text for the user, so that every warning and error
this class raises can be translated or reworded by a subclass or by assigning
to `%Log::Dispatch::Email::DKIM::MESSAGES`.  Protected: callable from
this class and its subclasses only.

#### Args

The message key, then an optional hash reference of arguments.  `count`
selects the `one` or `other` variant of a message, and `gender` selects the
variant of that name, with `other` as the fallback.

#### Returns

The message text.  An unknown key returns the key itself, so a missing
translation is visible rather than fatal.

#### Side Effects

None.

#### Usage

```perl
my $text = $self->i18n('no_key', { 'domain' => 'example.com' });
```

#### Example

```perl
# A catalogue entry is [ $sprintf_format, @argument_names ], or a hash
# of variants of one
local $Log::Dispatch::Email::DKIM::MESSAGES{'files'} = {
    'one' => ['%s file', 'count'],
    'other' => ['%s files', 'count'],
};
$self->i18n('files', { 'count' => 2 });     # "2 files"
```

#### Api Specification

##### Input

```perl
{
    key => { type => 'string', min => 1 },
    args => { type => 'hashref', optional => 1 },
}
```

##### Output

```perl
{ type => 'string' }
```

#### Messages

None of its own.  An unknown key is returned as the text.

#### Pseudocode

```
look the key up; if absent, return the key
if the entry is a hash of variants, choose one by gender, then count
format the entry with its named arguments
```

## Examples

A complete log4perl configuration file, which logs everything to a file and
emails anything of level `WARN` or above.  Save it as, say,
`myapp.l4pconf` and load it with `Log::Log4perl->init('myapp.l4pconf')`.

```
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
```

## Limitations

- The message catalogue is a package variable and `i18n` is protected, because
`Log::Dispatch` constructs the appender and does not pass on extra
arguments, so there is no object configuration to carry a locale.
[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) is therefore not used: there is nowhere for it to hook
in.  A site changes the wording by assigning to
`%Log::Dispatch::Email::DKIM::MESSAGES`, which is global to the process.
- The key is found by convention (`~/dkim/*.private`, highest name wins) and
the environment, not configured per appender, for the same reason.  Two
appenders in one process cannot sign with different keys.
- The key with the highest _name_ is used, not the newest or the one that
matches the published DNS record.  Leave a retired key in the directory and,
if it sorts last, it is the one that signs.
- The message goes out only once: if sendmail(1) fails the message is lost, not
queued for retry, and the only record is the warning.
- A `from` with no valid address, or a missing recipient, loses the message.
This used to be a fatal error from the underlying mailer, which a logger should
not raise.
- No MIME headers are added: the body has no declared charset and the subject
is not encoded.  See ["ENCODING"](#encoding).
- Redirecting STDERR is process-wide for the duration of the send, so output
written by another thread meanwhile is lost.
- The plural and gender support in `i18n` selects a variant by key; it does
not know the plural rules of any language beyond one against other.  Use
[Locale::Maketext](https://metacpan.org/pod/Locale%3A%3AMaketext) if you need more.

## See Also

- [Test Dashboard](https://nigelhorne.github.io/Log-Dispatch-Email-DKIM/coverage/)

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Formal Specification

The notation is Z.  `Config` is what an appender holds after `new`.  A
message is signed only when a readable key, a domain and a selector are all
found.

```
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
```

### Send\_Email

```
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
```

### i18n

```
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
```

## State Diagram

An appender is always in one of these states:

```
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
```

The same changes in a table:

```
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
```

## Licence and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
