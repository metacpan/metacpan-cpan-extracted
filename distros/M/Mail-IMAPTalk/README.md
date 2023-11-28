# NAME

Mail::IMAPTalk - IMAP client interface with lots of features

# SYNOPSIS

    use Mail::IMAPTalk;

    $IMAP = Mail::IMAPTalk->new(
        Server   => $IMAPServer,
        Username => 'foo',
        Password => 'bar',
    ) || die "Failed to connect/login to IMAP server";

    # Append message to folder
    open(my $F, 'rfc822msg.txt');
    $IMAP->append($FolderName, $F) || die $@;
    close($F);

    # Select folder and get first unseen message
    $IMAP->select($FolderName) || die $@;
    $MsgId = $IMAP->search('not', 'seen')->[0];

    # Get message envelope and print some details
    $MsgEV = $IMAP->fetch($MsgId, 'envelope')->{$MsgId}->{envelope};
    print "From: " . $MsgEv->{From};
    print "To: " . $MsgEv->{To};
    print "Subject: " . $MsgEv->{Subject};

    # Get message body structure
    $MsgBS = $IMAP->fetch($MsgId, 'bodystructure')->{$MsgId}->{bodystructure};

    # Find imap part number of text part of message
    $MsgTxtHash = Mail::IMAPTalk::find_message($MsgBS);
    $MsgPart = $MsgTxtHash->{text}->{'IMAP-Partnum'};

    # Retrieve message text body
    $MsgTxt = $IMAP->fetch($MsgId, "body[$MsgPart]")->{$MsgId}->{body};

    $IMAP->logout();

# DESCRIPTION

This module communicates with an IMAP server. Each IMAP server command
is mapped to a method of this object.

Although other IMAP modules exist on CPAN, this has several advantages
over other modules.

- It parses the more complex IMAP structures like envelopes and body
structures into nice Perl data structures.
- It correctly supports atoms, quoted strings and literals at any
point. Some parsers in other modules aren't fully IMAP compatiable
and may break at odd times with certain messages on some servers.
- It allows large return values (eg. attachments on a message)
to be read directly into a file, rather than into memory.
- It includes some helper functions to find the actual text/plain
or text/html part of a message out of a complex MIME structure.
It also can find a list of attachements, and CID links for HTML
messages with attached images.
- It supports decoding of MIME headers to Perl utf-8 strings automatically,
so you don't have to deal with MIME encoded headers (enabled optionally).

While the IMAP protocol does allow for asynchronous running of commands, this
module is designed to be used in a synchronous manner. That is, you issue a
command by calling a method, and the command will block until the appropriate
response is returned. The method will then return the parsed results from
the given command.

# CLASS OVERVIEW

The object methods have been broken in several sections.

## Sections

- CONSTANTS

    Lists the available constants the class uses.

- CONSTRUCTOR

    Explains all the options available when constructing a new instance of the
    `Mail::IMAPTalk` class.

- CONNECTION CONTROL METHODS

    These are methods which control the overall IMAP connection object, such
    as logging in and logging out, how results are parsed, how folder names and
    message id's are treated, etc.

- IMAP FOLDER COMMAND METHODS

    These are methods to inspect, add, delete and rename IMAP folders on
    the server.

- IMAP MESSAGE COMMAND METHODS

    These are methods to retrieve, delete, move and add messages to/from
    IMAP folders.

- HELPER METHODS

    These are extra methods that users of this class might find useful. They
    generally do extra parsing on returned structures to provide higher
    level functionality.

- INTERNAL METHODS

    These are methods used internally by the `Mail::IMAPTalk` object to get work
    done. They may be useful if you need to extend the class yourself. Note that
    internal methods will always 'die' if they encounter any errors.

- INTERNAL SOCKET FUNCTIONS

    These are functions used internally by the `Mail::IMAPTalk` object 
    to read/write data to/from the IMAP connection socket. The class does
    its own buffering so if you want to read/write to the IMAP socket, you
    should use these functions.

- INTERNAL PARSING FUNCTIONS

    These are functions used to parse the results returned from the IMAP server
    into Perl style data structures.

## Method results

All methods return undef on failure. There are four main modes of failure:

- 1. An error occurred reading/writing to a socket. Maybe the server
closed it, or you're not connected to any server.
- 2. An error occurred parsing the response of an IMAP command. This is
usually only a problem if your IMAP server returns invalid data.
- 3. An IMAP command didn't return an 'OK' response.
- 4. The socket read operation timed out waiting for a response from
the server.

In each case, some readable form of error text is placed in $@, or you
can call the `get_last_error()` method. For commands which return
responses (e.g. fetch, getacl, etc), the result is returned. See each
command for details of the response result. For commands
with no response but which succeed (e.g. setacl, rename, etc) the result
'ok' is generally returned.

## Method parameters

All methods which send data to the IMAP server (e.g. `fetch()`, `search()`,
etc) have their arguments processed before they are sent. Arguments may be
specified in several ways:

- **scalar**

    The value is first checked and quoted if required. Values containing
    \[\\000\\012\\015\] are turned into literals, values containing
    \[\\000-\\040\\{\\} \\%\\\*\\"\] are quoted by surrounding with a "..." pair
    (any " themselves are turned into \\"). undef is turned into NIL

- **file ref**

    The contents of the file is sent as an IMAP literal. Note that
    because IMAPTalk has to know the length of the file being sent,
    this must be a true file reference that can be seeked and not
    just some stream. The entire file will be sent regardless of the
    current seek point.

- **scalar ref**

    The string/data in the referenced item should be sent as is, no quoting will
    occur, and the data won't be sent as quoted or as a literal regardless
    of the contents of the string/data.

- **array ref**

    Emits an opening bracket, and then each item in the array separated
    by a space, and finally a closing bracket. Each item in the array
    is processed by the same methods, so can be a scalar, file ref,
    scalar ref, another array ref, etc.

- **hash ref**

    The hash reference should contain only 1 item. The key is a text
    string which specifies what to do with the value item of the hash.

    - 'Literal'

        The string/data in the value is sent as an IMAP literal
        regardless of the actual data in the string/data.

    - 'Quote'

        The string/data in the value is sent as an IMAP quoted string
        regardless of the actual data in the string/data.

    Examples:

        # Password is automatically quoted to "nasty%*\"passwd"
        $IMAP->login("joe", 'nasty%*"passwd');
        # Append $MsgTxt as string
        $IMAP->append("inbox", { Literal => $MsgTxt })
        # Append MSGFILE contents as new message
        $IMAP->append("inbox", \*MSGFILE ])

# CONSTANTS

These constants relate to the standard 4 states that an IMAP connection can
be in. They are passed and returned from the `state()` method. See RFC 3501
for more details about IMAP connection states.

- _Unconnected_

    Current not connected to any server.

- _Connected_

    Connected to a server, but not logged in.

- _Authenticated_

    Connected and logged into a server, but not current folder.

- _Selected_

    Connected, logged in and have 'select'ed a current folder.

# CONSTRUCTOR

- _Mail::IMAPTalk->new(%Options)_

    Creates new Mail::IMAPTalk object. The following options are supported.

