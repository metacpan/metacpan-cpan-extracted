package IO::NestedCapture;

use strict;
use warnings;

use Carp;
use File::Temp;

require Exporter;
our @ISA = qw/ Exporter /;

our @EXPORT_OK = qw/ 
	CAPTURE_NONE
	CAPTURE_STDIN
	CAPTURE_STDOUT
	CAPTURE_IN_OUT
	CAPTURE_STDERR
	CAPTURE_IN_ERR
	CAPTURE_OUT_ERR
	CAPTURE_ALL

	capture_in
	capture_out
	capture_err
	capture_in_out
	capture_out_err
	capture_in_err
	capture_all
/;

our %EXPORT_TAGS = (
	'constants' => [ qw/
		CAPTURE_NONE
		CAPTURE_STDIN
		CAPTURE_STDOUT
		CAPTURE_IN_OUT
		CAPTURE_STDERR
		CAPTURE_IN_ERR
		CAPTURE_OUT_ERR
		CAPTURE_ALL
	/ ],

	'subroutines' => [ qw/
		capture_in
		capture_out
		capture_err
		capture_in_out
		capture_out_err
		capture_in_err
		capture_all
	/ ],
);

our $VERSION = '1.03';

use constant CAPTURE_NONE    => 0;
use constant CAPTURE_STDIN   => 1;
use constant CAPTURE_STDOUT  => 2;
use constant CAPTURE_IN_OUT  => 3;
use constant CAPTURE_STDERR  => 4;
use constant CAPTURE_IN_ERR  => 5;
use constant CAPTURE_OUT_ERR => 6;
use constant CAPTURE_ALL     => 7;

=head1 NAME

IO::NestedCapture - module for performing nested STD* handle captures

=head1 SYNOPSIS

  use IO::NestedCapture qw/ :subroutines /;

  my $in = IO::NestedCapture->get_next_in;
  print $in "Harry\n";
  print $in "Ron\n";
  print $in "Hermione\n";

  capture_in_out {
      my @profs = qw( Dumbledore Flitwick McGonagall );
      while (<STDIN>) {
    	  my $prof = shift @prof;
    	  print STDOUT "$_ favors $prof";
      }
  };

  my $out = IO::NestedCapture->get_last_out;
  while (<$out>) {
	  print;
  }

  # This program will output:
  # Harry favors Dumbledore
  # Ron favors Flitwick
  # Hermione favors McGonagall

=head1 DESCRIPTION

This module was partially inspired by L<IO::Capture>, but is intended for a very different purpose and is not otherwise related to that package. In particular, I have a need for some pretty aggressive output/input redirection in a web project I'm working on. I'd like to be able to pipe input into a subroutine and then capture that subroutines output to be used as input on the next.

I was using a fairly clumsy, fragile, and brute force method for doing this. If you're interested, you can take a look at the code on PerlMonks.org:

  http://perlmonks.org/?node_id=459275

This module implements a much saner approach that involves only a single tie per file handle (regardless of what you want to tie it to). It works by tying the STDIN, STDOUT, and STDERR file handles. Then, uses internal tied class logic to handle any nested use or other work.

With this module you can capture any combination of STDIN, STDOUT, and STDERR. In the case of STDIN, you may feed any input into capture you want (or even set it to use another file handle). For STDOUT and STDERR you may review the full output of these or prior to capture set a file handle that will receive all the data during the capture.

As of version 1.02 of this library, there are two different interfaces to the library. The object-oriented version was first, but the new subroutine interface is a little less verbose and a little safer.

=head2 OBJECT-ORIENTED INTERFACE

The object-oriented interface is available either through the  C<IO::NestedCapture> class directly or through a single instance of the class available through the C<instance> method.

  my $capture = IO::NestedCapture->instance;
  $capture->start(CAPTURE_STDOUT);
  
  # Is the same as...

  IO::NestedCapture->start(CAPTURE_STDOUT);

It doesn't really make much difference.

You will probably want to important one, several, or all of the capture constants to use this interface.

=head2 SUBROUTINE INTERFACE

This interface is available via the import of one of the capture subroutines (or not if you want to fully qualify the names):

  use IO::NestedCapture 'capture_out';
  capture_out {
      # your code to print to STDOUT here...
  };

  # Is similar to...
  IO::NestedCapture::capture_err {
      # your code to print to STDERR here...
  };

