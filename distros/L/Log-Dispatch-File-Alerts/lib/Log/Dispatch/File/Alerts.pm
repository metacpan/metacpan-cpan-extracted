## no critic
package Log::Dispatch::File::Alerts;

use 5.006001;
use strict;
use warnings;

use Log::Dispatch::File '2.37';
use Log::Log4perl::DateFormat;
use Fcntl ':flock'; # import LOCK_* constants

our @ISA = qw(Log::Dispatch::File);

our $VERSION = '1.04';

our $TIME_HIRES_AVAILABLE = undef;

BEGIN { # borrowed from Log::Log4perl::Layout::PatternLayout, Thanks!
	# Check if we've got Time::HiRes. If not, don't make a big fuss,
	# just set a flag so we know later on that we can't have fine-grained
	# time stamps
	
	eval { require Time::HiRes; };
	if ($@) {
		$TIME_HIRES_AVAILABLE = 0;
	} else {
		$TIME_HIRES_AVAILABLE = 1;
	}
}

# Preloaded methods go here.

sub new {
	my $proto = shift;
	my $class = ref $proto || $proto;
	
	my %p = @_;
	
	my $self = bless {}, $class;
	
	# only append mode is supported
	$p{mode} = 'append';
	# 'close' mode is always used
	$p{close_after_write} = 1;
	
	# base class initialization
	$self->_basic_init(%p);

	# split pathname into path, basename, extension
	if ($p{filename} =~ /^(.*)\%d\{([^\}]*)\}(.*)$/) {
		$self->{rolling_filename_prefix}  = $1;
		$self->{rolling_filename_postfix} = $3;
		$self->{rolling_filename_format}  = Log::Log4perl::DateFormat->new($2);
		$self->{filename} = $self->_createFilename(0);
	} elsif ($p{filename} =~ /^(.*)(\.[^\.]+)$/) {
		$self->{rolling_filename_prefix}  = $1;
		$self->{rolling_filename_postfix} = $2;
		$self->{rolling_filename_format}  = Log::Log4perl::DateFormat->new('-yyyy-MM-dd-$!');
		$self->{filename} = $self->_createFilename(0);
	} else {
		$self->{rolling_filename_prefix}  = $p{filename};
		$self->{rolling_filename_postfix} = '';
		$self->{rolling_filename_format}  = Log::Log4perl::DateFormat->new('.yyyy-MM-dd-$!');
		$self->{filename} = $self->_createFilename(0);
	}

	$self->_make_handle();
			
	return $self;
}

sub log_message { # parts borrowed from Log::Dispatch::FileRotate, Thanks!
	my $self = shift;
	my %p = @_;
	my $try = 1;
	my $firstfilename = $self->_createFilename(0); # if this is generated, we are done

	while (defined $try) {
		$self->{filename} = $self->_createFilename($try);

		if (($try > 1 and $firstfilename eq $self->{filename}) or $try < 1) { # later checks for integer overflow
			die 'could not find an unused file for filename "'
			. $self->{filename}
			. '". Did you use "!"?';
		}

		$self->_open_file;
		$self->_lock();
		my $fh = $self->{fh};
		if (not -s $fh) {
			# if the file is zero-sized, it is fresh.
			# else someone else already used it.
			print $fh $p{message};
			$try = undef;
		} else {
			$try++;
		}
		$self->_unlock();
		close($fh);
		$self->{fh} = undef;
	}
}

sub _lock { # borrowed from Log::Dispatch::FileRotate, Thanks!
	my $self = shift;
	flock($self->{fh},LOCK_EX);
	# Make sure we are at the EOF
	seek($self->{fh}, 0, 2);
	return 1;
}

sub _unlock { # borrowed from Log::Dispatch::FileRotate, Thanks!
	my $self = shift;
	flock($self->{fh},LOCK_UN);
	return 1;
}

sub _current_time { # borrowed from Log::Log4perl::Layout::PatternLayout, Thanks!
	# Return secs and optionally msecs if we have Time::HiRes
	if($TIME_HIRES_AVAILABLE) {
		return (Time::HiRes::gettimeofday());
	} else {
		return (time(), 0);
	}
}

