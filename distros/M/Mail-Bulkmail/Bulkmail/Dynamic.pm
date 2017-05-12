package Mail::Bulkmail::Dynamic;

# Copyright and (c) 1999, 2000, 2001, 2002, 2003 James A Thomason III (jim@jimandkoka.com). All rights reserved.
# Mail::Bulkmail::Dynamic is distributed under the terms of the Perl Artistic License.


=pod

=head1 NAME

Mail::Bulkmail::Dynamic - platform independent mailing list module for mail merges and dynamically built
messages

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 SYNOPSIS

 my $bulk = Mail::Bulkmail::Dynamic->new(
 	"merge_keys"		=> [qw(BULK_EMAIL name id address city state zip)],
 	"merge_delimiter"	=> "::",
	"LIST" 				=> "~/my.list.txt",
	"From"				=> "'Jim Thomason'<jim@jimandkoka.com>",
	"Subject"			=> "This is a test message",
	"Message"			=> "Here is my test message"
 ) || die Mail::Bulkmail->error();

 $bulk->bulkmail() || die $bulk->error;

Don't forget to set up your conf file!

=head1 DESCRIPTION

Mail::Bulkmail 1.00 had a thing called "filemapping", it was to allow you to dynamically populate certain variables
into your message. Put in people's names, or the like.

2.00 renamed "filemapping" to the correct term - "mail merging", and also added in the ability to dynamically
create your message, if so desired. So you could very easily send out completely different messages to
everyone on your list, if so desired. But 2.00 also added a *lot* of processing overhead, most of which
was unfortunately in the form of voodoo. i.e., I seem to recall lots of testing, debugging, etc. until I
finally reached a point where the code worked and I sent it off. Not quite sure how it worked, mind you,
but happy with the fact that it worked nonetheless.

3.00 strips that ability out of Mail::Bulkmail, cleans it up, and places it here. This has a few advantages.
For one thing, if you're not doing any mailmerging, then you don't have to worry about any of the overhead
of building hashes, doing checks, internally handling things, and so on. There wasn't a tremendous amount
of useless work done in that case, but it was enough to be noticed. So now use Mail::Bulkmail if you're
not doing mail merges, and Mail::Bulkmail::Dynamic if you are.

And the other thing is that the code is cleaned up a B<lot>. I actually know and understand how it all works
now, and it functions much better than previous versions did. Faster, more efficient, and so on.

=cut

use Mail::Bulkmail;
@ISA = qw(Mail::Bulkmail);

$VERSION = '3.12';

use strict;
use warnings;

=pod

=head1 ATTRIBUTES

=over 11

=item log_all_data

boolean flag, 1/0.

Mail::Bulkmail has an easy job logging its list items - they're always guaranteed to be single email
addresses. Mail::Bulkmail::Dynamic has a harder time, since it's usually an email address and some other data.

 'jim@jimandkoka.com::Jim Thomason::24'
 or
 ['jim@jimandkoka.com', "Jim Thomason", "24"]
 or
 {
 	"BULK_EMAIL" => 'jim@jimandkoka.com',
 	"name"		 => "Jim Thomason",
 	"age"		 => "24"
 }

Most of that is obviously not simple scalar data and needs to be logged differently. If log_all_data is
set to 0, then only the email address will be logged and everything is fine. However, if log_all_data is
1, then a hashref containing all of the data is returned (regardless of the type of data structure you
initially handed in). Obviously, you will then need to deal with logging yourself, either by logging to an
arrayref or (better) to a function call. Logging to a file with log_all_data set to 1 will just give you
a useless list of "HASH(0x7482)" and the like.

All pieces may be used simultaneously. So in one mailing, you can use merge_keys, dynamic_message_data,
dynamic_header_data, and global_merge.

=cut

__PACKAGE__->add_attr('log_all_data');

=pod

=item merge_keys

This should be much easier to use and understand than it was in prior versions.

Okay, let's start off with the simple case, you have a file that contains a list of email addresses:

 foo@bar.com
 bob@hope.com
 john@junior.com

And you set up a list with Mail::Bulkmail to mail to them. Your message is something like this:

 "Hi there. Things are great in my world, how's yours?"

This works fine for a while, people are happy, everything's dandy. But then, you decide that it would
be nice to personalize your email messages in some fashion. So you switch to Mail::Bulkmail::Dynamic.
You'll need more information in your list of addresses now.

 foo@bar.com::Mr. Foo
 me@there.com::Bob Hope
 john@junior.com::John Jr.

And then you'll need to define your merge_keys. merge_keys is an arrayref that defines how the data in your
file is structured:

 merge_keys => [qw(BULK_EMAIL <<NAME>>)]

That tells Mail::Bulkmail::Dynamic that the first item in your list is the email address, and the second
one is your name. Please note that the email address B<MUST> be called "BULK_EMAIL", that's the keyword
that the module looks for to find the address to send to. The rest of your keys may be named anything you'd
like, but avoid naming keys starting with "BULK_", because those are reserved for my use internally and I
may add more special keys like that in the future.