- **Connection Options**
    - **Server**

        The hostname or IP address to connect to. This must be supplied unless
        the **Socket** option is supplied.

    - **Port**

        The port number on the host to connect to. Defaults to 143 if not supplied
        or 993 if not supplied and UseSSL is true.

    - **UseSSL**

        If true, use an IO::Socket::SSL connection. All other SSL\_\* arguments
        are passed to the IO::Socket::SSL constructor.

    - **Socket**

        An existing socket to use as the connection to the IMAP server. If you
        supply the **Socket** option, you should not supply a **Server** or **Port**
        option.

        This is useful if you want to create an SSL socket connection using
        IO::Socket::SSL and then pass in the connected socket to the new() call.

        It's also useful in conjunction with the `release_socket()` method
        described below for reusing the same socket beyond the lifetime of the IMAPTalk
        object. See a description in the section `release_socket()` method for
        more information.

        You must have write flushing enabled for any
        socket you pass in here so that commands will actually be sent,
        and responses received, rather than just waiting and eventually
        timing out. you can do this using the Perl `select()` call and
        $| ($AUTOFLUSH) variable as shown below.

            my $ofh = select($Socket); $| = 1; select ($ofh);

    - **UseBlocking**

        For historical reasons, when reading from a socket, the module
        sets the socket to non-blocking and does a select(). If you're
        using an SSL socket that doesn't work, so you have to set
        UseBlocking to true to use blocking reads instead.

    - **State**

        If you supply a `Socket` option, you can specify the IMAP state the
        socket is currently in, namely one of 'Unconnected', 'Connected',
        'Authenticated' or 'Selected'. This defaults to 'Connected' if not
        supplied and the `Socket` option is supplied.

    - **ExpectGreeting**

        If supplied and true, and a socket is supplied via the `Socket`
        option, checks that a greeting line is supplied by the server
        and reads the greeting line.

    - **PreserveINBOX**

        For historical reasons, the special name "INBOX" is rewritten as
        Inbox because it looks nicer on the way out, and back on the way
        in.  If you want to preserve the name INBOX on the outside, set
        this flag to true.

    - **UseCompress**

        If you have the Compress::Zlib package installed, and the server
        supports compress, then setting this flag to true will cause
        compression to be enabled immediately after login.
- **Login Options**

    - **Username**

        The username to connect to the IMAP server as. If not supplied, no login
        is attempted and the IMAP object is left in the **CONNECTED** state.
        If supplied, you must also supply the **Password** option and a login
        is attempted. If the login fails, the connection is closed and **undef**
        is returned. If you want to do something with a connection even if the
        login fails, don't pass a **Username** option, but instead use the **login**
        method described below.

    - **Password**

        The password to use to login to the account.

    - **AsUser**

        If the server supports it, access the server as this user rather than the
        authenticate user.

    See the `login` method for more information.

- **IMAP message/folder options**

    - **Uid**

        Control whether message ids are message uids or not. This is 1 (on) by
        default because generally that's how most people want to use it. This affects
        most commands that require/use/return message ids (e.g. **fetch**, **search**,
        **sort**, etc)

    - **RootFolder**

        If supplied, sets the root folder prefix. This is the same as calling
        `set_root_folder()` with the value passed. If no value is supplied,
        `set_root_folder()` is called with no value. See the `set_root_folder()`
        method for more details.

    - **Separator**

        If supplied, sets the folder name text string separator character. 
        Passed as the second parameter to the `set_root_folder()` method.

    - **AltRootRegexp**

        If supplied, passed along with RootFolder to the `set_root_folder()`
        method.

    Examples:

        $imap = Mail::IMAPTalk->new(
          Server          => 'foo.com',
          Port            => 143,
          Username        => 'joebloggs',
          Password        => 'mypassword',
          Separator       => '.',
          RootFolder      => 'INBOX',
        ) || die "Connection to foo.com failed. Reason: $@";

        $imap = Mail::IMAPTalk->new(
          Socket => $SSLSocket,
          State  => Mail::IMAPTalk::Authenticated,
          Uid    => 0
        ) || die "Could not query on existing socket. Reason: $@";

# CONNECTION CONTROL METHODS

- _login($User, $Password, \[$AsUser\])_

    Attempt to login user specified username and password.

    The actual authentication may be done using the `LOGIN` or `AUTHENTICATE`
    commands, depending on what the server advertises support for.

    If `$AsUser` is supplied, an attempt will be made to login on behalf of that user.

- _logout()_

    Log out of IMAP server. This usually closes the servers connection as well.

- _state(optional $State)_

    Set/get the current IMAP connection state. Returned or passed value should be
    one of the constants (Unconnected, Connected, Authenticated, Selected).

- _uid(optional $UidMode)_

    Get/set the UID status of all UID possible IMAP commands.
    If set to 1, all commands that can take a UID are set to 'UID Mode',
    where any ID sent to IMAPTalk is assumed to be a UID.

- _capability()_

    This method returns the IMAP servers capability command results.
    The result is a hash reference of (lc(Capability) => 1) key value pairs.
    This means you can do things like:

        if ($IMAP->capability()->{quota}) { ... }

    to test if the server has the QUOTA capability. If you just want a list of
    capabilities, use the Perl 'keys' function to get a list of keys from the
    returned hash reference.

- _namespace()_

    Returns the result of the IMAP servers namespace command.

- _noop()_

    Perform the standard IMAP 'noop' command which does nothing.

- _enable($option)_

    Enabled the given imap extension

