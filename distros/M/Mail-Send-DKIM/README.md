# Mail::Send::DKIM

## Name

Mail::Send::DKIM - sign a message with DKIM and hand it to sendmail

## Version

0.003.0

## Synopsis

```perl
    use Mail::Send::DKIM;

    my $dkim = Mail::Send::DKIM->new(
            domains => ['example.org'],
            keydir => "$ENV{HOME}/dkim",
    );

    my $signed = $dkim->sign($message);
    $message = $signed if(defined($signed));

    exit($dkim->send($message, '-t', '-f', 'alerts@example.org'));
```

More ways to use it:

```perl
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
```

## Description

Signs a message with DKIM when its `From:` domain is one this host signs for,
and hands it to sendmail with whatever arguments sendmail should have.  The
signed form is `rsa-sha256` with `relaxed` canonicalization, which is the
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

## Platforms

Windows is not supported.  [Mail::DKIM](https://metacpan.org/pod/Mail%3A%3ADKIM) needs [Crypt::OpenSSL::RSA](https://metacpan.org/pod/Crypt%3A%3AOpenSSL%3A%3ARSA), and that
module and its prerequisites, [Crypt::OpenSSL::Random](https://metacpan.org/pod/Crypt%3A%3AOpenSSL%3A%3ARandom) and
[Crypt::OpenSSL::Bignum](https://metacpan.org/pod/Crypt%3A%3AOpenSSL%3A%3ABignum), do not link on Windows: Strawberry Perl's static
OpenSSL needs the `crypt32` library, which their `Makefile.PL` files do not
ask for.  `Makefile.PL` stops with `OS unsupported` there, rather than failing
part-way through the install.

## Environment

**DKIM\_DOMAINS**, **DKIM\_SIGNING\_DOMAIN**, **DKIM\_KEYDIR**, **DKIM\_SELECTOR**,
**DKIM\_KEYFILE** and **SENDMAIL** are read by **new** when the corresponding option is not given, so
the command line programs needs no configuration of its own.

## Programs

The distribution is named after this module and installs five programs with
it, each with a page of its own: `perldoc bin/mail-dkim`,
`perldoc bin/dmarc-report.pl`, `perldoc bin/dmarc-summary`,
`perldoc bin/dmarc-check-mail.pl` and `perldoc bin/dmarc-weekly.sh` in a
checkout, and the same pages as manual pages once installed.

- [mail-dkim](https://github.com/nigelhorne/Mail-Send-DKIM/blob/master/bin/mail-dkim)

    The front end to this module: a message on standard input is signed when its
    `From:` domain is one named in `DKIM_DOMAINS`, and handed to sendmail(1) with
    the arguments it was given.  Put it where a script or a crontab calls sendmail
    and the mail is signed without the script being changed.  Its page has the
    environment variables, the key layout and the exit status.

- [dmarc-report](https://github.com/nigelhorne/Mail-Send-DKIM/blob/master/bin/dmarc-report.pl)

    Reads a directory of DMARC aggregate reports and says who sent mail for each
    domain, marking every source that is not an expected one (`DMARC_EXPECTED`),
    every expected one whose mail did not authenticate, and every message that was
    quarantined or rejected by policy despite passing.  The exit status is non-zero
    when anything needs looking at.  Its page has the options.

- [dmarc-summary](https://github.com/nigelhorne/Mail-Send-DKIM/blob/master/bin/dmarc-summary)

    The shorter reading of the same reports: a line per source address with its
    DKIM and SPF verdicts, the disposition applied, whether the address is one of
    ours and who owns it, over every report in `~/Downloads`, plain or gzipped.
    Where **dmarc-report.pl** decides whether anything needs acting on and says so
    in its exit status, this one is for reading.

- [dmarc-weekly.sh](https://github.com/nigelhorne/Mail-Send-DKIM/blob/master/bin/dmarc-weekly.sh)

    The cron wrapper around it: silent when the week is clean, a mail with the full
    output when it is not, and the reports moved aside to an archive afterwards.
    `DRY_RUN=1` rehearses a run and `--crontab` prints the line to paste into a
    crontab; see ["A CRONTAB ENTRY"](#a-crontab-entry) below.

- [dmarc-check-mail.pl](https://github.com/nigelhorne/Mail-Send-DKIM/blob/master/bin/dmarc-check-mail.pl)

    Sends one message, signed with this module, to a mailbox that can be read, so
    that the `Authentication-Results` header at the far end shows what receivers
    make of this host's mail before the DMARC policy is tightened.  `--plain`
    sends the same message unsigned, which is what a cron job without the module
    looks like.

The four DMARC programs are the reason the module exists: they report on the
mail it signs, and the weekly one sends its own report through it.

## Methods

### **New** %Options

- `domains`

    The domains to sign for, either an array reference or a string of them
    separated by commas or spaces.  Defaults to `$ENV{DKIM_DOMAINS}`.  A message
    from any other domain is left alone.

- `signing_domain`

    The domain put in the signature (its `d=` tag), when it is not the domain in
    the `From:` header - for a host that signs with the key of a parent or
    organisational domain, say.  Defaults to `$ENV{DKIM_SIGNING_DOMAIN}`; with
    neither set, the `From:` domain is used.  Which messages are signed is still
    decided by **domains**, which is matched against the `From:` domain.  The
    receiver finds the public key at
    `<selector>._domainkey.<signing_domain>`, and DMARC accepts the signature
    only if that domain aligns with the `From:` domain.

- `keydir`

    Where the private keys are.  Defaults to `$ENV{DKIM_KEYDIR}`, or `~/dkim`.
    The value is used as it stands: a relative path is taken from the working
    directory, and `~` is not expanded - the shell does that, and only when the
    assignment is written unquoted.

- `selector`

    The selector the key is published under, which names the key file
    `<keydir>/<selector>.private`.  Defaults to `$ENV{DKIM_SELECTOR}`; with
    neither set, the key file's own name is the selector when **keyfile** is given,
    and otherwise the only `*.private` file in **keydir** is used and its name is
    the selector.

- `keyfile`

    The private key to sign with, when it does not live at
    `<keydir>/<selector>.private` - a tester given one key to try, for
    instance.  Defaults to `$ENV{DKIM_KEYFILE}`.  It is used as it stands, and
    the selector comes from its name unless one is given.

- `sendmail`

    The program **send** hands the message to.  Defaults to `$ENV{SENDMAIL}`, or
    `/usr/sbin/sendmail`.

- `home`

    The directory the default **keydir** is made from, as `<home>/dkim`.
    Defaults to `$ENV{HOME}`, then the home directory in the password file entry,
    then the current directory.  It matters only when **keydir** is not given.

- `messages`

    A hash reference of message formats that replace or add to the ones this
    module speaks with, keyed by message key, for a language other than English or
    wording of your own.  See **i18n** for the format.  Because **new** reads its
    options through [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure), the same hash can come from a
    configuration file.

#### Purpose

Builds the signer.  No file is read and no program is run here, so a mistake
in **keydir** or **keyfile** shows when a message is signed, not when the object
is made.

#### Example

```perl
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
```

#### Api Specification

##### Input (Params::Validate::Strict)

```perl
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
```

Options not listed are ignored.  The options may be given as a hash or as a
hash reference.

##### Output (Return::Set)

```perl
    { type => 'object', isa => 'Mail::Send::DKIM' }
```

#### Messages

An option of the wrong type is refused with the message of
[Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict), which names the option.  Nothing else is said.

#### Pseudocode

```
    options = get_params(args)
    options = Object::Configure(options)       # config files, environment
    options = validate(options, NEW_SCHEMA)    # croak on a wrong type
    home    = options.home or $HOME or passwd entry or "."
    domains = split(options.domains or $DKIM_DOMAINS), lower-cased, as a set
    messages = defaults overlaid with options.messages
    return object(domains, keydir, selector, keyfile, sendmail, messages)
```

### **Sign** $Message

Returns the message with a `DKIM-Signature` header added, or `undef` when
there is nothing to do or nothing that can be done: the domain is not one of
**domains**, there is no `From:` header, no key can be found or read, or the
signer failed.  The reasons are warnings on standard error; the message itself
is never altered in the undef case, so the caller sends it unchanged.
Carriage returns are folded to LF on the way, so what comes back is in the
local form.

#### Purpose

Signs the message when, and only when, a key for its `From:` domain can be
found and used.  Nothing is raised for a failure to sign: the caller sends the
message as it is.

The key must be a regular file that can be read.  A directory whose name ends
in `.private` is not a key, and is reported as one that cannot be read.

#### Example

```perl
    my $signed = $dkim->sign($message);
    $message = $signed if(defined($signed));
```

#### Api Specification

##### Input (Params::Validate::Strict)

```perl
    { message => { type => 'string' } }
```

An undefined message is treated as an empty one, which has no `From:`.  It
may be given positionally or as `message => $text`.

##### Output (Return::Set)

```perl
    { type => 'string', optional => 1 }
```

The signed message in the local form, or `undef`.

#### Messages

```
    Message key       Text                                      Meaning and resolution
    key_unreadable    no readable key at FILE; sending DOMAIN   The key file is absent or not
                      unsigned                                  readable: fix the path or the mode.
    sign_failed       cannot sign for DOMAIN (REASON); ...      Mail::DKIM refused the key or
                                                                the message: see REASON.
    keydir_unreadable, keys_ambiguous                           As for selector, below.
```

Each is a warning, and the return is `undef`.

### **Send** $Message, @Arguments

Pipes the message to **sendmail** with the arguments given - `-t`, `-f` and
the rest are sendmail's own - and returns `0` when sendmail accepted the
message, sendmail's exit status when it did not, and `1` when sendmail cannot
be run at all.  The message is normalised to LF first, so nothing that arrived
with CRLF - signed or passed through unsigned - carries a carriage return to
the MTA.

#### Purpose

Delivers the message to the local MTA and reports what the MTA said.

A **sendmail** that is an empty string is the same failure as a program that is
not there: the return is `1` and the message is `sendmail_failed`.  The
caller's `$@`, `$?` and `$SIG{PIPE}` are the same after the call as before
it.

#### Example

```perl
    my $status = $dkim->send($message, '-t', '-f', 'alerts@example.org');
    exit($status);
```

#### Api Specification

##### Input (Params::Validate::Strict)

```perl
    {
            message => { type => 'string' },
            arguments => { type => 'arrayref', optional => 1 },   # the rest of @_
    }
```

##### Output (Return::Set)

```perl
    { type => 'integer', min => 0, max => 255 }
```

#### Messages

```
    Message key        Meaning and resolution
    sendmail_failed    The sendmail program could not be started (not found,
                       not executable): fix the sendmail option or SENDMAIL.
                       The return is 1.
```

A sendmail that exits before it has read the whole message does not stop the
caller with SIGPIPE: its exit status is returned.

#### Pseudocode

```
    ignore SIGPIPE's default action (a handler, so sendmail does not inherit it)
    open a pipe to sendmail with the arguments, as a list so no shell is involved
    if that fails: warn sendmail_failed, return 1
    write the local form of the message, then close the pipe
    if the write and the close both succeeded: return 0
    return sendmail's exit status, or 1 when that would have been 0
```

### **Log\_Send** $Message, @Arguments

Records in syslog, under the identity `mail-dkim` and the `mail` facility,
the sender, the recipients and the subject of a message that has been sent.
The arguments are those given to **send**.  The sender is the address after
`-f` when there is one, and the address in the `From:` header otherwise.  The
recipients are the arguments that are not options and, when `-t` was given,
the addresses in the `To:`, `Cc:` and `Bcc:` headers too.  A value that is
missing is logged as `-`, and control characters in the subject are replaced
by spaces so that a message cannot forge a log line.

Returns true when the line was written.  Logging never stands between a message
and its recipient: a syslog that cannot be reached is a warning, and a false
return.

#### Purpose

Leaves a trace, in the system log, of every message that was passed on.

The arguments are read the way sendmail reads them.  These options take a
value, which is the rest of the argument or else the next argument, and the
value is never a recipient: `-f -F -o -b -p -r -R -V -N -L -X -A -q -C -B`.
Only `-f` is used.  A `-f` with an empty value is a null sender, and is
logged as `-`.  `-t` counts when it is alone or in a group of flags
(`-ti`), but not when it is inside a value, as in `-FNigelTest`, and not in
`-bt`.  An empty argument names nobody.  The members of an empty group, such
as `undisclosed-recipients:;`, are not recipients.

#### Example

```
    $dkim->log_send($message, '-t', '-f', 'alerts@example.org')
            if($dkim->send($message, '-t', '-f', 'alerts@example.org') == 0);
```

#### Api Specification

##### Input (Params::Validate::Strict)

```perl
    {
            message => { type => 'string' },
            arguments => { type => 'arrayref', optional => 1 },
    }
```

##### Output (Return::Set)

```perl
    { type => 'boolean' }
```

#### Messages

```
    Message key        Meaning and resolution
    syslog_failed      openlog or syslog failed: check that a syslog daemon is
                       running and its socket is reachable.  The return is 0.
```

#### Pseudocode

```
    parse the arguments into (sender, recipients, whether -t was given), where an
        option that takes a value, attached or separate, never yields a recipient
    parse the headers of the message once
    sender   = the -f value, else the first address of From
    if -t was given: add the addresses of To, Cc and Bcc to the recipients
    subject  = the Subject, or "-"
    make the line, replace control characters by spaces
    write it to syslog; if that fails, warn syslog_failed and return 0
    return 1
```

### **From\_Domain** $Message

The domain of the address in the first `From:` header, in lower case, or
`undef` when there is no such header.  Folded headers and display names are
understood.

#### Purpose

Says whose domain a message claims to be from, which is what decides whether
it is signed.  The address is read by [Mail::Address](https://metacpan.org/pod/Mail%3A%3AAddress), so quoted display
names, comments and groups are handled by a parser that has seen them before.
Only a plain host name is accepted as a domain (letters, digits, dots and
hyphens).

A `From:` header that holds a control character, other than a tab, gives
`undef`.  A NUL or an escape character can make two programs read two
different addresses from the same header, so no domain is trusted from it.

#### Example

```perl
    my $domain = Mail::Send::DKIM::from_domain($message);   # 'example.org'
    my $same = $dkim->from_domain($message);
```

#### Api Specification

##### Input (Params::Validate::Strict)

```perl
    { message => { type => 'string' } }
```

It may be called as a function or as a method.

##### Output (Return::Set)

```perl
    { type => 'string', optional => 1, matches => qr/\A[a-z0-9.-]+\z/ }
```

#### Messages

None: a message without a usable From: is not an error, the answer is `undef`.

### **Selector**

The selector the message will be signed under: the one given to **new** or read
from `DKIM_SELECTOR`, otherwise the name of the **keyfile** when one is given,
otherwise the name of the only `*.private` file in **keydir**.  `undef` when it
cannot be decided - no key, or several keys and no name - and the reason is a
warning on standard error.  **sign** asks this before doing anything else.

#### Purpose

Settles which of the keys is to be used, once, in one place.

A key in **keydir** is a regular file with a name in front of `.private`.
A directory with such a name, and a file that is only `.private`, are not
keys and are not counted.  A selector that is an empty string is the same as
none.

#### Example

```perl
    my $selector = $dkim->selector();
    die 'no usable key' unless(defined($selector));
```

#### Api Specification

##### Input (Params::Validate::Strict)

```
    {}
```

##### Output (Return::Set)

```perl
    { type => 'string', optional => 1 }
```

#### Messages

```
    Message key         Meaning and resolution
    keydir_unreadable   keydir cannot be opened: create it, or fix the mode or
                        the keydir option.
    keys_ambiguous      keydir holds no key, or more than one, and no selector
                        was named: add the key, or set DKIM_SELECTOR.
```

#### Pseudocode

```
    if a selector was given: return it
    if a key file was given: return its name without .private, .key or .pem
    list the *.private files in keydir (a warning and undef if it cannot be read)
    if there is not exactly one: warn, return undef
    return its name without .private
```

### **i18n** $Key, \\%Arguments

Returns the text of a message, in the language this object speaks, with the
arguments put in.  This is the one place any sentence is made, so a caller can
change every message by giving **new** a `messages` option.

A message is a format whose placeholders are named, `%{name}s` or
`%{name}d`, and which may carry the usual `sprintf` width and flags
(`%{name}-8s`).  It may instead be a hash of formats, from which one is chosen
by the arguments: `count` selects `zero`, `one` or `other` (`other` when
there is no better one), and `variant` - a grammatical gender, for instance -
selects the entry of that name, or `variant.one`, `variant.other` and so on
when the choice is both.  An argument a format asks for and was not given is an
error, not an empty string.  An argument that is given as `undef` is an empty
string (`0` in a `%{name}d`).  A `count` that is not a number selects no
plural form.  `%%` is a percent sign, and any other `%` that is not part of a
placeholder is plain text.  An entry that is an empty hash says nothing.

Croaks if `$key` is not a message that is defined.

#### Example

```perl
    my $text = $dkim->i18n('keys_ambiguous', { keydir => '/etc/dkim', count => 2 });
    # '... /etc/dkim holds 2 keys; name the selector to choose one'

    my $french = Mail::Send::DKIM->new(messages => {
            'keys_ambiguous' => {
                    'one' => '%{keydir}s contient %{count}d cle',
                    'other' => '%{keydir}s contient %{count}d cles',
            },
    });
```

#### Api Specification

##### Input (Params::Validate::Strict)

```perl
    {
            key => { type => 'string' },
            arguments => { type => 'hashref', optional => 1 },
    }
```

##### Output (Return::Set)

```perl
    { type => 'string' }
```

#### Messages

```perl
    Message key        Meaning and resolution
    unknown_message    The key is not in the catalogue: fix the caller, or add it to messages.
    bad_arguments      The arguments were not a hash reference: pass { name => value }.
    missing_argument   A placeholder has no argument: pass it.
```

## A Crontab Entry

A job that sends mail from cron is where an unsigned message is least likely to
be noticed, so that is usually where this module earns its keep: the program
that ships with it, `mail-dkim`, is put where the job would have called
sendmail(1), and the job itself is not changed.

The weekly summary in this distribution is such a job, and its mail goes out
through `mail-dkim`.  A crontab line for it looks like this, with the values of
the machine it runs on:

```
    0 6 * * 1 DMARC_EXPECTED=192.0.2.10 MAIL_TO=alerts@example.org \
            PERL=/usr/bin/perl /usr/local/bin/dmarc-weekly.sh
```

The three settings are not optional, because cron starts a job with almost no
environment.  `DMARC_EXPECTED` is what makes a sender nobody expected a
finding, and the run stops with a usage error without it, since guessing would
excuse every sender.  `MAIL_TO` is where a week that needs looking at is
mailed, and is also the address the alert is sent as unless `MAIL_FROM` says
otherwise.  `PERL` has to be an absolute path to a perl that has
`XML::PP`, as cron's `PATH` usually holds only the system one; `--crontab`
fills it in with the first perl on the machine that can load the module.
`DMARC_DIR` and `DMARC_ARCHIVE_DIR` are left out of the line because they
default to `~/Downloads` and `~/dmarc-archive`.

`dmarc-weekly.sh --crontab` prints that line with the path and the perl filled
in for the machine it runs on, which is more use than an example carrying
somebody else's values; for that reason no example crontab file is shipped or
installed.  A job of your own takes the same shape with `mail-dkim` in place of
the wrapper: `DKIM_DOMAINS` and `DKIM_KEYDIR` say what to sign for, and the
arguments given to it are passed to sendmail(1) as they are.

## Common Pitfalls

- **sign** returns `undef` to mean "nothing was signed"

    It does not die and it does not return an empty string.  Always test with
    `defined`.  The reason is a warning on standard error, except when the
    message simply is not from one of your domains: that is normal and says
    nothing.  Keep the original message and send it if **sign** gave you `undef`.

- An `undef` option means "not given"

    `new(keydir => undef)` is the same as leaving `keydir` out: the
    environment variable, then the built-in default, is used.  An empty string is
    a value: `domains => ''` means "sign for no domain", and nothing is
    signed.

- Replacing a message replaces all of it

    The `messages` option is merged one level deep.  A key you give replaces the
    whole entry for that key.  If the English entry has the forms `one` and
    `other` and you give only `other`, the `one` form is gone: it does not fall
    back to English.  Give every form you need.

- Every placeholder needs a value

    A message such as `%{error}s` is filled from the arguments given to **i18n**.
    A placeholder with no value is an error (a croak), not an empty space.  The
    placeholder style is `%{name}s`, not `%s`.

- Exit status `0` means "accepted", not "delivered"

    **send** only knows that sendmail took the message.  A later failure is the
    mail system's to report.  Call **log\_send** only after a `0`.

- The signed message is not the same text as the one you gave

    Carriage returns are removed, so the result has LF line endings.  This is on
    purpose, and **send** does the same.  Do not compare the two with `eq`.

- Only the first `From:` header counts

    A message with two `From:` headers is signed for the domain of the first one.

- Several keys, no name

    If the key directory holds more than one `*.private` file and you give no
    **selector**, nothing is signed, and there is a warning.  Name the selector.

- `~` is not expanded

    `keydir => '~/dkim'` means a directory that is really called `~`.  Use
    the full path, or `$ENV{HOME}`.

- Private and protected methods

    Names that start with an underscore cannot be called from outside the package.
    Under a test harness (`HARNESS_ACTIVE` is set) the check is switched off, so
    that tests can reach them.

## Encoding

The module works on **bytes**, not on decoded characters, because DKIM signs
bytes.

- The message

    Give **sign**, **send**, **log\_send** and **from\_domain** a message that is
    already encoded, normally as UTF-8 bytes.  Non-ASCII text and emojis in the
    subject or the body are safe in that form.  Mail systems usually expect a
    non-ASCII header to be MIME encoded (for example `=?UTF-8?B?...?=`), and that
    is your job, not this module's.

    If the message is a Perl string holding characters above code point 255 (an
    emoji that has been decoded, for example), **sign** cannot sign it: there is a
    warning and it returns `undef`.  **send** would write it as UTF-8 and Perl
    would warn "Wide character".  Call `Encode::encode('UTF-8', $text)` first.

- Domains and selectors

    ASCII only.  The domain taken from `From:` must be letters, digits, dots and
    hyphens, or it is treated as no domain.  An internationalised domain name must
    be written in its `xn--` form.  Selectors are used as file names and in DNS,
    so use letters, digits and hyphens.

- File names

    **keydir**, **keyfile** and **sendmail** are passed to the operating system as
    they are.  Non-ASCII names work if the bytes are what the file system holds.

- The log line

    **log\_send** writes the sender, recipients and subject as they are.  UTF-8 bytes
    and emojis are kept.  Control characters, such as a line break, are replaced by
    a space.

- Message texts

    The text given in `messages` may contain any characters, emojis included.
    Warnings go to standard error: put a UTF-8 layer on it
    (`binmode(STDERR, ':encoding(UTF-8)')`) when the text is not ASCII, or Perl
    will warn "Wide character".  The text of an operating system error comes from
    the locale of the process.

## Limitations

These are the weaknesses of the design, set down so that they are chosen rather
than found.

- One key for every domain

    A single selector and key serve every domain in `domains`.  A host that signs
    for several customers with a key each cannot say so; it needs one object per
    key.

- Only the From: domain is looked at

    A message is signed when its first `From:` domain is ours.  A message with two
    `From:` headers is signed with the first one's domain, and the signature does
    not oversign the header, so a second `From:` can be added later without
    breaking it.  Refusing such a message would be the safer rule.

- The key is not checked

    That the key file is readable is checked; its mode is not, and nor is whether
    the public half is published in DNS.  A key that is readable by others is not
    reported.

- The whole message is in memory

    The message is a string, held two or three times over while it is signed.  A
    very large message costs that much memory; a stream would not.

- Sending cannot be interrupted

    **send** waits for sendmail as long as sendmail takes.  There is no timeout.

- A bare carriage return is removed

    The local form has no CR at all, as specified, so a lone CR inside a line is
    deleted instead of becoming a line break, and the two halves of the line join.

- Addresses are RFC 822

    [Mail::Address](https://metacpan.org/pod/Mail%3A%3AAddress) is a lenient RFC 822 parser.  Internationalised addresses and
    domain names are not understood, and a From: domain that is not plain ASCII is
    treated as having none.

- The messages are English, with English plurals

    The catalogue is English.  `count` knows `zero`, `one` and `other`, which is
    not enough for languages with more plural forms; a translation that needs them
    would be better served by [Locale::Maketext](https://metacpan.org/pod/Locale%3A%3AMaketext), which this module does not use
    to avoid a language class for six sentences.  The text of an operating system
    error follows the locale of the process that raised it, which this module does
    not control.

- log\_send reads sendmail's options approximately

    **log\_send** knows which of sendmail's options take a value, but not every
    MTA's.  An option it has not heard of that takes a value would have that value
    logged as a recipient.

- rsa-sha256 only

    There is one signature, `rsa-sha256` with `relaxed` canonicalization.  Ed25519
    and a second signature are not offered.

- Windows

    ["PLATFORMS"](#platforms) applies.

- Private means private, except under a test harness

    The helpers whose names begin with an underscore are enforced private
    ([Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate)) and the message writer is protected ([Sub::Protected](https://metacpan.org/pod/Sub%3A%3AProtected)), at
    the cost of a check on every call.  A subclass cannot replace a private helper.

    Both modules skip their checks whenever the environment variable
    `HARNESS_ACTIVE` is set, which is how white-box tests reach the helpers.  A
    program that runs with that variable set, by accident or from inside a test
    harness, loses the protection without a word.  The helpers do nothing harmful
    when called, so the guarantee is then only a convention.

## See Also

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Mail-Send-DKIM/coverage/)

[Mail::DKIM::Signer](https://metacpan.org/pod/Mail%3A%3ADKIM%3A%3ASigner), which does the signing underneath, and ["PROGRAMS"](#programs)
above for the programs this distribution installs beside the module.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Formal Specification

These are mathematical descriptions, in the Z notation, of what each routine
does.  You do not need them to use the module.  Each one is explained in plain
words first.  A name followed by `?` is an input and a name followed by `!`
is an output.  The few symbols used mean this:

```
    Ξ  the object is not changed        ⊥  no value (undef)
    ⇸  a partial map (some keys only)   ⇒  "if this, then that"
    ∈  is a member of                   ⁀  joined to (concatenation)
    ℕ  a whole number, 0 or more        𝔹  true or false
```

### New

The new object holds the set of domains (in lower case), the key directory,
the optional selector and key file, the sendmail program and the messages.
Each comes from the option, else the environment, else a default.

```
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
```

### Sign

The result is the signed message when the From: domain is one of ours and a
key can be used.  In every other case the result is undefined, and nothing
else changes.

```
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
```

### Send

The result is 1 if sendmail cannot be run, 0 if sendmail accepts the message,
and otherwise sendmail's own exit status (1 if that status would be 0).

```
    ┌─ Send ──────────────────────────────────────────────
    │ ΞSigner
    │ message? : STRING;  args? : seq STRING;  status! : ℕ
    ├─────────────────────────────────────────────────────
    │ ¬runnable(sendmail)                      ⇒ status! = 1
    │ runnable(sendmail) ∧ accepted(local(message?)) ⇒ status! = 0
    │ runnable(sendmail) ∧ ¬accepted(local(message?)) ⇒
    │     status! = exitStatus(sendmail) ∨ 1  (1 when that status would be 0)
    └─────────────────────────────────────────────────────
```

### Log\_Send

One line is written to the system log.  The result is true if that worked and false if it did not.

```
    ┌─ LogSend ───────────────────────────────────────────
    │ message? : STRING;  args? : seq STRING;  written! : 𝔹
    ├─────────────────────────────────────────────────────
    │ sender     = valueOf(-f, args?) ∨ firstAddress(From)
    │ recipients = nonOptions(args?) ⁀ (headerAddresses(To, Cc, Bcc) ◁ "-t" ∈ flags(args?))
    │ line = "sender=" ⁀ (sender ∨ "-") ⁀ " recipient=" ⁀ (join "," recipients ∨ "-")
    │        ⁀ " subject=" ⁀ (subject ∨ "-")        (control characters made spaces)
    │ written! = line reached syslog
    └─────────────────────────────────────────────────────
```

### From\_Domain

The result is the lower-case host of the first address of the first From:
header, if it is a plain host name.  Otherwise it is undefined.

```
    ┌─ FromDomain ────────────────────────────────────────
    │ message? : STRING;  domain! : STRING ∪ {⊥}
    ├─────────────────────────────────────────────────────
    │ first(From, headers(message?)) = ⊥ ⇒ domain! = ⊥
    │ a = firstAddress(first(From, headers(message?)))
    │ host(a) matches [A-Za-z0-9.-]+ ⇒ domain! = lower(host(a))
    │ otherwise domain! = ⊥
    └─────────────────────────────────────────────────────
```

### Selector

The result is the selector, chosen in this order: the one given, the name of
the key file, the name of the only key in the key directory.  Otherwise it is
undefined.

```
    ┌─ Selector ──────────────────────────────────────────
    │ ΞSigner;  selector! : STRING ∪ {⊥}
    ├─────────────────────────────────────────────────────
    │ selector ≠ ⊥ ∧ selector ≠ ""    ⇒ selector! = selector
    │ keyfile ≠ ⊥ ∧ name(keyfile) ≠ "" ⇒ selector! = strip(name(keyfile))
    │ #privateKeys(keydir) = 1         ⇒ selector! = strip(the one)
    │ otherwise                          selector! = ⊥
    └─────────────────────────────────────────────────────
```

### i18n

The result is the text of the message, with the arguments put in.  The message must exist.

```
    ┌─ I18n ──────────────────────────────────────────────
    │ ΞSigner;  key? : STRING;  args? : STRING ⇸ VALUE;  text! : STRING
    ├─────────────────────────────────────────────────────
    │ key? ∈ dom messages
    │ text! = format(choose(messages(key?), args?.count, args?.variant), args?)
    └─────────────────────────────────────────────────────
```

## State Diagram

The object itself has one state.  **new** builds it, and nothing afterwards
changes it: **sign**, **send**, **log\_send**, **selector** and **i18n** only read it.
What changes is the state of **a message** as it passes through the calls.  This
is the diagram of that journey.

```
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
```

Each change, what causes it and what happens:

```
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
```

An UNSIGNED message is still sent: signing must never stop mail being
delivered.  UNSENDABLE, REFUSED, LOGGED and NOT LOGGED are the end of the
journey.  The calls **from\_domain**, **selector** and **i18n** are questions that
do not move the message anywhere.

## Licence and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