(You'll also need to make sure that your merge_delimiter is set to "::", see merge_delimiter, below).

Now you can change your message to the following:

 "Hi there, <<NAME>>. Things are great in my world, how's yours?"

This will send out the messages, respectively:

 Hi there, Mr. Foo. Things are great in my world, how's yours?

 Hi there, Bob Hope. Things are great in my world, how's yours?

 Hi there, John Junior. Things are great in my world, how's yours?

And voila. Customization. you may include as much data as you'd like:

 merge_keys = [qw(<<NAME>> BULK_EMAIL <<STATE>> <<AGE>> <<HOBBY>> <<PREFERRED COMPUTER>>)]

 #in your list:
 Jim Thomason::jim@jimandkoka.com::IL::24::Programming Perl::titanium powerbook

 #and then your message.

 Dear <<NAME>>,
 How've you been? I see that your email address is still BULK_EMAIL.
 Are you still living in <<STATE>>? And you're still <<AGE>>, right?

 Do you still enjoy <<HOBBY>>?
 Well, email me back a message from your <<PREFERRED COMPUTER>>.

And that's all there is to it. Just be sure to remember that any keys you define will get clobbered *anywhere*
in the message.

 merge_keys => [qw(BULK_EMAIL name)]
 LIST => [qw(jim@jimandkoka.com::Jim)]

 "Hi there, name. I've always liked your name."

You *probably* want that message to populate as:

 "Hi there, Jim. I've always liked your name."

But it will populate as:

 "Hi there, Jim. I've always liked your Jim."

Which doesn't make sense. So just make sure your keys aren't anywhere else in your message. For example,

 merge_keys => [qw(BULK_EMAIL <name>)]
 LIST => [qw(jim@jimandkoka.com::Jim)]

 "Hi there, <name>. I've always liked your name."

Your list data may be a delimited scalar, as we've been using in our examples:

 jim@jimandkoka.com::Jim::24

Or an arrayref:

 ['jim@jimandkoka.com', 'Jim', '24']

In both of those cases, the order of the data is important. Each data element matches up to a particular
key. So be sure that your data is actually in the same order as defined in your merge_keys array.

Alternatively, you can also just store your data in a hash and pass that in:

 {
 	'BULK_EMAIL'	=> 'jim@jimandkoka.com',
 	'<name>'		=> 'Jim',
 	'<age>'			=> '24'
 }

This is the one case where your merge_keys values will be ignored, and a mailmerge will be done
with the key/value pairs passed in that hashtable.

Passing in a hashtable is the fastest in terms of internal processing, but there may be additional
work on your end to generate the hash. When reading from a file, you should always use delimited strings
(since that's what'd be in your file anyway), but from other sources you can experiment with hashrefs
or arrayrefs and see which is faster for your uses.

mail merges apply to B<both> message B<and> header information. So it's valid to do:

 $dynamic->Subject("Hello there, <name>");

And have the mail merge pick that up.

Note that the merge will be performed in an arbitrary order, independent of what's specified in
merge_keys. So don't expect to have one piece of the merge populate into your message before another one.

=cut

__PACKAGE__->add_attr('merge_keys');

=pod

=item merge_delimiter

If you're reading in from a file, you can't have arrayrefs, hashrefs, whatever. They don't store nicely
in text. So your data will probably be a delimited string. In that case, you need to know the delimiter.
Set it with merge_delimiter.

 #in your list
 jim@jimandkoka.com::Jim

 #then
 $dynamic->merge_delimiter("::");

 #in your list
 jim@jimandkoka.com-+-Jim

 #then
 $dynamic->merge_delimiter('-+-');

 #in your list
 jim@jimandkoka.com,Jim

 #then
 $dynamic->merge_delimiter(',');

Just be sure that your delimiting string occurs *only* as the delimiter and is never embedded in your data.
No escaping of a delimiter is possible.

=cut

__PACKAGE__->add_attr("merge_delimiter");

=pod

=item global_merge

It can be useful to to do a mail merge with non-address specific data. For example, you may want to
put today's date in your subject. But it's silly (if not impossible) to populate that data out to all
of your addresses. This is where the global_merge comes in.

 $dynamic->global_merge(
 	{
 		"<DATE>" => scalar localtime
 	}
 );

 or, at creation:

 my $dynamic = Mail::Bulkmail::Dynamic->new(
 	"global_merge" => {
 		"<DATE>" => scalar localtime
 	}
 );

<DATE> will now change to today's date in your message.

 "Hello, list member. This is the list for <DATE>"

This is a hash table that populates merge data B<before> individual mail merge items. There is no way
to use the same key for both a global_merge and a per-address merge. The global merge will always pick it
up and the individual merge will miss it. So, as always, use different keys.

=cut

__PACKAGE__->add_attr('global_merge');

=pod

=item dynamic_message_data

Mail merges are all well and good, they store unique information about a unique email address. But sometimes
you want to group together several users and send them the same information based upon some other criteria.
That's where dynamic_message_data comes in handy.

This is probably easiest explained via examples. dynamic_message_data is a hashref of hashrefs, such as this:

 $dynamic->dynamic_message_data(
 	{
 		'<agegroup>' => {
 			'over70'	=> 'napping',
 			'40-50'		=> 'amassing wealth',
 			'20-40'		=> 'working',
 			'under20'	=> 'playing'
 		},
 		'<animallover>' => {
 			'hates_animals' => "I see you hate animals.",
 			"likes_animals" => "I see you like animals.",
 			"loves_animals" => "I see you love animals."
 		},
 		'<personalized>' => {
 			'yes'	=> 'Hi there, <name>',
 			'no'	=> 'Hi there'
 		}
 	}
 );

Now then, your merge keys could be defined as such:

 ->merge_keys([qw(BULK_EMAIL <name> <age> BULK_DYNAMIC_MESSAGE)]);

Your list would be:

 foo@bar.com::Mr. Foo::23::<agegroup>=20-40;<animallover>=hates_animals;<personalized>=yes
 me@there.com::Bob Hope::78::<agegroup>=over70;<animallover>=likes_animals;<personalized>=no
 john@junior.com::John Jr.::14::<agegroup>=under20;<animallover>=likes_animals;<personalized>=yes

And finally, your message would be:

 <personalized>. Judging by your age, which is <age>, you should enjoy <agegroup>.
 Oh, and <animallover>

The messages sent out would be, respectively:

 Hi there, Mr. Foo. Judging by your age, which is 23, you should enjoy working.
 Oh, and I see you hate animals.

 Hi there. Judging by your age, which is 78, you should enjoy napping.
 Oh, and I see you like animals.

 Hi there, John Jr.. Judging by your age, which is 14, you should enjoy playing.
 Oh, and I see you like animals.

See? easy as pie. Your dynamic message should be specified in your merge_keys as BULK_DYNAMIC_MESSAGE,
and should be a delimited string (in this case).

 agegroup=20-40;<animallover>=hates_animals;<personilized>=yes

You can specify what delimiters you'd like to use. In this case, your dynamic_message_delimiter is ';',
and your dynamic_message_value_delimiter is '='.

More clearly, this information translates to the following:

 <agegroup>		=> 20-40
 <animallover>	=> hates_animals
 <personilized>	=> yes

Please note that angle brackets are not required, they're just useful for clarity in our example.
This is also perfectly acceptable:

 $dynamic->dynamic_message_data(
 	{
 		'agegroup' => {
 			'over70'	=> 'napping',
 			'40-50'		=> 'amassing wealth',
 			'20-40'		=> 'working',
 			'under20'	=> 'playing'
 		}
 	}
 );

  me@there.com::Bob Hope::78::agegroup=over70

As long as you use the same keys, you're fine.

So you should be able to easily see that we'll look up the message associated with being in the agegroup
of 20-40, the animallover that hates_animals, and then personilized with a choice of 'yes'.

Dynamic message creation is done before mail merging, so you are more than welcome to put mail merge tokens
inside your dynamic message, as we did above with the "<personalized>" token, which may include the mail
merge token of "<name>".

Don't use the same tokens for mailmerges and dynamic messages, since the system may get confused.

Alternatively, instead of a delimited string, you may pass in an arrayref of strings:

 [qw(agegroup=20-40 <animallover>=hates_animals <personilized>=yes)]

or an arrayref of arrayrefs:

 [[qw(agegroup 20-40)], [qw(<animallover> hates_animals)], [qw(<personlized> yes)]]

or a hashref:

 {
	 agegroup		=> 20-40
	 animallover	=> hates_animals
	 personilized	=> yes
 }

Passing in a hashtable is the fastest in terms of internal processing, but there may be additional
work on your end to generate the hash. When reading from a file, you should always use delimited strings
(since that's what'd be in your file anyway), but from other sources you can experiment with hashrefs
or arrayrefs and see which is faster for your uses.

dynamic messages apply to B<only> message information. use dynamic_header_data for dynamic pieces in headers.

Note that the dynamic message creation will be performed in an arbitrary order. So don't expect to
have one piece of the dynamic message populate into your message before another one.

There is one special key for dynamic_message_data, "_default".

 $dynamic->dynamic_message_data(
 	{
 		'<agegroup>' => {
 			'over70'	=> 'napping',
 			'40-50'		=> 'amassing wealth',
 			'20-40'		=> 'working',
 			'under20'	=> 'playing',
 			'_default'	=> 'You have not specified an age group'
 		},
 		'<animallover>' => {
 			'hates_animals' => "I see you hate animals.",
 			"likes_animals" => "I see you like animals.",
 			"loves_animals" => "I see you love animals.",
 			"_default"		=> "I don't know how you feel about animals"
 		},
 		'<personalized>' => {
 			'yes'	=> 'Hi there, <name>',
 			'no'	=> 'Hi there',
 		}
 	}
 );

It should be fairly obvious - if that key is not specified, then the _default value is used.
Using our earlier example, with the following list:

 foo@bar.com::Mr. Foo::23::<agegroup>=20-40

And the same message of:

 <personalized>. Judging by your age, which is <age>, you should enjoy <agegroup>.
 Oh, and <animallover>

The messages sent out would be, respectively:

 . Judging by your age, which is 23, you should enjoy working.
 Oh, and I don't know how you feel about animals.

Note that since <agegroup> was specified, we used that value. Since <animallover> was not specified,
the default was used, and since <personalized> was not specified and has no default, it was simply wiped out.


=cut

__PACKAGE__->add_attr('dynamic_message_data');

=pod

=item dynamic_message_delimiter

If you're reading in from a file, you can't have arrayrefs, hashrefs, whatever. They don't store nicely
in text. So your data will probably be a delimited string. In that case, you need to know the delimiter.
Set it with dynamic_message_delimiter. Note that your dynamic message data is just an entry in your
merge data. We'll assume a merge_delimiter of '::' and a dynamic_message_value_delimiter of '=' for
these examples

 ->merge_keys([qw(BULK_EMAIL <name> BULK_DYNAMIC_MESSAGE)]);

 #in your list
 jim@jimandkoka.com::Jim::agegroup=20-40;animallover=yes

 #then
 $dynamic->dynamic_message_delimiter(";");

 #in your list
 jim@jimandkoka.com::Jim::agegroup=20-40&animallover=yes

 #then
 $dynamic->dynamic_message_delimiter('&');

 #in your list
 jim@jimandkoka.com::Jim::agegroup=20-40,,animallover=yes

 #then
 $dynamic->dynamic_message_delimiter(',,');

Just be sure that your delimiting string occurs *only* as the delimiter and is never embedded in your data.
No escaping of a delimiter is possible.

=cut

__PACKAGE__->add_attr("dynamic_message_delimiter");

=pod

=item dynamic_message_value_delimiter

If you're reading in from a file, you can't have arrayrefs, hashrefs, whatever. They don't store nicely
in text. So your data will probably be a delimited string. In that case, you need to know the delimiter.
Set it with dynamic_message_delimiter. Note that your dynamic message data is just an entry in your
merge data. We'll assume a merge_delimiter of '::' and a dynamic_message_delimiter of ';' for these
examples

 ->merge_keys([qw(BULK_EMAIL <name> BULK_DYNAMIC_MESSAGE)]);

 #in your list
 jim@jimandkoka.com::Jim::agegroup=20-40;animallover=yes

 #then
 $dynamic->dynamic_message_value_delimiter("=");

 #in your list
 jim@jimandkoka.com::Jim::agegroup:=20-40;animallover:=yes

 #then
 $dynamic->dynamic_message_value_delimiter(':=');

 #in your list
 jim@jimandkoka.com::Jim::agegroup--20-40;animallover--yes

 #then
 $dynamic->dynamic_message_value_delimiter('--');

Just be sure that your delimiting string occurs *only* as the delimiter and is never embedded in your data.
No escaping of a delimiter is possible.

=cut

__PACKAGE__->add_attr("dynamic_message_value_delimiter");


=pod

=item dynamic_header_data

Mail merges are all well and good, they store unique information about a unique email address. But sometimes
you want to group together several users and send them the same information based upon some other criteria.
That's where dynamic_message_data comes in handy. dynamic_header_data is virtually identical to dynamic_message_data
in terms of behavior, but it operates on the message header instead of the message instelf.

This is probably easiest explained via examples. dynamic_header_data is a hashref of hashrefs, such as this:

 $dynamic->dynamic_header_data(
 	{
 		'Subject' => {
 			'polite'	=> "Hello, sir",
 			"impolite"	=> "Hello",
 			"rude"		=> "Hey, jerk-off"
 		},
 		'Reply-To' => {
 			'useful'		=> 'return@myaddress.com',
 			'semiuseful'	=> 'filteredreturn@myaddress.com',
 			'useless'		=> 'nowhere@noemail.com'
 		},
 		'X-Type' => {
 			'premium'		=> "All Services are available",
 			"gold"			=> "Most servies are available",
 			"none"			=> "No services are available"
 		}
 	}
 );

Now then, your merge keys could be defined as such:

 ->merge_keys([qw(BULK_EMAIL <name> <age> BULK_DYNAMIC_MESSAGE BULK_DYNAMIC_HEADERS)]);

Your list would be:

 foo@bar.com::Mr. Foo::23::agegroup=20-40;animallover=hates_animals;personalized=yes::Subject=polite;Reply-To:useful;X-Type:gold
 me@there.com::Bob Hope::78::agegroup=over70;animallover=likes_animals;personalized=no::Subject=rude;Reply-To:useful;X-Type:premium
 john@junior.com::John Jr.::14::agegroup=under20;animallover=likes_animals;personalized=yes::Subject=impolite;Reply-To:useless;X-Type:none

The messages sent out would have the following headers, respectively:

 Subject : Hello, sir
 Reply-To: return@myaddress.com
 X-Type  : Most services are available

 Subject : Hey, jerk-off
 Reply-To: return@myaddress.com
 X-Type  : All Services are available

 Subject : Hello
 Reply-To: nowhere@noemail.com
 X-Type  : No services are available


See? easy as pie. Your dynamic headers should be specified in your merge_keys as BULK_DYNAMIC_HEADERS,
and should be a delimited string (in this case).

Subject=polite;Reply-To=useful;X-Type=gold

You can specify what delimiters you'd like to use. In this case, your dynamic_header_delimiter is ';',
and your dynamic_header_value_delimiter is '='.

More clearly, this information translates to the following:

 Subject		=> polite
 Reply-To		=> useful
 X-Type			=> gold

Note that unlike dynamic_message_data, the key in this case is not used to substitute out a string in your
headers (or message), the key is used to name the header that is appended on the message.

Dynamic header creation is done before mail merging, so you are more than welcome to put mail merge tokens
inside your dynamic headers.

Don't use the same tokens for mailmerges and dynamic headers, since the system may get confused.

Alternatively, instead of a delimited string, you may pass in an arrayref of strings:

 [qw(Subject=polite Reply-To=useful X-Type:gold)]

or an arrayref of arrayrefs:

 [[qw(Subject polite)], [qw(Reply-To useful)], [qw(X-Type gold)]]

or a hashref:

 {
	 Subject		=> polite
	 Reply-To		=> useful
	 X-Type			=> gold
 }

Passing in a hashtable is the fastest in terms of internal processing, but there may be additional
work on your end to generate the hash. When reading from a file, you should always use delimited strings
(since that's what'd be in your file anyway), but from other sources you can experiment with hashrefs
or arrayrefs and see which is faster for your uses.

dynamic headers apply to B<only> header information. use dynamic_message_data for dynamic pieces in messages.

Note that the dynamic header creation will be performed in an arbitrary order. So don't expect to
have one piece of the dynamic header populate into your message before another one.

There is one special key for dynamic_header_data, "_default".

 $dynamic->dynamic_message_data(
 	{
 		'Subject' => {
 			'polite'	=> "Hello, sir",
 			"impolite"	=> "Hello",
 			"rude"		=> "Hey, jerk-off",
 			'_default'	=> "Default subject",
 		},
 		'Reply-To' => {
 			'useful'		=> 'return@myaddress.com',
 			'semiuseful'	=> 'filteredreturn@myaddress.com',
 			'useless'		=> 'nowhere@noemail.com',
 			'_default"		=> 'reply@to.com'
 		},
 		'X-Type' => {
 			'premium'		=> "All Services are available",
 			"gold"			=> "Most servies are available",
 			"none"			=> "No services are available"
 		}
 	}
 );

Behavior is similar to that of _default in dynamic_message_data. If a header is specified, it is used.
If no value is specified, it will attempt to use the _default value. But, in this case, if there is no
value passed and no default, then the header just won't be set. Unless it is one of the speciality headers,
such as From. In that case, it will attempt a specific dynamic_message_data value for From, then the
"_default" value in dynamic_message_data for from, and then finally the ->From value itself.

If there's a header specified in ->dynamic_header_data, it will be preferred to use over one
set via ->header.

i.e., the order that a header will be checked is:

 1) Is there a specific header key for the header? (Subject => polite)
 2) Is there a default header key for the header? (Subject => _default)
 3) Is this a specialty header (i.e., ->From), and is that set? ($bulk->From())
 4) Is there a generic, non-dynamic header set? (->header('Foo'))