This interface has the advantage of being a little more concise and automatically starts and stops the capture before and after running the code block. This will help avoid typos and other mistakes in your code, such as forgetting to call C<stop> when you are done.

=head2 NESTED CAPTURE SUBROUTINES

These subroutines are used with the subroutine interface. (See L</"SUBROUTINE INTERFACE">.) These subroutines actually use the object-oriented interface internally, so they merely provide a convenient set of shortcuts to it that may help save you some trouble.

For each subroutine, the subroutine captures one or more file handles before running the given code block and uncaptures them after. In case of an exception, the file handles will still be uncaptured properly. Make sure to put a semi-colon after each method call.

To manipulate the input, output, and error handles before or after the capture, you will still need to use parts of the object-oriented interface.

You will want to import the subroutines you want to use when you load the C<IO::NestedCapture> object:

  use IO::NestedCapture qw/ capture_in capture_out /;

or you can import all of the capture subroutines with the C<:subroutines> mnemonic:

  use IO::NestedCapture ':subroutines';

In place of a block, you may also give a code reference as the argument to any of these calls:

  sub foo { print "bah\n" }

  capture_all \&foo;

This will run the subroutine foo (with no arguments) and capture the streams it reads/writes. Also, each of the capture subroutines return the return value of the block or rethrow the exceptions raised in the block after stopping the capture.

=over

=item capture_in { };

This subroutine captures C<STDIN> for the duration of the given block.

=cut

sub capture_in(&) {
	my $self = IO::NestedCapture->instance;
	my $code = shift;

	# capture input and then turn off capture, even on error
	$self->start(CAPTURE_STDIN);
	my $result = eval {
		$code->();
	};
	my $ERROR = $@;
	$self->stop(CAPTURE_STDIN);

	# rethrow any errors or return normally
	die $ERROR if $ERROR;
	return $result;
}

=item capture_out { };

This subroutine captures C<STDOUT> for the duration of the given block.

=cut

sub capture_out(&) {
	my $self = IO::NestedCapture->instance;
	my $code = shift;

	# capture output and then turn off capture, even on error
	$self->start(CAPTURE_STDOUT);
	my $result = eval {
		$code->();
	};
	my $ERROR = $@;
	$self->stop(CAPTURE_STDOUT);

	# rethrow any errors or return normally
	die $ERROR if $ERROR;
	return $result;
}

=item capture_err { };

This subroutine captures C<STDERR> for the duration of the given block.

=cut

sub capture_err(&) {
	my $self = IO::NestedCapture->instance;
	my $code = shift;

	# capture error output and then turn off capture, even on error
	$self->start(CAPTURE_STDERR);
	my $result = eval {
		$code->();
	};
	my $ERROR = $@;
	$self->stop(CAPTURE_STDERR);

	# rethrow any errors or return normally
	die $ERROR if $ERROR;
	return $result;
}

=item capture_in_out { };

This subroutine captures C<STDIN> and C<STDOUT> for the duration of the given block.

=cut

sub capture_in_out(&) {
	my $self = IO::NestedCapture->instance;
	my $code = shift;

	# capture input and output and then turn off capture, even on error
	$self->start(CAPTURE_IN_OUT);
	my $result = eval {
		$code->();
	};
	my $ERROR = $@;
	$self->stop(CAPTURE_IN_OUT);

	# rethrow any errors or return normally
	die $ERROR if $ERROR;
	return $result;
}

=item capture_in_err { };

This subroutine captures C<STDIN> and C<STDERR> for the duration of the given block.

=cut

sub capture_in_err(&) {
	my $self = IO::NestedCapture->instance;
	my $code = shift;

	# capture input and error output and then turn off capture, even on error
	$self->start(CAPTURE_IN_ERR);
	my $result = eval {
		$code->();
	};
	my $ERROR = $@;
	$self->stop(CAPTURE_IN_ERR);

	# rethrow any errors or return normally
	die $ERROR if $ERROR;
	return $result;
}

=item capture_out_err { };

This subroutine captures C<STDOUT> and C<STDERR> for the duration of the given block.

=cut

