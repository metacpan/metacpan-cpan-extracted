#
#	Cclient.pm
#
#	Copyright (c) 1998,1999,2000 Malcolm Beattie
#
#	You may distribute under the terms of either the GNU General Public
#	License or the Artistic License, as specified in the README file.
# 

package Mail::Cclient;
use DynaLoader;
use Exporter;
use strict;
use vars qw($VERSION @ISA @EXPORT_OK %_callback);

$VERSION = "1.1";
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(set_callback get_callback
		rfc822_base64 rfc822_qprint rfc822_date);

=head1 NAME

Mail::Cclient - Mailbox access via the c-client library API

=head1 SYNOPSIS

    use Mail::Cclient;
    $c = Mail::Cclient->new(MAILBOX [, OPTION ...]);

    ($envelope, $body) = $c->fetchstructure(MSGNO [, FLAG ...] );
    $hdr = $c->fetchheader(MSGNO [, FLAG ...]);
    $text = $c->fetchtext(MSGNO [, FLAG ..i]);
    $text = $c->fetchbody(MSGNO, SECTION, [, FLAG ...]);
    $elt = $c->elt(MSGNO);

    $c->create(MAILBOX);
    $c->delete(MAILBOX);
    $c->rename(OLDNAME, NEWNAME);
    $c->open(MAILBOX);

    $nmsgs = $c->nmsgs;

    Mail::Cclient::set_callback KEY => CODE, ...
    $c->list(REF, PAT);			# uses "list" callback
    $c->scan(REF, PAT, CONTENTS);
    $c->lsub(REF, PAT);
    $c->subscribe(MAILBOX);
    $c->unsubscribe(MAILBOX);
    $c->status(MAILBOX [, FLAG ...]);	# uses "status" callback

    $c->copy(SEQUENCE, MAILBOX [, FLAG ...]);
    $c->move(SEQUENCE, MAILBOX [, FLAG ...]);
    $c->append(MAILBOX, MESSAGE [, DATE [, FLAGS]);

    $c->search(CRITERIA);		# uses "search" callback

    $c->ping;
    $c->check;				# uses "log" callback
    $c->expunge;			# uses "expunge" callback
    $uid = $c->uid(MSGNO);
    $c->setflag(SEQUENCE, MAILFLAG [, FLAG ...]);
    $c->clearflag(SEQUENCE, MAILFLAG [, FLAG ...]);

    $c->fetchfast(SEQUENCE);
    $c->fetchflags(SEQUENCE);

    $c->gc( [FLAG, ...] );
    $c->debug;
    $c->nodebug;
    $c->set_sequence(SEQUENCE);
    $c->uid_set_sequence(SEQUENCE);
    $result = $c->parameters(PARAM);
    $c->parameters(PARAM1 => NEWVALUE1 [, PARAM2 => NEWVALUE2 ...]);

    $text = Mail::Cclient::rfc822_base64(SOURCE);
    $text = Mail::Cclient::rfc822_qprint(SOURCE);

    $c->close;

=head1 DESCRIPTION

C<Mail::Cclient> gives access to mailboxes in many different formats
(including remote IMAP folders) via the c-client API. The c-client
library is the core library used by Pine and the University of
Washington IMAP daemon (written by Mark Crispin).

The Perl API is mostly taken directly from the underlying c-client
library with minor adjustments in places where Perl provides a more
natural interface. The primary interface is an object oriented one
via the C<Mail::Cclient> class but certain methods implicitly use
callbacks set via the set_callback function.

The c-client library often provides a given piece of functionality by
two different function names: one for simple usage under a name of the
form C<mail_foo> and one with an additional flags arguments under a
name of the form C<mail_foo_full>. The corresponding functionality is
available from the Perl C<Mail::Cclient> class under the single name
C<foo>.

Setting a flag bit such as C<FT_UID> in the c-client API is done in
Perl by appending an extra argument C<"uid"> to the method call.

Arguments to c-client functions which are there only to pass or
receive the length of a string argument or result are not present in
the Perl API since Perl handles them automatically.

Some methods take arguments which refer to a message or messages in a
mailbox. An argument denoted MSGNO is a number that refers to a single
message. Message 1 refers to the first message in the mailbox, unless
the "uid" option is passed as as additional argument in which case the
number refers to the uid of the message. An argument denoted SEQUENCE
refers to a list of messages and is a string such as '1,3,5-9,12'. 

Creating a C<Mail::Cclient> object and associating a mailstream with it
is done with the C<"new"> constructor method (whereas the underlying
c-client library uses the C<mail_open> function).

=over

=item new(MAILBOX [, OPTION ...])

The MAILBOX argument can be anything accepted by the underlying
c-client library. This includes the following forms

=over

=item the special string "INBOX"

This is the driver-dependent INBOX folder.

=item an absolute filename

This specifies a mailbox in the default format 
(usually Berkeley format for most default library builds)

=item a string of the form "{host}folder" or "{host/prot}folder"

These refer to an IMAP folder held on host. The "folder"
part can be "INBOX" to reference the distinguished INBOX folder that
the IMAP protocol defines. The username and password required for
logging in to the IMAP server are obtained by using the "login"
callback (q.v.).

=item a string of the form "#driver.foo/bar/baz"

This refers to folder "/bar/baz" which is held in a non-default
mailbox format handled by the c-client driver "foo" (e.g. "mbx").

=back

The options which can be passed to the C<new> are as follows
(taken almost verbatim from the c-client Internal.doc file):

=over

=item debug

Log IMAP protocol telemetry through "debug" callback (q.v.).

=item readonly

Open mailbox read-only.

=item anonymous

Don't use or update a .newsrc file for news.

=item shortcache

Don't cache envelopes or body structures.

=item prototype 

Return the "prototype stream" for the driver associated with
this mailbox instead of opening the stream.

=item halfopen

For IMAP and NNTP names, open a connection to the server but
don't open a mailbox.

=item expunge

Silently expunge the oldstream before recycling.

=back

You can use the method

=over

=item open(MAILBOX)

=back

to get the mailstream object to open a different mailbox. The cclient
library will try to reuse the same IMAP connection where possible in
the case of IMAP mailboxes but the host part of the mailbox spec must
be given exactly as in the original connection for this to work.


Read-only access to the fields of the underlying mailstream
of a C<Mail::Cclient> object is supplied by the following methods:

=over

=item nmsgs

Returns the number of messages in the mailbox.

=item mailbox

Returns the mailbox name.

=item rdonly

Stream is open read-only.

=item anonymous

Stream is open with anonymous access.

=item halfopen

Stream is half-open; it can be reopened or used for functions that
don't need a open mailbox such as $c->create() but no message data
can be fetched.

=item perm_seen, perm_deleted, perm_flagged, perm_answered, perm_draft

The relevant flag can be set permanently.

=item kwd_create

New user flags can be created by referencing them in setflag or
clearflag method calls. This can change during a session (e.g. if
there is a limit).

=item perm_user_flags

Returns a list of the user flags which can be set permanently.

=item recent

Number of recent messages in current mailbox.

=item uid_validity

The UID validity value.

=item uid_last

The highest currently assigned UID in the current mailbox.

=back

The following methods are for creating/deleting/renaming folders.

=over

=item create(MAILBOX)

=item delete(MAILBOX)

=item rename(OLDNAME, NEWNAME)

=back

The following methods provide access to messages themselves: their
headers, structures and the text of their bodies (or parts thereof).

=over

=item fetchstructure(MSGNO [, FLAG ...] )

This returns the equivalent of what c-client calls an ENVELOPE
structure for message MSGNO. If called in an array context then
the equivalent of a BODY structure is passed as a second return
value. The ENVELOPE structure is in the form of a Perl object of
class C<Mail::Cclient::Envelope>. The BODY structure is in the
form of a Perl object of class C<Mail::Cclient::Body>. See later
on for the description of these objects. The FLAG "uid" can be
passed which makes the MSGNO argument be interpreted as a
message uid.

=item fetchheader(MSGNO [, LINES [, FLAG ...]])

This returns the header text (as a single string) of message MSGNO
(which is interpreted as a message uid if the flag "uid" is included).
With no LINES argument, all headers are put into the string. If an
array ref argument is passed then it is taken to be a reference to a
list of header names. Those headers are the ones that are included in
the result, unless the flag "not" is passed in which case all headers
are included except those in the list. The flag "internal" can be
passed to avoid canonicalising the header texts. The flag
"prefetchtext" can be passed to pre-fetch the RFC822.TEXT part of the
message at the same time.

=item fetchtext(MSGNO [, FLAG ...])

This returns the body of message MSGNO (a message uid if the flag
"uid" is included). The whole body is returned as a single string
with no MIME processing done. Line endings are canonicalised to CRLF
unless the "internal" flag is included. If the "peek" flag is
included then the \Seen flag is not actively set (though it may
already have been set previously, of course).

=item fetchbody(MSGNO, SECTION, [, FLAG ...])

This returns a single (MIME) section of message MSGNO (a message uid
if the flag "uid" is included). The SECTION argument determines which
section is returned and is a string in the form of a dot-separated
list of numbers. See the IMAP specification for details. As an
example, a multipart/mixed MIME message has sections "1", "2", "3"
and so on. If section "3" is multipart/mixed itself, then it has
subsections "3.1", "3.2" and so on. The "peek" and "internal" flags
may also be passed and have the same effect as in C<fetchtext>
documented above.

=item elt(MSGNO)

This returns the MESSAGECACHE (commonly known as "elt") information
associated with message MSGNO as an object in class Mail::Cclient::Elt.
See below for what such an object contains. B<Important note>: for
this method to be valid, a previous C<fetchstructure> or C<fetchflags>
B<must> have been called on this message. Otherwise, you are into the
realms of undefined behaviour and at the mercy of the underlying
c-client library.

=back

A message may be copied or moved into another mailbox with the
methods C<copy> and C<move>. These methods only allow the
destination mailbox to be of the same type as (and on the same
host as) the mailstream object on which the methods are called.

=over

=item copy(MSGNO, MAILBOX [, FLAGS])

This copies message MSGNO (a message uid if the "uid" flag is
included) to mailbox MAILBOX. If the "move" flag is included
then the message is actually moved instead (for compatibility
with the CP_MOVE flag of the underlying c-client
C<mail_copy_full> function).

=item move(MSGNO, MAILBOX [, FLAGS])

This moved message MSGNO (a message uid if the "uid" flag is
included) to mailbox MAILBOX.

=item append(MAILBOX, MESSAGE [, DATE [, FLAGS])

Append a raw message (MESSAGE is an ordinary string) to MAILBOX,
giving it an optional date and FLAGS (again, simply strings).

=item search(CRITERIA)

Search for messages satisfying CRITERIA. The "search" callback (q.v.)
is called for each matching message. CRITERIA is a string containing
a search specification as defined on pages 15-16 of RFC1176. Note
that this is an IMAP2 search specification--this method does not
support the more advanced IMAP4rev1 search specification.

=back

The following methods provide access to information about mailboxes.

=over

=item status(MAILBOX [, FLAG ...])

This method provides status information about MAILBOX. The
information calculated is limited to those mentioned in FLAG
arguments and is returned via the "status" callback (q.v.).
The FLAG arguments possible are precisely those mentioned in
the documentation below for the "status" callback.

=back

The following are miscellaneous methods.

=over

=item

=item ping

Checks where the mailstream is still alive: used as a keep-alive
and to check for new mail.

=item check

Performs a (driver-dependent) checkpoint of the mailstream
(B<not> a check for new mail). Information about the checkpoint
is passed to the "log" callback (q.v.).

=item expunge

Expunges all message marked as deleted in the mailbox. Calls the
"expunged" callback (q.v.) on each such message and logging information
is passed to the "log" callback. Decrementing message numbers happens
after each and every message is expunged. As the example in the
c-client documentation for mail_expunge says, if three consecutive
messages starting at msgno 5 are expunged, the "expunged" callback
will be called with a msgno of 5 three times.

=item uid(MSGNO)

Returns the uid associated with message MSGNO.

=item setflag(SEQUENCE, MAILFLAG [, FLAG ...])

Sets flag MAILFLAG on each message in SEQUENCE (taken to be a
sequence of message uids if the "uid" flag is passed). The "silent"
flag causes the local cache not to be updated.

=item clearflag(SEQUENCE, MAILFLAG [, FLAG ...]);

Clears flag MAILFLAG from each message in SEQUENCE (taken to be a
sequence of message uids if the "uid" flag is passed). The "silent"
flag causes the local cache not to be updated.

=item gc( [FLAG, ...] )

Garbage collects the cache for the mailstream. The FLAG arguments,
"elt", "env", "texts", determine what is garbage collected.

=item debug

Enables debugging for the mailstream, logged via the "dlog"
callback (q.v.).

=item nodebug

Disables debugging for the mailstream.

=item set_sequence(SEQUENCE)

Sets the sequence bit for each message in SEQUENCE (and turns it off
for all other messages). This has been renamed for Perl from the
underlying c-client function C<mail_sequence> to avoid clashing with
the sequence field member of the mailstream object.

=item uid_set_sequence(SEQUENCE)

Sets the sequence bit for each message referenced by uid in SEQUENCE
(and turns it off for all other messages). This has been renamed for
Perl from the underlying c-client function C<mail_uid_sequence> for
consistency with C<set_sequence> above.

=item parameters(PARAM [, => NEWVALUE [, PARAM2 => NEWVALUE2 ...]])

With a single argument, gets the current value of parameter PARAM.
With one or more pairs of PARAM => VALUE arguments, sets those PARAM
values to the given new values. PARAM can be one of the following
strings: USERNAME, HOMEDIR, LOCALHOST, SYSINBOX, OPENTIMEOUT,
READTIMEOUT, WRITETIMEOUT, CLOSETIMEOUT, RSHTIMEOUT, MAXLOGINTRIALS,
LOOKAHEAD, IMAPPORT, PREFETCH, CLOSEONERROR, POP3PORT, UIDLOOKAHEAD,
MBXPROTECTION, DIRPROTECTION, LOCKPROTECTION, FROMWIDGET, NEWSACTIVE,
NEWSSPOOL, NEWSRC, DISABLEFCNTLLOCK, LOCKEACCESERROR, LISTMAXLEVEL,
ANONYMOUSHOME.

=back

The following are utility functions (not methods).

=over

=item Mail::Cclient::rfc822_base64(SOURCE)

Returns the SOURCE text converted to base64 format.

=item Mail::Cclient::rfc822_qprint(SOURCE)

Returns the SOURCE text converted to quoted printable format.

=item Mail::Cclient::rfc822_date()

Returns the current date in RFC822 format.

=back

=head1 CALLBACKS

Certain methods mentioned above use callbacks to pass or receive extra
information. Each callback has a particular name (e.g. "log", "dlog",
"list", "login") and can be associated with a particular piece of Perl
code via the C<Mail::Cclient::set_callback> function (available for
export by the C<Mail::Cclient> class). The C<set_callback> function
takes pairs of arguments NAME, CODE for setting callback NAME to be
the given CODE, a subroutine reference. The only callback which is
required to be set and the only callback whose return value matters is
the "login" callback (only used when the "new" method constructs an
IMAP mailstream). Apart from that case, callbacks which have not been
set are ignored. A callback set to undef is also ignored.

=over

=item searched(STREAM, MSGNO)

This callback is invoked for each message number satifying the
CRITERIA of the "search" method, defined above.

=item exists(STREAM, MSGNO)

=item expunged(STREAM, MSGNO)

=item flags(STREAM, MSGNO)

=item notify(STREAM, STRING, ERRFLAG)

=item list(STREAM, DELIMITER, MAILBOX [, ATTR ...])

=item lsub(STREAM, DELIMITER, MAILBOX [, ATTR ...])

=item status(STREAM, MAILBOX, [, ATTR, VALUE] ...)

Attribute values passed can be "messages", "recent", "unseen",
"uidvalidity", "uidnext".

=item log(STRING, ERRFLAG)

=item dlog(STRING)

=item fatal(STRING)

=item login(NETMBXINFO, TRIAL)

The "login" callback is invoked when the c-client library is
opening an IMAP mailstream and needs to find out the username
and password required. This callback must return precisely two
values in the form (USERNAME, PASSWORD). TRIAL is the number of
the current login attempt (starting at 1). NETMBXINFO is a hash
reference with the following keys:

=over

=item host

The hostname of the IMAP server.

=item user

The username requested.

=item mailbox

The mailbox name requested.

=item service

=item port

=item anoflag

Set to 1 if anonymous access has been requested otherwise this
key is not created at all.

=item dbgflag

Set to 1 if debugging access has been requested otherwise this
key is not created at all.

=back

=item critical(STREAM)

=item nocritical(STREAM)

=item diskerror(STREAM, ERRCODE, SERIOUS)

=back

=head1 ENVELOPES, BODIES, ADDRESSES and ELTS

The results of the C<fetchstructure> and C<elt> methods involve
objects in the classes C<Mail::Cclient::Envelope>,
C<Mail::Cclient::Body>, C<Mail::Cclient::Address> and C<Mail::Cclient::Elt>.
These will be referred to as Envelope, Body, Address and Elt objects
respectively. These objects are all "read-only" and only have methods
for picking out particular fields.

=head2 Address objects

An Address object represents a single email address and has the
following fields, available as methods or, if Perl 5.005 or later
is being used, as pseudo-hash keys.

=over

=item personal

The personal phrase of the address (i.e. the part contained in
parentheses or outside the angle brackets).

=item adl

The at-domain-list or source route (not usually used).

=item mailbox

The mailbox name (i.e. the part before the @ which is usually
a username or suchlike).

=item host

The hostname (i.e. the part after the @).

=item error

Only set if the address has delivery errors when C<smtp_mail> is
called. Since that function hasn't been implemented in the Perl
module yet, this isn't any use.

=back

=head2 Envelope objects

An Envelope object represents a structured form of the header of
a message. It has the following fields, available as methods or,
if Perl 5.005 or later is being used, as pseudo-hash keys.

=over

=item remail, date, subject, in_reply_to, message_id,
newsgroups, followup_to, references,

These are all strings.

=item return_path, from, sender, reply_to, to, cc, bcc

These are all references to lists which contain one or more
Address objects.

=back

=head2 Body objects

A Body object represents the structure of a message body (not
its contents).It has the following fields, available as methods
or, if Perl 5.005 or later is being used, as pseudo-hash keys.

=over

=item type

The MIME type (as a string) of the message (currently in
uppercase as returned from the c-client library). For example,
"TEXT" or "MULTIPART".

=item encoding

The MIME encoding (as a string) of the message.

=item subtype

The MIME subtype (as a string) of the message. For example,
"PLAIN", "HTML" or "MIXED".

=item parameter

A reference to a list of MIME parameter key/value pairs.

=item id

The message ID.

=item description

The MIME description of the body part.

=item nested

If (and only if) the body is of MIME type multipart, then this
field is a reference to a list of Body objects, each representing
one of the sub parts of the message. If (and only if) the body is
of MIME type message/rfc822, then this field is a reference to a list
of the form (ENVELOPE, BODY) which are, respectively, the Body and
Envelope objects referring to the encapsulated message. If the
message is not of MIME type multipart or message/rfc822 then this
field is undef.

=item lines

The size in lines of the body.

=item bytes

The size in bytes of the body.

=item md5

The MD5 checksum of the body.

=item disposition

The content disposition of the body: a reference to a list
consisting of the disposition type followed by a (possibly empty)
list of parameter key/value pairs.

=back

=head2 Elt objects

These have fields containing flag information for a given message,
along with internal date information and the RFC822 message size.

=over

=item msgno

The message number.

=item date

This contains the internal date information (spread about a series of
bitfields in the underlying c-client library C structure) in the form
of a string:

    yyyy-mm-dd hh:mm:ss [+-]hhmm

=item flags

A reference to a list of flags associated with the message. The flags
are in the forms of their RFC2060 names (e.g. \Deleted, \Seen) for
official flags and the user-chosen name for user-defined flags.

=item rfc822_size

The RFC822 size of the message.

=back

=head1 CAVEATS

This CAVEATS section was contributed by Bruce Gingery
<bgingery@gtcs.com>.

The Mail::Cclient::B<mailbox> method returns the actual full path
opened, which may not give an accurate string comparison with
the mailbox that was requested to be opened.  This is especially
true with remote mailboxes.

The C-Client library is VERY intolerant of logic errors, and
does not automatically garbage collect.  Use the C<gc> method
as it makes sense for your application.

Some POP3 servers B<delete and expunge WITHOUT instruction to 
do so.>  This is not a malfunction in either the C-Client code
nor the Mail::Cclient modules.

The C<open> method can be used to extend a C<halfopen>
connection (e.g. use the same c-client instance to read
a mailbox that was previously halfopened for a list of
mailboxes.  This may or may not be a good idea, depending
upon your needs.  It does, however, eliminate the problem
of opening multiple connections, such as has been noted in 
Netscape 4.x mail handling, and which plagues some servers
badly.  It may be better, however, to C<close> the connection
used for C<list>, and re-instantiate to process the mailbox.

C-Client may not support headers you need for send.  Note
that other modules I<can> be used in place of sending with
the c-client.  These include Net::SMTP, local invocation of 
piped sendmail (or other E-mail insertion software), or 
sendto: URLs under libwww POST.

C<Elt> information for remote mailboxes is server dependent,
as well.  You may or may not get rfc822_size in elt returns,
for example.

Multiple c-client instances open simultaneously may not
work as expected.

=head1 AUTHOR

Malcolm Beattie, mbeattie@sable.ox.ac.uk.

=cut

{
    package Mail::Cclient::Address;
    use vars qw(%FIELDS);

    %FIELDS = (personal => 1,
	       adl => 2,
	       mailbox => 3,
	       host => 4,
	       error => 5);
    sub personal { shift->[1] }
    sub adl { shift->[2] }
    sub mailbox { shift->[3] }
    sub host { shift->[4] }
    sub error { shift->[5] }
}

{
    package Mail::Cclient::Body;
    use vars qw(%FIELDS);

    %FIELDS = (type => 1,
	       encoding => 2,
	       subtype => 3,
	       parameter => 4,
	       id => 5,
	       description => 6,
	       nested => 7,
	       lines => 8,
	       bytes => 9,
	       md5 => 10,
	       disposition => 11);
    sub type { shift->[1] }
    sub encoding { shift->[2] }
    sub subtype { shift->[3] }
    sub parameter { shift->[4] }
    sub id { shift->[5] }
    sub description { shift->[6] }
    sub nested { shift->[7] }
    sub lines { shift->[8] }
    sub bytes { shift->[9] }
    sub md5 { shift->[10] }
    sub disposition { shift->[11] }
}

{
    package Mail::Cclient::Envelope;
    use vars qw(%FIELDS);

    %FIELDS = (remail => 1,
	       return_path => 2,
	       date => 3,
	       from => 4,
	       sender => 5,
	       reply_to => 6,
	       subject => 7,
	       to => 8,
	       cc => 9,
	       bcc => 10,
	       in_reply_to => 11,
	       message_id => 12,
	       newsgroups => 13,
	       followup_to => 14,
	       references => 15);
    sub remail { shift->[1] }
    sub return_path { shift->[2] }
    sub date { shift->[3] }
    sub from { shift->[4] }
    sub sender { shift->[5] }
    sub reply_to { shift->[6] }
    sub subject { shift->[7] }
    sub to { shift->[8] }
    sub cc { shift->[9] }
    sub bcc { shift->[10] }
    sub in_reply_to { shift->[11] }
    sub message_id { shift->[12] }
    sub newsgroups { shift->[13] }
    sub followup_to { shift->[14] }
    sub references { shift->[15] }
}

{
    package Mail::Cclient::Elt;
    use vars qw(%FIELDS);

    %FIELDS = (msgno => 1,
	       date => 2,
	       flags => 3,
	       rfc822_size => 4);
    sub msgno { shift->[1] }
    sub date { shift->[2] }
    sub flags { shift->[3] }
    sub rfc822_size { shift->[4] }
}

# Our own methods
sub new {
    my $class = shift;
    return Mail::Cclient::open(undef, @_);
}

sub set_callback {
    while (@_) {
	my $name = shift;
	my $value = shift;
	$_callback{$name} = $value;
    }
}

sub get_callback {
    my $name = shift;
    return $_callback{$name};
}

sub gc {
    my $obj = shift;
    $obj = undef unless ref($obj);
    $obj->real_gc;
}

sub parameters {
    my $stream = shift; # XXX Ignore stream for now
    if (@_ == 1) {
	return _parameters(undef, @_);
    } elsif (@_ % 2) {
	require Carp;
	Carp::croak("Mail::Cclient::parameters takes one argument or pairs");
    }
    while (my ($param, $value) = splice(@_, 0, 2)) {
	_parameters(undef, $param, $value);
    }
    return 1;
}

bootstrap Mail::Cclient;

1;