Headers will not be set more than once, no matter how many places you specify them.

=cut

__PACKAGE__->add_attr('dynamic_header_data');

=pod

=item dynamic_header_delimiter

If you're reading in from a file, you can't have arrayrefs, hashrefs, whatever. They don't store nicely
in text. So your data will probably be a delimited string. In that case, you need to know the delimiter.
Set it with dynamic_header_delimiter. Note that your dynamic header data is just an entry in your
merge data. We'll assume a merge_delimiter of '::' and a dynamic_header_value_delimiter of '=' for
these examples

 ->merge_keys([qw(BULK_EMAIL <name> BULK_DYNAMIC_HEADERS)]);

 #in your list
 jim@jimandkoka.com::Jim::Subject=polite;Reply-To=useful

 #then
 $dynamic->dynamic_message_delimiter(";");

 #in your list
 jim@jimandkoka.com::Jim::Subject=polite&Reply-To=useful

 #then
 $dynamic->dynamic_message_delimiter('&');

 #in your list
 jim@jimandkoka.com::Jim::Subject=polite,,Reply-To=useful

 #then
 $dynamic->dynamic_message_delimiter(',,');

Just be sure that your delimiting string occurs *only* as the delimiter and is never embedded in your data.
No escaping of a delimiter is possible.

=cut