sub capture_out_err(&) {
	my $self = IO::NestedCapture->instance;
	my $code = shift;

	# capture output and error output and then turn off capture, even on error
	$self->start(CAPTURE_OUT_ERR);
	my $result = eval {
		$code->();
	};
	my $ERROR = $@;
	$self->stop(CAPTURE_OUT_ERR);

	# rethrow any errors or return normally
	die $ERROR if $ERROR;
	return $result;
}

=item capture_all { };

This subroutine captures C<STDIN>, C<STDOUT>, and C<STDERR> for the duration of the given block.

=cut

sub capture_all(&) {
	my $self = IO::NestedCapture->instance;
	my $code = shift;

	# capture input, output and error output and then turn off capture, even on
	# error
	$self->start(CAPTURE_ALL);
	my $result = eval {
		$code->();
	};
	my $ERROR = $@;
	$self->stop(CAPTURE_ALL);

	# rethrow any errors or return normally
	die $ERROR if $ERROR;
	return $result;
}

=back

=head2 NESTED CAPTURE CONSTANTS

These constants are used with the object-oriented interface. (See L</"OBJECT-ORIENTED INTERFACE">.)

You will want to import the constants you want when you load the C<IO::NestedCapture> module:

  use IO::NestedCapture qw/ CAPTURE_STDIN CAPTURE_STDOUT /;

or you may import all of them with the C<:constants> mnemonic.:

  use IO::NestedCapture ':constants';

=over

=item CAPTURE_STDIN

Used to start or stop capture on STDIN.

=item CAPTURE_STDOUT

Used to start or stop capture on STDOUT.

=item CAPTURE_STDERR

Used to start or stop capture on STDERR.

=item CAPTURE_IN_OUT

Used to start or stop capture on STDIN and STDOUT. This is a shortcut for "C<CAPTURE_STDIN | CAPTURE_STDOUT>".

=item CAPTURE_IN_ERR

Used to start or stop cpature on STDIN and STDERR. This is a shortcut for "C<CAPTURE_STDIN | CAPTURE_STDERR>".

=item CAPTURE_OUT_ERR

Used to start or stop capture on STDOUT and STDERR. This is a shortcut for "C<CAPTURE_STDOUT | CAPTURE_STDERR>".)

=item CAPTURE_ALL

Used to start or stop capture on STDIN, STDOUT, and STDERR. This is a shortcut for "C<CAPTURE_STDIN | CAPTURE_STDOUT | CAPTURE_STDERR>".

=back

=head2 OBJECT-ORIENTED CAPTURE METHODS

These are the methods used for the object-oriented interface. (See L</"OBJECT-ORIENTED INTERFACE">.)

=over

=item $capture = IO::NestedCapture-E<gt>instance;

Retrieves an instance of the singleton. Use of this method is optional.

=cut

my $instance;
sub instance {
	# We've already got one...
	return $instance if $instance;

	# I told 'im we already got one...
	my $class = shift;
	return $instance = bless {}, $class;
}

=item IO::NestedCapture-E<gt>start($capture_what)

=item $capture-E<gt>start($capture_what)

The C<$capture_what> variable is a bit field that should be set to one or more of the L</"NESTED CAPTURE CONSTANTS"> bit-or'd together. Until this method is called, the STD* handles are not tied to the C<IO::NestedCapture> interface. The tie will only occur on the very first call to this method. After that, the nesting is handled with stacks internal to the C<IO::NestedCapture> singleton.

If you're capturing STDIN, you should be sure to fill in the input using the C<in> method first if you want there to be any to be read. 

If you're capturing STDOUT or STDERR, you should be sure to set the file handles to output too, if you want to do that before calling this method.

=cut

my %fhs = (
	CAPTURE_STDIN()  => 'STDIN',
	CAPTURE_STDOUT() => 'STDOUT',
	CAPTURE_STDERR() => 'STDERR',
);

