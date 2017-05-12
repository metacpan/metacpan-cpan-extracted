#!/usr/bin/perl


package Mail::Log::Trace;
{
=head1 NAME

Mail::Log::Trace - Trace an email through the mailsystem logs.

=head1 SYNOPSIS

  use Mail::Log::Trace;
  
  my $tracer = Mail::Log::Trace::SUBCLASS->new({log_file => 'path/to/log'});
  $tracer->set_message_id('message_id');
  $tracer->find_message();
  my $from_address = $tracer->get_from_address();
  
  etc.

=head1 DESCRIPTION

This is the root-level class for a mail tracer: It allows you to search for
and find messages in maillogs.  Accessors are provided for info common to
most maillogs: Specific subclasses may have further accessors depending on their
situation.

Probably the two methods most commonly used (and sort of the point of this
module) are C<find_message> and C<find_message_info>.  Both are simply stubs
for subclasses to implement:  The first is defined to find the first (or first
from current location...) mention of the specified message in the log.
Depending on the log format that may or may not be the only mention, and there
may be information missing/incomplete at that point.

C<find_message_info> should find I<all> information about a specific message
in the log.  (Well, all information about a specific instance of the message:
If there are multiple messages that would match the info provided it must
find info on the first found.)  That may mean searching through the log for
other information.

If you just need to find if the message exists, use C<find_message>: it will
be faster (or at the least, the same speed.  It should never be slower.)

=head1 USAGE

This is a an object-orientend module, with specific methods documented below.

The string coersion is overloaded to return the class name, and the file
we are working with.  Boolean currently checks to see if we were able to
open the file.  (Which is kinda silly, as we'd throw an error if we couldn't.)

All times are expected to be in Unix epoc-time format.

=cut

use strict;
use warnings;
use Scalar::Util qw(refaddr blessed reftype);
use Mail::Log::Exceptions 1.0100;
use base qw(Exporter);

BEGIN {
    use Exporter ();
    use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '1.0101';
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

#
# Define class variables.  Note that they are hashes...
#

my %message_info;
my %log_info;
my %message_raw_info;

# Accessors.
my %public = (	from_address	=> undef,
				message_id		=> undef,
				recieved_time	=> undef,
				sent_time		=> undef,
				relay			=> undef,
				subject			=> undef,
			);
my %public_set_only = ();
my %public_get_only = ( connect_time => undef, disconnect_time => undef, delay => undef );
my %array_accessors = ( to_address => undef );
my @valid_parameters;
my @checked_parameters = qw(from_address message_id	recieved_time sent_time	relay
							subject to_address);
my %all_setters;
my %all_getters;

my @cleared_parameters = qw(from_address message_id recieved_time sent_time
							relay to_address subject connect_time disconnect_time
							delay);

#
# DESTROY class variables.
#
### IF NOT DONE THERE IS A MEMORY LEAK.  ###

sub DESTROY {
	my ($self) = @_;
	
	delete $message_info{$$self};
	delete $log_info{$$self};
	delete $message_raw_info{$$self};
	delete $all_setters{$$self};
	delete $all_getters{$$self};
	
	return;
}

#
# Set the coercions to something useful.
#

use overload (
	# Strings overload to the path and line number.
	qw{""} => sub { my ($self) = @_;
					return  blessed($self)
							.' File: '
							.$log_info{$$self}{filename};
					},
	
	# Boolean overloads to if we are usable.  (Have a filehandle.)
	qw{bool} => sub { my ($self) = @_;
						return defined($log_info{$$self}{log_parser});
					},
	
	# Numeric context just doesn't mean anything.  Throw an error.
	q{0+} => sub { Mail::Log::Exceptions->throw(q{Can't get a numeric value of a Mail::Log::Trace.} );
				},
	
	# Perl standard for everything else.
	fallback => 1,
			);


=head2 new (constructor)

The base constructor for the Mail::Log::Trace classes.  It takes inital values
for the following in a hash: C<from_address>, C<to_address>, C<message_id>,
C<log_file>.  The only required value is the path to the logfile.

  use Mail::Log::Trace;
  my $object = Mail::Log::Trace->new({ from_address => 'from@example.com',
                                       to_address   => 'to@example.com',
                                       message_id   => 'messg.id.string',
                                       log_file     => 'path/to/log',
                                       ...
                                      });

=cut

sub new
{
    my ($class, $parameters_ref) = @_;

    my $self = bless \do{my $anon}, $class;
	$$self = refaddr $self;

	# Build accessors
	
	# Get stuff from the any base classes.
	my @public = $self->_requested_public_accessors();
	my %public_special = $self->_requested_special_accessors();
	my @public_set_only = $self->_requested_public_set_only();
	my @public_get_only = $self->_requested_public_get_only();
	my @array = $self->_requested_array_accessors();
	
	@checked_parameters = ($self->_set_as_message_info(), @checked_parameters);
	my %checked_parameters = map { $_ => undef if $_ ne ''; } @checked_parameters;
	@checked_parameters = keys %checked_parameters;

	foreach my $item ( @public ) {
		$public{$item} = undef;
	}
	foreach my $item ( @public_set_only ) {
		$public_set_only{$item} = undef;
	}
	foreach my $item ( @public_get_only ) {
		$public_get_only{$item} = undef;
	}
	foreach my $item ( @array ) {
		$array_accessors{$item} = undef;
	}
	
	# Setters first.
	my %merged_hash = (%public, %public_set_only, %public_special);
	while ( my ($accessor, $action) = each %merged_hash ) {
		$all_setters{$$self}{$accessor} = $self->_build_setter($accessor, 0, $action);
		push @valid_parameters, $accessor;
	}
	
	# Now getters.
	foreach my $accessor ( keys %public, keys %public_get_only, keys %public_special ) {
		$all_getters{$$self}{$accessor} = $self->_build_getter($accessor);
	}

	# Now build the private.
	$all_setters{$$self}{$_} = $self->_build_setter($_, 1) foreach ( keys %public_get_only );
	$all_getters{$$self}{$_} = $self->_build_getter($_, 1) foreach ( keys %public_set_only );

	# And the complex...
	$self->_build_array_accessors($_) foreach ( keys %array_accessors );
	push @valid_parameters, keys %array_accessors;

	# Get the list of parameters to clear when 'clear' is called.
	my @requested_cleared = $self->_requested_cleared_parameters();
	@requested_cleared = grep { defined($_) } @requested_cleared;
	push @cleared_parameters, @requested_cleared;

	# Set up any/all passed parameters.
	# (Only does message info.  Note this can only be called after the above!)
	$self->_parse_args($parameters_ref, 0);

	# Log info.
	$self->set_log($parameters_ref->{log_file});  # Better to keep validation together.

    return $self;
}

#
# The method factories.
#

sub _build_setter {
	my ($self, $attribute, $private, $action) = @_;
	
	# Build the correct name.
	my $sub_name = "set_$attribute";
	$sub_name = "_$sub_name" if $private;
	
	# The typeglob below sets off all kinds of warnings.
	# (The 'redefine' is because this happens for _every_object_.)
	no strict 'refs';
	no warnings qw(redefine);
	
	# Build the actual subroutine.
	if ( defined($action) ) {
		# If we do processing or validation, give it a chance to happen.
		return *{blessed($self)."::$sub_name"} = sub {
			use strict 'refs';
			my ($self, $new_id) = @_;
			
			# True if they accept the value, false otherwise.
			# (To make validation easier.)
			$new_id = $action->($self, $new_id);
			if ( $new_id ne '____INVALID__VALUE____' ) {
				$message_info{$$self}{$attribute} = $new_id;
			}
			else {
				# If they don't accept the value, tell the user.
				Mail::Log::Exceptions::InvalidParameter->throw("'$new_id' is not a valid value for $attribute.\n");
			}
			return;
		}
	}
	else {
		# For basic setters, use a speed-optimized version.
		return *{blessed($self)."::$sub_name"} = sub {
			$message_info{${$_[0]}}{$attribute} = $_[1];
			return;
		}
	}
}

sub _build_getter {
	my ($self, $attribute, $private) = @_;

	# Build the correct name.
	my $sub_name = "get_$attribute";
	$sub_name = "_$sub_name" if $private;

	# The typeglob below sets off all kinds of warnings.
	# (The 'redefine' is because this happens for _every_object_.)
	no strict 'refs';
	no warnings qw(redefine);

	# Build the actual subroutine. (As fast as we can make it.)
	return *{blessed($self)."::$sub_name"} = sub {
		return $message_info{${$_[0]}}{$attribute};
	}
}

sub _build_array_accessors {
	my ($self, $attribute, $private) = @_;

	my $get_name = "get_$attribute";
	my $set_name = "set_$attribute";
	my $add_name = "add_$attribute";
	my $remove_name = "remove_$attribute";

	foreach my $name ( ($get_name, $set_name, $add_name, $remove_name) ) {
		$name = "_$name" if ( $private );
		$name = blessed($self)."::$name";
	}

	no strict 'refs';
	no warnings qw(redefine);

	*$get_name = sub {
		return $message_info{${$_[0]}}{$attribute};
	};
	$all_getters{$$self}{$attribute} = *$get_name;

	# Note that strict refs still aren't in effect.
	# Needed for the call to $add_name below.
	*$set_name = sub {
		my ($self, $new_id) = @_;
		if (defined($new_id) ) {
			@{$message_info{$$self}{$attribute}} = ();
			$add_name->($self, $new_id);
		}
		else {
			$message_info{$$self}->{$attribute} = undef;
		}
		return;
	};
	$all_setters{$$self}{$attribute} = *$set_name;

	*$add_name = sub {
		use strict 'refs';
		my ($self, $new_id) = @_;
		
		# If we are given a single element, and we haven't seen it before,
		# add it to the array.
		if ( !defined(reftype($new_id)) ) {
			unless ( grep { $_ eq $new_id } @{$message_info{$$self}{$attribute}} ) {
				push @{$message_info{$$self}{$attribute}}, ($new_id);
			}
		}
		# If we are given an array of elements, merge it with our current array.
		elsif ( reftype($new_id) eq 'ARRAY' ) {
			my %temp_hash;
			foreach my $element (@{$message_info{$$self}{$attribute}}, @{$new_id}) {
				$temp_hash{$element} = undef;
			}
			@{$message_info{$$self}{$attribute}} = keys %temp_hash;
		}
		return;
	};

	*$remove_name = sub {
		my ($self, $id) = @_;
		@{$message_info{$$self}{$attribute}}
			= grep { $_ ne $id } @{$message_info{$$self}{$attribute}};
		return;
	};
}

#
# Setters.
#

=head2 SETTERS

=head3 set_from_address

Sets the from address of the message we are looking for.

=head3 set_message_id

Sets the message_id of the message we are looking for.
(Check with the specific parser class for what that means in a particular
log format.)

=head3 set_recieved_time

Sets the recieved time of the message we are looking for.
(The time this machine got the message.)

=head3 set_sent_time

Sets the sent time of the message we are looking for.
(The time this machine sent the message.)

=head3 set_relay_host

Sets the relay host of the message we are looking for.  Commonly either
the relay we recieved it from, or the relay we sent it to.  (Depending
on the logfile.)

=head3 set_subject

Sets the subject of the message we are looking for.

=head3 set_parser_class

Sets the parser class to use when searching the log file.  A subclass will
have a 'default' parser that it will normally use: This is to allow easy
site-specific logfile formats based on more common formats.  To use you
would subclass the default parser for the log file format of the base program
to handle the site's specific changes.

Takes the name of a class as a string, and will throw an exception 
(C<Mail::Log::Exceptions::InvalidParameter>) if that class name doesn't start
with Mail::Log::Parse.

=cut

sub set_parser_class {
	my ($self, $new_id) = @_;
	if ( $new_id =~ /Mail::Log::Parse::/ ) {
		$log_info{$$self}{parser_class} = $new_id;
	}
	else {
		Mail::Log::Exceptions::InvalidParameter->throw('Parser class needs to be a Mail::Log::Parse:: subclass.');
	}
	return;
}

=head3 set_log

Sets the log file we are searching throuh.  Takes a full or relative path.
If it doesn't exist, or can't be read by the current user, it will throw an
exception. (C<Mail::Log::Exceptions::LogFile>)  Note that it does I<not>
try to open it immedeately.  That will be done at first attempt to read from
the logfile.

=cut

sub set_log {
	my ($self, $new_name) = @_;

	if ( ! defined($new_name) ) {
		Mail::Log::Exceptions::InvalidParameter->throw('No log file specified in call to '.blessed($self).'->new().');
	}

	# Check to make sure the file exists,
	# and then that we can read it, before accpeting the filename.
	if ( -e $new_name ) {
		if ( -r $new_name ) {
			$log_info{refaddr $self}{'filename'} = $new_name;
		}
		else {
			Mail::Log::Exceptions::LogFile->throw("Log file $new_name is not readable.");
		}
	}
	else {
		Mail::Log::Exceptions::LogFile->throw("Log file $new_name does not exist.");
	}

	# Reset the parser.
	$self->_set_log_parser(undef);

	return;
}

=head3 set_to_address

Sets the to address of the message we are looking for.  Multiple addresses can
be specified, they will all be added, with duplicates skipped.  This method
completely clears the array: there will be no addresses in the list except
those given to it.  Duplicates will be consolidated: Only one of any particular
address will be in the final array.

As a special case, passing C<undef> to this will set the array to undef.

=head3 add_to_address

Adds to the list of to addresses we are looking for.  It does I<not> delete the
array first.

Duplicates will be consolidated, so that the array will only have one of any
given address.  (No matter the order they are given in.)

=head3 remove_to_address

Removes a single to address from the array.

=cut

#
# Getters.
#

=head2 GETTERS

=head3 get_from_address

Gets the from address.  (Either as set using the setter, or as found in the
log.)

=head3 get_to_address

Gets the to address array.  (Either as set using the setters, or as found in the
log.)

Will return a reference to an array, or 'undef' if the to address has not been
set/found.

=head3 get_message_id

Gets the message_id.  (Either as set using the setter, or as found in the
log.)

=head3 get_subject

Gets the message subject.  (Either as set using the setter, or as found in the
log.)

=head3 get_recieved_time

Gets the recieved time.  (Either as set using the setter, or as found in the
log.)

=head3 get_sent_time

Gets the sent time.  (Either as set using the setter, or as found in the
log.)

=head3 get_relay_host

Gets the relay host.  (Either as set using the setter, or as found in the
log.)

=head3 get_log

Returns the path to the logfile we are reading.

=cut

sub get_log {
	my ($self) = @_;
	return  $log_info{$$self}{'filename'};
}

=head3 get_connect_time

Returns the time the remote host connected to this host to send the message.

=head3 get_disconnect_time

Returns the time the remote host disconnected from this host after sending
the message.

=head3 get_delay

Returns the total delay in this stage in processing the message.

=head3 get_all_info

Returns message info as returned from the parser, for more direct/complete
access.

(It's probably a good idea to avoid using this, but it is useful and arguably
needed under certain circumstances.)

=cut

sub get_all_info {
	my ($self) = @_;
	return $message_raw_info{$$self};
}

#
# To be implemented by the sub-classes.
#

=head2 Utility subroutines

=head3 clear_message_info

Clears I<all> known information on the current message, but not on the log.

Use to start searching for a new message.

=cut

sub clear_message_info {
	my ($self) = @_;

	foreach my $parameter ( @cleared_parameters ) {
		$all_setters{$$self}{$parameter}->($self, undef) if defined($all_setters{$$self}{$parameter});
	}

	$self->_set_message_raw_info(undef);

	return;
}

=head3 find_message

Finds the first/next occurance of a message in the log.  Can be passed any
of the above information in a hash format.

Default is to search I<forward> in the log: If you have already done a search,
this will start searching where the previous search ended.  To start over
at the beginning of the logfile, set C<from_start> as true in the parameter
hash.

This method needs to be overridden by the subclass: by default it will throw
an C<Mail::Log::Exceptions::Unimplemented> error.

=cut

sub find_message {
	Mail::Log::Exceptions::Unimplemented->throw("Method 'find_message' needs to be implemented by subclass.\n");
#	return 0;	# Return false: The message couldn't be found.  This will never be called.
}

=head3 find_message_info

Finds as much information as possible about a specific occurance of a message
in the logfile.  Acts much the same as find_message, other than the fact that
once it finds a message it will do any searching necarry to find all information
on that message connection.

(Also needs to be implemented by subclasses.)

=cut

sub find_message_info {
	Mail::Log::Exceptions::Unimplemented->throw("Method 'find_message_info' needs to be implemented by subclass.\n");
#	return 0;	# Return false: The message couldn't be found.  This will never be called.
}

=head1 SUBCLASSING

There are two ways to subclass Mail::Log::Trace: The standard way, and the
automatic way.  The old way is fairly straightforward: You create the accessors
for all the subclass-specific information, and overide C<find_message>,
C<find_message_info>, and C<_parse_args>. (Making sure for C<_parse_args> that
you call the SUPER version.)

Or you can try to let Mail::Log::Trace do as much of that as possible, and only
do C<find_message> and C<find_message_info>.

To do the latter, you need to override several of the following list of methods:

  _requested_public_accessors
  _requested_public_set_only
  _requested_public_get_only
  _requested_array_accessors
  _requested_special_accessors
  _requested_cleared_parameters
  _set_as_message_info

That looks like a long list, but it is very rare that you'll need to override
all of them, and all they need to do is return a static list of keys that you
want the relevant action taken on.

The first five build accessors for you, of the form  C<get_$key>, C<set_$key>
for standard public, C<_get_$key> and C<_set_key> for private accessors (note
that if you request a private setter, you'll also get a I<public> getter, and
vice-versa), and C<get_$key>, C<set_$key>, C<add_$key> and C<remove_$key> for
keys which store arrays.  All of these have been heavily optimised for speed.

The last two set what keys are cleared when you call C<clear_message_info> and
what keys will be checked when C<_parse_args> is called.  (If none of those are
present, an exception will be thrown, saying there is no message-specific data.)

C<_requested_special_accessors> requires a little more discussion.  Unlike the
rest, it expects not an array, but a hash (not a hashref: a hash).  The keys of
the hash are the keys that will have accessors built for them (public, single,
only), and the values are code references to parsing/validation functions.

An example:

  sub _requested_special_accessors { 
      return ( year => sub {  my ($self, $year) = @_;
                              return '____INVALID__VALUE____' if $year < 1970;
                              my $maillog = $self->_get_log_parser();
                              if (defined($maillog)) {
                                  $maillog->set_year($year);
                              }
                              return $year;
                           },
              );
  };

The above is from L<Mail::Log::Trace::Postfix>, and is for the key 'year'.
The coderef in this case does both validation and some extra action.  The action
is to call C<$self->_get_log_parser()->set_year()> on the year being passed.
(Because in this case the parser needs to have the year to return info
correctly.)  The validation is to check to make sure the year is greater than
1970. (The birth of UNIX, so we are unlikey to handle any logs earlier than
that.)  If it is not, the special value C<____INVALID__VALUE____> is returned.
This will cause an exception to be thrown.  If the value is valid, it is
returned.

The purpose of all the above is to allow subclasses to check values, do any
parsing that is needed, and to any other actions that may be needed.  (This is
in contrast to the normal accessors, which just store the value given blindly.)

Note that C<undef> should always be considered a valid value.

Normally keys should be in the 'public_accessors' list: those accessors are much
faster.

These accessors are built at I<run time>, when the object is first created.
This means object creation is fairly expensive.

Of course, you still need to write C<find_message> and C<find_message_info>...

Mail::Log::Trace is a cached inside-out object.  If you don't know what that
means, you can probably ignore it.  However if you need to store object state
data (and aren't using the convience accessors), it may be useful to know that
C<$$self == refaddr $self>.

=cut

#
# Private to be implemented by the sub-classes...
# (If needed.)
#

sub _requested_public_accessors { return (); };
sub _requested_public_set_only { return (); };
sub _requested_public_get_only { return (); };
sub _requested_array_accessors { return (); };
sub _requested_cleared_parameters { return (); };
sub _requested_special_accessors { return (); };
sub _set_as_message_info { return (); };

sub _parse_args {
	my ($self, $argref, $throw_error) = @_;
	
	# It is possible for them to pass the message info here.
	my %args;
	foreach my $parameter ( @valid_parameters ) {
		$all_setters{$$self}{$parameter}->($self, $argref->{$parameter}) if exists $argref->{$parameter};
	}
	
	# Not all parameters are checked...
	foreach my $parameter ( @checked_parameters ) {
		$args{$parameter} = $all_getters{$$self}{$parameter}->($self) if defined($all_setters{$$self}{$parameter});
	}
	$args{from_start}	= $argref->{from_start} ? 1 : 0;
	
	# And log info.
	$self->set_parser_class($argref->{parser_class})		if exists $argref->{parser_class};
	
	# Speed things up a bit, and make it easier to read.
	
	if ($throw_error) {
		# If none are defined...
		if ( (grep { defined($args{$_}) } keys %args) == 1 ) {
			Mail::Log::Exceptions::Message->throw("Warning: Trying to search for a message with no message-specific data.\n");
		}
	}

	return \%args;
}

#
# Private functions/methods.
#

=head1 UTILITY SUBROUTINES

B<THESE ARE ONLY FOR USE BY SUBCLASSES>

There are a few subroutines especially for use by subclasses.

=head2 _set_message_raw_info

Give this the raw message info, in whatever format the parser gives it.  The
user should hopefully never want it, but just in case...

=cut

sub _set_message_raw_info {
	my ($self, $new_hash) = @_;
	$message_raw_info{$$self} = $new_hash;
	return;
}

=head2 _set_log_parser

Sets the log parser.  Takes a reference to a parser object.

=cut

sub _set_log_parser {
	my ($self, $log_parser) = @_;
	$log_info{$$self}->{log_parser} = $log_parser;
	return;
}

=head2 _get_log_parser

Returns the log parser object.

=cut

sub _get_log_parser {
	my ($self) = @_;
	return $log_info{$$self}->{log_parser};
}

=head2 _get_parser_class

Returns the name of the class the user wants you to use to parse the file.

Please take it under advisement.

=cut

sub _get_parser_class {
	my ($self) = @_;
	return $log_info{$$self}->{parser_class};
}

=head1 BUGS

None known at the moment...  (I am nervious about the way I'm storing some of
these coderefs.  So far I haven't run into problems, but I'm not entirely sure
there aren't any.  If you start getting weird behaviour when using multiple
Mail::Log::Trace subclasses at once, please tell me.)

=head1 REQUIRES

L<Scalar::Util>, L<Mail::Log::Exceptions>.

Some subclass, and probably a L<Mail::Log::Parse> class to be useful.

=head1 HISTORY

1.1.1 Feb 2, 2009 - Fixed a minor issue that could cause problems with multiple
subclass objects exisiting at the same time.

1.1.0 Dec 23, 2008 - Major re-write to make subclassing easier.  Or possibly
more confusing.

1.00.03 Dec 5, 2208 - Licence clarification.

1.00.02 Dec 2, 2008 - I really mean it this time.

1.00.01 Dec 1, 2008 - Requirements fix, no code changes.

1.00.00 Nov 28, 2008 - original version.

=head1 AUTHOR

    Daniel T. Staal
    CPAN ID: DSTAAL
    dstaal@usa.net

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

This copyright will expire in 30 years, or five years after the author's death,
whichever occurs last, at which time the code be released to the public domain.

=cut

#################### main pod documentation end ###################

}
1;
# The preceding line will help the module return a true value