__PACKAGE__->add_attr("dynamic_header_delimiter");

=pod

=item dynamic_header_value_delimiter

If you're reading in from a file, you can't have arrayrefs, hashrefs, whatever. They don't store nicely
in text. So your data will probably be a delimited string. In that case, you need to know the delimiter.
Set it with dynamic_header_delimiter. Note that your dynamic header data is just an entry in your
merge data. We'll assume a merge_delimiter of '::' and a dynamic_header_delimiter of ';' for these
examples

 ->merge_keys([qw(BULK_EMAIL <name> BULK_DYNAMIC_HEADERS)]);

 #in your list
 jim@jimandkoka.com::Jim::Subject=polite;Reply-To=useful

 #then
 $dynamic->dynamic_message_value_delimiter("=");

 #in your list
 jim@jimandkoka.com::Jim::Subject:=polite;Reply-To:=useful

 #then
 $dynamic->dynamic_message_value_delimiter(':=');

 #in your list
 jim@jimandkoka.com::Jim::Subject--polite;Reply-To--useful

 #then
 $dynamic->dynamic_message_value_delimiter('--');

Just be sure that your delimiting string occurs *only* as the delimiter and is never embedded in your data.
No escaping of a delimiter is possible.

=cut


__PACKAGE__->add_attr("dynamic_header_value_delimiter");

=pod

=item quotemeta

boolean flag. 1/0

While mailmerging, you can specify keys that would contain regex meta data.

For example:

 ->merge_keys [qw(*name* BULK_EMAIL)]

Would generate an error, because the * character has special meaning to a regex. With quotemeta turned on,
you can use that as a token because it will be quoted when used in the regex.