sub start {
	my $self = shift->instance;
	my $capture_what = shift;

	# check parameters for sanity
	$capture_what >= CAPTURE_NONE
		or croak "start() called without specifying which handles to capture.";
	$capture_what <= CAPTURE_ALL
		or croak "start() called with unknown capture parameters.";

	# For each capture constant asked to start, let's make sure it's tied and
	# then push us up onto the next level
	for my $capcon ((CAPTURE_STDIN, CAPTURE_STDOUT, CAPTURE_STDERR)) {
		if ($capture_what & $capcon) {
			
			# figure out what we're checking
			my $fh = $fhs{$capcon};

			no strict 'refs';

			# croak if it's tied to the wrong thingy, tie it if we're untied
			if (tied(*$fh) && !UNIVERSAL::isa(tied(*$fh), 'IO::NestedCapture')) {
				croak "start() failed because $fh is not tied as expected.";
			} elsif (!tied(*$fh)) {
				tie *$fh, 'IO::NestedCapture', $fh;
			}

			# grab the one being prepped or create it
			my $pushed_fh;
			my $pushed_reset = 0;
			if ($pushed_fh = delete $self->{"${fh}_next"}) {
				
				# if this is our own file handle, we want to go back to the top
				# of the file before starting. if this is the user's file
				# handle, we won't mess with it.
				my $next_reset = delete $self->{"${fh}_next_reset"};
				seek $pushed_fh, 0, 0 if $next_reset;
			} else {
				$pushed_fh = File::Temp::tempfile;
				$pushed_reset = 1;
			}

			# put this one on top of the file handle stack
			push @{ $self->{"${fh}_current"} }, $pushed_fh;
			push @{ $self->{"${fh}_current_reset"} }, $pushed_reset;
		}
	}
}

=item IO::NestedCapture-E<gt>stop($uncapture_what)

=item $capture-E<gt>stop($uncapture_what)

The C<$uncapture_what> variable is a bit field that should be set to one or more of the L</"NESTED CAPTURE CONSTANTS"> bit-or'd together. If this method is called and the internal nesting state shows that this is the last layer to remove, the associated STD* handles are untied. If C<$uncapture_what> indicates that a certain handle should be uncaptured, but it isn't currently captured, an error will be thrown.

=cut

sub stop {
	my $self = shift->instance;
	my $uncapture_what = shift;

	# check parameters for sanity
	$uncapture_what > 0
		or croak "stop() called without specifying which handles to uncapture.";
	$uncapture_what <= CAPTURE_ALL
		or croak "stop() called with unknown uncapture parameters.";

	# For each uncapture constant asked to stop, check to make sure we're
	# stopping after one or more starts, pop the file handle, and untie if it's
	# the last one
	for my $uncapcon ((CAPTURE_STDIN, CAPTURE_STDOUT, CAPTURE_STDERR)) {
		if ($uncapture_what & $uncapcon) {
			# figure out what we're checking
			my $fh = $fhs{$uncapcon};

			# is this in use or should we croak?
			(defined $self->{"${fh}_current"} && @{ $self->{"${fh}_current"} })
				or croak "stop() asked to stop $fh, but it wasn't started";

			$self->{"${fh}_last"} = pop @{ $self->{"${fh}_current"} };
			seek $self->{"${fh}_last"}, 0, 0
				if pop @{ $self->{"${fh}_current_reset"} };

			unless (@{ $self->{"${fh}_current"} }) {
				no strict 'refs';
				untie *$fh;
			}
		}
	}
}

=item $handle = IO::NestedCapture-E<gt>get_next_in

=item $handle = $capture-E<gt>get_next_in

This method returns the file handle that will be used for STDIN after the next call to C<start(CAPTURE_STDIN)>. If one has not been set using C<set_next_in>, then a seekable file handle will be created. If you just use the automatically created file handle (which is created using L<File::Temp>), then C<start()> will seek to the top of the file handle before use.

=cut

sub get_next_in {
	my $self = shift->instance;

	unless ($self->{'STDIN_next'}) {
		$self->{'STDIN_next'} = File::Temp::tempfile;
		$self->{'STDIN_next_reset'} = 1;
	}

	return $self->{'STDIN_next'};
}

=item IO::NestedCapture-E<gt>set_next_in($handle)

=item $capture-E<gt>in($handle)

