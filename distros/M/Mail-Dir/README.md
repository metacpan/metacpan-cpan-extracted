# NAME

Mail::Dir - Compliant Maildir and Maildir++ delivery mechanism

# SYNOPSIS

    use Mail::Dir;

    my $maildir = Mail::Dir->open("$ENV{'HOME'}/Maildir");

    $maildir->deliver('somefile.msg');

    #
    # Create a new Maildir++ mailbox with sub-mailboxes
    #
    my $maildirPP = Mail::Dir->open("$ENV{'HOME'}/newmaildir",
        'maildir++' => 1,
        'create'    => 1
    );

    $maildirPP->create_mailbox('INBOX.foo');
    $maildirPP->create_mailbox('INBOX.foo.bar');
    $maildirPP->select_mailbox('INBOX.foo.bar');

    $maildirPP->deliver(\*STDIN);

# DESCRIPTION

`Mail::Dir` provides a straightforward mechanism for delivering mail messages
to a Maildir or Maildir++ mailbox.

# OPENING OR CREATING A MAILBOX

- `Mail::Dir->open(_$dir_, _%opts_)`

    Open or create a mailbox, in a manner dependent on the flags specified in
    _%opts_, and returns an object representing the Maildir structure.

    Recognized option flags are:

    - `create`

        When specified, create a Maildir inbox at _$dir_ if one does not already
        exist.

    - `maildir++`

        When specified, enable management and usage of Maildir++ sub-mailboxes.

# MANIPULATING MAILBOXES

The following methods require Maildir++ extensions to be enabled.

- `$maildir->select_mailbox(_$mailbox_)`

    Change the current mailbox to which mail is delivered, to _$mailbox_.

- `$maildir->mailbox()`

    Returns the name of the currently selected mailbox.

- `$maildir->mailbox_exists(_$mailbox_)`

    Returns true if _$mailbox_ exists.

- `$maildir->create_mailbox(_$mailbox_)`

    Create the new _$mailbox_ if it does not already exist.  Will throw an error
    if the parent mailbox does not already exist.

# DELIVERING MESSAGES

- `$maildir->deliver(_$from_)`

    Deliver a piece of mail from the source indicated by _$from_.  The following
    types of values can be specified in _$from_:

    - A `CODE` reference

        When passed a `CODE` reference, the subroutine specified in _$from_ is called,
        with a file handle passed that the subroutine may write mail data to.

    - A file handle

        The file handle passed in _$from_ is read until end-of-file condition is
        reached, and spooled to a new message in the current mailbox.

    - A filename

        The message at the filename indicated by _$from_ is spooled into the current
        mailbox.

# RETRIEVING MESSAGES

- `$maildir->messages(_%opts_)`

    Return a list of [Mail::Dir::Message](https://metacpan.org/pod/Mail::Dir::Message) references containing mail messages as
    selected by the criteria specified in _%opts_.  Options include:

    - `tmp`, `new`, `cur`

        When any of these are set to 1, messages in those queues are processed.

    - `filter`

        A subroutine can be passed via `CODE` reference which filters for messages
        that are desired.  Each [Mail::Dir::Message](https://metacpan.org/pod/Mail::Dir::Message) object is passed to the
        subroutine as its sole argument, and is kept if the subroutine returns 1.

# PURGING EXPIRED MESSAGES

- `$maildir->purge()`

    Purge all messages in the `tmp` queue that have not been accessed for the past
    36 hours.

# SEE ALSO

- [`Mail::Dir::Message`](https://metacpan.org/pod/Mail::Dir::Message) - Manipulate messages in a Maildir queue

# CONTRIBUTORS

- Nova Patch &lt;patch@cpan.org>
- Aristotle Pagaltzis &lt;pagaltzis@gmx.de>

# AUTHOR

Alexandra Hrefna Hilmisdóttir &lt;xan@cpan.org>

# COPYRIGHT

Copyright (c) 2016, cPanel, Inc.  Distributed under the terms of the MIT
license.  See the LICENSE file for further details.