It is B<highly> recommended that you leave quotemeta set to 1. Set it to 0 only if you really know what you're doing.

=cut

__PACKAGE__->add_attr('quotemeta');

=pod

=item use_envelope

In this subclass, use_envelope is a method that will always return 0.

For Dynamic messages, it's impossible to use the envelope. Sorry, gang, if you want to
use mail merges, then you can't use the added speed that the envelope provides you with.

And it only makes sense, because envelope sending sends the exact same message to multiple people.
If you're doing a mail merge, then you're customizing each message, so it wouldn't make sense
to send that thing to multiple people.

For raw speed, use Mail::Bulkmail and use_envelope => 1. For mail merges, use this.

=cut

sub use_envelope { return 0};

=pod

=back

=head1 METHODS

=over 11

=item extractEmail

extractEmail is an overridden method from Mail::Bulkmail. Most of the time when you're in Mail::Bulkmail::Dynamic,
the data structure that's passed around internally is a hashref, and the email address is at the key BULK_EMAIL.

This extracts that key and returns it. Again, this method is used internally and is not something you need to worry about.

This method is known to be able to return:

 MBD001 - no BULK_EMAIL defined

=cut

sub extractEmail {

	my $self = shift;
	my $data = shift;

	#if this is a hash, then we'll assume that we want the BULK_EMAIL key out of it.
	if (ref $data eq "HASH"){

		#return the BULK_EMAIL key if we have it, an error otherwise
		if ($data->{"BULK_EMAIL"}){
			return $self->valid_email($data->{"BULK_EMAIL"});
		}
		else {
			return $self->error("No BULK_EMAIL defined", "MBD001");
		};
	}
	#otherwise, it's assumed to be a single email address, so we just use the super method
	else {
		return $self->SUPER::extractEmail($data, @_);
	};

};

=item extractSender

extractSender is an overridden method from Mail::Bulkmail. Most of the time when you're in Mail::Bulkmail::Dynamic,
the data structure that's passed around internally is a hashref, and the sender is at the key BULK_SENDER.

This extracts that key and returns it. Again, this method is used internally and is not something you need to worry about.

This method is known to be able to return:

 MBD015 - no BULK_SENDER defined

=cut

sub extractSender {

	my $self = shift;
	my $data = shift;

	#if this is a hash, then we'll assume that we want the BULK_SENDER key out of it.
	if (ref $data eq "HASH"){

		#return the BULK_SENDER key if we have it, an error otherwise
		if ($data->{"BULK_SENDER"}){
			return $self->valid_email($data->{"BULK_SENDER"});
		}
	}
	#otherwise, it's assumed to be a single email address, so we just use the super method
	return $self->SUPER::extractSender($data, @_);

};

=item extractReplyTo

extractReplyTo is an overridden method from Mail::Bulkmail. Most of the time when you're in Mail::Bulkmail::Dynamic,
the data structure that's passed around internally is a hashref, and the email address is at the key BULK_REPLYTO.

This extracts that key and returns it. Again, this method is used internally and is not something you need to worry about.

This method is known to be able to return:

 MBD016 - no BULK_REPLYTO defined

=cut

sub extractReplyTo {

	my $self = shift;
	my $data = shift;

	#if this is a hash, then we'll assume that we want the BULK_REPLYTO key out of it.
	if (ref $data eq "HASH"){

		#return the BULK_REPLYTO key if we have it, an error otherwise
		if ($data->{"BULK_REPLYTO"}){
			return $self->valid_email($data->{"BULK_REPLYTO"});
		}
	}
	#otherwise, it's assumed to be a single email address, so we just use the super method
	return $self->SUPER::extractReplyTo($data, @_);

};

=pod

=item buildHeaders

Another overridden method from Mail::Bulkmail. This one constructs headers and also includes any dynamic headers, if
they have been specified in BULK_DYNAMIC_HEADERS.

And, finally, it will do a mail merge on all headers (first global, then individual).

Still called internally and still something you don't need to worry about.

This ->buildHeaders cannot accept the optional second headers_hash parameter

This method is known to be able to return:

 MBD013 - cannot bulkmail w/o From
 MBD014 - cannot bulkmail w/o To

=cut

sub buildHeaders {
	my $self = shift;
	my $data = shift;


	my $headers = undef;

	$headers .= "Date: " . $self->Date . "\015\012";

	# keep track of the headers that we have set from dynamic_header_data
	my $set = {};

	if (ref $data eq "HASH" && $data->{"BULK_DYNAMIC_HEADERS"}){
		foreach my $key (keys %{$self->dynamic_header_data}) {

			my $subkey = $data->{"BULK_DYNAMIC_HEADERS"}->{$key} || '_default';
			my $val = $self->dynamic_header_data->{$key}->{$subkey};

			next if ! defined $val || $val !~ /\S/;

			next if $set->{$key}++;

			$headers .= $key . ": " . $val . "\015\012";
		};
	};

	#now, we take care of our regular headers, including the ones that could return errors if not present

	unless ($set->{"From"}){
		if (my $from = $self->From){
			$headers .= "From: " . $from . "\015\012";
		}
		else {
			return $self->error("Cannot bulkmail...no From address", "MBD013");
		};
	};

	$headers .= "Subject: " . $self->Subject . "\015\012" if ! $set->{"Subject"} && defined $self->Subject && $self->Subject =~ /\S/;

	unless ($set->{"To"}){
		if (my $to_hash = $self->extractEmail($data)){
			my $to = $to_hash->{'original'};
			$headers .= "To: $to\015\012";
		}
		else {
			return $self->error("Cannot bulkmail...no To address", "MBD014");
		};
	};

	my $sender_hash = $self->extractSender($data);
	if (! $set->{"Sender"} && defined $sender_hash) {
		$headers .= "Sender: "		. $sender_hash->{'original'}		. "\015\012";
	}

	my $reply_to_hash = $self->extractReplyTo($data);
	if (! $set->{"ReplyTo"} && defined $reply_to_hash) {
		$headers .= "Reply-To: "	. $reply_to_hash->{'original'}		. "\015\012";
	};

	#we're always going to specify at least a list precedence
	$headers .= "Precedence: "		. ($self->Precedence || 'list')			. "\015\012" unless $set->{"Precedence"};


	unless ($self->{"Content-type"}){
		if ($self->_headers->{"Content-type"}){
			$headers .= "Content-type: " . $self->_headers->{"Content-type"} . "\015\012";
		}
		else {
			if ($self->HTML){
				$headers .= "Content-type: text/html\015\012";
			}
			else {
				$headers .= "Content-type: text/plain\015\012";
			};
		};
	};
	#done with our default headers

	foreach my $key (keys %{$self->_headers}) {
		next if $key eq 'Content-type';
		my $val = $self->_headers->{$key};

		next if ! defined $val || $val !~ /\S/;

		next if $set->{$key}++;

		$headers .= $key . ": " . $val . "\015\012";
	};

	#do our global value merge
	if ($self->global_merge){

		#iterate through the keys of the global_merge hash, and swap them with the relevant values
		#this is part of our mail merge, but not the main customization

		foreach my $key (keys %{$self->global_merge}){
			my $val = $self->global_merge->{$key} || '';
			my $key = $self->quotemeta() ? "\Q$key\E" : $key;
			$headers =~ s/$key/$val/g;
		};
	};

	#if we have a mail merge, then do it.
	if (ref $data eq "HASH"){

		#iterate through the keys of the merge_hash, and swap them with the relevant values
		#this is our mailmerge
		foreach my $key (keys %$data){
			next if ref $data->{$key};
			my $val = $data->{$key} || '';
			my $key = $self->quotemeta() ? "\Q$key\E" : $key;
			$headers =~ s/$key/$val/g;
		};
	};

	# I'm taking credit for the mailing, dammit!
	$headers .= "X-Bulkmail: " . $Mail::Bulkmail::Dynamic::VERSION . "\015\012";

	$headers = $self->_force_wrap_string($headers, 'start with a blank', 'no blank lines');

	$headers .= "\015\012";	#blank line between the header and the message

	return \$headers;

};

