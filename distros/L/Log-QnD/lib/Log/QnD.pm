package Log::QnD;
use strict;
use Carp 'croak';
use String::Util ':all';
use JSON qw{to_json -convert_blessed_universally};

# debugging
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# version
our $VERSION = '0.17';

# extend Class::PublicPrivate
use base 'Class::PublicPrivate';

=head1 NAME

Log::QnD - Quick and dirty logging system

=head1 SYNOPSIS

 use Log::QnD;

 # create log entry
 my $qnd = Log::QnD->new('./log-file');

 # save stuff into the log entry
 $qnd->{'stage'} = 1;
 $qnd->{'tracks'} = [qw{1 4}];
 $qnd->{'coord'} = {x=>1, z=>42};

 # undef the log entry or let it go out of scope
 undef $qnd;

 # the log entry looks like this:
 # {"stage":1,"tracks":["1","4"],"time":"Tue May 20 17:13:22 2014","coord":{"x":1,"z":42},"entry_id":"7WHHJ"}

 # get a log file object
 $log = Log::QnD::LogFile->new($log_path);

 # get first entry from log
 $from_log = $log->read_forward();

 # get latest entry from log
 $from_log = $log->read_backward();

=head1 DESCRIPTION

Log::QnD is for creating quickly creating log files without a lot of setup.
All you have to do is create a Log::QnD object with a file path. The returned
object is a hashref into which you can save any data you want, including data
nested in arrays and hashrefs. When the object goes out of scope its contents
are saved to the log as a JSON string.

PLEASE NOTE: Until this module reaches version 1.0, I might make some
non-backwards-compatible changes.  See Versions notes for such changes.

=head1 INSTALLATION

Log::QnD can be installed with the usual routine:

 perl Makefile.PL
 make
 make test
 make install

=head1 Log::QnD

A Log::QnD object represents a single log entry in a log file.  It is created
by calling Log::QnD->new() with the path to the log file:

 my $qnd = Log::QnD->new('./log-file');

That command alone is enough to create the log file if necessary and an entry
into the log.  It is not necessary to explicitly save the log entry; it will be
saved when the Log::QnD object goes out of scope.

By default, each log entry has two properties when it is created: the time the
object was created ('time') and a (probably) unique ID ('entry_id').  The
structure looks like this:

 {
    'time' => 'Mon May 19 19:22:22 2014',
    'entry_id' => 'JNnwk'
 }

The 'time' field is the time the log entry was created. The 'entry_id' field is
just a random five-character string. It is not checked for uniqueness, it is
just probable that there is no other entry in the log with the same ID.

Each log entry is stored as a single line in the log to make it easy to parse.
Entries are separated by a blank line to make them more human-readable. So the
entry above and another entry would be stored like this:

 {"time":"Mon May 19 19:22:22 2014","entry_id":"JNnwk"}

 {"time":"Mon May 19 19:22:23 2014","entry_id":"kjH0c"}

You can save other values into the hash, including nested hashes and arrays:

 $qnd->{'stage'} = 1;
 $qnd->{'tracks'} = [qw{1 4}];
 $qnd->{'coord'} = {x=>1, z=>42};

which results in a JSON string like this:

 {"stage":1,"tracks":["1","4"],"time":"Tue May 20 17:13:22 2014","coord":{"x":1,"z":42},"entry_id":"7WHHJ"}

=cut



#------------------------------------------------------------------------------
# new
#

=head2 Log::QnD->new($log_file_path)

Create a new Log::QnD object. The only param for this method is the path to
the log file.  The log file does not need to actually exist yet; if necessary
it will be created when the QnD object saves itself.

=cut

