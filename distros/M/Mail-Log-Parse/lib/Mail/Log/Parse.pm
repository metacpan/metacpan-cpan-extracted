#!/usr/bin/perl

package Mail::Log::Parse;
{
=head1 NAME

Mail::Log::Parse - Parse and return info in maillogs

=head1 SYNOPSIS

  use Mail::Log::Parse;

  $object = Mail::Log::Parse->new({  log_file => '/path/to/logfile'  });
  %line_info = %{object->next()};

  $line_num = $object->get_line_number();

  if ( $object->go_forward($amount) ) {
    ...
  }

  if ( $object->go_backward($amount) ) {
    ...
  }

  %line_info = %{object->previous()};

=head1 DESCRIPTION

This is the root-level module for a generic mail log file parser.  It is capable
of opening either a compressed or uncompressed logfile, and either stepping
through it line by line, or seeking around in it based on the logical lines.
(Lines not pertaining to the type of log currently being searched are skipped,
as if they don't exist.)

On it's own it doesn't actually do much: You'll need a subclass that can
parse a particular program's log entries.  But such subclasses are designed to
be easy to write and use.

=head1 USAGE

This is an object-oriented module.  Available object methods are below.

In a string context, it will return a string specifying the path to the file
and the current line number.  In a boolean context, it will return whether it
has been correctly initialized.  (Whether it has a file.)  Numeric context throws
an error.

Oh, and iterator context ('<>') returns the same as 'next'...

=cut

use strict;
use warnings;
use Scalar::Util qw(refaddr blessed);
use File::Basename;
use IO::File;
use Mail::Log::Exceptions;
use base qw(Exporter);

BEGIN {
    use Exporter ();
    use vars qw($VERSION);
    $VERSION     = '1.0402';
}

#
# Define class variables.  Note that they are hashes...
#

my %log_info;
my %parse_buffer;
my %parse_buffer_start_line;
my %parse_buffer_size;
my %debug;
my %current_line;

#
# DESTROY class variables.
#
### IF NOT DONE THERE IS A MEMORY LEAK.  ###

sub DESTROY {
	my ($self) = @_;

	$log_info{refaddr $self}{filehandle}->close() if defined($log_info{refaddr $self}{filehandle});

	delete $log_info{refaddr $self};
	delete $parse_buffer{refaddr $self};
	delete $parse_buffer_start_line{refaddr $self};
	delete $parse_buffer_size{refaddr $self};
	delete $debug{refaddr $self};
	delete $current_line{refaddr $self};

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
							.$log_info{$$self}{'filename'}
							.' Line: '
							.$current_line{$$self};
					},

	# Boolean overloads to if we are usable.  (Have a filehandle.)
	qw{bool} => sub { my ($self) = @_;
						return defined($log_info{$$self}{'filehandle'});
					},

	# Numeric context just doesn't mean anything.  Throw an error.
	q{0+} => sub { Mail::Log::Exceptions->throw(q{Can't get a numeric value of a Mail::Log::Parse.} );
				},

	# Heh.  Iterator context is the same as 'next'...
	q{<>} => sub { return $_[0]->next(); },

	# Perl standard for everything else.
	fallback => 1,
			);

=head2 new (constructor)

The base constructor for the Mail::Log::Parse classes.  It takes an (optional)
hash containing path to the logfile as an argument, and returns the new object.

Example:

  $object = Mail::Log::Parse->new({  log_file => '/path/to/logfile'  });

Note that it is an error to call any method other than C<set_logfile> if you
have not passed it in the constructor.

Optional keys in the hash are 'buffer_length' and 'debug'.  The buffer length
is the number of lines to read at a time (and store in the internal buffer).
Default is 128.  Setting debug to a true value will result in some debugging
information being printed to STDERR.  (I reserve the right to remove or change
the debug info at any time.)

=cut

sub new
{
    my ($class, $parameters_ref) = @_;

    my $self = bless \do{my $anon}, $class;
	$$self = refaddr $self;

	# Log info.
	if ( defined($parameters_ref->{'log_file'}) ) {
		$self->set_logfile($parameters_ref->{'log_file'});  # Better to keep validation together.
	}

	$debug{$$self} = defined($parameters_ref->{debug});

#$debug{refaddr $self} = 1;

	# Init the buffer.
	$current_line{$$self} = 0;
	$parse_buffer_start_line{$$self} = 0;
	$parse_buffer{$$self} = undef;
	$parse_buffer_size{$$self} = defined($parameters_ref->{buffer_length}) ? $parameters_ref->{buffer_length} : 128;


	return $self;
}

=head2 set_logfile

Sets the logfile that this object will attempt to parse.  It will throw
exceptions if it can't open the file for any reason, and will return true on
success.

Files can be compressed or uncompressed: If they are compressed, then
C<IO::Uncompress::AnyUncompress> must be installed with the relevant
decompression libraries. (As well as version 0.17 or better of File::Temp.)
Currently only 'tgz', 'zip', 'gz', and 'bz2' archives are supported, but
there is no technical reason not to support more.  (It just keeps a couple
of lines of code shorter.)

Note that to support seeking in the file the log will be uncompressed to disk
before it is read: If there is insufficient space to do so, we may have trouble.
It also means this method may take a while to return for large compressed logs.

Example:

  $object->set_logfile('path/to/file');

=cut

sub set_logfile {
	my ($self, $new_name) = @_;

	# Check to make sure the file exists,
	# and then that we can read it, before accpeting the filename.
	if ( -e $new_name ) {
		if ( -r $new_name ) {
			$log_info{$$self}{'filename'} = $new_name;

			# We'll check the extension to see if it is compressed.
			my (undef, undef, $suffix) = fileparse($new_name, qw(tgz zip gz bz2));
			if ( $suffix ) {

				# Since we only need uncompress symantics right here, we'll
				# only load them if we need them.  Neat, huh?
				eval { require IO::Uncompress::AnyUncompress } or Mail::Log::Exceptions->throw("Need IO::Uncompress::AnyUncompress for compressed files.\n");
				IO::Uncompress::AnyUncompress->import( qw(anyuncompress) );

				# Same with File::Temp;
				eval { require File::Temp } or Mail::Log::Exceptions->throw("Need File::Temp version 0.17 or better for compressed files.\n");
				File::Temp->VERSION( 0.17 )	# Minimum version check.
					or Mail::Log::Exceptions->throw("Need File::Temp version 0.17 or better for compressed files.\n");

				# If it is compressed, uncompress to a temp file and use that.
				my $temp = new File::Temp();
				anyuncompress($new_name, $temp)
					or Mail::Log::Exceptions::LogFile->throw("Unable to uncompress logfile $new_name: ". $IO::Uncompress::AnyUncompress::AnyUncompressError ."\n");
				$temp->seek(0,0)
					or Mail::Log::Exceptions::LogFile->throw("Unable to seek to beginning of temp file.\n");
				$log_info{$$self}{'filehandle'} = $temp;
			}
			else {
				# If it wasn't compressed, open it direct.
				$log_info{$$self}{'filehandle'} = IO::File->new($new_name, '<')
					or Mail::Log::Exceptions::LogFile->throw("Unable to open file $new_name: $!\n");
			}

			# Init some location information on the file.
			$current_line{$$self} = 0;
			delete $log_info{$$self}->{'line_positions'};
			${$log_info{$$self}{'line_positions'}}[$current_line{$$self}] = $log_info{$$self}{'filehandle'}->getpos();
		}
		else {
			Mail::Log::Exceptions::LogFile->throw("Log file $new_name is not readable.\n");
		}
	}
	else {
		Mail::Log::Exceptions::LogFile->throw("Log file $new_name does not exist.\n");
	}

	return 1;
}

=head2 next

Returns a reference to a hash of the next parsable line of the log, or 'undef' on
end of file/failure.

There are a couple of required keys that any parser must implement:

timestamp, program, id, text.

Where C<timestamp> must the the unix timestamp, C<program> must be the name of
the program that reported the logline (Sub-programs are recommended to be listed,
if possible), C<id> is the tracking ID for that message, as reported by the
program, and C<text> is the text following any 'standard' headers.  (Usually,
minus those already required keys.)

This version is just a placeholder: It will return a
'Mail::Log::Exceptions::Unimplemented' exception if called.  Subclasses are
expected to override the C<_parse_next_line> method to get an operable parser.
(And that is the only method needed to be overridden for a working subclass.)

Other 'standard' fields that are expected in a certain format (but are not
required to always be present) are 'from', 'to', 'size', 'subject', delay.  'to'
should point to an array of addresses.  (As listed in the log.  That includes
angle brackets, usually.)

Example:

  while $hash_ref ( $object->next() ) {
    ...
  }

or...

  while $hash_ref ( <$object> ) {
    ...
  }

=cut

sub next {
	my ($self) = @_;

	# This is the same as $self->get_current_line();
	# (Or at least it should be.  Done for speed.)
	my $current_line = $current_line{$$self};

	if ( defined($parse_buffer{$$self})
			and ( ($current_line+1) <= ($parse_buffer_start_line{$$self} + $#{$parse_buffer{$$self}}) )
			and ( ($current_line+1) >= $parse_buffer_start_line{$$self})
		) {

		# Increment where we are.
		$current_line{$$self} = $current_line{$$self} + 1;

#		print STDERR 'Returning line number '. $self->get_line_number() ." from buffer.\n" if $debug{$selfref};

		# Return the data we were asked for.
		return $parse_buffer{$$self}->[($current_line - $parse_buffer_start_line{$$self}+1)];
	}
	else {
		# Move the actual read postition to where we are.
		# (But only if we've acutally ever read anything.)
		if ( defined($log_info{$$self}->{line_positions}->[$current_line]) ) {
			$log_info{$$self}{filehandle}->setpos($log_info{$$self}->{line_positions}->[$current_line])
				or Mail::Log::Exceptions::LogFile->throw("Error seeking to position: $!\n");
		}

#		print STDERR 'Reading buffer for line '. $current_line .".\n" if $debug{refaddr $self};

		# Check if we've reached the end of the file.
		# (And that we haven't gone back...)
		if ( defined($parse_buffer{$$self}->[0])
			and $#{$parse_buffer{$$self}} < $parse_buffer_size{$$self}
			and $current_line >= $parse_buffer_start_line{$$self}
			) {
			return $parse_buffer{$$self}->[-1];
		}

		# Clear the buffer.
		@{$parse_buffer{$$self}} = ();

		# Read in the buffer.
		READ_LOOP: for my $i (0...$parse_buffer_size{$$self}) {
			$parse_buffer{$$self}->[$i] = $self->_parse_next_line();
			last READ_LOOP unless defined $parse_buffer{$$self}->[$i];
			$self->_set_position_as_next_line;
		}

#use Data::Dumper;
#print STDERR Data::Dumper->Dump($parse_buffer{refaddr $self});

		# Move the indexes back to the line we are reading.
		# (Note the 'current line' direct access again...)
		$parse_buffer_start_line{$$self} = $current_line{$$self} - $#{$parse_buffer{$$self}};
		$self->go_to_line_number($parse_buffer_start_line{$$self});

		# Return the data.
		return $parse_buffer{$$self}->[0];
	}
}

=head2 previous

Returns a reference to a hash of the previous line of the log, or undef on
failure/beginning of file.

See C<next> for details: It works nearly exactly the same.  (In fact, it calls
next as a parser.)

=cut

sub previous {
	my ($self) = @_;

	# Check if we can.
	if ( $current_line{$$self} <= 1 ) {
		return undef;
	}

	# Go back two lines
	$self->go_backward(2);

	# And read forward one, returning that.
	return $self->next();
}

=head2 go_forward

Goes forward a specified number of (logical) lines, or 1 if unspecified.  It will
throw an error if it fails to seek as requested.

Returns true on success.

Example:

  $object->go_forward(4);

=cut

sub go_forward {
	my $self = shift;
	my $lines = shift;

	# Just because I'm paranoid.
	$lines ||= 1;

	# If we've read the line before, go straight to it.
	if ( ${$log_info{$$self}{line_positions}}[($current_line{$$self}+$lines)] ) {
		$current_line{$$self} = $current_line{$$self} + $lines;
		return 1;
	}
	else {
		# Work out where we are.
		my $start_pos = $self->get_line_number();
		my $end_known_pos = $#{$log_info{$$self}{line_positions}};	# zero-indexed.
		my $lines_remaining = $lines - ($end_known_pos - $start_pos);

		# Go to the last line we have.
		$current_line{$$self} = $#{$log_info{$$self}{line_positions}};

		# Then read until we get to the line we want.
		if ( $self->next() ) {
			unshift @_, ($self, $lines_remaining - 1 );
			goto &go_forward;
		}
		else {
			return 0;
		}
	}
}

=head2 go_backward

Goes backward a specified number of (logical) lines, or 1 if unspecified.  It will
throw an error if it fails to seek as requested.

If the seek would go beyond the beginning of the file, it will go to the
beginning of the file.

Returns true on success.

Example:

  $object->go_backward(4);

=cut

sub go_backward {
	my ($self, $lines) = @_;

	# Just because I'm paranoid.
	$lines ||= 1;

	# If the line exits, go straight to it.
	if ( ($current_line{$$self} - $lines ) > 0 ) {
		$current_line{$$self} -= $lines;
	}
	else {
		#If they've asked us to go beyond the beginning of the file, just go to the beginning.
		$current_line{$$self} = 0;
		return 0;
	}
	return 1;
}

=head2 go_to_beginning

Goes to the beginning of the file, no matter how far away that is.

Returns true on success.

=cut

sub go_to_beginning {
	my ($self) = @_;

	$current_line{$$self} = 0;

	return 1;
}

=head2 go_to_end

Goes to the end of the file, no matter where it is.

This attempts to be efficient about it, skipping where it can.

Returns true on success.

=cut

sub go_to_end {
	my ($self) = @_;

	# Go to the end of what we have.
	$current_line{$$self} = $#{$log_info{$$self}{line_positions}};

	if ( !$self->next() ) {
		return 1;
	}
	else {
		goto &go_to_end;
	}
}

=head2 get_line_number

Returns the current logical line number.

Note that line numbers start at zero, where 0 is the absolute beginning of the
file.

Example:

  $line_num = $object->get_line_number();

=cut

sub get_line_number () {
	# This method gets called a lot: speed is an issue.
	# This is as fast as I could make it.
	return $current_line{${$_[0]}};
}

=head2 go_to_line_number

Goes to a specific logical line number.  (Preferably one that exits...)

=cut

sub go_to_line_number {
	my ($self, $line_number) = @_;

#	my $current_line_number = $self->get_line_number();

	no warnings qw(uninitialized);
	if ( $current_line{$$self} >= $line_number ) {
		return $self->go_backward($current_line{$$self} - $line_number);
	}
	else {
		return $self->go_forward($line_number - $current_line{$$self});
	}
}

#
# To be overrridden by subclasses.
#

sub _parse_next_line {
	my ($self) = @_;

	Mail::Log::Exceptions::Unimplemented->throw("Method '_parse_next_line' needs to be implemented by the subclass.\n");
}

#
# These are semi-private methods: They are for the use of subclasses only.
#
=for readme stop

=head1 SUBCLASSING

This class is useless without subclasses to handle specific file formats.  As
such, attempts have been made to make subclassing as painless as possible.  In
general, you should only ever have to implement one method: C<_parse_next_line>.

C<_parse_next_line> will be called whenever another line of the log needs to be
read.  Its responsibility is to identify the next line, report where that is
in the actual file, and to parse that line.

Specifically, it should I<not> assume that every line in the input file is a
valid log line.  It is expected to check first.

Mail::Log::Parse is (as of v1.3) a cached inside-out object.  If you don't know
what that means, ignore it: just writing C<_parse_next_line> correctly is enough.
However, if you find you need to store sub-class object info for some reason,
and want to use an inside-out object syntax yourself, C<$$self == refaddr $self>.
Which is useful and fast.

Speed I<is> important.  It is not unlikely for someone to try to parse through
a week's worth of logs from a dozen boxes, where each day's log is hundreds of
megabytes worth of data.  Be as good as you can.

One other thing: Realize that you may also be subclassed.  Even if you parse
every possible option of some log format, someone somewhere will probably have
a customized version with a slightly different format.  If you've done your job
well, they'll be able to use your parser and just extend it slightly.  Key to
this is to leave the I<unaltered> line in the return hash under the 'text' key.

=head2 Suggested usage:

Suggestion on how to use the above two methods to implement a '_parse_next_line' routine in
a subclass:

  sub _parse_next_line {
	my ($self) = @_;

	# The hash we will return.
	my %line_info = ( program => '' );

	# Some temp variables.
	my $line;

	# In a mixed-log enviornment, we can't count on any
	# particular line being something we can parse.  Keep
	# going until we can.
	while ( $line_info{program} !~ m/$program_name/ ) {
		# Read the line, using the Mail::Log::Parse utilty method.
		$line = $self->_get_data_line() or return undef;

		# Program name.  (We trust the logs. ;) )
		$line_info{program} = $line ~= m/$regrex/;
	}

	# Continue parsing
	...

	return \%line_info;
 }

=head1 UTILITY METHODS

The following methods are not for general consumption: They are specifically
provided for use in implementing subclasses.  Using them incorrectly, or
outside a subclass, can get the object into an invalid state.

B<ONLY USE IF YOU ARE IMPLEMENTING A SUBCLASS.>

=head2 _set_current_position_as_next_line

Depreciated: No longer needed.  An empty stub exists for backwards-compatibility.

=cut

sub _set_current_position_as_next_line () {  }


# Sets the current positition as the next 'line' of logical data.
# Purely internal at this point.
# Optimized for speed over clarity, since we potentially use this a lot.
# (At least once per log line read.)
sub _set_position_as_next_line {
	$current_line{${$_[0]}} += 1;
	${$log_info{${$_[0]}}}{line_positions}[$current_line{${$_[0]}}] = $log_info{${$_[0]}}{'filehandle'}->getpos()
		or Mail::Log::Exceptions::LogFile->throw("Unable to get current file position: $!\n");
}

=head2 _get_data_line

Returns the next line of data, as a string, from the logfile.  This is raw data
from the logfile, separated by the current input separator.

=cut

# Optimized for speed over clarity, since we potentially use this a lot.
# (At least once per log line read.)

sub _get_data_line {
	if ( defined($log_info{${$_[0]}}{'filehandle'}) ){
		return $log_info{${$_[0]}}{'filehandle'}->getline()
	}
	else {
		Mail::Log::Exceptions::LogFile->throw("Trying to read without a valid logfile: $!\n");
	}
}

=head2 _clear_buffer

Clears the internal buffer of any data that may have been read into it so far.
Normally you should never need to use this: It is provided only for those rare
cases where something that has already been read may be changed because of
outside input.  (For instance: You can change the year dates are assumed to be
in during mid-read on Postfix.)

Avoid using unless actually needed.

=cut

sub _clear_buffer {
	my ($self) = @_;
	@{$parse_buffer{$$self}} = undef;
	$parse_buffer_start_line{$$self} = -1;
	return;
}

#
# Fully private methods.
#
=for readme continue

=head1 BUGS

C<go_forward> and C<go_backward> at the moment don't test for negative
numbers.  They may or may not work with a negative number of lines: It depends
where you are in the file and what you've read so far.

Those two methods should do slightly better on 'success' testing, to return
better values.  (They basically always return true at the moment.)

C<get_line_number> will return one less than the true line number if you are
at the end of the file, and the buffer was completely filled.  (So that the
end of the file is the last space of the buffer.)  Changing the buffer size or
just going back and re-reading so that the buffer is restarted at a different
location will allow you to retrieve the correct file length.

=head1 REQUIRES

L<Scalar::Util>, L<File::Basename>, L<IO::File>, L<Mail::Log::Exceptions>

=head1 RECOMMENDS

L<IO::Uncompress::AnyUncompress>, L<File::Temp>

=head1 AUTHOR

Daniel T. Staal

DStaal@usa.net

=head1 SEE ALSO

L<Parse::Syslog::Mail>, which does some of what this module does.  (This module
is a result of running into what that module I<doesn't> support.  Namely
seeking through a file, both forwards and back.)

=for readme stop

=head1 HISTORY

November 14, 2015 (1.4.2) - Switched from depreciated 'Module::Build::ModuleInfo
to it's replacement 'Module::Metadata' and included it in configure_requires.
(As it is no longer part of the Module::Build package.)

February 8, 2014 (1.4.1) - Switched to using Perl-standard environment variables
for checking to run author tests.  (Should now test cleanly on Windows.)

April 17, 2009 (1.4.0) - Simplified subclassing: No longer need to call
C<_set_current_position_as_next_line> in subclass.  (A stub exists for backwards
compatibility.)

April 9, 2009 (1.3.1) - Documentation fixes, better handling of trying to work
without a valid logfile.

Dec 23, 2008 (1.3.0) - Further code speedups.  Now stores a cache of the refaddr
for easy and quick access.

Dec 09, 2008 (1.2.10) - Profiled and sped up code.  (Cut processing time in half
for some cases.)

Nov 28, 2008 - Documentation fixes.

Nov 18, 2008 - Now buffers reading, and prefers data from the buffer.

Oct 24, 2008 - File::Temp now optional; only required for uncompressed files.
               Added go_to_line_number for slightly better functionality.

Oct 14, 2008 - Found that I need File::Temp of at least version 0.17.

Oct 13, 2008 - Fixed tests so they do a better job of checking if they
need to skip.

Oct 6, 2008 - Initial version.

=for readme continue

=head1 COPYRIGHT and LICENSE

Copyright (c) 2008 Daniel T. Staal. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This copyright will expire in 30 years, or 5 years after the author's
death, whichever is longer.

=cut
}	# End Package.
1;