The given file handle is used as the file handle to read from after C<start(CAPTURE_STDIN)> is called. If you set a file handle yourself, you must make sure that it is ready to be read from when you call C<start()> (i.e., the file handle pointer won't be reset to the top of the file automatically).

=cut

sub set_next_in {
	my $self = shift->instance;
	my $handle = shift;

	$self->{'STDIN_next'} = $handle;
	delete $self->{'STDIN_next_reset'};

	return;
}

=item $handle = IO::NestedCapture-E<gt>get_last_out

=item $handle = $capture-E<gt>get_last_out

Retrieve the file handle used to capture the output prior to the previous call to C<stop(CAPTURE_STDOUT)>. If this file handle was automatically generated (i.e., not set with C<set_next_out()>, then the file pointer will already be set to the top of the file and ready to read).

=cut

sub get_last_out {
	my $self = shift->instance;
	return $self->{'STDOUT_last'};
}

=item IO::NestedCapture-E<gt>set_next_out($handle)

=item $capture-E<gt>set_next_out($handle)

Install your own file handle to capture the output following the next call to C<start(CAPTURE_STDOUT)>. Make sure the file handle is in the exact state you want before calling C<start()>.

=cut

sub set_next_out {
	my $self = shift->instance;
	my $handle = shift;

	$self->{'STDOUT_next'} = $handle;
	delete $self->{'STDOUT_next_reset'};

	return;
}

=item $handle = IO::NestedCapture-E<gt>get_last_error

=item $handle = $capture-E<gt>get_last_error

Retrieve the file handle used to capture the error output prior to the previous call to C<stop(CAPTURE_STDERR)>. If this file handle was automatically generated (i.e., not set with C<set_next_err()>, then the file pointer will already be set to the top of the file and ready to read).

=cut

sub get_last_err {
	my $self = shift->instance;
	return $self->{'STDERR_last'};
}

=item IO::NestedCapture-E<gt>set_next_err($handle)

=item $capture-E<gt>set_next_err($handle)

Install your own file handle to capture the error output following the next call to C<start(CAPTURE_STDERR)>. Make sure the file handle is in the exact state you want before calling C<start()>.

=cut

sub set_next_err {
	my $self = shift->instance;
	my $handle = shift;

	$self->{'STDERR_next'} = $handle;
	delete $self->{'STDERR_next_reset'};

	return;
}

=back

=cut

# The rest of this is private tie stuff...

# Okay, so the documentation lies. This isn't really a singleton, but the extra
# objects are internally used as ties only.
sub TIEHANDLE { 
	my $class = shift;
	my $instance = $class->instance;

	# Make a non-singleton tie class... shhhhhh.
	my $self = bless {
		instance => $instance,
		fh       => shift,
	}, $class;
}

sub WRITE {
	my $self = shift;
	my $buf  = shift;
	my $len  = shift;
	my $off  = shift;

	# load state
	my $capture = $self->{instance};
	my $fh      = $self->{fh};

	# write
	syswrite $capture->{"${fh}_current"}[-1], $buf, $len, $off;
}

sub PRINT {
	my $self = shift;

	# load state
	my $capture = $self->{instance};
	my $fh      = $self->{fh};
	my $handle  = $capture->{"${fh}_current"}[-1];

	# write
	print $handle @_;
}

sub PRINTF {
	my $self = shift;
	
	# load state
	my $capture = $self->{instance};
	my $fh      = $self->{fh};
	my $handle  = $capture->{"${fh}_current"}[-1];

	# write
	printf $handle @_;
}

sub READ {
	my $self   = shift;

	# load state
	my $capture = $self->{instance};
	my $fh      = $self->{fh};
	my $handle  = $capture->{"${fh}_current"}[-1];

	# read
	read $handle, $_[0], $_[1], $_[2];
}

sub READLINE {
	my $self = shift;

	# load state
	my $capture = $self->{instance};
	my $fh      = $self->{fh};
	my $handle  = $capture->{"${fh}_current"}[-1];

	# read
	readline $handle;
}

sub GETC {
	my $self = shift;

	# load state
	my $capture = $self->{instance};
	my $fh      = $self->{fh};
	my $handle  = $capture->{"${fh}_current"}[-1];

	# read
	getc $handle;
}

sub CLOSE {
	my $self = shift;

	# load state
	my $capture = $self->{instance};
	my $fh      = $self->{fh};
	my $handle  = $capture->{"${fh}_current"}[-1];

	# close
	close $handle;
}

=head1 EXPORTS

This module exports all of the constants used with the object-oriented interface and the subroutines used with the subroutine interface. 

See L</"NESTED CAPTURE CONSTANTS"> for the specific constant names or use C<:constants> to import all the constants. 

See L</"NESTED CAPTURE SUBROUTINES"> for the specific subroutine names or use C<:subroutines> to import all the subroutines.

=head1 SEE ALSO

L<IO::Capture>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp.

This code is licensed and distributed under the same terms as Perl itself.

=cut

1