sub new {
	my $class = shift(@_);
	my $qnd = $class->SUPER::new();
	my ($path) = @_;
	my ($private);
	
	# must get path to log file
	unless (defined $path)
		{ croak 'did not get defined path to log file' }
	
	# get private values
	$private = $qnd->private();
	
	# hold on to path
	$private->{'path'} = $path;
	
	# set date/time of entry
	$qnd->{'time'} = localtime;
	
	# set id
	$qnd->{'entry_id'} = randword(5);
	
	# autosave
	$private->{'autosave'} = 1;
	
	# return
	return $qnd;
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# cancel, uncancel
#

=head2 $qnd->cancel()

Cancels the automatic save.  By default the $qnd object saves to the log when
it goes out of scope, undeffing it won't cancel the save.  $qnd->cancel()
causes the object to not save when it goes out of scope.

=head2 $qnd->uncancel()

Sets the log entry object to automatically save when the object goes out of scope.
By default the object is set to autosave, so uncancel() is only useful if you
have cancelled the autosave in some way, such as with $qnd-E<gt>cancel().

=cut

sub cancel {
	my ($qnd) = @_;
	$qnd->private->{'autosave'} = 0;
}

sub uncancel {
	my ($qnd) = @_;
	$qnd->private->{'autosave'} = 1;
}
#
# cancel, uncancel
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# save
#

=head2 $qnd->save()

Saves the Log::QnD log entry.  By default, this method is called when the
object goes out of scope.  If you've used $qnd-E<gt>cancel() to cancel
autosave then you can use $qnd->save() to explicitly save the log entry.

=cut

sub save {
	my ($qnd) = @_;
	my ($log, $json);
	
	# get log object
	$log = $qnd->log_file();
	
	# get json string
	$json = to_json($qnd, {convert_blessed=>1});
	
	# change newlines to spaces to ensure the log entry is a single line
	$json =~ s|[\r\n]| |gs;
	
	# write entry to log
	$log->write_entry($json) or return 0;
	
	# return success
	return 1;
}
#
# save
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# log_file
#

=head2 $qnd->log_file()

Returns a Log::QnD::LogFile object.  The log entry object does not hold on to
the log file object, nor does the log file object "know" about the entry
object.

=cut

sub log_file {
	my ($qnd) = @_;
	my ($log_class, $log);
	
	# get log file object
	$log_class = ref($qnd) . '::LogFile';
	$log = $log_class->new($qnd->private->{'path'});
	
	# return
	return $log;
}
#
# log_file
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# catch_stderr
#

=head2 $qnd->catch_stderr()

Closes the existing STDERR, redirects new STDERR to the C<stderr> element in
the log entry.  STDERR is release when the log object goes out of scope.

Currently it's undefined what should or will happen if too log entries both
try to catch STDERR. Either don't do that or solve this dilemna and submit your
ideas back to me.

=cut

sub catch_stderr {
	my ($qnd) = @_;
	
	# TESTING
	# println subname(); ##i
	
	# require necessary module
	require IO::Scalar;
	
	# catch STDERR
	tie *STDERR, 'IO::Scalar', \$qnd->{'stderr'};
}
#
# catch_stderr
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# private
# NOTE: There is no subroutine in this section, just POD to document the
# $qnd->private() method that is inherited from Class::PublicPrivate.
#

=head2 $qnd->private()

$qnd->private() is a method inherited from
L<Class::PublicPrivate|http://search.cpan.org/~miko/Class-PublicPrivate/>. This
method is used to store private properties such as the location of the log
file. Unless you want to tinker around with the log entry's internals you can
ignore this method.

=cut

#
# private
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# DESTROY
#
sub DESTROY {
	my ($qnd) = @_;
	
	# autosave if set to do so
	if ($qnd->private->{'autosave'}) {
		$qnd->save();
	}
	
	# release stderr
	if (exists $qnd->{'stderr'}) {
		untie *STDERR;
	}
}
#
# DESTROY
#------------------------------------------------------------------------------



###############################################################################
# Log::QnD::LogFile
#
package Log::QnD::LogFile;
use strict;
use Carp 'croak';
use FileHandle;
use String::Util ':all';
use Fcntl ':mode', ':flock', 'SEEK_END';
use JSON 'from_json';

# debugging
# use Debug::ShowStuff ':all';

=head1 Log::QnD::LogFile

A Log::QnD::LogFile object represents the log file to which the log entry is
saved.  The LogFile object does the actual work of saving the log entry.  It
also provides a mechanism for retrieving information from the log.  If you use
Log::QnD in its simplest form by just creating Log::QnD objects and allowing
them to save themselves when they go out of scope then you don't need to
explicitly use Log::QnD::LogFile.

=cut

#------------------------------------------------------------------------------
# new
#

=head2 Log::QnD::LogFile->new($log_file_path)

Create a new Log::QnD::LogFile object. The only param for this method is the
path to the log file.

=cut

sub new {
	my ($class, $path) = @_;
	my $log = bless({}, $class);
	
	# must get path to log file
	unless (defined $path)
		{ croak 'did not get defined path to log file' }
	
	# hold on to log path
	$log->{'path'} = $path;
	
	# return
	return $log;
}
#
# new
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# write_entry
#

=head2 $log->write_entry($string)

This method writes the log entry to the log file.  The log file is created if
it doesn't already exist.

The only input for this method is the string to write to the log.  The string
should already be in JSON format and should have no newline.  C<write_entry()>
doesn't do anything about formatting the string, it just spits it into the
log.

=cut

sub write_entry {
	my ($log, $entry_str) = @_;
	my ($out);
	
	# get write handle
	$out = FileHandle->new(">> $log->{'path'}")
		or die "unable to get write handle: $!";
	
	# get lock
	flock($out, LOCK_EX) or
		die "unable to lock file: $!";
	
	# seek end of file
	$out->seek(0, SEEK_END) or die "cannot seek end of file: $!";
	
	# unless the file is empty, output a newline
	if (tell $out) {
		print $out "\n";
	}
	
	# output
	print $out $entry_str, "\n";
	
	# return success
	return 1;
}
#
# write_entry
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# entry_count
#

=head2 $log->entry_count()

This method returns the number of entries in the log file.  If the log file
doesn't exist then this method returns undef.

=cut

sub entry_count {
	my ($log) = @_;
	my ($read, $count);
	
	# special case: log file doesn't actually exist
	if (! -e $log->{'path'})
		{ return undef }
	
	# get lock
	$read = FileHandle->new($log->{'path'}) or die "unable to get read handle: $!";
	flock($read, LOCK_SH) or die "unable to lock file: $!";
	
	# initialize count to zero
	$count = 0;
	
	LOG_LOOP:
	while( defined( my $line = $read->getline ) ) {
		my ($entry);
		
		# skip empty lines
		hascontent($line) or next LOG_LOOP;
		
		# increment count
		$count++;
	}
	
	# return
	return $count;
}
#
# entry_count
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# read_entry
# Private method for implementing readforward() and read_backward().
#

# constants for reading
use constant READ_FORWARD => 1;
use constant READ_BACKWARD => 2;

sub read_entry {
	my ($log, $direction, %opts) = @_;
	my ($read, $lock, $tgt_id, $multiple, $get_count, @rv);
	
	# special case: log file doesn't actually exist
	if (! -e $log->{'path'})
		{ return undef }
	
	# get target id
	$tgt_id = $opts{'entry_id'};
	
	# if there is already a read handle, make sure it's the correct direction
	if ($log->{'read'}) {
		if ($log->{'read'}->{'direction'} != $direction) {
			$log->end_read();
		}
	}
	
	# determine if we're fetching more than one entry
	if (defined ($get_count = $opts{'count'})) {
		$multiple = 1;
	}
	
	# get cached read, else create and cache
	unless ($read = $log->{'read'}) {
		$log->{'read'} = $read = {};
		
		# set direction
		$read->{'direction'} = $direction;
		
		# get lock
		$read->{'lock'} = FileHandle->new($log->{'path'}) or die "unable to get read handle: $!";
		flock($read->{'lock'}, LOCK_SH) or die "unable to lock file: $!";
		
		# get read handle
		if ($direction == READ_FORWARD) {
			require FileHandle;
			$read->{'fh'} = FileHandle->new($log->{'path'});
		}
		else {
			require File::ReadBackwards;
			$read->{'fh'} = File::ReadBackwards->new($log->{'path'});
		}
		
		# die on failure
		$read->{'fh'} or die $!
	}
	
	LOG_LOOP:
	while( defined( my $line = $read->{'fh'}->getline ) ) {
		my ($entry);
		
		# skip empty lines
		hascontent($line) or next LOG_LOOP;
		
		# get json object
		$entry = from_json($line);
		
		# if there is a target id, and this isn't it, next entry
		# KLUDGE: Something about this next block of code feels spaghettish,
		# though I can't quite specify why.
		if ($tgt_id) {
			if ($entry->{'entry_id'} eq $tgt_id) {
				$log->end_read();
				return $entry;
			}
			else {
				next LOG_LOOP;
			}
		}
		
		# if geting multiple entries
		if ($multiple) {
			push @rv, $entry;
			
			if ($get_count && (@rv >= $get_count)) {
				wantarray() and return @rv;
				return \@rv;
			}
		}
		
		# else just return this entry
		else {
			return $entry;
		}
	}
	
	# at ending|beginning of log, so return undef
	$log->end_read();
	
	# if seeking multiple values
	if ($multiple) {
		wantarray() and return @rv;
		return \@rv;
	}
	
	# else return undef
	else {
		return undef;
	}
}
#
# read_entry
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# read_forward, read_backward
#

=head2 $log->read_forward(), $log->read_backward()

C<read_forward()> and C<read_backward()> each return a single entry from the
log file. The data is already parsed from JSON. So, for example, the following
line returns an entry from the log:

 $log->read_forward();

read_forward() starts with the first entry in the log.  Each subsequent call to
read_forward() returns the next log entry.

read_backward() starts with the last log entry.  Each subsequent call to
read_backward() returns the next entry back.

After the latest/earliest entry in the log is returned then these methods
return undef.

It is important to know that after the first call to C<read_forward()> or
C<read_backward()> is made the log file object puts a read lock on the log
file. That means that log entry objects cannot write to the file until the
read lock is removed.  The read lock is removed when the log file object is
detroyed, when C<read_backward()> returns undef, or when you explicitly call
C<$log-E<gt>end_read>.

If you call one of these methods while the log object is reading through using
the other method, then the read will reset and the end/beginning of the log
file.

=over

=item B<option:> entry_id

If you send the 'entry_id' option then the log entry specified by the given id
will be returned. If no such entry is found then undef is returned. For
example, the following line returns the log entry for 'fv8sd', or undef if the
entry is not found:

 $log->read_backward(entry_id=>'fv8sd');

=item B<option:> count

The C<count> option indicates how many log entries to return.  So, for
example, the following line retrieves up to five entries, fewer if the
ending|beginning of the file is reached:

 @entries = $log->read_forward(count=>5)

If C<count> is 0 then all remaining entries are returned.  In array context an
array is returned.  In scalar context an array reference is returned.  Undef is
never returned.  Each subsequent call using count returns the next batch of
C<count> entries.

=back

=cut

sub read_forward {
	my $log = shift(@_);
	return $log->read_entry(READ_FORWARD, @_);
}

sub read_backward {
	my $log = shift(@_);
	return $log->read_entry(READ_BACKWARD, @_);
}
#
# read_forward, read_backward
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# end_read
#

=head2 $log->end_read()

C<end_read()> explicitly closes the read handle for the log and releases the
read lock. C<end_read()> always returns undef.

=cut

sub end_read {
	my ($log) = @_;
	delete $log->{'read'};
	return undef;
}
#
# end_read
#------------------------------------------------------------------------------


#
# Log::QnD::LogFile
###############################################################################


# return true
1;

__END__

=head1 SEE ALSO

The following modules provide similar functionality. I like mine best (or I
wouldn't have written it) but your tastes may differ. Funny how the world works
like that.

=over

=item L<Log::JSON|http://search.cpan.org/~kablamo/Log-JSON/>

=item L<Log::Message::JSON|http://search.cpan.org/~dozzie/Log-Message-JSON/>

=item L<Mojo::Log::JSON|http://search.cpan.org/dist/Mojo-Log-JSON/>

=back

=head1 TERMS AND CONDITIONS

Copyright (c) 2014 by Miko O'Sullivan. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself. This software comes with no warranty of any kind.

=head1 AUTHOR

Miko O'Sullivan C<miko@idocs.com>

=head1 TO DO

=over

=item Clean up POD

In particular, I can't figure out how to link to sections in this page that
have greater-than symbols in their names like $qnd->cancel()

=back

=head1 VERSIONS

=over

=item Version 0.10, May 20, 2014

Initial release.

=item Version 0.11, May 22, 2014

Fixed problem in test script.  Fixed incorrect documentation.

=item Version 0.12, May 225, 2014

Made non-backwards-compatible change from "entry-id" to "entry_id".

Added 'entry_id' option to $log_file->get_entry().

Added documentation for $qnd->private() method.

=item 0.13, May 26, 2014

Changed $log_file->get_entry() to $log_file->read_backward(). This is a
non-backwards-compatible change.

Added $log_file->read_forward().

Added private method $log_file->read_entry().

=item 0.14, May 27, 2014

Fixed test script that was attempting to clear the screen. That bug was an
artifact from development.

Added C<count> option to C<read_forward> and C<read_backward>.

=item 0.15, May 28, 2014

Tidied up output of log entry so that the entry is followed by a newline.

Added C<$log-E<gt>entry_count()> method.

=item 0.16, July 28, 2014

Added catch_stderr method. Fixed typos in documentation. Clarified wording in
documentation.

=item 0.16, August 9, 2014

Fixed problem in prerequisites.


=back

=cut