=pod

=item buildMessage

Another overridden method from Mail::Bulkmail. This one constructs the message and also includes any dynamic message content,
if it has been specified in BULK_DYNAMIC_MESSAGE.

And, finally, it will do a mail merge on the message (first global, then individual).

Still called internally and still something you don't need to worry about.

This method is known to be able to return:

 MBD012 - cannot build message w/o message

=cut

sub buildMessage {
	my $self = shift;
	my $data = shift;

	#Mail::Bulkmail builds the message for us just fine, then we'll do the mail merge into it.
	my $message = $self->Message()
		|| return $self->error("Cannot build message w/o message", "MBD012");

	#first of all, dynamically build a message, if so desired
	if (ref $data eq "HASH" && $data->{"BULK_DYNAMIC_MESSAGE"}){
		foreach my $key (keys %{$self->dynamic_message_data}) {

			my $subkey = $data->{"BULK_DYNAMIC_MESSAGE"}->{$key} || '_default';
			my $val = $self->dynamic_message_data->{$key}->{$subkey} || '';

			my $key = $self->quotemeta() ? "\Q$key\E" : $key;
			$message =~ s/$key/$val/g;
		};
	};

	#do our global value merge
	if ($self->global_merge){

		#iterate through the keys of the global_merge hash, and swap them with the relevant values
		#this is part of our mail merge, but not the main customization

		foreach my $key (keys %{$self->global_merge}){
			my $val = $self->global_merge->{$key} || '';
			my $key = $self->quotemeta() ? "\Q$key\E" : $key;
			$message =~ s/$key/$val/g;
		};
	};

	#if we have a mail merge, then do it.
	if ($self->merge_keys || ref $data eq 'HASH'){

		#iterate through the keys of the merge_hash, and swap them with the relevant values
		#this is our mailmerge
		foreach my $key (keys %$data){
			next if ref $data->{$key};
			my $val = $data->{$key} || '';
			my $key = $self->quotemeta() ? "\Q$key\E" : $key;

			$message =~ s/$key/$val/g;
		};
	};

	#sendmail-ify our line breaks
	$message =~ s/(?:\r?\n|\r\n?)/\015\012/g;

	$message = $self->_force_wrap_string($message);

	#double any periods that start lines
	$message =~ s/^\./../gm;

	#and force a CRLF at the end, unless one is already present
	$message .= "\015\012" unless $message =~ /\015\012$/;
	$message .= ".";

	return \$message;
};

=pod

=item preprocess

Overridden from Mail::Bulkmail, preprocesses the data returned from getNextLine($bulk->LIST) and makes sure that
Mail::Bulkmail::Dynamic knows how to work with it. Constructs the internal data structures to handle mail merges,
dynamic messages, and dynamic headers, for any of those items that are in use.

Still called internally and still not something you need to worry about.

=cut

sub preprocess {
	my $self = shift;
	my $data = shift;

	#make sure it's a reference
	$data = $self->SUPER::preprocess($data) || return undef;

	#build the mail merge hash, if necessary
	if ($self->merge_keys){
		my $original = $data;
		$data = $self->buildMergeHash($data) || return undef;
		$data->{"BULK_ORIGINAL"} ||= $original if ref $original ne "HASH";
	};

	#if we have a dynamic message component, then build the dynamic message data
	if (ref $data eq "HASH" && $self->dynamic_message_data){
		$data->{"BULK_DYNAMIC_MESSAGE"} = $self->SUPER::preprocess($data->{"BULK_DYNAMIC_MESSAGE"}) || return undef;
		$data->{"BULK_DYNAMIC_MESSAGE"} = $self->buildDynamicMessageHash($data->{"BULK_DYNAMIC_MESSAGE"}) || return undef;
	};

	#if we have a dynamic header component, then build the dynamic header data
	if (ref $data eq "HASH" && $self->dynamic_header_data){
		$data->{"BULK_DYNAMIC_HEADERS"} = $self->SUPER::preprocess($data->{"BULK_DYNAMIC_HEADERS"}) || return undef;
		$data->{"BULK_DYNAMIC_HEADERS"} = $self->buildDynamicHeaderHash($data->{"BULK_DYNAMIC_HEADERS"}) || return undef;
	};

	return $data;

};

=pod

=item buildMessageHash

Given a delimited string, arrayref, or hashref, formats it according to the information contained in merge_keys and
returns it.

Called internally, and not something you should worry about.

This method is known to be able to return:

 MBD002 - no merge_delimiter
 MBD003 - different number of keys and values
 MBD004 - cannot bulid merge hash

=cut