- _is\_open()_

    Returns true if the current socket connection is still open (e.g. the socket
    hasn't been closed this end or the other end due to a timeout).

- _set\_root\_folder($RootFolder, $Separator, $AltRootRegexp)_

    Change the root folder prefix. Some IMAP servers require that all user
    folders/mailboxes live under a root folder prefix (current versions of
    **cyrus** for example use 'INBOX' for personal folders and 'user' for other
    users folders). If no value is specified, it sets it to ''. You might
    want to use the **namespace()** method to find out what roots are
    available.

    Setting this affects all commands that take a folder argument. Basically
    if the foldername begins with root folder prefix, it's left as is,
    otherwise the root folder prefix and separator char are prefixed to the
    folder name.

    The AltRootRegexp is a regexp that if the start of the folder name matches,
    does not have $RootFolder preprended. You can use this to protect
    other namespaces in your IMAP server.

    Examples:

        # This is what cyrus uses
        $IMAP->set_root_folder('INBOX', '.', qr/^user/);

        # Selects 'Inbox' (because 'Inbox' eq 'inbox' case insensitive)
        $IMAP->select('Inbox');
        # Selects 'INBOX.blah'
        $IMAP->select('blah');
        # Selects 'INBOX.Inbox.fred'
        #IMAP->select('Inbox.fred');
        # Selects 'user.john' (because 'user' is alt root)
        #IMAP->select('user.john'); # Selects 'user.john'

- _\_set\_separator($Separator)_

    Checks if the given separator is the same as the one we used before.
    If not, it calls set\_root\_folder to recreate the settings with the new
    Separator.

- _literal\_handle\_control(optional $FileHandle)_

    Sets the mode whether to read literals as file handles or scalars.

    You should pass a filehandle here that any literal will be read into. To
    turn off literal reads into a file handle, pass a 0.

    Examples:

        # Read rfc822 text of message 3 into file
        # (note that the file will have /r/n line terminators)
        open(F, ">messagebody.txt");
        $IMAP->literal_handle_control(\*F);
        $IMAP->fetch(3, 'rfc822');
        $IMAP->literal_handle_control(0);

- _release\_socket($Close)_

    Release IMAPTalk's ownership of the current socket it's using so it's not
    disconnected on DESTROY. This returns the socket, and makes sure that the
    IMAPTalk object doesn't hold a reference to it any more and the connection
    state is set to "Unconnected".

    This means you can't call any methods on the IMAPTalk object any more.

    If the socket is being released and being closed, then $Close is set to true.

- _get\_last\_error()_

    Returns a text string which describes the last error that occurred.

- _get\_last\_completion\_response()_

    Returns the last completion response to the tagged command.

    This is either the string "ok", "no" or "bad" (always lower case) 

- _get\_response\_code($Response)_

    Returns the extra response data generated by a previous call. This is
    most often used after calling **select** which usually generates some
    set of the following sub-results.

    - **permanentflags**

        Array reference of flags which are stored permanently.

    - **uidvalidity**

        Whether the current UID set is valid. See the IMAP RFC for more
        information on this. If this value changes, then all UIDs in the folder
        have been changed.

    - **uidnext**

        The next UID number that will be assigned.

    - **exists**

        Number of messages that exist in the folder.

    - **recent**

        Number of messages that are recent in the folder.

    Other possible responses are **alert**, **newname**, **parse**,
    **trycreate**, **appenduid**, etc.

    The values are stored in a hash keyed on the $Response item.
    They're kept until either overwritten by a future response,
    or explicitly cleared via clear\_response\_code().

    Examples:

        # Select inbox and get list of permanent flags, uidnext and number
        #  of message in the folder
        $IMAP->select('inbox');
        my $NMessages = $IMAP->get_response_code('exists');
        my $PermanentFlags = $IMAP->get_response_code('permanentflags');
        my $UidNext = $IMAP->get_response_code('uidnext');

- _clear\_response\_code($Response)_

    Clears any response code information. Response code information
    is not normally cleared between calls.

- _parse\_mode(ParseOption => $ParseMode)_

    Changes how results of fetch commands are parsed. Available
    options are:

    - _BodyStructure_

        Parse bodystructure into more Perl-friendly structure
        See the **FETCH RESULTS** section.

    - _Envelope_

        Parse envelopes into more Perl-friendly structure
        See the **FETCH RESULTS** section.

    - _Annotation_

        Parse annotation (from RFC 5257) into more Perl-friendly structure
        See the **FETCH RESULTS** section.

    - _EnvelopeRaw_

        If parsing envelopes, create To/Cc/Bcc and
        Raw-To/Raw-Cc/Raw-Bcc entries which are array refs of 4
        entries each as returned by the IMAP server.

    - _DecodeUTF8_

        If parsing envelopes, decode any MIME encoded headers into
        Perl UTF-8 strings.

        For this to work, you must have 'used' Mail::IMAPTalk with:

        use Mail::IMAPTalk qw(:utf8support ...)

- _set\_tracing($Tracer)_

    Allows you to trace both IMAP input and output sent to the server
    and returned from the server. This is useful for debugging. Returns
    the previous value of the tracer and then sets it to the passed
    value. Possible values for $Tracer are:

    - _0_

        Disable all tracing.

    - _1_

        Print to STDERR.

    - _Code ref_

        Call code ref for each line input and output. Pass line as parameter.

    - _Glob ref_

        Print to glob.

    - _Scalar ref_

        Appends to the referenced scalar.

    Note: literals are never passed to the tracer.

- _set\_unicode\_folders($Unicode)_

    $Unicode should be 1 or 0

    Sets whether folder names are expected and returned
    as perl unicode strings.

    The default is currently 0, BUT YOU SHOULD NOT ASSUME THIS,
    because it will probably change in the future.

    If you want to work with perl unicode strings for
    folder names, you should call
      $ImapTalk->set\_unicode\_folders(1)
    and IMAPTalk will automatically encode the unicode
    strings into IMAP-UTF7 when sending to the IMAP server,
    and will also decode IMAP-UTF7 back into perl unicode
    strings when returning results from the IMAP server.

    If you want to work with folder names in IMAP-UTF7 bytes,
    then call
      $ImapTalk->set\_unicode\_folders(0)
    and IMAPTalk will leave folder names as bytes when
    sending to and returning results from the IMAP server.

# IMAP FOLDER COMMAND METHODS

**Note:** In all cases where a folder name is used, 
the folder name is first manipulated according to the current root folder
prefix as described in `set_root_folder()`.

- _select($FolderName, @Opts)_

    Perform the standard IMAP 'select' command to select a folder for
    retrieving/moving/adding messages. If $Opts{ReadOnly} is true, the 
    IMAP EXAMINE verb is used instead of SELECT.

    Mail::IMAPTalk will cache the currently selected folder, and if you
    issue another ->select("XYZ") for the folder that is already selected,
    it will just return immediately. This can confuse code that expects
    to get side effects of a select call. For that case, call ->unselect()
    first, then ->select().

- _unselect()_

    Performs the standard IMAP unselect command.

- _examine($FolderName)_

    Perform the standard IMAP 'examine' command to select a folder in read only
    mode for retrieving messages. This is the same as `select($FolderName, 1)`.
    See `select()` for more details.

- _create($FolderName)_

    Perform the standard IMAP 'create' command to create a new folder.

- _delete($FolderName)_

    Perform the standard IMAP 'delete' command to delete a folder.

- _localdelete($FolderName)_

    Perform the IMAP 'localdelete' command to delete a folder (doesn't delete subfolders even of INBOX, is always immediate.

- _rename($OldFolderName, $NewFolderName)_

    Perform the standard IMAP 'rename' command to rename a folder.

- _list($Reference, $Name)_

    Perform the standard IMAP 'list' command to return a list of available
    folders.

- _xlist($Reference, $Name)_

    Perform the IMAP 'xlist' extension command to return a list of available
    folders and their special use attributes.

- _id($key =_ $value, ...)>

    Perform the IMAP extension command 'id'

- _lsub($Reference, $Name)_

    Perform the standard IMAP 'lsub' command to return a list of subscribed
    folders

- _subscribe($FolderName)_

    Perform the standard IMAP 'subscribe' command to subscribe to a folder.

- _unsubscribe($FolderName)_

    Perform the standard IMAP 'unsubscribe' command to unsubscribe from a folder.

- _check()_

    Perform the standard IMAP 'check' command to checkpoint the current folder.

- _setacl($FolderName, $User, $Rights)_

    Perform the IMAP 'setacl' command to set the access control list
    details of a folder/mailbox. See RFC 4314 for more details on the IMAP
    ACL extension. $User is the user name to set the access
    rights for. $Rights is either a list of absolute rights to set, or a
    list prefixed by a - to remove those rights, or a + to add those rights.

    - l - lookup (mailbox is visible to LIST/LSUB commands)
    - r - read (SELECT the mailbox, perform CHECK, FETCH, PARTIAL, SEARCH, COPY from mailbox)
    - s - keep seen/unseen information across sessions (STORE SEEN flag)
    - w - write (STORE flags other than SEEN and DELETED)
    - i - insert (perform APPEND, COPY into mailbox)
    - p - post (send mail to submission address for mailbox, not enforced by IMAP4 itself)
    - k - create mailboxes (CREATE new sub-mailboxes in any implementation-defined hierarchy, parent mailbox for the new mailbox name in RENAME)
    - x - delete mailbox (DELETE mailbox, old mailbox name in RENAME)
    - t - delete messages (set or clear \\DELETED flag via STORE, set \\DELETED flag during APPEND/COPY)
    - e - perform EXPUNGE and expunge as a part of CLOSE
    - a - administer (perform SETACL)

    Due to ambiguity in RFC 2086, some existing RFC 2086 server
    implementations use the "c" right to control the DELETE command.
    Others chose to use the "d" right to control the DELETE command. See
    the 2.1.1. Obsolete Rights in RFC 4314 for more details.

    - c - create (CREATE new sub-mailboxes in any implementation-defined hierarchy)
    - d - delete (STORE DELETED flag, perform EXPUNGE)

    The standard access control configurations for cyrus are

    - read   = "lrs"
    - post   = "lrsp"
    - append = "lrsip"
    - write  = "lrswipcd"
    - all    = "lrswipcda"

    Examples:

        # Get full access for user 'joe' on his own folder
        $IMAP->setacl('user.joe', 'joe', 'lrswipcda') || die "IMAP error: $@";
        # Remove write, insert, post, create, delete access for user 'andrew'
        $IMAP->setacl('user.joe', 'andrew', '-wipcd') || die "IMAP error: $@";
        # Add lookup, read, keep unseen information for user 'paul'
        $IMAP->setacl('user.joe', 'paul', '+lrs') || die "IMAP error: $@";

- _getacl($FolderName)_

    Perform the IMAP 'getacl' command to get the access control list
    details of a folder/mailbox. See RFC 4314 for more details on the IMAP
    ACL extension. Returns an array of pairs. Each pair is
    a username followed by the access rights for that user. See **setacl**
    for more information on access rights.

    Examples:

        my $Rights = $IMAP->getacl('user.joe') || die "IMAP error : $@";
        $Rights = [
          'joe', 'lrs',
          'andrew', 'lrswipcda'
        ];

        $IMAP->setacl('user.joe', 'joe', 'lrswipcda') || die "IMAP error : $@";
        $IMAP->setacl('user.joe', 'andrew', '-wipcd') || die "IMAP error : $@";
        $IMAP->setacl('user.joe', 'paul', '+lrs') || die "IMAP error : $@";

        $Rights = $IMAP->getacl('user.joe') || die "IMAP error : $@";
        $Rights = [
          'joe', 'lrswipcd',
          'andrew', 'lrs',
          'paul', 'lrs'
        ];

- _deleteacl($FolderName, $Username)_

    Perform the IMAP 'deleteacl' command to delete all access
    control information for the given user on the given folder. See **setacl**
    for more information on access rights.

    Examples:

        my $Rights = $IMAP->getacl('user.joe') || die "IMAP error : $@";
        $Rights = [
          'joe', 'lrswipcd',
          'andrew', 'lrs',
          'paul', 'lrs'
        ];

        # Delete access information for user 'andrew'
        $IMAP->deleteacl('user.joe', 'andrew') || die "IMAP error : $@";

        $Rights = $IMAP->getacl('user.joe') || die "IMAP error : $@";
        $Rights = [
          'joe', 'lrswipcd',
          'paul', 'lrs'
        ];

- _setquota($FolderName, $QuotaDetails)_

    Perform the IMAP 'setquota' command to set the usage quota
    details of a folder/mailbox. See RFC 2087 for details of the IMAP
    quota extension. $QuotaDetails is a bracketed list of limit item/value
    pairs which represent a particular type of limit and the value to set
    it to. Current limits are:

    - STORAGE - Sum of messages' RFC822.SIZE, in units of 1024 octets
    - MESSAGE - Number of messages

    Examples:

        # Set maximum size of folder to 50M and 1000 messages
        $IMAP->setquota('user.joe', '(storage 50000)') || die "IMAP error: $@";
        $IMAP->setquota('user.john', '(messages 1000)') || die "IMAP error: $@";
        # Remove quotas
        $IMAP->setquota('user.joe', '()') || die "IMAP error: $@";

- _getquota($FolderName)_

    Perform the standard IMAP 'getquota' command to get the quota
    details of a folder/mailbox. See RFC 2087 for details of the IMAP
    quota extension. Returns an array reference to quota limit triplets.
    Each triplet is made of: limit item, current value, maximum value.

    Note that this only returns the quota for a folder if it actually
    has had a quota set on it. It's possible that a parent folder
    might have a quota as well which affects sub-folders. Use the
    getquotaroot to find out if this is true.

    Examples:

        my $Result = $IMAP->getquota('user.joe') || die "IMAP error: $@";
        $Result = [
          'STORAGE', 31, 50000,
          'MESSAGE', 5, 1000
        ];

- _getquotaroot($FolderName)_

    Perform the IMAP 'getquotaroot' command to get the quota
    details of a folder/mailbox and possible root quota as well.
    See RFC 2087 for details of the IMAP
    quota extension. The result of this command is a little complex.
    Unfortunately it doesn't map really easily into any structure
    since there are several different responses. 

    Basically it's a hash reference. The 'quotaroot' item is the
    response which lists the root quotas that apply to the given
    folder. The first item is the folder name, and the remaining
    items are the quota root items. There is then a hash item
    for each quota root item. It's probably easiest to look at
    the example below.

    Examples:

        my $Result = $IMAP->getquotaroot('user.joe.blah') || die "IMAP error: $@";
        $Result = {
          'quotaroot' => [
            'user.joe.blah', 'user.joe', ''
          ],
          'user.joe' => [
            'STORAGE', 31, 50000,
            'MESSAGES', 5, 1000
          ],
          '' => [
            'MESSAGES', 3498, 100000
          ]
        };

- _message\_count($FolderName)_

    Return the number of messages in a folder. See also `status()` for getting
    more information about messages in a folder.

- _status($FolderName, $StatusList)_

    Perform the standard IMAP 'status' command to retrieve status information about
    a folder/mailbox.

    The $StatusList is a bracketed list of folder items to obtain the status of.
    Can contain: messages, recent, uidnext, uidvalidity, unseen.

    The return value is a hash reference of lc(status-item) => value.

    Examples:

        my $Res = $IMAP->status('inbox', '(MESSAGES UNSEEN)');

        $Res = {
          'messages' => 8,
          'unseen' => 2
        };

- _multistatus($StatusList, @FolderNames)_

    Performs many IMAP 'status' commands on a list of folders. Sends all the
    commands at once and wait for responses. This speeds up latency issues.

    Returns a hash ref of folder name => status results.

    If an error occurs, the annotation result is a scalar ref to the completion
    response string (eg 'bad', 'no', etc)

- _getannotation($FolderName, $Entry, $Attribute)_

    Perform the IMAP 'getannotation' command to get the annotation(s)
    for a mailbox.  See imap-annotatemore extension for details.

    Examples:

        my $Result = $IMAP->getannotation('user.joe.blah', '/*' '*') || die "IMAP error: $@";
        $Result = {
          'user.joe.blah' => {
            '/vendor/cmu/cyrus-imapd/size' => {
              'size.shared' => '5',
              'content-type.shared' => 'text/plain',
              'value.shared' => '19261'
            },
            '/vendor/cmu/cyrus-imapd/lastupdate' => {
              'size.shared' => '26',
              'content-type.shared' => 'text/plain',
              'value.shared' => '26-Mar-2004 13:31:56 -0800'
            },
            '/vendor/cmu/cyrus-imapd/partition' => {
              'size.shared' => '7',
              'content-type.shared' => 'text/plain',
              'value.shared' => 'default'
            }
          }
        };

- _getmetadata($FolderName, \[ \\%Options \], @Entries)_

    Perform the IMAP 'getmetadata' command to get the metadata items
    for a mailbox.  See RFC 5464 for details.

    If $Options is passed, it is a hashref of options to set.

    If foldername is the empty string, gets server annotations

    Examples:

        my $Result = $IMAP->getmetadata('user.joe.blah', {depth => 'infinity'}, '/shared') || die "IMAP error: $@";
        $Result = {
          'user.joe.blah' => {
            '/shared/vendor/cmu/cyrus-imapd/size' => '19261',
            '/shared/vendor/cmu/cyrus-imapd/lastupdate' => '26-Mar-2004 13:31:56 -0800',
            '/shared/vendor/cmu/cyrus-imapd/partition' => 'default',
          }
        };

        my $Result = $IMAP->getmetadata('', "/shared/comment");
        $Result => {
          '' => {
            '/shared/comment' => "Shared comment",
          }
        };

- _multigetmetadata(\\@Entries, @FolderNames)_

    Performs many IMAP 'getmetadata' commands on a list of folders. Sends
    all the commands at once and wait for responses. This speeds up latency
    issues.

    Returns a hash ref of folder name => metadata results.

    If an error occurs, the annotation result is a scalar ref to the completion
    response string (eg 'bad', 'no', etc)

- _setannotation($FolderName, $Entry, \[ $Attribute, $Value \])_

    Perform the IMAP 'setannotation' command to get the annotation(s)
    for a mailbox.  See imap-annotatemore extension for details.

    Examples:

        my $Result = $IMAP->setannotation('user.joe.blah', '/comment', [ 'value.priv' 'A comment' ])
          || die "IMAP error: $@";

- _setmetadata($FolderName, $Name, $Value, $Name2, $Value2)_

    Perform the IMAP 'setmetadata' command.  See RFC 5464 for details.

    Examples:

        my $Result = $IMAP->setmetadata('user.joe.blah', '/comment', 'A comment')
          || die "IMAP error: $@";

- _close()_

    Perform the standard IMAP 'close' command to expunge deleted messages
    from the current folder and return to the Authenticated state.

- _idle(\\&Callback, \[ $Timeout \])_

    Perform an IMAP idle call. Call given callback for each IDLE event
    received.

    If the callback returns 0, the idle continues. If the callback returns 1,
    the idle is finished and this call returns.

    If no timeout is passed, will continue to idle until the callback returns
    1 or the server disconnects.

    If a timeout is passed (including a 0 timeout), the call will return if
    no events are received within the given time. It will return the result
    of the DONE command, and set $Self->get\_response\_code('timeout') to true.

    If the server closes the connection with a "bye" response, it will
    return undef and $@ =~ /bye/ will be true with the remainder of the bye
    line following.

# IMAP MESSAGE COMMAND METHODS

- _fetch(\[ \\%ParseMode \], $MessageIds, $MessageItems)_

    Perform the standard IMAP 'fetch' command to retrieve the specified message
    items from the specified message IDs.

    The first parameter can be an optional hash reference that overrides
    particular parse mode parameters just for this fetch. See `parse_mode`
    for possible keys.

    `$MessageIds` can be one of two forms:

    1. A text string with a comma separated list of message ID's or message ranges
    separated by colons. A '\*' represents the highest message number.

        Examples:

        - '1' - first message
        - '1,2,5'
        - '1:\*' - all messages
        - '1,3:\*' - all but message 2

        Note that , separated lists and : separated ranges can be mixed, but to
        make sure a certain hack works, if a '\*' is used, it must be the last
        character in the string.

    2. An array reference with a list of message ID's or ranges. The array contents
    are `join(',', ...)`ed together.

    Note: If the `uid()` state has been set to true, then all message ID's
    must be message UIDs.

    `$MessageItems` can be one of, or a bracketed list of:

    - uid
    - flags
    - internaldate
    - envelope
    - bodystructure
    - body
    - body\[section\]&lt;partial>
    - body.peek\[section\]&lt;partial>
    - rfc822
    - rfc822.header
    - rfc822.size
    - rfc822.text
    - fast
    - all
    - full

    It would be a good idea to see RFC 3501 for what all these means.

    Examples:

        my $Res = $IMAP->fetch('1:*', 'rfc822.size');
        my $Res = $IMAP->fetch([1,2,3], '(bodystructure envelope)');

    Return results:

    The results returned by the IMAP server are parsed into a Perl structure.
    See the section **FETCH RESULTS** for all the interesting details.

    Note that message can disappear on you, so you may not get back
    all the entries you expect in the hash

    There is one piece of magic. If your request is for a single uid,
    (eg "123"), and no data is return, we return undef, because it's
    easier to handle as an error condition.

- _copy($MsgIds, $ToFolder)_

    Perform standard IMAP copy command to copy a set of messages from one folder
    to another.

- _append($FolderName, optional $MsgFlags, optional $MsgDate, $MessageData)_

    Perform standard IMAP append command to append a new message into a folder.

    The $MessageData to append can either be a Perl scalar containing the data,
    or a file handle to read the data from. In each case, the data must be in
    proper RFC 822 format with \\r\\n line terminators.

    Any optional fields not needed should be removed, not left blank.

    Examples:

        # msg.txt should have \r\n line terminators
        open(F, "msg.txt");
        $IMAP->append('inbox', \*F);

        my $MsgTxt =<<MSG;
        From: blah\@xyz.com
        To: whoever\@whereever.com
        ...
        MSG

        $MsgTxt =~ s/\n/\015\012/g;
        $IMAP->append('inbox', { Literal => $MsgTxt });

- _search($MsgIdSet, @SearchCriteria)_

    Perform standard IMAP search command. The result is an array reference to a list
    of message IDs (or UIDs if in Uid mode) of messages that are in the $MsgIdSet
    and also meet the search criteria.

    @SearchCriteria is a list of search specifications, for example to look for
    ASCII messages bigger than 2000 bytes you would set the list to be:

        my @SearchCriteria = ('CHARSET', 'US-ASCII', 'LARGER', '2000');

    Examples:

        my $Res = $IMAP->search('1:*', 'NOT', 'DELETED');
        $Res = [ 1, 2, 5 ];

- _store($MsgIdSet, $FlagOperation, $Flags)_

    Perform standard IMAP store command. Changes the flags associated with a
    set of messages.

    Examples:

        $IMAP->store('1:*', '+flags', '(\\deleted)');
        $IMAP->store('1:*', '-flags.silent', '(\\read)');

- _expunge()_

    Perform standard IMAP expunge command. This actually deletes any messages
    marked as deleted.

- _uidexpunge($MsgIdSet)_

    Perform IMAP uid expunge command as per RFC 2359.

- _sort($SortField, $CharSet, @SearchCriteria)_

    Perform extension IMAP sort command. The result is an array reference to a list
    of message IDs (or UIDs if in Uid mode) in sorted order.

    It would probably be a good idea to look at the sort RFC 5256 details at
    somewhere like : http://www.ietf.org/rfc/rfc5256.txt

    Examples:

        my $Res = $IMAP->sort('(subject)', 'US-ASCII', 'NOT', 'DELETED');
        $Res = [ 5, 2, 3, 1, 4 ];

- _thread($ThreadType, $CharSet, @SearchCriteria)_

    Perform extension IMAP thread command. The $ThreadType should be one
    of 'REFERENCES' or 'ORDEREDSUBJECT'. You should check the `capability()`
    of the server to see if it supports one or both of these.

    Examples

        my $Res = $IMAP->thread('REFERENCES', 'US-ASCII', 'NOT', 'DELETED');
        $Res = [ [10, 15, 20], [11], [ [ 12, 16 ], [13, 17] ];

- _fetch\_flags($MessageIds)_

    Perform an IMAP 'fetch flags' command to retrieve the specified flags
    for the specified messages.

    This is just a special fast path version of `fetch`.

- _fetch\_meta($MessageIds, @MetaItems)_

    Perform an IMAP 'fetch' command to retrieve the specified meta
    items. These must be simple items that return only atoms
    (eg no flags, bodystructure, body, envelope, etc)

    This is just a special fast path version of `fetch`.

# IMAP CYRUS EXTENSION METHODS

Methods provided by extensions to the cyrus IMAP server

**Note:** In all cases where a folder name is used, 
the folder name is first manipulated according to the current root folder
prefix as described in `set_root_folder()`.

- _xrunannotator($MessageIds)_

    Run the xannotator command on the given message id's

- _xconvfetch($CIDs, $ChangedSince, $Items)_

    Use the server XCONVFETCH command to fetch information about messages
    in a conversation.

    CIDs can be a single CID or an array ref of CIDs.

        my $Res = $IMAP->xconvfetch('2fc2122a109cb6c8', 0, '(uid cid envelope)')
        $Res = {
          state => { CID => [ HighestModSeq ], ... }
          folders => [ [ FolderName, UidValidity ], ..., ],
          found => [ [ FolderIndex, Uid, { Details } ], ... ],
        }

    Note: FolderIndex is an integer index into the folders list

- _xconvmeta($CIDs, $Items)_

    Use the server XCONVMETA command to fetch information about
    a conversation.

    CIDs can be a single CID or an array ref of CIDs.

        my $Res = $IMAP->xconvmeta('2fc2122a109cb6c8', '(senders exists unseen)')
        $Res = {
          CID1 => { senders => { name => ..., email => ... }, exists => ..., unseen => ..., ...  },
          CID2 => { ...  },
        }

- _xconvsort($Sort, $Window, $Charset, @SearchParams)_

    Use the server XCONVSORT command to fetch exemplar conversation
    messages in a mailbox.

        my $Res = $IMAP->xconvsort( [ qw(reverse arrival) ], [ 'conversations', position => [1, 10] ], 'utf-8', 'ALL')
        $Res = {
          sort => [ Uid, ... ],
          position => N,
          highestmodseq => M,
          uidvalidity => V,
          uidnext => U,
          total => R,
        }

- _xconvupdates($Sort, $Window, $Charset, @SearchParams)_

    Use the server XCONVUPDATES command to find changed exemplar
    messages

        my $Res = $IMAP->xconvupdates( [ qw(reverse arrival) ], [ 'conversations', changedsince => [ $mod_seq, $uid_next ] ], 'utf-8', 'ALL');
        $Res = {
          added => [ [ Uid, Pos ], ... ],
          removed => [ Uid, ... ],
          changed => [ CID, ... ],
          highestmodseq => M,
          uidvalidity => V,
          uidnext => U,
          total => R,
        }

- _xconvmultisort($Sort, $Window, $Charset, @SearchParams)_

    Use the server XCONVMULTISORT command to fetch messages across
    all mailboxes

        my $Res = $IMAP->xconvmultisort( [ qw(reverse arrival) ], [ 'conversations', postion => [1,10] ], 'utf-8', 'ALL')
        $Res = {
          folders => [ [ FolderName, UidValidity ], ... ],
          sort => [ FolderIndex, Uid ], ... ],
          position => N,
          highestmodseq => M,
          total => R,
        }

    Note: FolderIndex is an integer index into the folders list

- _xsnippets($Items, $Charset, @SearchParams)_

    Use the server XSNIPPETS command to fetch message search snippets

        my $Res = $IMAP->xsnippets( [ [ FolderName, UidValidity, [ Uid, ... ] ], ... ], 'utf-8', 'ALL')
        $Res = {
          folders => [ [ FolderName, UidValidity ], ... ],
          snippets => [
            [ FolderIndex, Uid, Location, Snippet ],
            ...
          ]
        ]

    Note: FolderIndex is an integer index into the folders list

# IMAP HELPER FUNCTIONS

- _get\_body\_part($BodyStruct, $PartNum)_

    This is a helper function that can be used to further parse the
    results of a fetched bodystructure. Given a top level body
    structure, and a part number, it returns the reference to
    the bodystructure sub part which that part number refers to.

    Examples:

        # Fetch body structure
        my $FR = $IMAP->fetch(1, 'bodystructure');
        my $BS = $FR->{1}->{bodystructure};

        # Parse further to find particular sub part
        my $P12 = $IMAP->get_body_part($BS, '1.2');
        $P12->{'IMAP->Partnum'} eq '1.2' || die "Unexpected IMAP part number";

- _find\_message($BodyStruct)_

    This is a helper function that can be used to further parse the results of
    a fetched bodystructure. It returns a hash reference with the following
    items.

        text => $best_text_part
        html => $best_html_part (optional)
        textlist => [ ... text/html (if no alt text bits)/image (if inline) parts ... ]
        htmllist => [ ... text (if no alt html bits)/html/image (if inline) parts ... ]
        att => [ {
           bs => $part, text => 0/1, html => 0/1, msg => 1/0,
         }, { ... }, ... ]

    For instance, consider a message with text and html pages that's then
    gone through a list software manager that attaches a header/footer

        multipart/mixed
          text/plain, cd=inline - A
          multipart/mixed
            multipart/alternative
              multipart/mixed
                text/plain, cd=inline - B
                image/jpeg, cd=inline - C
                text/plain, cd=inline - D
              multipart/related
                text/html - E
                image/jpeg - F
            image/jpeg, cd=attachment - G
            application/x-excel - H
            message/rfc822 - J
          text/plain, cd=inline - K

    In this case, we'd have the following list items

        text => B
        html => E
        textlist => [ A, B, C, D, K ]
        htmllist => [ A, E, K ]
        att => [
          { bs => C, text => 1, html => 1 },
          { bs => F, text => 1, html => 0 },
          { bs => G, text => 1, html => 1 },
          { bs => H, text => 1, html => 1 },
          { bs => J, text => 0, html => 0, msg => 1 },
        ]

    Examples:

        # Fetch body structure
        my $FR = $IMAP->fetch(1, 'bodystructure');
        my $BS = $FR->{1}->{bodystructure};

        # Parse further to find message components
        my $MC = $IMAP->find_message($BS);
        $MC = { 'plain' => ... text body struct ref part ...,
                'html' => ... html body struct ref part (if present) ... 
                'htmllist' => [ ... html body struct ref parts (if present) ... ] };

        # Now get the text part of the message
        my $MT = $IMAP->fetch(1, 'body[' . $MC->{text}->{'IMAP-Part'} . ']');

- _generate\_cid( $Token, $PartBS )_

    This method generates a ContentID based on $Token and $PartBS.

    The same value should always be returned for a given $Token and $PartBS

- _build\_cid\_map($BodyStruct, \[ $IMAP, $Uid, $GenCidToken \])_

    This is a helper function that can be used to further parse the
    results of a fetched bodystructure. It recursively parses the
    bodystructure and returns a hash of Content-ID to bodystruct
    part references. This is useful when trying to determine CID
    links from an HTML message.

    If you pass a Mail::IMAPTalk object as the second parameter,
    the CID map built may be even more detailed. It seems some
    stupid versions of exchange put details in the Content-Location
    header rather than the Content-Type header. If that's the
    case, this will try and fetch the header from the message

    Examples:

        # Fetch body structure
        my $FR = $IMAP->fetch(1, 'bodystructure');
        my $BS = $FR->{1}->{bodystructure};

        # Parse further to get CID links
        my $CL = build_cid_map($BS);
        $CL = { '2958293123' => ... ref to body part ..., ... };

- _obliterate($CyrusName)_

    Given a username (optionally username\\@domain) immediately delete all messages belonging
    to this user.  Uses LOCALDELETE.  Quite FastMail Patchd Cyrus specific.

# IMAP CALLBACKS

By default, these methods do nothing, but you can dervice
from Mail::IMAPTalk and override these methods to trap
any things you want to catch

- _cb\_switch\_folder($CurrentFolder, $NewFolder)_

    Called when the currently selected folder is being changed
    (eg 'select' called and definitely a different folder
    is being selected, or 'unselect' methods called)

- _cb\_folder\_changed($Folder)_

    Called when a command changes the contents of a folder
    (eg copy, append, etc). $Folder is the name of the
    folder that's changing.

# FETCH RESULTS

The 'fetch' operation is probably the most common thing you'll do with an
IMAP connection. This operation allows you to retrieve information about a
message or set of messages, including header fields, flags or parts of the
message body.

`Mail::IMAPTalk` will always parse the results of a fetch call into a Perl like
structure, though 'bodystructure', 'envelope' and 'uid' responses may
have additional parsing depending on the `parse_mode` state and the `uid`
state (see below).

For an example case, consider the following IMAP commands and responses
(C is what the client sends, S is the server response).

    C: a100 fetch 5,6 (flags rfc822.size uid)
    S: * 1 fetch (UID 1952 FLAGS (\recent \seen) RFC822.SIZE 1150)
    S: * 2 fetch (UID 1958 FLAGS (\recent) RFC822.SIZE 110)
    S: a100 OK Completed

The fetch command can be sent by calling:

    my $Res = $IMAP->fetch('1:*', '(flags rfc822.size uid)');

The result in response will look like this:

    $Res = {
      1 => {
        'uid' => 1952,
        'flags' => [ '\\recent', '\\seen' ],
        'rfc822.size' => 1150
      },
      2 => {
        'uid' => 1958,
        'flags' => [ '\\recent' ],
        'rfc822.size' => 110
      }
    };

A couple of points to note:

1. The message IDs have been turned into a hash from message ID to fetch
response result.
2. The response items (e.g. uid, flags, etc) have been turned into a hash for
each message, and also changed to lower case values.
3. Other bracketed (...) lists have become array references.

In general, this is how all fetch responses are parsed.
There is one major difference however when the IMAP connection
is in 'uid' mode. In this case, the message IDs in the main hash are changed
to message UIDs, and the 'uid' entry in the inner hash is removed. So the
above example would become:

    my $Res = $IMAP->fetch('1:*', '(flags rfc822.size)');

    $Res = {
      1952 => {
        'flags' => [ '\\recent', '\\seen' ],
        'rfc822.size' => 1150
      },
      1958 => {
        'flags' => [ '\\recent' ],
        'rfc822.size' => 110
      }
    };

## Bodystructure

When dealing with messages, we need to understand the MIME structure of
the message, so we can work out what is the text body, what is attachments,
etc. This is where the 'bodystructure' item from an IMAP server comes in.

    C: a101 fetch 1 (bodystructure)
    S: * 1 fetch (BODYSTRUCTURE ("TEXT" "PLAIN" NIL NIL NIL "QUOTED-PRINTABLE" 255 11 NIL ("INLINE" NIL) NIL))
    S: a101 OK Completed

The fetch command can be sent by calling:

    my $Res = $IMAP->fetch(1, 'bodystructure');

As expected, the resultant response would look like this:

    $Res = {
      1 => {
        'bodystructure' => [
          'TEXT', 'PLAIN', undef, undef, undef, 'QUOTED-PRINTABLE',
            255, 11, UNDEF, [ 'INLINE', undef ], undef
        ]
      }
    };

However, if you set the `parse_mode(BodyStructure =` 1)>, then the result would be:

    $Res = {
      '1' => {
        'bodystructure' => {
          'MIME-Type' => 'text',
          'MIME-Subtype' => 'plain',
          'MIME-TxtType' => 'text/plain',
          'Content-Type' => {},
          'Content-ID' => undef,
          'Content-Description' => undef,
          'Content-Transfer-Encoding' => 'QUOTED-PRINTABLE',
          'Size' => '3569',
          'Lines' => '94',
          'Content-MD5' => undef,
          'Disposition-Type' => 'inline',
          'Content-Disposition' => {},
          'Content-Language' => undef,
          'Remainder' => [],
          'IMAP-Partnum' => ''
        }
      }
    };

A couple of points to note here:

1. All the positional fields from the bodystructure list response
have been turned into nicely named key/value hash items.
2. The MIME-Type and MIME-Subtype fields have been made lower case.
3. An IMAP-Partnum item has been added. The value in this field can
be passed as the 'section' number of an IMAP body fetch call to
retrieve the text of that IMAP section.

In general, the following items are defined for all body structures:

- MIME-Type
- MIME-Subtype
- Content-Type
- Disposition-Type
- Content-Disposition
- Content-Language

For all bodystructures EXCEPT those that have a MIME-Type of 'multipart',
the following are defined:

- Content-ID
- Content-Description
- Content-Transfer-Encoding
- Size
- Content-MD5
- Remainder
- IMAP-Partnum

For bodystructures where MIME-Type is 'text', an extra item 'Lines'
is defined.

For bodystructures where MIME-Type is 'message' and MIME-Subtype is 'rfc822', the
extra items 'Message-Envelope', 'Message-Bodystructure' and 'Message-Lines'
are defined. The 'Message-Bodystructure' item is itself a reference
to an entire bodystructure hash with all the format information of the
contained message. The 'Message-Envelope' item is a hash structure with
the message header information. See the **Envelope** entry below.

For bodystructures where MIME-Type is 'multipart', an extra item 'MIME-Subparts' is
defined. The 'MIME-Subparts' item is an array reference, with each item being a
reference to an entire bodystructure hash with all the format information
of each MIME sub-part.

For further processing, you can use the **find\_message()** function.
This will analyse the body structure and find which part corresponds
to the main text/html message parts to display. You can also use
the **find\_cid\_parts()** function to find CID links in an html
message.

## Envelope

The envelope structure contains most of the addressing header fields from
an email message. The following shows an example envelope fetch (the
response from the IMAP server has been neatened up here)

    C: a102 fetch 1 (envelope)
    S: * 1 FETCH (ENVELOPE
        ("Tue, 7 Nov 2000 08:31:21 UT"      # Date
         "FW: another question"             # Subject
         (("John B" NIL "jb" "abc.com"))    # From
         (("John B" NIL "jb" "abc.com"))    # Sender
         (("John B" NIL "jb" "abc.com"))    # Reply-To
         (("Bob H" NIL "bh" "xyz.com")      # To
          ("K Jones" NIL "kj" "lmn.com"))
         NIL                                # Cc
         NIL                                # Bcc
         NIL                                # In-Reply-To
         NIL)                               # Message-ID
       )
    S: a102 OK Completed

The fetch command can be sent by calling:

    my $Res = $IMAP->fetch(1, 'envelope');

And you get the idea of what the resultant response would be. Again
if you change `parse_mode(Envelope =` 1)>, you get a neat structure as follows:

    $Res = {
      '1' => {
        'envelope' => {
          'Date' => 'Tue, 7 Nov 2000 08:31:21 UT',
          'Subject' => 'FW: another question',
          'From' => '"John B" <jb@abc.com>',
          'Sender' => '"John B" <jb@abc.com>',
          'Reply-To' => '"John B" <jb@abc.com>',
          'To' => '"Bob H" <bh@xyz.com>, "K Jones" <kj@lmn.com>',
          'Cc' => '',
          'Bcc' => '',
          'In-Reply-To' => undef,
          'Message-ID' => undef,

          'From-Raw' => [ [ 'John B', undef, 'jb', 'abc.com' ] ],
          'Sender-Raw' => [ [ 'John B', undef, 'jb', 'abc.com' ] ],
          'Reply-To-Raw' => [ [ 'John B', undef, 'jb', 'abc.com' ] ],
          'To-Raw' => [
            [ 'Bob H', undef, 'bh', 'xyz.com' ],
            [ 'K Jones', undef, 'kj', 'lmn.com' ],
          ],
          'Cc-Raw' => [],
          'Bcc-Raw' => [],
        }
      }
    };

