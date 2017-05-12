package Mail::Bulkmail;

# Copyright and (c) 1999, 2000, 2001, 2002, 2003 James A Thomason III (jim@jimandkoka.com). All rights reserved.
# Mail::Bulkmail is distributed under the terms of the Perl Artistic License.

# Mail::Bulkmail is still my baby and shall be supported forevermore.

=pod

=head1 NAME

Mail::Bulkmail - Platform independent mailing list module

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com (http://www.jimandkoka.com)

=head1 SYNOPSIS

 use Mail::Bulkmail /path/to/conf.file

 my $bulk = Mail::Bulkmail->new(
	"LIST" 		=> "~/my.list.txt",
	"From"		=> '"Jim Thomason"<jim@jimandkoka.com>',
	"Subject"	=> "This is a test message",
	"Message"	=> "Here is my test message"
 ) || die Mail::Bulkmail->error();

 $bulk->bulkmail() || die $bulk->error;

Don't forget to set up your conf file!

=head1 DESCRIPTION

Mail::Bulkmail gives a fairly complete set of tools for managing mass-mailing lists. I initially
wrote it because the tools I was using at the time were just too damn slow for mailing out to
thousands of recipients. I keep working on it because it's reasonably popular and I enjoy it.

In a nutshell, it allows you to rapidly transmit a message to a mailing list by zipping out the
information to them via an SMTP relay (your own, of course). Subclasses provide the ability to
use mail merges, dynamic messages, and anything else you can think of.

Mail::Bulkmail 3.00 is a major major B<major> upgrade to the previous version (2.05), which
was a major upgrade to the previous version (1.11). My software philosophy is that most code
should be scrapped and re-written every 6-8 months or so. 2.05 was released in October of 2000, and
I'm writing these docs for 3.00 in January of 2003. So I'm at least 3 major re-writes behind.
(philosophy is referenced in the FAQ, below)

But that's okay, because we're getting it done now.

3.00 is about as backwards compatible to 2.00 as 2.00 is to 1.00. That is to say, sorta. I've
tried to make a note of things where they changed, but I'm sure I missed things. Some things can
no longer be done, lots are done differently, some are the same. You will need to change your code
to update from 1.x or 2.x to 3.00, though. That's a given.

So what's new for 3.00? Lots of stuff.

Immediate changes are:

 * code compartmentalization
 * multi-server support
 * conf file

The immediate change is that the code is now compartmentalized.
Mail::Bulkmail now just handles ordinary, non-dynamic mailings. See Mail::Bulkmail::Dynamic for the
merging and dynamic text abilities from the prior versions.

Server connections are no longer handled directly in Mail::Bulkmail (Smtp attribute, Port attribute,
etc.), there is now a separate Mail::Bulkmail::Server object to handle all of that.

And everything subclasses off of Mail::Bulkmail::Object, where I have my super-methods to define
my objects, some helper stuff, and so on.

It's just a lot easier for me to maintain, think about it, etc. if it's all separated. It's also easier
for you, the user, if you want to make changes to things. Just subclass it, tweak it, and use it.
Very straightforward to modify and extend now. 2.x and below *could* do it, but it wasn't really that
easy (unless you were making very trivial changes). This should rectify that.

Another major change is the addition of multi-server support. See the docs in Mail::Bulkmail::Server for
more information. You can still specify one SMTP relay if that's all you've got, but if you have multiple
servers, Mail::Bulkmail can now load balance between them to help take the stress off. No matter what,
the biggest bottleneck to all of this is network performance (both to the SMTP relay and then from
the relay to the rest of the world), so i wanted to try and help alleviate that by using multiple servers.
I know that some people were doing that on there own with small changes, but this allows you to do it all
invisibly.

And finally, finally, finally there is a conf file. Documentation on the format is in Mail::Bulkmail::Object.
It's pretty easy to use. This is the conf file format that I designed for my own use (along with most of the
rest of Mail::Bulkmail::Object). The software also has the ability to read multiple conf files, if so
desired. So no more worrying about asking your sysadmin to tweak the values in your module somewhere up in /usr/lib/whatever

Just have him create the conf file you want, or pass in your own as desired.

conf_files are specified and further documented in Mail::Bulkmail::Object, in an internal array called @conf_files, right
at the top of the module. To specify a universal conf file, put it in that array (or have your sysadmin do so).
Alternatively, you can also add a conf_file via the conf_files accessor.

 Mail::Bulkmail->conf_files('/path/to/conf_file', '/path/to/other/conf_file');	#, etc.

But the recommended way is to specify your conf file upon module import.

 use Mail::Bulkmail 3.00 "/path/to/conf/file";

In addition, there is the usual plethora of bug fixes, tweaks, clean-ups, and so on.

And yes, the horrid long-standing bug in the Tz method is B<fixed!> No, honest.

I'm also trying a new documentation technique. The pod for a given method is now in the module by that
method, as opposed to everything being bunched up at the bottom. Personally, I prefer everything being bunched
up there for clarities sake. But from a maintenance point of view, spreading it all out makes my life much easier.