sub buildMergeHash {
	my $self = shift;
	my $data = shift;

	#if it's a hashref, then just return it. We'll use that as the keys AND values and
	#completely ignore whatever's in merge_keys
	#we're putting this first because it should be the most common case
	if (ref $data eq 'HASH'){
		return $data;
	}
	# okay, if it's a string, then we want to split it on the merge_delimiter, and use that
	# as an array of values with the merge_keys
	elsif (ref $data eq "SCALAR"){

		my $delimiter = quotemeta($self->merge_delimiter())
			|| return $self->error("Cannot split without a merge_delimiter", "MBD002");
		my @values = split(/$delimiter/, $$data, scalar @{$self->merge_keys});

		return $self->error("I won't attempt a mail merge unless there are the same number of keys and values", "MBD003")
			unless @values == @{$self->merge_keys};

		#we need to create the hash to return
		my $mergehash = {};
		foreach my $key (@{$self->merge_keys}){
			$mergehash->{$key} = shift @values;
		};

		return $mergehash;
	}
	#arrays behave just like strings, but we don't need to split the string into an arrayref first
	elsif (ref $data eq 'ARRAY'){

		return $self->error("I won't attempt a mail merge unless there are the same number of keys and values", "MBD003")
			unless @$data == @{$self->merge_keys};

		#we need to create the hash to return
		my $mergehash = {};

		#I'm not going to shift off of @$data, because I want to leave the arrayref intact, but it'd be
		#wasteful to de-reference it here and shift off the copy. So we'll just increment through it
		my $i = 0;

		foreach my $key (@{$self->merge_keys}){
			$mergehash->{$key} = $data->[$i++];
		};

		return $mergehash;
	}
	#and, finally, if it's none of the above, then we can't deal with it, so return an error.
	else {
		return $self->error("Cannot build merge hash...I don't know what a $data is", "MBD004");
	};
};

=pod

=item buildDynamicMessageHash

Given a delimited string, arrayref, or hashref, formats it according to the information contained in dynamic_message_data and
returns it.

Called internally, and not something you should worry about.

This method is known to be able to return:

 MBD005 - cannot split w/o dynamic_message_delimiter
 MBD006 - cannot split w/o dynamic_message_value_delimiter
 MBD007 - invalid dynamic message key
 MBD008 - cannot build dynamic message hash

=cut

sub buildDynamicMessageHash {
	my $self = shift;
	my $data = shift;

	#if it's a hashref, then just return it, so that's our keys and values
	#we're putting this first because it should be the most common case
	if (ref $data eq 'HASH'){
		return $data;
	}
	# okay, if it's a string, then we want to split it on the merge_delimiter, and use that
	# as an array of values with the merge_keys
	elsif (ref $data eq "SCALAR"){

		my $delimiter = quotemeta($self->dynamic_message_delimiter())
			|| return $self->error("Cannot split without a dynamic_message_delimiter", "MBD005");

		my $eqdelimiter = quotemeta($self->dynamic_message_value_delimiter())
			|| return $self->error("Cannot split without a dynamic_message_value_delimiter", "MBD006");

		my @values = split(/$delimiter/, $$data);

		#we need to create the hash to return
		my $dynamicmessagehash = {};

		foreach my $pair (@values){
			my ($key, $value) = split(/$eqdelimiter/, $pair);

			return $self->error("Invalid dynamic message key : $key", "MBD007")
				unless exists $self->dynamic_message_data->{$key};

			$dynamicmessagehash->{$key} = $value;
		};

		return $dynamicmessagehash;
	}
	#arrays behave just like strings, but we don't need to split the string into an arrayref first
	elsif (ref $data eq 'ARRAY'){

		#we need to create the hash to return
		my $dynamicmessagehash = {};

		foreach my $pair (@$data){
			my ($key, $value);
			if (ref $pair){
				($key, $pair) = @$pair;
			}
			else {
				my $eqdelimiter = quotemeta($self->dynamic_message_value_delimiter())
					|| return $self->error("Cannot split without a dynamic_message_value_delimiter", "MBD006");
				($key, $pair) = split(/$eqdelimiter/, $pair);
			};

			$dynamicmessagehash->{$key} = $value;
		};

		return $dynamicmessagehash;
	}
	#and, finally, if it's none of the above, then we can't deal with it, so return an error.
	else {
		return $self->error("Cannot build dynamic message hash...I don't know what a $data is", "MBD008");
	};
};

=pod

=item buildDynamicHeaderHash

Given a delimited string, arrayref, or hashref, formats it according to the information contained in dynamic_header_data and
returns it.

Called internally, and not something you should worry about.

This method is known to be able to return:

 MBD008 - cannot split w/o dynamic_header_delimiter
 MBD009 - cannot split w/o dynamic_header_value_delimiter
 MBD010 - invalid dynamic header key
 MBD011 - cannot build dynamic header hash

=cut


sub buildDynamicHeaderHash {
	my $self = shift;
	my $data = shift || {};

	#if it's a hashref, then just return it. so that's our keys and values
	#we're putting this first because it should be the most common case
	if (ref $data eq 'HASH'){
		return $data;
	}
	# okay, if it's a string, then we want to split it on the merge_delimiter, and use that
	# as an array of values with the merge_keys
	elsif (ref $data eq "SCALAR"){

		my $delimiter = quotemeta($self->dynamic_header_delimiter())
			|| return $self->error("Cannot split without a dynamic_header_delimiter", "MBD008");

		my $eqdelimiter = quotemeta($self->dynamic_header_value_delimiter())
			|| return $self->error("Cannot split without a dynamic_header_value_delimiter", "MBD009");

		my @values = split(/$delimiter/, $$data);

		#we need to create the hash to return
		my $dynamicheaderhash = {};

		foreach my $pair (@values){
			my ($key, $value) = split(/$eqdelimiter/, $pair);

			return $self->error("Invalid dynamic header key : $key", "MBD010")
				unless exists $self->dynamic_header_data->{$key};

			$dynamicheaderhash->{$key} = $value;
		};

		return $dynamicheaderhash;
	}
	#arrays behave just like strings, but we don't need to split the string into an arrayref first
	elsif (ref $data eq 'ARRAY'){

		#we need to create the hash to return
		my $dynamicheaderhash = {};

		foreach my $pair (@$data){
			my ($key, $value);
			if (ref $pair){
				($key, $pair) = @$pair;
			}
			else {
				my $eqdelimiter = quotemeta($self->dynamic_header_value_delimiter())
					|| return $self->error("Cannot split without a dynamic_header_value_delimiter", "MBD009");
				($key, $pair) = split(/$eqdelimiter/, $pair);
			};

			$dynamicheaderhash->{$key} = $value;
		};

		return $dynamicheaderhash;
	}
	#and, finally, if it's none of the above, then we can't deal with it, so return an error.
	else {
		return $self->error("Cannot build dynamic header hash...I don't know what a $data is", "MBD011");
	};
};


=pod

=item convert_to_scalar