All the fields here are from straight from the email headers.
See RFC 822 for more details.

## Annotation

If the server supports RFC 5257 (ANNOTATE Extension), then you can
fetch per-message annotations.

Annotation responses would normally be returned as a a nested set of
arrays. However it's much easier to access the results as a nested set
of hashes, so the results are so converted if the Annotation parse
mode is enabled, which is on by default.

Part of an example from the RFC

    S: * 12 FETCH (UID 1123 ANNOTATION
       (/comment (value.priv "My comment"
          size.priv "10")
       /altsubject (value.priv "Rhinoceroses!"
          size.priv "13")

So the fetch command:

    my $Res = $IMAP->fetch(1123, 'annotation', [ '/*', [ 'value.priv', 'size.priv' ] ]);

Would have the result:

    $Res = {
      '1123' => {
        'annotation' => {
          '/comment' => {
            'value.priv' => 'My comment',
            'size.priv => 10
          },
          '/altsubject' => {
            'value.priv' => '"Rhinoceroses',
            'size.priv => 13
          }
        }
      }
    }
           

# INTERNAL METHODS

- _\_imap\_cmd($Command, $IsUidCmd, $RespItems, @Args)_

    Executes a standard IMAP command.

- _Method arguments_
    - **$Command**

        Text string of command to call IMAP server with (e.g. 'select', 'search', etc).

    - **$IsUidCmd**

        1 if command involved message ids and can be prefixed with UID, 0 otherwise.

    - **$RespItems**

        Responses to look for from command (eg 'list', 'fetch', etc). Commands
        which return results usually return them untagged. The following is an
        example of fetching flags from a number of messages.

            C123 uid fetch 1:* (flags)
            * 1 FETCH (FLAGS (\Seen) UID 1)
            * 2 FETCH (FLAGS (\Seen) UID 2)
            C123 OK Completed

        Between the sending of the command and the 'OK Completed' response,
        we have to pick up all the untagged 'FETCH' response items so we
        would pass 'fetch' (always use lower case) as the $RespItems to extract.

        This can also be a hash ref of callback functions. See \_parse\_response
        for more examples

    - **@Args**

        Any extra arguments to pass to command.
- _\_send\_cmd($Self, $Cmd, @InArgs)_

    Helper method used by the **\_imap\_cmd** method to actually build (and
    quote where necessary) the command arguments and then send the
    actual command.

- _\_send\_data($Self, $Opts, $Buffer, @Args)_

    Helper method used by the **\_send\_cmd** method to actually build (and
    quote where necessary) the command arguments and then send the
    actual command.

- _\_parse\_response($Self, $RespItems, \[ \\%ParseMode \])_

    Helper method called by **\_imap\_cmd** after sending the command. This
    methods retrieves data from the IMAP socket and parses it into Perl
    structures and returns the results.

    $RespItems is either a string, which is the untagged response(s)
    to find and return, or for custom processing, it can be a
    hash ref.

    If a hash ref, then each key will be an untagged response to look for,
    and each value a callback function to call for the corresponding untagged
    response.

    Each callback will be called with 2 or 3 arguments; the untagged
    response string, the remainder of the line parsed into an array ref, and
    for fetch type responses, the id will be passed as the third argument.

    One other piece of magic, if you pass a 'responseitem' key, then the
    value should be a string, and will be the untagged response returned
    from the function

- _\_require\_capability($Self, $Capability)_

    Helper method which checks that the server has a certain capability.
    If not, it sets the internal last error, $@ and returns undef.

- _\_trace($Self, $Line)_

    Helper method which outputs any tracing data.

- _\_is\_current\_folder($Self, $FolderName)_

    Return true if a folder is currently selected and that
    folder is $FolderName

# INTERNAL SOCKET FUNCTIONS

- _\_next\_atom($Self)_

    Returns the next atom from the current line. Uses $Self->{ReadLine} for
    line data, or if undef, fills it with a new line of data from the IMAP
    connection socket and then begins processing.

    If the next atom is:

    - An unquoted string, simply returns the string.
    - A quoted string, unquotes the string, changes any occurances
    of \\" to " and returns the string.
    - A literal (e.g. {NBytes}\\r\\n), reads the number of bytes of data
    in the literal into a scalar or file (depending on `literal_handle_control`).
    - A bracketed structure, reads all the sub-atoms within the structure
    and returns an array reference with all the sub-atoms.

    In each case, after parsing the atom, it removes any trailing space separator,
    and then returns the remainder of the line to $Self->{ReadLine} ready for the
    next call to `_next_atom()`.

- _\_next\_simple\_atom($Self)_

    Faster version of \_next\_atom() for known simple cases

- _\_remaining\_atoms($Self)_

    Returns all the remaining atoms for the current line in the read line
    buffer as an array reference. Leaves $Self->{ReadLine} eq ''.
    See `_next_atom()`

- _\_remaining\_line($Self)_

    Returns the remaining data in the read line buffer ($Self->{ReadLine}) as
    a scalar string/data value.

- _\_fill\_imap\_read\_buffer($Self)_

    Wait until data is available on the IMAP connection socket (or a timeout
    occurs). Read the data into the internal buffer $Self->{ReadBuf}. You
    can then use `_imap_socket_read_line()`, `_imap_socket_read_bytes()`
    or `_copy_imap_socket_to_handle()` to read data from the buffer in
    lines or bytes at a time.

- _\_imap\_socket\_read\_line($Self)_

    Read a \\r\\n terminated list from the buffered IMAP connection socket.

- _\_imap\_socket\_read\_bytes($Self, $NBytes)_

    Read a certain number of bytes from the buffered IMAP connection socket.

- _\_imap\_socket\_out($Self, $Data)_

    Write the data in $Data to the IMAP connection socket.

- _\_copy\_handle\_to\_imapsocket($Self, $InHandle)_

    Copy a given number of bytes from a file handle to the IMAP connection

- _\_copy\_imap\_socket\_to\_handle($Self, $OutHandle, $NBytes)_

    Copies data from the IMAP socket to a file handle. This is different
    to \_copy\_handle\_to\_imap\_socket() because we internally buffer the IMAP
    socket so we can't just use it to copy from the socket handle, we
    have to copy the contents of our buffer first.

    The number of bytes specified must be available on the IMAP socket,
    if the function runs out of data it will 'die' with an error.

- _\_quote($String)_

    Returns an IMAP quoted version of a string. This place "..." around the
    string, and replaces any internal " with \\".

# INTERNAL PARSING FUNCTIONS

- _\_parse\_list\_to\_hash($ListRef, $Recursive)_

    Parses an array reference list of ($Key, $Value) pairs into a hash.
    Makes sure that all the keys are lower cased (lc) first.

- _\_fix\_folder\_name($FolderName, %Opts)_

    Changes a folder name based on the current root folder prefix as set
    with the `set_root_prefix()` call.

        Wildcard => 1 = a folder name with % or * is left alone
        NoEncoding => 1 = don't do modified utf-7 encoding, leave as unicode

- _\_fix\_folder\_encoding($FolderName)_

    Encode folder name using IMAP-UTF-7

- _\_unfix\_folder\_name($FolderName)_

    Unchanges a folder name based on the current root folder prefix as set
    with the `set_root_prefix()` call.

- _\_fix\_message\_ids($MessageIds)_

    Used by IMAP commands to handle a number of different ways that message
    IDs can be specified.

- _Method arguments_

    - **$MessageIds**

        String or array ref which specified the message IDs or UIDs.

    The $MessageIds parameter may take the following forms:

    - **array ref**

        Array is turned into a string of comma separated ID numbers.

    - **1:\***

        Normally a \* would result in the message ID string being quoted.
        This ensure that such a range string is not quoted because some
        servers (e.g. cyrus) don't like.

- _\_parse\_email\_address($EmailAddressList)_

    Converts a list of IMAP email address structures as parsed and returned
    from an IMAP fetch (envelope) call into a single RFC 822 email string
    (e.g. "Person 1 Name" <ename@ecorp.com>, "Person 2 Name" <...>, etc) to
    finally return to the user.

    This is used to parse an envelope structure returned from a fetch call.

    See the documentation section 'FETCH RESULTS' for more information.

- _\_parse\_envelope($Envelope, $IncludeRaw, $DecodeUTF8)_

    Converts an IMAP envelope structure as parsed and returned from an
    IMAP fetch (envelope) call into a convenient hash structure.

    If $IncludeRaw is true, includes the XXX-Raw fields, otherwise
    these are left out.

    If $DecodeUTF8 is true, then checks if the fields contain
    any quoted-printable chars, and decodes them to a Perl UTF8
    string if they do.

    See the documentation section 'FETCH RESULTS' from more information.

- _\_parse\_bodystructure($BodyStructure, $IncludeRaw, $DecodeUTF8, $PartNum)_

    Parses a standard IMAP body structure and turns it into a Perl friendly
    nested hash structure. This routine is recursive and you should not
    pass a value for $PartNum when called for the top level bodystructure
    item.  Note that this routine destroys the array reference structure
    passed in as $BodyStructure.

    See the documentation section 'FETCH RESULTS' from more information

- _\_parse\_fetch\_annotation($AnnotateItem)_

    Takes the result from a single IMAP annotation item
    into a Perl friendly structure. 

    See the documentation section 'FETCH RESULTS' from more information.

- _\_parse\_fetch\_result($FetchResult)_

    Takes the result from a single IMAP fetch response line and parses it
    into a Perl friendly structure. 

    See the documentation section 'FETCH RESULTS' from more information.

- _\_parse\_header\_result($HeaderResults, $Value, $FetchResult)_

    Take a body\[header.fields (xyz)\] fetch response and parse out the
    header fields and values

- _\_decode\_utf8($Value)_

    Decodes the passed quoted printable value to a Perl Unicode string.

- _\_expand\_sequence(@Sequences)_

    Expand a list of IMAP id sequences into a full list of ids

# PERL METHODS

- _DESTROY()_

    Called by Perl when this object is destroyed. Logs out of the
    IMAP server if still connected.

# SEE ALSO

_Net::IMAP_, _Mail::IMAPClient_, _IMAP::Admin_, RFC 3501

Latest news/details can also be found at:

http://cpan.robm.fastmail.fm/mailimaptalk/

Available on github at:

[https://github.com/robmueller/mail-imaptalk/](https://github.com/robmueller/mail-imaptalk/)

# AUTHOR

Rob Mueller <cpan@robm.fastmail.fm>. Thanks to Jeremy Howard
&lt;j+daemonize@howard.fm> for socket code, support and
documentation setup.

# COPYRIGHT AND LICENSE

Copyright (C) 2003-2016 by FastMail Pty Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