=head1 requires

 Perl 5.6.0, Socket
 (It probaly can get by with less than 5.6.0, but I haven't tested it in such an environment)

=cut

use Mail::Bulkmail::Object;
@ISA = Mail::Bulkmail::Object;

$VERSION = '3.12';

use Socket;

use strict;
use warnings;

=head1 ATTRIBUTES

=over 11

=cut

#attributes for storing important headers

# you'll note that these 5 attributes are email addresses and don't use the standard add_attr
# instead, they're wrapped to call _email_accessor internally instead of _accessor as normal.
# Externally, it's the same. $obj->From($value) sets it and $obj->From() reads it
#
# But this also creates additional internal methods for the slots. So there is a ->From and a ->_From
# for example. ->_From internally stores whatever is accepted by ->From, and same with the rest of them.
# Don't access the ->_ attributes directly, use the wrappers instead.

=pod

=item From

Stores the From address of this mailing. Must be a valid email address, unless Trusting is set.
Really really should be a valid email address anyway.

From is no longer used as the Sender, as was the behavior in prior versions. Now, Mail::Bulkmail
first tries to use the Sender as the Sender, and failing that, falls back on the from.

 $bulk->From('"Jim Thomason"<jim@jimandkoka.com>');
 print $bulk->From;

=cut

__PACKAGE__->add_attr(["From",			'_email_accessor'], 0);

=pod

=item To

Stores the To address of this mailing. Must be a valid email address, unless Trusting is set.
Really should be a valid email address anyway.

To is used if you have use_envelope set to 1. See use_envelope, below. If you are not using the envelope,
then the actual email address that we are currently on is used instead and ->To is never used at all.

 $bulk->To('jimslist:;');
 print $bulk->To;

As of 3.00, ->To may contain either a valid email address or a valid group definition. A group definition is as follows
(pseudo-regex):

 Groupname:(address(,address)*)?;

i.e., "the group name", then a colon, then an optional list of email addresses, then a semi-colon

 $bulk->To('jim@jimandkoka.com');
 $bulk->To('MyList:jim@jimandkoka.com');
 $bulk->To('MyList:;');

Are all valid addresses. Only the ->To attribute may accept group syntax emails

=cut

__PACKAGE__->add_attr(["To",			'_email_accessor'], 1);

=pod

=item Sender

Stores the Sender address of this mailing. Must be a valid email address, unless Trusting is set.
Really really should be a valid email address anyway.

Sender is mainly used when speaking SMTP to the server, specifically in the RCPT TO command.
The spec defines "Sender" as "he who send the message" (paraphrasing), which may not actually be who
the message is from. 2.00 used the From address as the Sender.

You should specify this, but if you don't then the From value is assumed to be the sender.

 $bulk->Sender('jim@jimandkoka.com');
 print $bulk->Sender;

If this value is not set, then Mail::Bulkmail B<will> place a Sender header equal to the From value.

Note that the ultimate receiving SMTP server is expected to place a Return-Path header in the message. This
Return-Path value will be set to the value of the sender of the message, either ->Sender or ->From. This, in
turn, will be the address that bounce backs go to. You should not set a Return-Path header yourself, because bad things
will result.

=cut

__PACKAGE__->add_attr(["Sender",		'_email_accessor'], 0);

=pod

=item ReplyTo

Stores the Reply-To address of this mailing. Must be a valid email address, unless Trusting is set.
Really really should be a valid email address anyway.

Reply-To is used as the address that the user's email client should reply to, if present. If this
value is not set, then Mail::Bulkmail B<will> place a Reply-To header equal to the From value.

Note that even though the attribute is "ReplyTo", the header set is "Reply-To"

 $bulk->ReplyTo('jim@jimandkoka.com');
 print $bulk->ReplyTo;

=cut

__PACKAGE__->add_attr(["ReplyTo", 		'_email_accessor'], 0);

=pod

=item Subject

Boring old accessor that stores the subject of the message. It's really recommended that this is
set either at your object or in the conf file, otherwise you'll send out a mailing list with no subject
which will probably be ignored.

 $bulk->Subject("This is the list you signed up for");
 print $bulk->Subject;

=cut

__PACKAGE__->add_attr("Subject");

# internally stores the Precedence of the bulkmail object. Should never be accessed
# directly, should always be accessed via the ->Precedence method, which does a validation check
__PACKAGE__->add_attr("_Precedence");

# internally stores all non-standard (read: "not defined above") headers that the bulkmail object
# may have. It's stored as a hashref, and should be accessed via the ->header method.
__PACKAGE__->add_attr('_headers');

# internally stores the _cached_headers for a given message. This is populated by the
# buildHeaders() method during mailing. After the headers have been built once, then
# buildHeaders returns the value in _cached_headers instead of constantly rebuilding them.
#
# _cached_headers is static if using the envelope. If not using the envelope, then the
# string ##EMAIL## is populated into the To: header, and buildHeaders swaps that for the
# actual individual email addresses
__PACKAGE__->add_attr('_cached_headers');

#attributes for storing boolean flags

=pod

=item HTML

Boolean flag. 1/0 only.

A lot of people, though obviously not you, because you're reading the pod, just couldn't figure out how
to send HTML messages. It's easy.

 $bulk->header("Content-type", "text/html");

But it was just too hard for most people. So I added this flag.

Here's the order:

 Check and see if ->header("Content-type") is set, if so then send it.
 Otherwise, check and see if ->HTML is true, if so, then send a content-type of text/html
   i.e., an HTML message
 Otherwise, send a content-type of text/plain
   i.e., a plaintext message

 $bulk->HTML(1);
 print $bulk->HTML();

=cut

__PACKAGE__->add_attr('HTML');

=pod

=item use_envelope

Boolean flag. 1/0 only.

use_envelope was the coolest thing I added to Bulkmail 2.00, and is arguably still the best thing I've got
here in terms of raw power in your lists.

Basically, it's like lasing a stick of dynamite. Mail::Bulkmail is fast. Mail::Bulkmail with use_envelope
is mind-numbingly fast.

For the uninformed, an email message contains two parts, the message itself and the envelope.   Mail servers only
care about the envelope (for the most part), since that's where they find out who the message is to and from, and
they don't really need to know anything else.

A nifty feature of the envelope is that you can submit multiple addresses within the envelope, and then your
mail server will automagically send along the message to everyone contained within the envelope.  You end up
sending a hell of a lot less data across your connection, your SMTP server has less work to do, and everything
ends up working out wonderfully.

There are two catches.  First of all, with envelope sending turned off, the recipient will have their own email
address in the "To" field (To: jim@jimandkoka.com, fer instance).  With the envelope on, the recipient will only
receive a generic email address ("To: list@myserver.com", fer instance)  Most people don't care since that's
how most email lists work, but you should be aware of it.

Secondly, you B<MUST> and I mean B<MUST> sort your list by domain.  Envelopes can only be bundled up by domain,
so that we send all email to a domain in one burst, all of the email to another domain in the next burst, and so
on.  So you need to have all of your domains clustered together in your list.  If you don't, your list will still
go out, but it will be a B<lot> slower, since Mail::Bulkmail has a fair amount more processing to do when you send
with then envelope.  This is normally more than offset by the gains received from sending fewer messages.  But with
an unsorted list, you never see the big gains and you see a major slow down.  Sort your lists.

 $bulk->use_envelope(0);
 print $bulk->use_envelope;

=cut

__PACKAGE__->add_attr('use_envelope');

=pod

=item force80

Boolean flag 1/0

RFC 2822 recommends that all messages have no more than 80 characters in a line (78 + CRLF), but doesn't require it. if force80 is 1,
then it will force a message to have only 80 characters per line. It will try to insert carriage returns between word boundaries,
but if it can't, then it will cut words in half to force the limit.

Regardless of force80, be warned that RFC 2822 mandates that messages must have no more than 1000 characters per line (998 + CRLF),
and that wrapping will be done no matter what. Again, it will try to wrap at word boundaries, but if it can't, it will cut words
in half to force the limit.

It is recommended that you just have your message with at most 78 characters + CRLF for happiness' sake, and B<definitely> at most
998 characters + CRLF. You may end up with extra CRLFs in your message that you weren't expecting.

If your message is not guaranteed to have only < 78 characters + CRLF per line, then it's recommended to have force80 on for
full compatibility. Note that force80 will be overridden by ->Trusting('wrapping');

=cut

__PACKAGE__->add_attr('force80');

# internal flag to let ->bulkmail know if a message is waiting. This is necessary for envelope sending:
# when we get a new domain from the getNextLine call on LIST, we need to see if there's a waiting message
# first. If there is a waiting message, then we need to finish that one up before we start the next one
# for the new domain. _waiting_message stores that value
__PACKAGE__->add_attr("_waiting_message");

#attributes for storing connection information

=pod

=item servers

arrayref of servers.

Okay, this is the first major change between 2.x and 3.x. 2.x had methods to connect to one server (->Smtp, ->Port, etc.).
3.x doesn't have those, and the relevent things are now in Mail::Bulkmail::Server, instead it has a list of servers.

servers should contain an arrayref of server objects. You can either create them externally yourself and pass them in in an arrayref,

 $bulk->servers([\$server, \$server2, \$server3]);

or you can create them in your conf file. See the Mail::Bulkmail::Object for more info on the format of the conf file, and
Mail::Bulkmail::Server for the attributes to specify.

servers will automatically be populated with a list of all servers in the server_list in the conf file if you don't specify anything,
so you really don't need to worry about it.

If you'd rather use a different server_file, then pass the server_file flag to the constructor:

 $bulk = Mail::Bulkmail->new(
 	'server_file' => '/path/to/server_file'
 );

That will B<override and ignore> the server_file in B<any> conf file, so use it with caution.

Realistically, though, just let the program populate in the values of the servers you specified in the conf file and don't worry about
this.

Be warned that servers will be populated by the constructor if you do not populate servers at object creation. You may still
change servers later (before you begin mailing), but there is the slight performance hit to initialize all of the server objects
and then throw them away. This doesn't affect mailing speed in anyway, it'll just take a little longer to get started than it should.

=cut

__PACKAGE__->add_attr('servers');

# internal flag to let ->bulkmail know the domain of the last email address we looked at when using
# the envelope. This is necessary to know when we reach a new domain in the LIST. If we have a new
# domain (i.e., the current message's domain is different from _cached_domain), then finish off the
# message if we _waiting_message is true and then move on
__PACKAGE__->add_attr("_cached_domain");

# internally stores which index of the ->servers list we're on used and set by nextServer
__PACKAGE__->add_attr("_server_index");

#attributes for storing information about the message

=pod

=item Message

This stores the message that you will send out to the recipients of your list.

 $bulk->Message('Hi there. You're on my mailing list');
 print $bulk->Message;

Don't put any headers in your Message, since they won't be transmitted as headers. Instead they will show up in the body
of your message text. Use the ->header method instead for additional headers

This mutator is known to be able to return:

 MB020 - could not open file for message
 MB021 - could not close file for message
 MB022 - invalid headers from message

=cut

# The message is actually stored internally (_Message) and accessed via Message.
# That way, if we change the message, we can be sure to wipe out the internal _cached_message as well
__PACKAGE__->add_attr('_Message');

sub Message {
	my $self = shift;
	$self->_cached_message(undef) if @_;

	my @passed = @_;
	
	my $needs_header_extraction = 0;
	
	if (@passed) {
		$self->_extracted_headers_from_message(0);
	};

	if ($self->message_from_file) {

		my $file = shift @passed || $self->_message_file;

		if (! defined $self->_message_file_access_time || $file ne $self->_message_file || -M $file < $self->_message_file_access_time) {

			$self->_message_file($file);
			$self->_message_file_access_time(-M $file);

			#theoretically, you could call ->Message with no arguments but with message_from_file turned on
			#in that case, you may re-read the file if it's been modified since you last looked at it.
			#We're currently in that case. So we wipe out the previously _cached_message to be safe.
			$self->_cached_message(undef);

			my $handle = $self->gen_handle;

			my $message = undef;

			open ($handle, $file) || return $self->error("Could not open file for message: $!", "MB020");

			{
				local $/ = undef;
				$message = <$handle>;
			}

			close ($handle) || return $self->error("Could not close file for message: $!", "MB021");

			unshift @passed, $message;
		};
	};

	#first, wipe out any previously set headers_from_message
	if (defined $self->_previous_headers_from_message) {
		foreach my $header (@{$self->_previous_headers_from_message}){
			$self->header($header, undef);
		};
	};

	#wipe out the list of previously set headers
	$self->_previous_headers_from_message([]);

	#then, if we're setting new headers, we should set them.
	if ($self->headers_from_message && ! $self->_extracted_headers_from_message) {
		$self->_extracted_headers_from_message(1);
		$passed[0] ||= $self->_Message();	#We'll sometimes call this method after setting the message
		#sendmail-ify our messages newlines
		$passed[0] =~ s/(?:\r?\n|\r\n?)/\015\012/g;

		my $header_string = undef;

		#split out the header string and the message body
		($header_string, $passed[0]) = split(/\015\012\015\012/, $passed[0], 2);

		my ($last_header, $last_value) = ();
		foreach (split/\015\012/, $header_string){
			if (/:/){
				if (defined $last_header && defined $last_value) {
					#set our header
					$self->header($last_header, $last_value)
						|| return undef;	#bubble up the header error

					#and wipe out the prior values
					$last_header = $last_value = undef;
				};
				($last_header, $last_value) = split(/:/, $_, 2);
				push @{$self->_previous_headers_from_message}, $last_header;
			}
			elsif (/^\s+/){
				$last_value .= "\015\012$_";
			}
			else {
				return $self->error("Invalid Headers from Message: line ($_)\n\n-->($header_string)", "MB022");
			};
		};

		#clean up any headers that remain
		if (defined $last_header && defined $last_value) {
			#set our header
			$self->header($last_header, $last_value)
				|| return undef;	#bubble up the header error
		};
	};

	return $self->_Message(@passed);
};

# internal method. Looks to see if a the message is being read from disk. If so, if it
# was modified since it was read, then it is not current. Otherwise, it is.

sub _current_message {
	my $self = shift;

	if (
		$self->message_from_file
		&& (
			! defined $self->_message_file_access_time
			|| -M $self->_message_file < $self->_message_file_access_time
			)
		) {
			return 0;
	}
	else {
		return 1;
	};
};

# internally stores the _cached_message for a given message. This is populated by the buildMessage()
# method during mailing. After the message has been built once, then buildMessage returns the
# value in _cached_message instead of constantly rebuilding it.
__PACKAGE__->add_attr('_cached_message');

=pod

=item message_from_file

boolean flag. 1/0 only.

message_from_file allows you to load your message in from a file. If message_from_file is
set to 1, then the value passed to ->Message() will be assumed to be a path to a file on disk.
That file will be openned in read mode (if possible), read in, and stored as your message. Note
that your entire message text will be read into memory - no matter how large the message may be.

This is simply a shortcut so that you don't have to open and read in the message yourself.

B<NOTE> This is a bit picky, to put it mildly. No doubt you've read that the constructor actually
is taking in its arguments in an array, not a hash. So they're parsed in order, which means you need
pass in message_from_file B<before> Message. i.e., this will work:

 $bulk = Mail::Bulkmail->new(
 	'message_from_file' => 1,
 	'Message'			=> '/path/to/message.txt',
 );

But this will not:

 $bulk = Mail::Bulkmail->new(
 	'Message'			=> '/path/to/message.txt',
 	'message_from_file' => 1,
 );

Ditto for using the mutators. Turn on the flag, i<then> specify the Message.

=cut

__PACKAGE__->add_attr('message_from_file');

# internal caching attribute to store the message file. This way we will be able to re-open
# and re-read the message file if it happened to change.

__PACKAGE__->add_attr('_message_file');

# internal attribute to store the time the message file was last accessed. This allows the message
# file to change and be re-read, though lord knows why you'd want to necessarily do something like
# that.

__PACKAGE__->add_attr('_message_file_access_time');

=pod

=item headers_from_message

boolean flag. 1/0 only.

headers_from_message allows you to specify mail headers inside your message body. You may
still specify additional headers in the traditional manner.

Note that if you change the value of ->Message (not recommended, but there are times you may
want to do so), then any headers that were previously set via headers_from_message will be B<wiped out>.

any headers specified in the message will be set when you call ->Message.

=cut

__PACKAGE__->add_attr('headers_from_message');

# internal boolean flag. used to govern whether the headers have already been extracted from
# the message
__PACKAGE__->add_attr('_extracted_headers_from_message');

#internal arrayref containing the headers set the last time ->Message was called.

__PACKAGE__->add_attr("_previous_headers_from_message");

# internal hashref that stores the list of duplicate email addresses populated by setDuplicate and
# read by isDuplicate. WARNING - there is a *severe* penalty for using duplicates, this hash can
# get really really huge. It is recommended you remove duplicates in advance and turn on
# allow_duplicates to prevent this from being populated, if you do use it, then it
# is *strongly* recommended that you leave Trusting('banned') off, i.e. Trusting('banned' => 0)
__PACKAGE__->add_attr('_duplicates');

# internal hashref that stores the list of banned email addresses or domains populated by a call
# to banned (which does some magic with _file_accessor). accessed via isBanned
# It is *strongly* recommended that you leave Trusting('banned') off, i.e. Trusting('banned' => 0)
__PACKAGE__->add_attr('_banned');

#attributes for storing filehandles

=pod

=item LIST

LIST stores the list of addresses you're going to mail out to. LIST may be either a coderef, globref, arrayref, or string literal.

If a string literal, then Mail::Bulkmail will attempt to open that file as your list:

 $bulk->LIST("/path/to/my/list");

If a globref, it is assumed to be an open filehandle:

 open (L, "/path/to/my/list");
 $bulk->LIST(\*L);

if a coderef, it is assumed to be a function to return your list, or undef when it is done:

 sub L {return $listquery->execute()};	#or whatever your code is
 $bulk->LIST(\&L);

The coderef will receive the bulkmail object itself as an argument.

if an arrayref, it is assumed to be an array containing your list:

 my $list = [qw(jim@jimandkoka.com thomasoniii@yahoo.com)];
 $bulk->LIST($list);

Use whichever item is most convenient, and Mail::Bulkmail will take it from there.

=cut

__PACKAGE__->add_attr(['LIST', 		'_file_accessor'], '<');

=pod

=item BAD

This is an optional log file to keep track of the bad addresses you have, i.e. banned, invalid, or duplicates.

BAD may be either a coderef, globref, arrayref, or string literal.

If a string literal, then Mail::Bulkmail will attempt to open that file (in append mode) as your log:

 $bulk->BAD("/path/to/my/bad.addresses");

If a globref, it is assumed to be an open filehandle in append mode:

 open (B, ">>/path/to/my/bad.addresses");
 $bulk->BAD(\*L);

if a coderef, it is assumed to be a function to call with the address as an argument:

 sub B { print "BAD ADDRESS : ", $_[1], "\n"};	#or whatever your code is
 $bulk->BAD(\&B);

The coderef will receive two arguments. The first is the bulkmail object itself, and the second
is the data in the form that it was returned from the LIST attribute.

if an arrayref, then bad addresses will be pushed on to the end of it

 $bulk->BAD(\@bad);

Use whichever item is most convenient, and Mail::Bulkmail will take it from there.

=cut

__PACKAGE__->add_attr(['BAD',		'_file_accessor'], '>>');

=pod

=item GOOD

This is an optional log file to keep track of the good addresses you have, i.e. the ones that 
Mail::Bulkmail could successfully transmit to the server. Note that there is no guarantee that
an email address in the GOOD file actually received your mailing - it could have failed at a 
later point when out of Mail::Bulkmail's control.

GOOD may be either a coderef, globref, arrayref, or string literal.

If a string literal, then Mail::Bulkmail will attempt to open that file (in append mode) as your log:

 $bulk->GOOD("/path/to/my/good.addresses");

If a globref, it is assumed to be an open filehandle in append mode:

 open (B, ">>/path/to/my/good.addresses");
 $bulk->GOOD(\*B);

if a coderef, it is assumed to be a function to call with the address as an argument:

 sub G { print "GOOD ADDRESS : ", $_[1], "\n"};	#or whatever your code is
 $bulk->GOOD(\&G);

The coderef will receive two arguments. The first is the bulkmail object itself, and the second
is the data in the form that it was returned from the LIST attribute.

if an arrayref, then bad addresses will be pushed on to the end of it

 $bulk->GOOD(\@good);

Use whichever item is most convenient, and Mail::Bulkmail will take it from there.

Please note that ->GOOD only says that the address was initially accepted for delivery. It could later fail while transmitting
the email address, or it could be an valid but non-existent address that bounces later. It is up to the end user to inspect your
error logs to make sure no errors occurred, and look for (and weed out) bounces or other failures later.

=cut

__PACKAGE__->add_attr(['GOOD',		'_file_accessor'], '>>');

#class attributes

=pod

=item server_class

server_class is a class method that B<MUST> be specified in the conf file. You can initialize it in your program if you
really want, but it is B<strongly> recommended to be in the conf file so you don't forget it.

server_class is used by the constructor to create the server list to populate into ->servers, ->servers is not
populated in the constructor.

By default, this should probably be Mail::Bulkmail::Server, to allow mailing. Another useful value is Mail::Bulkmail::Dummy
See Mail::Bulkmail::Server and Mail::Bulkmail::Dummy for more information on how to create those objects.

Also, if you write your own server implementation, this would be where you'd hook it into Mail::Bulkmail

=cut

__PACKAGE__->add_class_attr('server_class');

#speciality accessors

# _Trusting stores the hashref that is accessed internally by the Trusting method

__PACKAGE__->add_attr('_Trusting');

=pod

=item Trusting

Trusting specifies your Trusting level. Mail::Bulkmail 3.00 will do its best to make sure that your email addresses
are valid and that your message conforms to RFC 2822. But, there is a slight performance hit to doing that - it does have
to check things, do regexes, and so on. It's not very slow, but extrapolated over a huge list, it can be noticeable.

So that's where Trusting comes in to play. If you set a Trusting value, then certain tests will be skipped. B<Use this at your
own risk>. If you tell Mail::Bulkmail to be Trusting, then it won't verify addresses or to make sure your list is under 1,000
characters per line. So if you're Trusting and you pass in bad data, it's your funeral. If there is B<any> chance of invalid data,
then don't be Trusting. If you're *positive* there's nothing wrong, then you may be Trusting.

Trusting values are set one as key/value pairs.

 $bulk->Trusting("email" => 1);
 $bulk->Trusting("wrapping" => 1);
 $bulk->Trusting("default" => 1);

And read back with just the key:

 $bulk->Trusting("email");
 $bulk->Trusting("wrapping");
 $bulk->Trusting("default");

default is used as a fall back. So if you didn't specify a Trusting value for "email", for example, it will use
the "default" value. Note that the default is only used if a value is not specified.

 $bulk->Trusting("default" => 1);
 print $bulk->Trusting("email");	#prints 1
 print $bulk->Trusting("default");	#prints 1
 $bulk->Trusting("default" => 0);
 print $bulk->Trusting("email");	#prints 0
 print $bulk->Trusting("default");	#prints 0
 $bulk->Trusting("email" => 1);
 print $bulk->Trusting("email");	#prints 1
 print $bulk->Trusting("default");	#prints 0
 $bulk->Trusting("email" => 0);
 $bulk->Trusting("default" => 0);
 print $bulk->Trusting("email");	#prints 0
 print $bulk->Trusting("default");	#prints 1

You may also directly set all values with the integer short cut.

 $bulk->Trusting(1);	# everything is Trusting
 $bulk->Trusting(0);	# nothing is Trusting

If you want to specify Trusting in the conf file, you may only directly specify via the integer shortcut. Otherwise, you must
use the list equation.

 # all Trusting
 Trusting = 1

 #none Trusting
 Trusting = 0

 #email is trusting
 Trusting @= email
 Trusting @= wrapping

This will not work:

 Trusting = email

If you use that syntax, it will internally do:

 $bulk->Trusting('email');

which you know will only read the value, not set it. If you use the array syntax, it will properly set the value.

Note that ->Trusting('default' => 0) is not equivalent to ->Trusting(0). Consider:

 $bulk->Trusting('email' => 1);
 print $bulk->Trusting('email');	# prints 1
 $bulk->Trusting("default' => 0);
 print $bulk->Trusting('email');	# still prints 1
 $bulk->Trusting(0);
 print $bulk->Trusting('email');	# now prints 0

Currently, you may set:

 email      - Trusting('email' => 1) will not check for valid email addresses
 wrapping   - Trusting('wrapping' => 1) will not try to wrap the message to reach the 1,000 character per line limit
 duplicates - Trusting('duplicates' => 1) will not do any duplicates checking
     (this is the equivalent of allow_duplicates in older versions)
 banned     - Trusting('banned' => 1) will not lowercase the local part of a domain in a banned or duplicates check
     (this is the opposite of safe_banned in older versions. i.e. $bulk2_05->safe_banned(1) == $bulk_300->Trusting('banned' => 0);

It is recommended your conf file be:

 Trusting @= duplicates

Since you're usually better off weeding duplicates out in advance. All other Trusting values are recommended to be false.

=cut

sub Trusting {
	my $self = shift;
	my $key = shift;

	$self->_Trusting({}) unless $self->_Trusting;

	if (defined $key) {
		if (ref $key eq "ARRAY"){
			foreach my $k (@$key){
				$self->_Trusting->{$k} = 1;
			};
			return 1;
		}
		elsif (@_){
			my $val = shift;
			$self->_Trusting->{$key} = $val;
			return $val;
		}
		elsif ($key =~ /^[10]$/){
			$self->_Trusting({});
			$self->_Trusting->{'default'} = $key;
			return $key;
		}
		else {
			return defined $self->_Trusting->{$key}
				? $self->_Trusting->{$key}
				: ($self->_Trusting->{'default'} || 0)
		};
	}
	else {
		return $self->_Trusting->{'default'} || 0;
	};
};

=pod

=item banned

banned stores the list of email addresses and domains that are banned. Only store user@domain.com portions of
email addresses, don't try to ban "Jim"<jim@jimandkoka.com>, for instance. Only ban jim@jimandkoka.com

banned may be either a coderef, globref, arrayref, or string literal.

If a string literal, then Mail::Bulkmail will attempt to open that file (in append mode) as your log:

 $bulk->banned("/path/to/my/banned.addresses");

If a globref, it is assumed to be an open filehandle in append mode:

 open (B, ">>/path/to/my/banned.addresses");
 $bulk->banned(\*B);

files should contain one entry per line, each entry being an email address or a domain. For example:

 jim@jimandkoka.com
 jimandkoka.com
 foo@bar.com
 bar.com

if a coderef, it is assumed to be a function to return your banned list:

 sub B {return $bannedquery->execute()};	#or whatever your code is
 $bulk->banned(\&B);

The function should return one entry per execution, either an address or a domain.

if an arrayref, then it's an array of banned addresses and domains

 $bulk->banned([qw(jim@jimandkoka.com jimandkoka.com)]);

The arrayref can contain email addresses and domains.

Use whichever item is most convenient, and Mail::Bulkmail will take it from there.

Once banned has been populated, the values are stored internally in a hashref.

=cut

sub banned {
	my $self = shift;

	if (@_) {
		my $banned = shift;

		#we're gonna cheat and populate the data into ->_banned via the _file_accessor.
		#then we'll iterate through it all, pop it into a hash, and then drop
		#that back into _banned instead

		my $ob = $self->_banned();	#save it for below.
		$self->_file_accessor("_banned", "<", $banned);

		my $b = $ob || {};	#keep the old value, or make a new hashref

		while (my $address = $self->getNextLine($self->_banned)){
			$b->{$address} = 1;
		};

		return $self->_banned($b);
	}
	else {
		#if we have a banned hash, return it.
		if ($self->_banned){
			return $self->_banned;
		}
		#otherwise, create one and return that.
		else {
			return $self->_banned({});
		};
	};
};

=pod

=item Precedence

Precedence is a validating accessor to validate the Precedence you have passed for your mailing list.

Precedence must be either:

 * list (default) - a mailing list
 * bulk - bulk mailing of some type
 * junk - worthless test message.

You can use an alternate Precedence if you set Trusting to 0. But seriously, there's *no* reason to do that. Keeping
the appropriate precedence will help the servers on the internet route your message as well as the rest of the email out
there more efficiently. So don't be a jerk, and leave it as one of those three.

This method is known to be able to return:

 MB001 - invalid precedence

=cut

sub Precedence {
	my $self = shift;
	my $prop = '_Precedence';

	if (@_){
		my $precedence = shift;
		if ($self->Trusting('precedence') || $self->_valid_precedence($precedence)){
			$self->_Precedence($precedence);
			return $self->_Precedence;
		}
		else {
			return $self->error("Invalid precedence: $precedence", "MB001");
		};
	}
	else {
		return $self->_Precedence || 'list';	#if they didn't set it, assume list, no matter what
	};
};

#date and tz are actually methods, not accessors, but they're close enough, so what the hell

=pod

=item Tz

Returns the timezone that you're in. You cannot set this value. You'll also never need to worry about it.

=cut

sub Tz {

	my $self = shift;
	my $time = shift || time;

	my ($min, $hour, $isdst)	= (localtime($time))[1,2,-1];
	my ($gmin, $ghour, $gsdst)	= (gmtime($time))[1,2, -1];

	my $diffhour = $hour - $ghour;
	$diffhour = $diffhour - 24 if $diffhour > 12;
	$diffhour = $diffhour + 24 if $diffhour < -12;

	($diffhour = sprintf("%03d", $diffhour)) =~ s/^0/\+/;

	return $diffhour . sprintf("%02d", $min - $gmin);

};

=pod

=item Date

Returns the date that this email is being sent, in valid RFC format. Note that this will be stored in _cached_headers as the
date that the first email is sent.

Another thing you won't need to worry about.

=cut

sub Date {

	my $self 	= shift;

	my @months 	= qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my @days 	= qw(Sun Mon Tue Wed Thu Fri Sat);

	my $time = time;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime($time);

	return sprintf("%s, %02d %s %04d %02d:%02d:%02d %05s",
		$days[$wday], $mday, $months[$mon], $year + 1900, $hour, $min, $sec, $self->Tz($time));
};

#done with speciality accessors

#our generic speciality accessors

# internally used to populate the attributes that are expected to contain email addresses
# basically, it just does a valid_email check on the email address before allowing it into
# the object's attribute. The validation check will be bypassed if Trusting is set
#
# otherwise, the attribute externally behaves just as any other
sub _email_accessor {
	my $self			= shift;
	my $prop			= shift;
	my $allow_groups	= shift;

	if (@_){
		my $email = shift;
		if (! defined $email || $self->Trusting('email') || $self->valid_email($email, $allow_groups)){
			my $return = $self->$prop($email);;
			return defined $email ? $return : 0;
		}
		else {
			return $self->error("Invalid address: $email", "MB002");
		};
	}
	else {
		return $self->$prop();
	};
};

#done with generic specialty accessors

#constructor

=pod

=back

=head1 METHODS

=over 11

=item new

The constructor, used to create new Mail::Bulkmail objects. See Mail::Bulkmail::Object for more information on constructors.

In a nutshell, the constructor accepts a hash with name/value pairs corresponding to attributes and attribute values.

So that:

 my $bulk = Mail::Bulkmail->new(
 	'LIST' => './list.txt',
 	'Message' => "This is my message!",
 	'HTML' => 0
 ) || die Mail::Bulkmail->error;

is the same as:

 my $bulk = Mail::Bulkmail->new() || die Mail::Bulkmail->error;

 $bulk->LIST("./list.txt");
 $bulk->Message("This is my message!");
 $bulk->HTML(0);

*technically* it's not exactly the same, since the constructor will fail with an error if your attribute calls return undef, but
it's close enough.

It is recommend to tack on an || die after your new() calls, to make sure you're alerted if your object isn't created.

 my $bulk = Mail::Bulkmail->new() || die Mail::Bulkmail->error();

Otherwise, you won't be alerted if your object isn't created.

Upon creation, Mail::Bulkmail will first iterate through the conf file and populate all of the attributes defined in the conf file
into your object. It will then iterate through the values you passed to the constructor and mutate the attributes to those
values. If you don't pass any arguments to the constructor, it still gets the default values in the conf file. Values passed to
the constructor always override values specified in the conf file

There is one special constructor flag, "server_file", which does not correspond to an attribute or method. "server_file" is used to
override the server_file specified in the conf file.

If you pass a key/value pair to the constructor that doesn't have a corresponding attribute, then it is assuming you are setting a
new header.

 my $bulk = Mail::Bulkmail->new('foo' => 'bar');

 is the same as:

 my $bulk = Mail::Bulkmail->new();
 $bulk->header('foo' => 'bar');

This method is known to be able to return:

 MB003 - could not use server class

=cut

sub new {
	my $class	= shift;

	my %init	= @_;

	my $self = $class->SUPER::new(
		'servers'			=> [],
		'_headers'			=> {},
		"_duplicates"		=> {},
		"_waiting_message"	=> 0,
		"_server_index"		=> -1,
		@_
	) || return undef;

	#now, we iterate through everything else that was passed, since we're gonna assume
	#that they want to set it as a header
	foreach my $key (grep {! $self->can($_)} keys %init){
		next if $key eq 'server_file';	#special case to allow passing of a separate server_file
		$self->header($key, $init{$key}) || return $class->error($self->error, $self->errcode, 'not logged');
	};

	#if we have no servers, but we do have a server file (which we should...)
	if ($class->server_class) {
		$@ = undef;
		eval "use " . $class->server_class;
		return $self->error("Could not use " . $class->server_class . " : $@", "MB003") if $@;
		#if we have no servers, then initialize them via create_all_servers
		$self->servers($class->server_class->create_all_servers($init{'server_file'} || undef))
			if $class->server_class && @{$self->servers} == 0;
	};

	return $self;

};

=pod

=item header

the header method is used to set additional headers for your object that don't have their own methods (such as Subject)
header expects the header and value to act as a mutator, or the header to act as an accessor.

 $bulk->header('X-Header', "My header value");
 print $bulk->header('X-Header'); #prints "My header value"

Use this to set any additional headers that you would like.

Note that you can't use this to bypass validation checks.

 $bulk->Header("Subject", "My Subject") will internally change into $bulk->Subject("My Subject");

There's no benefit to doing that, it'll just slow you down.

If you call header with no values, it returns the _headers hashref, containing key value pairs of header => value

This method is known to be able to return:

 MB004 - cannot set CC or BCC header
 MB005 - invalid header

=cut

#header allows us to specify additional headers
sub header {

	my $self	= shift;
	my $header	= shift || return $self->_headers;

	if ($header =~ /^(?:From|To|Sender|Reply-?To|Subject|Precedence)$/){
		$header =~ s/\W//g;
		return $self->$header(@_);
	}
	elsif ($header =~ /^b?cc/i){
		return $self->error("Cannot set CC or BCC...that's just common sense!", "MB004");
	}
	else {
		if ($header =~ /^[\x21-\x39\x3B-\x7E]+$/){
			my $value = shift;
			if (defined $value) {
				$self->_headers->{$header} = $value;
				return $value;
			}
			else {
				delete $self->_headers->{$header};
				return 0; #non-true value (didn't set it to anything), but a defined value since it's not an error.
			};
		}
		else {
			return $self->error("Cannot set header '$header' : invalid. Headers cannot contain non-printables, spaces, or colons", "MB005");
		};
	};

};

#validation methods

{
	# Mail::Bulkmail 3.00 has a greatly extended routine for validating email addresses. The one in 2.x was pretty good,
	# but was only slightly superior to the one in 1.x. It also wasn't quite perfect - there were valid addresses it would
	# refuse, and invalid addresses it would accept. It was *mostly* fine, though.
	#
	# 3.00 has a higher standard, though. :)
	# So valid_email has been re-written. This should match only valid RFC 2822 addresses, with deviations from the
	# spec noted below. Still only allows single addresses, though. No address lists or groups for the general case.

	# our regexes to deal with whitespace and folding whitespace
	my $wsp = q<[ \t]>;
	my $fws = qq<(?:(?:$wsp*\\015\\012)?$wsp+)>;

	# our regexes for control characters
	my $no_ws_ctl = q<\x01-\x08\x0B\x0C\x0E-\x1F\x7F>;

	# regex for "text", any ascii character other than a CR or LF
	my $text = q<[\x01-\x09\x0B\x0C\x14-\x7F]>;

	#regexes for "atoms"

		#define our atomtext
		my $atext = q<[!#$%&'*+\-/=?^`{|}~\w]>;

		# an atom is atext optionally surrounded by folded white space
		my $atom = qq<(?:$fws*$atext+$fws*)>;

		# a dotatom is atom text optionally followed by a dot and more atomtext
		my $dotatomtext = qq<(?:$atext+(?:\\.$atext+)*)>;

		#a dotatom is dotatomtext optionally surrounded by folded whitespace
		my $dotatom = qq<(?:$fws?$dotatomtext$fws?)>;

	#a quoted pair is a backslash followed by a single text character, as defined above.
	my $quoted_pair = '(?:' . q<\\> . qq<$text> . ')';

	#regexes for quoted strings

		#quoted text is text between quotes, it can be any control character,
		#in addition to any ASCII character other than \ or "
		my $qtext = '(?:' . '[' . $no_ws_ctl . q<\x21\x23-\x5B\x5D-\x7E> . ']' . ')';

		#content inside a quoted string may either be qtext or a quoted pair
		my $qcontent = qq<(?:$qtext|$quoted_pair)>;

		#and, finally, our quoted string is optional folded white space, then a double quote
		#with as much qcontent as we'd like (optionally surrounded by folding white space
		#then another double quote, and more optional folded white space
		my $quoted_string = qq<(?:$fws?"(?:$fws?$qcontent)*$fws?"$fws?)>;

	#a word is an atom or a quoted string
	my $word = qq<(?:$atom|$quoted_string)>;

	#a phrase is multiple words
	my $phrase = qq<$word+>;

	#the local part of an address is either a dotatom or a quoted string
	my $local_part = qq<(?:$dotatom|$quoted_string)>;

	#regexes for domains

	#	#domain text may be a control character, in addition to any ASCII character other than [, \, or ]
	#	my $dtext	= '(?:' . '[' . $no_ws_ctl . q<\x21-\x5A\x5E-\x7E> . ']' . ')';
	#
	#	#domain content is either dtext or a quoted pair
	#	my $dcontent = qq<(?:$dtext|$quoted_pair)>;
	#
	#	#a domain literal is optional folded white space, followed by a literal [
	#	#then optional folded white space and arbitrary dcontent, followed by another literal ]
	#	#and then optional fws
	#	my $domain_literal = qq<(?:$fws?\\[(?:$fws?$dcontent)*\\]$fws)>;
	#
	#	#and, finally, a domain is either a dotatom or a domainliteral.
	#	my $domain = qq<(?:$dotatom|$domain_literal)>;

		# RFC 2821 is a bit stricter than RFC 2822. In fact, according to that document, a domain may be only
		# letters, numbers, and hyphens. Go figure. I kept the old domain specification in the comments
		# immediately above here, just 'cuz I was so proud of 'em. :)
		my $domain = q<[a-zA-Z0-9\-]+(?:\.[a-zA-Z0-9\-]+)*\\.(?:[a-zA-Z][a-zA-Z](?:[a-zA-Z](?:[a-zA-Z](?:[a-zA-Z][a-zA-Z])?)?)?)>;

	#our address spec. Defines user@domain.com
	#note - very important, that the addr_spec is within backtracking parentheses. This value will
	#go into either $1 (common) or $2 (not quite as common).
	#also note that we deviate from RFC 2822 here, by forcing the TLD of 2,3,4 or 6 characters.
	#that's what the internet uses, regardless of what the spec allows.
	my $addr_spec = '(' . $local_part . '@' . $domain . ')';

	#a display name (displayname<addr_spec>) is just a phrase
	my $display_name = $phrase;

	#an angle_addr is just an addr_spec surrounded by < and >, with optional folded white space
	#around that
	my $angle_addr = qq[(?:$fws?<$addr_spec>$fws?)];

	#a name address is an optional display_name followed by an angle_addr
	my $name_addr = qq<(?:$display_name?$angle_addr)>;

	# and a mailbox is either an addr_spec or a name_addr
	# the mailbox is our final regex that we use in valid_email
	#
	my $mailbox = qq<(?:$addr_spec|$name_addr)>;
	#
	##

	# a mailbox list is, as it sounds, a list of at least one mailbox, with as many as you'd like, comma delimited
	my $mailbox_list = qq<(?:$mailbox(?:,$mailbox)*)>;

	# and a group is a display_name, a :, and an optional mailbox list, ended with a semi-colon
	# This is used in the To accessor, which is allowed to contain groups.
	my $group = qq<(?:$display_name:(?:$mailbox_list|$fws)?;)>;

=pod

=item valid_email

valid_email validates an email address and extracts the user@domain.com part of an address

 print $bulk->valid_email('jim@jimandkoka.com')->{'extracted'};					#prints jim@jimandkoka.com
 print $bulk->valid_email('"Jim Thomason"<jim@jimandkoka.com>')->{'extracted'};	#prints jim@jimandkoka.com
 print $bulk->valid_email('jim@jimandkoka.com')->{'extracted'};					#prints jim@jimandkoka.com
 print $bulk->valid_email('jim@@jimandkoka.com');								#prints nothing (invalid address)

Note that as of v3.10, valid_email returns a hash with two keys upon success. 'original' contains the address as you
passed it in, 'extracted' is the address person that was yanked out.

 {
 	'original'	=> 'Jim Thomason'<jim@jimandkoka.com',
 	'extracted'	=> 'jim@jimandkoka.com',
 }

Given an invalid address, returns undef and sets an error as always.

If Trusting is 1, then valid_email only removes comments and extracts the address spec part of the email. i.e., if your address is

 some name<some@address.com>

It'll just return some@address.com. This is required, because valid_email is also where the address spec is validated.
As of 3.00, valid_email should be fully RFC 2822 compliant, except where otherwise noted (such as forcing a valid domain as per RFC 2821).
And also as of 3.00, Trusting is even more trusting and has a faster return. There are speed reasons to have Trusting set
to 1 (such as not having to check the validity of each email address), but if you do that then you must be B<positive> that
B<all> of your addresses are 100% valid. If you have B<any> addresses in your list that are invalid and Trusting is set to 1,
then you may have bad things happen. You have been warned.

This method is known to be able to return:

 MB006 - no email address
 MB007 - invalid email address

=cut

	sub valid_email {

		my $self			= shift;
		my $email			= shift;
		my $allow_groups	= shift;

		my $return_hash 	= {
			'original' => $email
		};

		return $self->error("Cannot validate w/o email address", "MB006") unless $email;

		$email = $self->_comment_killer($email);				#No one else handles comments, to my knowledge. Cool, huh?  :)

		# if we're trusting, trivially extract the address-spec and return it
		if ($self->Trusting('email')){
			$email =~ s/.+<(.+)>/$1/g;
			$return_hash->{'extracted'} = $email;
			return $return_hash;
		};

		#okay, check our email address
		if ($email =~ m!^$mailbox$!o){
			$return_hash->{'extracted'} = $1 || $2;	#our address could be in either place;
			return $return_hash;
		}
		#if it fails as an email address and we allow groups, see if we were passed a group
		elsif ($allow_groups && $email =~ m!^$group$!o){
			#the $group regex can't extract emails, so we'll just return the whole thing.
			$return_hash->{'extracted'} = $email;
			return $return_hash;
		}
		#finally, otherwise give an error
		else {
			$self->logToFile($self->BAD, \$email);
			return $self->error("Invalid email address : $email", "MB007");
		};
	};

	# _comment_killer is used internally by valid_email, _comment_killer does what you'd expect from it, it removes
	# comments from email addresses

	sub _comment_killer {

		my $self  = shift;
		my $email = shift;

		#comment text is anything in ASCII, except for \, (, and )
		my $ctext = '(' . '[' . $no_ws_ctl . q<\x21-\x27\x2A-\x5B\x5D-\x7E> . ']' . ')';

		#the content of a comment is either ctext or a quoted pair
		#we are deviating from RFC 2822, because comments can nest arbitrarily. But we don't allow that.
		my $ccontent = qq<($ctext|$quoted_pair)>;	#|$comment, but we don't allow nesting here

		#and finally, a comment is a ( followed by arbitrary ccontent, followed by another )
		my $comment = '(' . '\(' . qq<($fws?$ccontent)*$fws?> . '\)' . ')';

		while ($email =~ /$comment/o){$email =~ s/$comment//go};

		return $email;
	};

};

# _valid_precedence is used internally to check whether a precedence is valid, i.e., list, bulk, or junk
# It is called by the Precedence wrapper to the _Precedence attribute

sub _valid_precedence {
	my $self	= shift;
	my $value	= shift;

	if ($self->Trusting('precedence') || (defined $value && $value =~ /list|bulk|junk/i)){
		return 1;
	} else {
		$value = '' unless defined $value;
		return $self->error("Invalid precedence ($value) : only 'list', 'bulk', or 'junk'", "MB008");
	};
};

#/validation

#now, for the methods

=pod

=item lc_domain

given an email address, lowercases the domain. Mainly used internally, but I thought it might be useful externally as well.

 print $self->lc_domain('Jim@JimANDKoka.com');	#prints Jim@jimandkoka.com
 print $self->lc_domain('JIM@JIMANDKOKA.com');	#prints JIM@jimandkoka.com
 print $self->lc_domain('jim@jimandkoka.com');	#prints jim@jimandkoka.com

This method is known to be able to return:

 MB009 - cannot lowercase domain w/o email

=cut

sub lc_domain {

	#lowercase the domain part, but _not_ the local part.  Why not?
	#Read the specs, you can't make assumptions about the local part, it is case sensitive
	#even though 99.999% of the net treats it as insensitive.

	my $self	= shift;

	my $email	= shift || return $self->error("Cannot lowercase domain with no email address", "MB009");

	(my $lc = $email) =~ s/^(.+)@(.+)$/$1@\L$2/;

	return $lc;

};

=pod

=item setDuplicate

sets an email address as a duplicate.

 $bulk->setDuplicate($email);

once an address is set as a duplicate, then isDuplicate will return a true value for that address

 print $bulk->isDuplicate($email2);	#prints 0
 $bulk->setDuplicate($email2);
 print $bulk->isDuplicate($email2);	#prints 1

This is mainly used internally, but I decided to make it external anyway.

setDuplicate will always return 1 if you have Trusting('duplicates') set.

Be warned that there is a performance hit to using this, since it will eventually store your entire list inside an
entire hashref in memory. You're in much better shape if you weed out the duplicates in advance and then set Trusting('duplicates' => 1)
to skip the check and skip storing the values in the hashref.

But if you have to use this to weed out values, go to town.

This method is known to be able to return:

 MB010 - cannot set duplicate w/o email
=cut

sub setDuplicate {
	my $self	= shift;
	my $email	= shift || return $self->error("Cannot set duplicate without email", "MB010");

	return 1 if $self->Trusting('duplicates');

	if (! $self->Trusting('banned')) {
		$self->_duplicates->{lc $email} = 1;
	}
	else {
		$self->_duplicates->{$self->lc_domain($email)} = 1;
	};

	return 1;
};

=pod

=item isDuplicate

returns a boolean value as to whether an email address is a duplicate

 print $bulk->isDuplicate($email); #prints 0 or 1

once an address is set as a duplicate, then isDuplicate will return a true value for that address

 print $bulk->isDuplicate($email2);	#prints 0
 $bulk->setDuplicate($email2);
 print $bulk->isDuplicate($email2);	#prints 1

This is mainly used internally, but I decided to make it external anyway.

isDuplicate will always return 0 if you have Trusting('duplicates' => 1) set.

Be warned that there is a performance hit to using this, since it will eventually store your entire list inside an
entire hashref in memory. You're in much better shape if you weed out the duplicates in advance and then set Trusting('duplicates' => 1)
to skip the check and skip storing the values in the hashref.

But if you have to use this to weed out values, go to town.

=cut

sub isDuplicate {
	my $self	= shift;
	my $email	= shift || return $self->undef("Cannot check duplicate without email", "MB015");

	return 0 if $self->Trusting('duplicates');

	if (! $self->Trusting('banned')){
		return $self->_duplicates->{lc $email};
	}
	else {
		return $self->_duplicates->{$self->lc_domain($email)};
	};
};

=pod

=item isBanned

returns a boolean value as to whether an email address (or domain) is banned or not

 $bulk->isBanned($email);	#prints 0 or 1
 $bulk->isBanned($domain);	#prints 0 or 1

->isBanned goes off of the values populated via the banned attribute

This is mainly used internally, but I decided to make it external anyway.

=cut

sub isBanned {
	my $self	= shift;
	my $email	= shift || return $self->undef("Cannot check banned-ness without email", "MB016");

	(my $domain = $email) =~ s/^.+@//;

	return 2 if $self->banned->{lc $domain};

	if (! $self->Trusting('banned')){
		return $self->banned->{lc $email};
	}
	else {
		return $self->banned->{$self->lc_domain($email)};
	};
};

=pod

=item nextServer

Again, mainly used internally.

->nextServer will iterate over the ->servers array and return the next valid, connected server. If a server is
not connected, ->nextServer will try to make it connect. If the server cannot connect, it will go on to the next one.

Once all servers are exhausted, it returns undef.

nextServer is called if the present server object has reached one of its internal limits. See Mail::Bulkmail::Server for more
information on server limits.

This method is known to be able to return:

 MB011 - No servers (->servers array is empty)
 MB012 - No available servers (cannot connect to any servers)

=cut

sub nextServer {
	my $self = shift;

	return $self->error("No servers", "MB011") unless $self->servers && @{$self->servers};

	my $old_idx = $self->_server_index;
	my $new_idx = ($old_idx + 1) % @{$self->servers};

	#special case for loop prevention. Internally, we initially start @ -1, to start off at 0 instead of 1.
	$old_idx = 0 if $new_idx == 0;

	while (1){
		#prevent infinite loops. If we get back to the beginning AND that server is worthless ("not not worthless"), then
		#we can't connect to any of 'em.
		if ($new_idx == $old_idx && ! $self->servers->[$new_idx]->_not_worthless){
			return $self->error("No available servers", "MB012");
		}
		else {
			#if we're connected, we're golden.
			if ($self->servers->[$new_idx]->connected){
				$self->_server_index($new_idx);
				return $self->servers->[$new_idx];
			}
			#otherwise, try to connect
			else {
				$self->servers->[$new_idx]->connect;

				#if we succeed, we're golden
				if ($self->servers->[$new_idx]->connected){
					$self->_server_index($new_idx);
					return $self->servers->[$new_idx];
				}
			}
		};

		#otherwise, no matter what, if we're down here we want to look at the next server in the list
		$new_idx = ($new_idx + 1) % @{$self->servers};
	};

};

=pod

=item extractEmail

The extract methods return results equivalent to the return of valid_email

extracts the email address from the data passed in the bulkmail object. Not necessary in Mail::Bulkmail, since all it
does in here is reflect through the same value that is passed.

This will be very important in a subclass, though. getNextLine might return values beyond just simple email addresses
in subclasses, hashes, objects, whatever. You name it. In that case, extractEmail is necessary to find the actual email
address out of whatever it is that was returned from getNextLine().

But here? Nothing to worry about.

This method is known to be able to return:

 MB013 - cannot extract email w/o email

=cut

sub extractEmail {
	my $self	= shift;
	my $email	= shift || return $self->error("Cannot extract email w/o email", "MB013");

	return $self->valid_email($$email);

};

=pod

=item extractSender

The extract methods return results equivalent to the return of valid_email

extracts the sender of the message from the data passed in the bulkmail object. Not necessary in Mail::Bulkmail, since
all it does in here is return either the Bulkmail object's Sender or its From field.

This will be very important in a subclass, though. getNextLine might return values beyond just simple email addresses
in subclasses - hashes, object, whatever. You name it. In that case, extractEmail is necessary to find the actual email
address out of whatever it is that was returned from getNextLine().

But here? Nothing to worry about.

=cut

sub extractSender {
	my $self = shift;

	#we cheat like a madman in this method. We -know- that the Sender and the From are valid, since we validated
	#them before they're insered. So we do the trivial extract and return that way.

	my $sender = $self->Sender || $self->From;
	my $return_hash = {'original' => $sender};
	$sender =~ s/.+<(.+)>/$1/g;
	$return_hash->{'extracted'} = $sender;
	return $return_hash;
};

=pod

=item extractReplyTo

The extract methods return results equivalent to the return of valid_email

extracts the Reply-To of the message from the data passed in the bulkmail object. Not necessary in Mail::Bulkmail, since
all it does in here is return either the Bulkmail object's Sender or its From field.

This will be very important in a subclass, though. getNextLine might return values beyond just simple email addresses
in subclasses - hashes, object, whatever. You name it. In that case, extractEmail is necessary to find the actual email
address out of whatever it is that was returned from getNextLine().

But here? Nothing to worry about.

=cut

sub extractReplyTo {
	my $self = shift;

	#we cheat like a madman in this method. We -know- that the Sender and the From are valid, since we validated
	#them before they're insered. So we do the trivial extract and return that way.

	my $replyto = $self->ReplyTo || $self->From;
	my $return_hash = {'original' => $replyto};
	$replyto =~ s/.+<(.+)>/$1/g;
	$return_hash->{'extracted'} = $replyto;
	return $return_hash;
};

=pod

=item preprocess

This is another method that'll do more in a subclass. When you had off data to either ->mail or ->bulkmail,
it gets preprocessed before it's actually used. In Mail::Bulkmail itself, all it does is take a non-reference
value and turn it into a reference, or return a reference as is if that was passed.

Here, the whole method:

 sub preprocess {
 	my $self	= shift;
 	my $val		= shift;

 	return ref $val ? $val : \$val;
 };

But in a subclass, this may be much more important. Making sure that your data is uniform or valid, that
particular values are populated, additional tests, whatever.

=cut

sub preprocess {
	my $self	= shift;
	my $val		= shift;

	return ref $val ? $val : \$val;
};

# _force_wrap_string is an internal method that handles wrapping lines as appropriate, either to 80 characters per line
# if ->force80 is true, and otherwise to 1000 characters to comply with RFC2822. Will not touch the string
# if Trusting is set to 1.
#
# though this is re-written, I'm still not terribly thrilled with it.

sub _force_wrap_string {
	my $self = shift;
	my $string = shift;
	my $spaceprepend= shift || 0;
	my $noblanks	= shift || 0;

	#if we're trusting the wrap, just return the string
	return $string if $self->Trusting('wrapping');

	#determine the length we wrap to
	my $length = $self->force80 ? 78 : 998;

	#if we're tacking a space on to the front, that's an extra character, so decrement the length to match
	$length-- if $spaceprepend;

	#we want to split into as many fields as there are returns in the message
	my @returns = $string =~ m/(\015\012)/g;

	my @lines = split(/\015\012/, $string, scalar @returns);
	foreach (@lines){
		if (length $_ > $length){
			my $one = 0;
			# boy, did this take finesse. Only prepend a space if it's not the start of the original line
			# That way, we can properly wrap our headers. That's what $one is.

			# this regex puts as many characters before a wordbreak as it can into $1, and the rest into $2.
			# if a string is a solid word greater than the the length, it all goes into $2
			$_ =~ s/(?:([^\015\012]{1,$length})\b)?([^\015\012]+)/$self->_process_string($1, $2, $length, $spaceprepend && ! $one++ ? 1 : 0)/ge;
		};
	};

	#rebuild our string
	$string = join("\015\012", @lines);

	#get rid of any blank lines we may have created, if so desired.
	if ($noblanks){
		$string =~ s/\015\012[^\015\012\S]*\015\012/\015\012/g while $string =~ /\015\012[^\015\012\S]+\015\012/;
	};

	return $string;
};

# process string is used internally by _force_wrap_string to do wrapping, as appropriate.

sub _process_string {
	my $self			= shift;
	my $one				= shift || '';	#$1, passed from _force_wrap_string
	my $two				= shift || '';	#$2, passed from _force_wrap_string
	my $length			= shift;		#the length we're wrapping to
	my $spaceprepend	= shift || 0;	#whether we're prepending a space

	#re-define the spaceprepend to the character we will prepend.
	$spaceprepend = $spaceprepend ? ' ' : '';

	#if we don't have $1, then we have a single word greater than the length. Cut it up at the length point, globally
	if (! $one){
		$two =~ s/([^\015\012]{$length})/$1\015\012$spaceprepend/g;
		return $two;
	}
	#otherwise, use the same regex that _force_wrap_string uses and proceed recusively.
	else {
		$two =~ s/(?:([^\015\012]{1,$length})\b)?([^\015\012]+)/$self->_process_string($1, $2, $length, $spaceprepend)/ge;
		return "$one\015\012$spaceprepend$two";
	}
};

=pod

=item buildHeaders

buildHeaders is mainly used internally, like its name implies, it builds the headers for the message.

You'll never need to call buildHeaders unless you're subclassing, in which case you may want to override this method
with a new routine to build headers in a different fashion.

This method is called internally by ->bulkmail and ->mail otherwise and is not something you need to worry about.

The first time buildHeaders is called, it populates _cached_headers so as not to have to go through the processing of rebuilding
the headers for each address in your list.

This method is known to be able to return:

 MB014 - no From address
 MB015 - no To address

=cut

sub buildHeaders {

	my $self			= shift;
	my $data			= shift;

	my $headers_hash	= shift || $self->_headers;

	if ($self->use_envelope && $self->_cached_headers){
		return $self->_cached_headers;
	}
	elsif ($self->_cached_headers){

		my $headers = ${$self->_cached_headers};

		my $extracted_emails = $self->extractEmail($data);
		my $email = $extracted_emails->{'original'};

		$headers =~ s/^To: ##EMAIL##/To: $email/m;

		return \$headers;
	};

	my $headers	= undef;

	$headers .= "Date: " . $self->Date . "\015\012";

	if (my $from = $self->From){
		$headers .= "From: " . $from . "\015\012";
	}
	else {
		return $self->error("Cannot bulkmail...no From address", "MB014");
	};

	$headers .= "Subject: " . $self->Subject . "\015\012" if defined $self->Subject && $self->Subject =~ /\S/;

	#if we're using the envelope, then the To: header is the To attribute
	if (my $to = $self->use_envelope ? $self->To : "##EMAIL##"){
		$headers .= "To: $to\015\012";
	}
	else {
		return $self->error("Cannot bulkmail...no To address", "MB015");
	};

	my $sender_hash = $self->extractSender($data);
	if (defined $sender_hash) {
		$headers .= "Sender: "		. $sender_hash->{'original'}		. "\015\012";
	}

	my $reply_to_hash = $self->extractReplyTo($data);
	if (defined $reply_to_hash) {
		$headers .= "Reply-To: "	. $reply_to_hash->{'original'}		. "\015\012";
	};

	#we're always going to specify at least a list precedence
	$headers .= "Precedence: "		. ($self->Precedence || 'list')			. "\015\012";

	if ($headers_hash->{"Content-type"}){
		$headers .= "Content-type: " . $headers_hash->{"Content-type"} . "\015\012";
	}
	else {
		if ($self->HTML){
			$headers .= "Content-type: text/html\015\012";
		}
		else {
			$headers .= "Content-type: text/plain\015\012";
		};
	};

	foreach my $key (keys %{$headers_hash}) {
		next if $key eq 'Content-type';
		my $val = $headers_hash->{$key};

		next if ! defined $val || $val !~ /\S/;

		$headers .= $key . ": " . $val . "\015\012";
	};

	# I'm taking credit for the mailing, dammit!
	$headers .= "X-Bulkmail: " . $Mail::Bulkmail::VERSION . "\015\012";

	$headers = $self->_force_wrap_string($headers, 'start with a blank', 'no blank lines');

	$headers .= "\015\012";	#blank line between the header and the message

	$self->_cached_headers(\$headers);

	unless ($self->use_envelope){
		my $h = $headers;	#can't just use $headers, we'll screw up the ref in _cached_headers
		my $extracted_emails = $self->extractEmail($data);
		my $email = $extracted_emails->{'original'};
		$h =~ s/^To: ##EMAIL##/To: $email/m;
		return \$h;
	};

	return \$headers;

};

=pod

=item buildMessage

buildMessage is mainly used internally, like its name implies, it builds the body of the message

You'll never need to call buildMessage unless you're subclassing, in which case you may want to override this method
with a new routine to build your message in a different fashion.

This method is called internally by ->bulkmail and ->mail otherwise and is not something you need to worry about.

This method is known to be able to return:

 MB016 - ->Message is not defined

=cut

sub buildMessage {
	my $self	= shift;

	my $data	= shift;

	#if we've cached the message, then return it
	return $self->_cached_message if $self->_cached_message && $self->_current_message;

	#otherwise, use the Message, cache that and return it.
	my $message	= $self->Message()
		|| return $self->error("Cannot build message w/o message", "MB016");

	return $message if ref $message;

	#sendmail-ify our line breaks
	$message =~ s/(?:\r?\n|\r\n?)/\015\012/g;

	$message = $self->_force_wrap_string($message);

	#double any periods that start lines
	$message =~ s/^\./../gm;

	#and force a CRLF at the end, unless one is already present
	$message .= "\015\012" unless $message =~ /\015\012$/;
	$message .= ".";

	$self->_cached_message(\$message);
	return \$message;
};

=pod

=item bulkmail

This is the bread and butter of the whole set up, and it's easy as pie.

 $bulk->bulkmail();

will take your list, iterate over it, build all your message headers, build your message, and email to everyone on your
list, iterating through all of your servers, log all relevant information, and send you happily on your way.

Easy as pie. You don't even need to worry about it if you subclass things, because you'd just need to override
buildHeaders, buildMessage, getNextLine and extractEmail at most.

This method is known to be able to return:

 MB017 - duplicate email
 MB018 - banned email
 MB019 - invalid sender/from

=cut

sub bulkmail {
	my $self	= shift;

	my $server	= $self->nextServer || return undef;

	my $last_data = undef;

	while (defined (my $data = $self->getNextLine)){

		if (my $r = $server->reached_limit){

			#if a message is waiting on the previous server, then finish it off
			if ($self->_waiting_message) {

				my $headers = $self->buildHeaders($last_data);

				my $message = $self->buildMessage($last_data);

				# it is *imperative* that we only send DATA if we have the headers and message body.
				# otherwise, the server will hang.
				if ($headers && $message) {
					my $rc = $server->talk_and_respond("DATA");
					$server->talk_and_respond($$headers . $$message) if $rc;
				}

				my $extracted_emails = $self->extractEmail($last_data);
				if (defined $extracted_emails) {
					$self->setDuplicate($extracted_emails->{'extracted'});
				};
			};

			$server = $self->nextServer || return undef;

			#new server, so nothing should be waiting, and there are no cached domains
			$self->_waiting_message(0);
			$self->_cached_domain(undef);

			#and reset that server's counters
			$server->reset_message_counters();
		};

		$data =~ s/(?:^\s+|\s+$)//g unless ref $data;

		$data = $self->preprocess($data) || next;

		my $extracted_emails = $self->extractEmail($data) || next;
		my $email = $extracted_emails->{'extracted'};

		#check for duplicates or banned addresses
		if ($self->isDuplicate($email)){

			$self->logToFile($self->BAD, $data) if $self->BAD;

			$self->error("Invalid email address $email : duplicate", "MB017");
			next;
		}
		elsif (my $b = $self->isBanned($email)){

			$self->logToFile($self->BAD, $data) if $self->BAD;

			$self->error("Invalid email address $email : " . ($b == 2 ? 'banned domain' : 'banned address'), "MB018");
			next;
		};

		#use the envelope, if we're using it
		if ($self->use_envelope){

			#extract the domain from the email address
			(my $domain = lc $email) =~ s/^[^@]+@//;

			#first, see if this is a new domain, either the first time through, if it's a different domain than the last
			#one we saw, or if we reached the server's envelope limit
			if (! $self->_cached_domain || ($self->_cached_domain && $domain ne $self->_cached_domain()) || $server->reached_envelope_limit) {

				#if a message is waiting, then finish it off
				if ($self->_waiting_message) {
					my $headers = $self->buildHeaders($last_data);

					my $message = $self->buildMessage($last_data);

					# it is *imperative* that we only send DATA if we have the headers and message body.
					# otherwise, the server will hang.
					if ($headers && $message) {
						my $rc = $server->talk_and_respond("DATA");
						$server->talk_and_respond($$headers . $$message) if $rc;
					}

					my $extracted_emails = $self->extractEmail($last_data);
					if (defined $extracted_emails) {
						$self->setDuplicate($extracted_emails->{'extracted'});
					};

					$self->_waiting_message(0);
				};

				#reset our connection, just to be safe

				$server->talk_and_respond("RSET") || next;

				my $from_hash = $self->extractSender($data)
					|| return $self->error("Could not get valid sender/from address", "MB019");

				my $from = $from_hash->{'extracted'};

				#say who the message is from
				$server->talk_and_respond("MAIL FROM:<" . $from . ">") || next;

				#now, since we know that we reset and sent MAIL FROM properly, we'll reset our counter
				#and cache this domain

				#reset that server's envelope counter
				$server->reset_envelope_counter();

				#so now we want to cache this domain
				$self->_cached_domain($domain);

			};

			#now, we add this email address to the envelope
			$server->talk_and_respond("RCPT TO:<" . $email . ">") || next;

			#a message is now waiting to be sent
			$self->_waiting_message(1);

			#make a note of the email address in the log
			$self->logToFile($self->GOOD, $data) if $self->GOOD;

			#we need to keep track of the last email sent, to finish off the final
			#waiting_message at the end.
			$last_data = $data;

			#and finally, we cache the domain
			$self->_cached_domain($domain);

		}

		#not using the envelope
		else {
			$self->mail($data, $server) || next;
		};

		#make a note of this email address
		$self->setDuplicate($email);

		#and we increment our counters
		$server->increment_messages_sent();

	};

	#if a message is waiting, then finish it off
	if ($self->_waiting_message) {

		my $headers = $self->buildHeaders($last_data);

		my $message = $self->buildMessage($last_data);

		# it is *imperative* that we only send DATA if we have the headers and message body.
		# otherwise, the server will hang.
		if ($headers && $message) {
			my $rc = $server->talk_and_respond("DATA");
			$server->talk_and_respond($$headers . $$message) if $rc;
		}

		my $extracted_emails = $self->extractEmail($last_data);
		if (defined $extracted_emails) {
			$self->setDuplicate($extracted_emails->{'extracted'});
		};

		$self->_waiting_message(0);
	};

	return 1;

};

=pod

=item mail

Works the same as ->bulkmail, but only operates on one email address instead of a list.

 $bulk->mail('jim@jimandkoka.com');

Sends your Message as defined in ->Message to jim@jimandkoka.com. You can also optionally pass in a server as the second argument.

 $bulk->mail('jim@jimandkoka.com', $server);

is the same as above, but relays through that particular server. if you don't pass a server, if tries to bring the next one
in via ->nextServer

->mail wants its first argument to be whatever would be normally returned by a call to ->getNextLine($bulk->LIST); Right now,
that's just a single email address. But that may change in a subclass. So, if you're operating in a subclass, just remember that
you may be able (or required) to pass additional information in your first argument.

This method is known to be able to return:

 MB018 - banned email
 MB019 - invalid sender/from address

=cut

sub mail {
	my $self			= shift;
	my $data			= shift;
	my $passed_server	= shift;

	my $server	= $passed_server || $self->nextServer() || return undef;

	$data = $self->preprocess($data);

	my $extracted_emails = $self->extractEmail($data) || return undef;
	my $email = $extracted_emails->{'extracted'};

	if (my $b = $self->isBanned($email)){

		$self->logToFile($self->BAD, $data) if $self->BAD;

		return $self->error("Invalid email address $email : " . ($b == 2 ? 'banned domain' : 'banned address'), "MB018");
	};

	#reset our connection, just to be safe

	$server->talk_and_respond("RSET")
		|| return $self->error($server->error, $server->errcode, 'not logged');

	my $from_hash = $self->extractSender($data)
		|| return $self->error("Could not get valid sender/from address", "MB019");

	my $from = $from_hash->{'extracted'};

	#say who the message is from
	$server->talk_and_respond("MAIL FROM:<" . $from . ">")
		|| return $self->error($server->error, $server->errcode, 'not logged');

	#now, we add this email address to the envelope
	$server->talk_and_respond("RCPT TO:<" . $email . ">")
		|| return $self->error($server->error, $server->errcode, 'not logged');

	#we build the headers and message body FIRST, to make sure we have them.
	#that way, we can never send DATA w/o a message and hang the server
	my $headers = $self->buildHeaders($data) || return undef;

	my $message = $self->buildMessage($data) || return undef;

	$server->talk_and_respond("DATA")
		|| return $self->error($server->error, $server->errcode, 'not logged');

	$server->talk_and_respond($$headers . $$message) || return undef;

	#make a note of the email address in the log
	$self->logToFile($self->GOOD, $data) if $self->GOOD;

	return $email;
};

1;

__END__

=pod

=back

=head1 FAQ

=over 5

=item So just how fast is this thing, anyway?>

I don't know any more, I don't have access to the same gigantic lists I used to anymore.  :~(

But, basically, Really fast.  Really stupendously incredibly fast.

The last official big benchmark I ran was with v1.11. That list runs through to completion in about
an hour and 43 minutes, which meant that Mail::Bulkmail 1.11 could process (at least) 884 messages per minute or about
53,100 per hour.

The last message sent out was 4,979 bytes.  4979 x 91,140 people is 453,786,060 bytes of data
transferred, or about 453.786 megabytes in 1 hour and 43 minutes.  This is a sustained transfer rate of about 4.4 megabytes
per minute, or 264.34 megabytes per hour.

So then, that tells you how fast the software was back in 1999, 2 major revisions ago. But, invariably, you want to know what it's
like *now*, right? Well, I'll do my best to guesstimate it. However, these tests were not run through an SMTP relay, they were run
using DummyServer in v3.0 and a hacked 2.05 and (severely) hacked 1.11 to insert similar functionality. All data was sent to /dev/null.

Tests were performed on a 5,000 recipient list.

First of all, with envelope sending turned off (average times):

 v1.11......20 seconds	(1.00)
 v3.00......23 seconds	(1.15)
 v2.05......50 seconds	(2.5)

1.11 was the speed champ in this case, but that's not surprising considering the fact that it did a lot less processing than the
other 2. The fact that 3.00 almost catches it should speak to the improvement in the code in the 3.x release. 2.05 was...clunky.

Now then, there's another thing to consider, envelope sending. With envelope sending turned on (average times):

 v3.00......12 seconds	(1.00)
 v2.05......19 seconds	(1.58)
 v1.11......22 seconds	(1.83)

This is with an envelope_limit of 100. So the supposed speed gains that envelope sending were supposed to see in 2.05 never
really materialized. While doing these tests, I discovered a bug in 2.05's use_envelope routine that would sometimes cause it
to slow down substantially. 3.00, with a new routine, was never affected. Incidentally, Bulkmail 2.05 will be faster with trivially
low envelope_limits. Bulkmail 3.00 becomes faster with an envelope_limit greater than 2.

There is also mail merging (filemapping in 1.x) that should be considered. This was benchmarked with Mail::Bulkmail::Dynamic for 3.00.
A simple mail merge with one item was used, and one global item, read from a file, and split on a delimiter (since this was the
only functionality that v1.x had). With mail merge turned on (average times):

 v1.11......20 seconds	(1.00)
 v3.00......35 seconds	(1.75)
 v2.05......40 seconds	(2.00)

And finally, 2.x and 3.x have both had the capability to generate a dynamic message. This is a minimal test with one dynamic
message element, one dynamic header, and a mail merge into the dynamic element:

 v3.00......36 seconds	(1.00)
 v2.05......44 seconds	(1.22)

So 3.x is usually faster than 2.x, but sometimes slower than 1.x. Which makes sense, again due to the added features in 2.x and 3.x.

These tests do not take into account the multi-server capability introduced in 3.00.

Also note that these speeds are only measuring the time it takes to get from Mail::Bulkmail to your SMTP relay. There are no
measurements reflecting how long it may take your SMTP relay to send the data on to the recipients on your list.

=item Am I going to see speeds that fast?

Maybe, maybe not.  It depends on how busy your SMTP server is.  If you have a relatively unused SMTP server with a fair amount
of horsepower and a fast connection, you can easily get these speeds or beyond.  If you have a relatively busy and/or low powered
SMTP server or slow connections, you're not going to reach speeds that fast.

=item How much faster will Mail::Bulkmail be than my current system?

This is a very tough question to answer, since it depends highly upon what your current system is.  For the sake of argument,
let's assume that for your current system, you open an SMTP connection to your server, send a message, and close the connection.
And then repeat.  Open, send, close, etc.

Mail::Bulkmail will I<always> be faster than this approach since it opens one SMTP connection and sends every single message across
on that one connection.  How much faster depends on how busy your server is as well as the size of your list. The connection will
only be closed if you have an error or if you reach the max number of messages to send in a given server connection.

Lets assume (for simplicity's sake) that you have a list of 100,000 people.  We'll also assume that you have a pretty busy
SMTP server and it takes (on average) 25 seconds for the server to respond to a connection request.  We're making 100,000
connection requests (with your old system).  That means 100,000 x 25 seconds = almost 29 days waiting just to make connections
to the server!  Mail::Bulkmail makes one connection, takes 25 seconds for it, and ends up being 100,000x faster!

But, now lets assume that you have a very unbusy SMTP server and it responds to connection requests in .003 seconds.  We're making
100,000 connection requests.  That means 100,000 x .0003 seconds = about 5 minutes waiting to make connections to the server.
Mail::Bulkmail makes on connection, takes .0003 seconds for it, and ends up only being 1666x faster.  But, even though being
1,666 times faster sounds impressive, the world won't stop spinning on its axis if you use your old system and take up an extra
5 minutes.

And this doesn't even begin to take into account systems that don't open and close SMTP connections for each message.

This also doesn't take into account the load balancing between multiple SMTP relays that 3.00 can perform.

In short, there's no way for me to tell how much faster (if at all) it'll be. Try it and find out.

=item Have you benchmarked it against anything else?

Not scientifically.  I've heard that Mail::Bulkmail 1.10 is about 4-5x faster than Listcaster from Mustang Software, but I don't
have any hard numbers.  But nothing beyond that.

If you want to benchmark it against some other system and let me know the results, it'll be much appreciated.  :-)

=item Can I send spam with this thing?

No.  Don't be a jerk.

=item SMTP relay? Wazzat?

All Mail::Bulkmail does is provide you a quick way to relay information from your local machine through to your SMTP relay (which may
be the same machine). Your SMTP relay then sends the messages on to the rest of the world.

So your SMTP server must be configured properly to allow you to relay your messages out. It is recommended that this machine be kept
behind a firewall for security reasons. Make sure that it's configured properly so it's not an open relay. Ask your SysAdmin for help.

=item What about multi-part messages?

Not yet supported. I'll definitely add internal support for multi-part/alternative in the future.

Until then? You can always do the MIME encoding yourself, set your own headers, etc. It's perfectly fine to do it yourself, but you
will have to do it yourself for now.

=item Mail::Bulkmail is really cool, but what'd be even cooler is a front end for the thing! Do you have one of those?

I don't. But check out Mojo Mail:

 http://mojo.skazat.com/

Active community, developer, etc. Looks like a good product.

=item You know, you re-invent a lot of wheels.

Yeah, I do. Hey, c'mon, I write this stuff for the fun of it. And that means that I'm going to do it the way that I want to. :)
Besides, I've never had any problem with re-inventing wheels. After all, if the wheel hadn't been re-invented a few times, we'd
still be using solid plain wooden wheels. Not to say that I necessarily think that I've invented better things here than are
available elsewhere, but I might eventually. Who knows.

Anyway, you're more than free to subclass and over-ride things with "standard" modules if you'd like. ou can make your
own server implementation using Net::SMTP, or your own dynamic message system using Text::Template, or whatever else. Feel free
to use the standards if you'd prefer.

Me? I enjoy re-inventing wheels, so I'll continue to do so.

=item Dude! Warnings is on!

That's by design. Nothing in the code ever should generate a warning, but if it does, then please please B<please> let me know
about it so I can patch it. You can always turn off warnings yourself if you're worried/annoyed.

=item So what is it with these version numbers anyway?

I'm going to I<try> to be consistent in how I number the releases.

The B<hundredths> digit will indicate bug fixes, minor behind-the-scenes changes, etc.

The B<tenths> digit will indicate new and/or better functionality, as well as some minor new features.

The B<ones> digit will indicate a major new feature or re-write.

Basically, if you have x.ab and x.ac comes out, you want to get it guaranteed.  Same for x.ad, x.ae, etc.

If you have x.ac and x.ba comes out, you'll probably want to get it.  Invariably there will be bug fixes from the last "hundredths"
release, but it'll also have additional features.  These will be the releases to be sure to read up on to make sure that nothing
drastic has changes.

If you have x.ac and y.ac comes out, you'll want to do research before upgrading. I break things, I lose backwards compatibility,
I change stuff around a lot. Just my nature. Porting from one major release to the next is pretty straightforward, but there's still
work to be done on your part - it won't just be a drop in replacement. And, depending upon your list and what options you're using, you
may or may not see any benefit to upgrading. Read the docs, ask me questions, and test test test.

Don't get me wrong, I'm not going to intentially *try* to make things not backwards compatible, but if I come up with what I think
is a better way of doing things, I'm going to go with it. And I don't like to pollute modules with a lot of cruft bridgeworks for
backwards compatibility. This thing is huge enough as is without having to worry about making sure internal band-aids work.

If this'll be a problem, then don't upgrade.

=item Is anything missing vs. the old versions?

Yes. You can't currently extract headers from the message you're sending. This will return in the future, probably.

When using dynamic_header_data, you can no longer set a default header to be used if no header is defined for the individual user.
This will also probably return in the future.

local merges no longer exist. You only have global merges and individual ones.

It will now date all messages to the time of the first sent message.

You can no longer externally load in a list of duplicates. Come on, did *anybody* ever actually do that?

=item When I try to bulkmail, I get an error that says "Cannot bulkmail...no To address" How do I fix this?

Ya know, I B<thought> this error was self-explanatory, but considering the number of people that email me
about it, I guess it's not.

The issue here is that (say it with me now), you can't bulkmail because the To header hasn't been set.
If you're using envelope sending (on by default in Mail::Bulkmail), then you have to specify an address
to set in the To: header of the message. This is specified via the ->To accessor.

 $bulk->To("mylist@mysite.com");

So, specify the To header, and then you'll be fine.

=item Wow, this module is really cool.  Have you contributed anything else to CPAN?

Yes, Carp::Notify and Text::Flowchart

=item Was that a shameless plug?

Why, yes.  Yes it was.

=item Anything else you want to tell me?

Sure, anything you need to know.  Just drop me a message.

=back

=head1 EXAMPLES

#simple mailing with a list called "./list.txt"

 my $bulk = Mail::Bulkmail->new(
 	"LIST" 		=> "./list.txt",
 	"Subject"	=> "A test message",
 	"Message"	=> "This is my test message",
 	"From"		=> 'me@mydomain.com',
 	"To"		=> 'somelist@mydomain.com',
 	"Reply-To"	=> 'replies@mydomain.com'
 ) || die Mail::Bulkmail->error();

 $bulk->bulkmail || die $bulk->error;

#same thing, but turning off envelope sending

 my $bulk = Mail::Bulkmail->new(
 	"LIST" 			=> "./list.txt",
 	"Subject"		=> "A test message",
 	"Message"		=> "This is my test message",
 	"From"			=> 'me@mydomain.com',
 	"Reply-To"		=> 'replies@mydomain.com',
 	"use_envelope" => 0
 ) || die Mail::Bulkmail->error();

 $bulk->bulkmail || die $bulk->error;

#Small example, with a miniature in memory list

 my $bulk = Mail::Bulkmail->new(
 	"LIST" 		=> [qw(test@mydomain.com me@mydomain.com test2@mydomain.com)],
 	"Subject"	=> "A test message",
 	"Message"	=> "This is my test message",
 	"From"		=> 'me@mydomain.com',
 	"To"		=> 'somelist@mydomain.com',
 	"Reply-To"	=> 'replies@mydomain.com',
 	"Sender"	=> 'sender@mydomain.com'
 ) || die Mail::Bulkmail->error();

 $bulk->bulkmail || die $bulk->error;

#Make sure our error logging is on in a different place, and set up a different server

 my $server = Mail::Bulkmail::Server->new(
 	'Smtp' => "smtp.mydomain.com",
 	"Port" => 25
 ) || die Mail::Bulkmail::Server->error();

 my $bulk = Mail::Bulkmail->new(
 	"LIST" 		=> "./list.txt",
 	"Subject"	=> "A test message",
 	"Message"	=> "This is my test message",
 	"From"		=> 'me@mydomain.com',
 	"To"		=> 'somelist@mydomain.com',
 	"Reply-To"	=> 'replies@mydomain.com',
 	"ERRFILE"	=> '/etc/mb/error.file.txt',
 	"servers"	=> [$server]	#our new server
 ) || die Mail::Bulkmail->error();

 $bulk->bulkmail || die $bulk->error;

#Make sure our error logging is on in a different place, and set up a different server
#this time, we'll use a dummy server for debugging purposes

 my $dummy_server = Mail::Bulkmail::DummyServer->new(
 	"dummy_file"	=> "/etc/mb/dummy.server.output.txt"
 ) || die Mail::Bulkmail::DummyServer->error();

 my $bulk = Mail::Bulkmail->new(
 	"LIST" 		=> "./list.txt",
 	"Subject"	=> "A test message",
 	"Message"	=> "This is my test message",
 	"From"		=> 'me@mydomain.com',
 	"To'		=> 'somelist@mydomain.com',
 	"Reply-To"	=> 'replies@mydomain.com',
 	"ERRFILE"	=> '/etc/mb/error.file.txt',
 	"servers"	=> [$dummy_server]	#our new server, which is a dummy server
 ) || die Mail::Bulkmail->error();

 $bulk->bulkmail || die $bulk->error;

#mailing just to one address

 my $bulk = Mail::Bulkmail->new(
 	"Subject"	=> "A test message",
 	"Message"	=> "This is my test message",
 	"From"		=> 'me@mydomain.com',
 	"Reply-To"	=> 'replies@mydomain.com',
 	"Sender"	=> 'sender@mydomain.com'
 ) || die Mail::Bulkmail->error();

 $bulk->mail('test@yourdomain.com') || die $bulk->error;

#here, a fun one. Use a coderef as our LIST

 my $query = "select email, domain from table order by domain";
 my $stmt = $dbh->prepare($query) || die;

 $stmt->execute || die;

 sub get_list {
 	my $bulk = shift; #we always get our bulkmail object first

 	my $data = $stmt->fetchrow_hashref();

 	if ($data) {
 		return $data->{"email"};
 	}
 	else {
 		return undef;
 	};
 };

 $bulk->LIST(\&get_list);

 #and now, logging to a coderef.

 my $query = ('insert into table good_addresses (email) values (?)');
 my $stmt = $dbh->prepare($query) || die;

 sub store_to_db {
 	my $bulk	= shift; #always get our bulkmail object first
 	my $email	= shift;

 	$stmt->execute($email) || return $bulk->error("Could not store to DB!");
 	return 1;
 };

 $bulk->GOOD(\&store_to_db);

=head1 SAMPLE CONFIG FILE

This is my current conf file. It's about as close to one that you want to use as possible. Remember, you
can set any values you'd like in the conf file, as long as they're scalars or arrayrefs of scalars. For example, if you
want a default "From" value, then define it in the conf file.

For more information on conf files, see Mail::Bulkmail::Object. For more information on the server file, see
Mail::Bulkmail::Server. This file is also stored in the file "sample.cfg.file"

 define package Mail::Bulkmail

 #server_class stores the server object that we're going to use.
 #uncomment the DummyServer line and comment out the Server line for debugging

 server_class = Mail::Bulkmail::Server
 #server_class = Mail::Bulkmail::DummyServer

 #log our errors
 ERRFILE = /etc/mb/error.txt
 BAD    = /etc/mb/bad.txt
 GOOD   = /etc/mb/good.txt
 banned = /etc/mb/banned.txt

 #if we want a default From value, you can place it here.
 #From = me@mydomain.com

 define package Mail::Bulkmail::Server

 #set up the domain we use to say HELO to our relay
 Domain = mydomain.com

 #Most servers are going to connect on port 25, so we'll set this as the default port here
 Port = 25

 #We'll give it 5 tries to connect before we let ->connect fail
 Tries = 5

 #Lets try to reconnect to a server 5 times if ->connect fails.
 max_connection_attempts = 5

 #100 is a good number for the envelope_limit
 envelope_limit = 100

 #Send 1,000 messages to each server in the round before going to the next one.
 #set max_messages_per_robin to 0 if you're only using one server, otherwise you'll have needless
 #overhead
 max_messages_per_robin = 0

 #maximum number of messages per connection. Probably best to keep this 0 unless you have a reason
 #to do otherwise
 max_messages_per_connection = 0

 #maximum number of messages for the server. Probably best to keep this 0 unless you have a reason
 #to do otherwise
 max_messages= 0

 #maximum number of messages to send before sleeping, probably best to keep this 0 unless you need
 #to let your server relax and sleep
 max_messages_while_awake = 0

 #sleep for 10 seconds if we're sleeping. This line is commented out because we don't need it.
 #No harm in uncommenting it, though.
 #sleep_length = 10

 #our list of servers
 server_file = /etc/mb/servers.txt

 define package Mail::Bulkmail::Dynamic

 #it is highly recommended that quotemeta be 1
 quotemeta = 1

 #set up our default delimiters
 dynamic_message_delimiter			= ;
 dynamic_message_value_delimiter	= =
 dynamic_header_delimiter			= ;
 dynamic_header_value_delimiter		= =

 #we're going to assume that duplicates have been weeded out, so we'll allow them.
 Trusting	@= duplicates

 #By default, we'll turn on our envelope. Mail::Bulkmail might as well use it.
 #Mail::Bulkmail::Dynamic doesn't care about this value.
 use_envelope    	= 1

 define package Mail::Bulkmail::DummyServer

 #Our dummy data file, for when we're using DummyServer. It's also useful to send the data to
 #/dev/null to test things if you don't care about the message output.
 dummy_file = /etc/mb/dummy.file
 #dummy_file = /dev/null

=head1 DIAGNOSTICS

Bulkmail doesn't directly generate any errors.  If something fails, it will return undef
and set the ->error property of the bulkmail object.  If you've provided an error log file,
the error will be printed out to the log file.

Check the return of your functions, if it's undef, check ->error to find out what happened.

Be warned that isDuplicate and isBanned will return 0 if an address is not a duplicate or banned, respectively,
but this is not an error condition.

=head1 SEE ALSO

Mail::Bulkmail::Object, Mail::Bulkmail::Server, Mail::Bulkmail::Dummy

=head1 COPYRIGHT (again)

Copyright and (c) 1999, 2000, 2001, 2002, 2003 James A Thomason III (jim@jimandkoka.com). All rights reserved.
Mail::Bulkmail is distributed under the terms of the Perl Artistic License.

=head1 CONTACT INFO

So you don't have to scroll all the way back to the top, I'm Jim Thomason (jim@jimandkoka.com) and feedback is appreciated.
Bug reports/suggestions/questions/etc.  Hell, drop me a line to let me know that you're using the module and that it's
made your life easier.  :-)

http://www.jimandkoka.com/jim/perl/ for more perl info, http://www.jimandkoka.com in general

=cut