convert_to_scalar is still used exclusively internally here, and you still don't need to worry about it.
The difference is that this time, our data passed in is not just a simple email address - it's a hash.
If log_all_data is set to true, then you get back the data in the form that you had originally passed it,
arrayref, hashref, or delimited string.

Alternatively, the user can decide to just log the email address, if the dynamic and merge information
are not important.

=cut

sub convert_to_scalar {
	my $self	= shift;
	my $value	= shift;

	if ($self->log_all_data()){
		my $v2 = ref $value eq 'HASH' ? ($value->{"BULK_ORIGINAL"} || $value) : $value;
		return ref $v2 eq "SCALAR" ? $$v2 : $v2;
	}
	else {
		return ref $value eq 'HASH' ? $value->{"BULK_EMAIL"} : $self->SUPER::convert_to_scalar($value);
	};

};

1;

__END__

=pod

=back

=head1 EXAMPLES

#simple mailing with a list called "./list.txt". Note that this is inefficient, since we're not merging we
#could just use Mail::Bulkmail instead.

 my $bulk = Mail::Bulkmail::Dynamic->new(
 	"LIST" 		=> "./list.txt",
 	"Subject"	=> "A test message",
 	"Message"	=> "This is my test message",
 	"From"		=> 'me@mydomain.com',
 	"Reply-To"	=> 'replies@mydomain.com'
 ) || die Mail::Bulkmail::Dynamic->error();

 $bulk->bulkmail || die $bulk->error;

#simple merge example. Assume that this is your list file:

 test1@yourdomain.com::Person #1
 test2@yourdomain.com::Person #2
 test3@yourdomain.com::Person #3

 my $bulk = Mail::Bulkmail::Dynamic->new(
 	"LIST" 		=> "./list.txt",
 	"Subject"	=> "A test message",
 	"Message"	=> "This is my test message just for you. And your name is NAME.",
 	"From"		=> 'me@mydomain.com',
 	"Reply-To"	=> 'replies@mydomain.com',
 	"merge_keys" => [qw(BULK_EMAIL NAME)]
 ) || die Mail::Bulkmail::Dynamic->error();

 $bulk->bulkmail || die $bulk->error;

#simple dynamic message example. Assume that this is your list file:

 test1@yourdomain.com::Person #1::personal_message=mess1
 test2@yourdomain.com::Person #2::personal_message=mess2
 test3@yourdomain.com::Person #3::personal_message=mess3

 my $bulk = Mail::Bulkmail::Dynamic->new(
 	"LIST" 		=> "./list.txt",
 	"Subject"	=> "A test message",
 	"Message"	=> "This is my test message. And here's something personalized for you : personal_message",
 	"From"		=> 'me@mydomain.com',
 	"Reply-To"	=> 'replies@mydomain.com',
 	"merge_keys" => [qw(BULK_EMAIL NAME)],
 	"dynamic_message_data" => {
 		"message" => {
 			"mess1" => "Greetings, NAME",
 			"mess2" => "Hello there, "NAME",
 			"mess3" => "Hiya, NAME"
 		}
 	}
 ) || die Mail::Bulkmail::Dynamic->error();

 $bulk->bulkmail || die $bulk->error;

#simple dynamic message example with two dynamic components. Assume that this is your list file:

 test1@yourdomain.com::Person #1::personal_message=mess1;addendum=one
 test2@yourdomain.com::Person #2::personal_message=mess2;addendum=two
 test3@yourdomain.com::Person #3::personal_message=mess3;addendum=three

 my $bulk = Mail::Bulkmail::Dynamic->new(
 	"LIST" 		=> "./list.txt",
 	"Subject"	=> "A test message",
 	"Message"	=> "This is my test message. And here's something personalized for you : personal_message. addendum",
 	"From"		=> 'me@mydomain.com',
 	"Reply-To"	=> 'replies@mydomain.com',
 	"merge_keys" => [qw(BULK_EMAIL NAME)],
 	"dynamic_message_data" => {
 		"message" => {
 			"mess1" => "Greetings, NAME",
 			"mess2" => "Hello there, "NAME",
 			"mess3" => "Hiya, NAME"
 		},
 		'addendum' => {
 			'one'	=> 'You have received addendum #1',
 			'two'	=> "You're getting addendum number two",
 			"three"	=> "3 is what you get"
 		}
 	}
 ) || die Mail::Bulkmail::Dynamic->error();

 $bulk->bulkmail || die $bulk->error;

#simple dynamic message example with a dynamic message, and a dynamic header component. Assume that this is your list file:

 test1@yourdomain.com::Person #1::personal_message=mess1;addendum=one::Subject=subject1
 test2@yourdomain.com::Person #2::personal_message=mess2;addendum=two::Subject=subject1
 test3@yourdomain.com::Person #3::personal_message=mess3;addendum=three::Subject=subject3

 my $bulk = Mail::Bulkmail::Dynamic->new(
 	"LIST" 		=> "./list.txt",
 	"Subject"	=> "A test message",
 	"Message"	=> "This is my test message. And here's something personalized for you : personal_message. addendum",
 	"From"		=> 'me@mydomain.com',
 	"Reply-To"	=> 'replies@mydomain.com',
 	"merge_keys" => [qw(BULK_EMAIL NAME)],
 	"dynamic_message_data" => {
 		"message" => {
 			"mess1" => "Greetings, NAME",
 			"mess2" => "Hello there, "NAME",
 			"mess3" => "Hiya, NAME"
 		},
 		'addendum' => {
 			'one'	=> 'You have received addendum #1',
 			'two'	=> "You're getting addendum number two",
 			"three"	=> "3 is what you get"
 		}
 	},
 	"dynamic_header_data" => {
 		"Subject" => {
 			"subject1" => "you're getting test message #1",
 			"subject2" => "you're getting test message #2",
 			"subject3" => "you're getting test message #3"
 		}
 	}
 ) || die Mail::Bulkmail::Dynamic->error();

 $bulk->bulkmail || die $bulk->error;


=head1 SEE ALSO

Mail::Bulkmail, Mail::Bulkmail::Server

=head1 COPYRIGHT (again)

Copyright and (c) 1999, 2000, 2001, 2002, 2003 James A Thomason III (jim@jimandkoka.com). All rights reserved.
Mail::Bulkmail::Dynamic is distributed under the terms of the Perl Artistic License.

=head1 CONTACT INFO

So you don't have to scroll all the way back to the top, I'm Jim Thomason (jim@jimandkoka.com) and feedback is appreciated.
Bug reports/suggestions/questions/etc.  Hell, drop me a line to let me know that you're using the module and that it's
made your life easier.  :-)

=cut