sub _createFilename {
	my $self = shift;
	my $try = shift;
	return $self->{rolling_filename_prefix}
	     . $self->_format($try)
	     . $self->{rolling_filename_postfix};
}

sub _format {
	my $self = shift;
	my $try = shift;
	my $result = $self->{rolling_filename_format}->format($self->_current_time());
	$result =~ s/(\$+)/sprintf('%0'.length($1).'.'.length($1).'u', $$)/eg;
	$result =~ s/(\!+)/sprintf('%0'.length($1).'.'.length($1).'u', substr($try, -length($1)))/eg;
	return $result;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=for changes stop

=head1 NAME

Log::Dispatch::File::Alerts - Object for logging to alert files

=head1 SYNOPSIS

  use Log::Dispatch::File::Alerts;

  my $file = Log::Dispatch::File::Alerts->new(
                             name      => 'file1',
                             min_level => 'emerg',
                             filename  => 'Somefile%d{yyyy!!!!}.log',
                             mode      => 'append' );

  $file->log( level => 'emerg',
              message => "I've fallen and I can't get up\n" );

=head1 ABSTRACT

This module provides an object for logging to files under the
Log::Dispatch::* system.

=head1 DESCRIPTION

This module subclasses Log::Dispatch::File for logging to date/time 
stamped files. See L<Log::Dispatch::File> for instructions on usage. 
This module differs only on the following three points:

=over 4

=item alert files

This module will use a seperate file for every log message.

=item multitasking-safe

This module uses flock() to lock the file while writing to it.

=item stamped filenames

This module supports a special tag in the filename that will expand to 
the current date/time/pid.

It is the same tag Log::Log4perl::Layout::PatternLayout uses, see 
L<Log::Log4perl::Layout::PatternLayout>, chapter "Fine-tune the date". 
In short: Include a "%d{...}" in the filename where "..." is a format 
string according to the SimpleDateFormat in the Java World 
(http://java.sun.com/j2se/1.3/docs/api/java/text/SimpleDateFormat.html). 
See also L<Log::Log4perl::DateFormat> for information about further 
restrictions.

In addition to the format provided by Log::Log4perl::DateFormat this 
module also supports '$' for inserting the PID and '!' for inserting a 
uniq number. Repeat the character to define how many character wide the 
field should be.

A note on the '!': The module first tries to find a fresh filename with this set 
to 1. If there is already a file with that name then it is increased until 
either a free filename has been found. If there is no free filename (e.g. you 
used '!!' and there are already 100 files) or the counter goes over the top 
(integer overflow) the module dies. So if you used many '!'s and there are many 
alert files, this can take quite a while. But if you have that many alert files, 
something already went very bad, so it should not really matter.

=back

=head1 METHODS

=over 4

=item new()

See L<Log::Dispatch::File> and chapter DESCRIPTION above.

=item log_message()

See L<Log::Dispatch::File> and chapter DESCRIPTION above.

=back

=for changes continue

=head1 HISTORY

=over 8

=item 0.99

Original version; taken from Log::Dispatch::File::Rolling 1.02

=item 1.00

Initial coding

=item 1.01

Updated packaging for newer standards. No changes to the coding.

=item 1.02

Added unlocking of files we do not use.

Removed the 9999 files limit. Now it will create as many files as a Perl integer 
can support.

=item 1.03

Adapted to changes in Log::Dispatch::File. If you are using Log::Dispatch::File
2.36 or earlier, use Alerts 1.02.

=item 1.04

Dependency change of 1.03 was missing from the Makefile.PL. Oops.

=back

=for changes stop

=head1 SEE ALSO

L<Log::Dispatch::File>, L<Log::Log4perl::Layout::PatternLayout>, 
L<Log::Dispatch::File::Rolling>, L<Log::Log4perl::DateFormat>, 
http://java.sun.com/j2se/1.3/docs/api/java/text/SimpleDateFormat.html, 
'perldoc -f flock'

=head1 AUTHOR

M. Jacob, E<lt>jacob@j-e-b.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003, 2007, 2010, 2013 M. Jacob E<lt>jacob@j-e-b.netE<gt>

Based on:

  Log::Dispatch::File::Stamped by Eric Cholet <cholet@logilune.com>
  Log::Dispatch::FileRotate by Mark Pfeiffer, <markpf@mlp-consulting.com.au>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
