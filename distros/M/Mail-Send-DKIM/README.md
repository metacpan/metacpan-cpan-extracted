# Mail::Send::DKIM

## Name

Mail::Send::DKIM - sign a message with DKIM and hand it to sendmail

## Version

0.002.0

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

**DKIM\_DOMAINS**, **DKIM\_KEYDIR**, **DKIM\_SELECTOR**, **DKIM\_KEYFILE** and
**SENDMAIL** are read by **new** when the corresponding option is not given, so
the command line programs needs no configuration of its own.

## Programs

The distribution is named after this module and installs four programs with
it, each with a page of its own: `perldoc bin/mail-dkim`,
`perldoc bin/dmarc-report.pl`, `perldoc bin/dmarc-check-mail.pl` and
`perldoc bin/dmarc-weekly.sh` in a checkout, and the same pages as manual
pages once installed.

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

The three DMARC programs are the reason the module exists: they report on the
mail it signs, and the weekly one sends its own report through it.

## Methods

### **New** %Options

- `domains`

    The domains to sign for, either an array reference or a string of them
    separated by commas or spaces.  Defaults to `$ENV{DKIM_DOMAINS}`.  A message
    from any other domain is left alone.

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

### **Sign** $Message

Returns the message with a `DKIM-Signature` header added, or `undef` when
there is nothing to do or nothing that can be done: the domain is not one of
**domains**, there is no `From:` header, no key can be found or read, or the
signer failed.  The reasons are warnings on standard error; the message itself
is never altered in the undef case, so the caller sends it unchanged.
Carriage returns are folded to LF on the way, so what comes back is in the
local form.

### **Send** $Message, @Arguments

Pipes the message to **sendmail** with the arguments given - `-t`, `-f` and
the rest are sendmail's own - and returns `0` when sendmail accepted the
message, sendmail's exit status when it did not, and `1` when sendmail cannot
be run at all.  The message is normalised to LF first, so nothing that arrived
with CRLF - signed or passed through unsigned - carries a carriage return to
the MTA.

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

### **From\_Domain** $Message

The domain of the address in the first `From:` header, in lower case, or
`undef` when there is no such header.  Folded headers and display names are
understood.

### **Selector**

The selector the message will be signed under: the one given to **new** or read
from `DKIM_SELECTOR`, otherwise the name of the **keyfile** when one is given,
otherwise the name of the only `*.private` file in **keydir**.  `undef` when it
cannot be decided - no key, or several keys and no name - and the reason is a
warning on standard error.  **sign** asks this before doing anything else.

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

## See Also

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/Mail-Send-DKIM/coverage/)

[Mail::DKIM::Signer](https://metacpan.org/pod/Mail%3A%3ADKIM%3A%3ASigner), which does the signing underneath, and ["PROGRAMS"](#programs)
above for the programs this distribution installs beside the module.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Licence and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
