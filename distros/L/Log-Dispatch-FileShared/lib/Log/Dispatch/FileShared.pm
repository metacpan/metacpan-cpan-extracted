package Log::Dispatch::FileShared;
# $Id: FileShared.pm,v 1.2 2007/02/03 18:24:11 cmanley Exp $
use strict;
use Carp;
use Fcntl qw(:DEFAULT :flock);
use Params::Validate qw(validate_with SCALAR BOOLEAN); Params::Validate::validation_options('allow_extra' => 1);
use Scalar::Util ();
use Time::HiRes ();
use base qw( Log::Dispatch::Output );
our $VERSION = sprintf '%d.%02d', q|$Revision: 1.2 $| =~ m/ (\d+) \. (\d+) /xg;



our $MOD_PERL;
unless(defined($MOD_PERL)) {
	$MOD_PERL = 0; # default == no mod_perl
	if (exists($ENV{MOD_PERL})) {
		# mod_perl handlers may run system() on other scripts, so also check %INC.
		if (exists($ENV{MOD_PERL_API_VERSION}) && ($ENV{MOD_PERL_API_VERSION} == 2) && $INC{'Apache2/RequestRec.pm'}) {
			$MOD_PERL = 2;
		} elsif ($INC{'Apache.pm'}) {
			$MOD_PERL = 1;
		}
	}
}




sub new {
	my $proto = shift;
	my %p = @_;
	my $class = ref($proto) || $proto;
	my $self = bless({}, $class);
	$self->_basic_init(%p);
    $self->_init(%p);
	return $self;
}



sub DESTROY {
    my $self = shift;
    $self->_close_handle();
}



sub _init {
    my $self = shift;
    my %p = validate_with(
    	'params'	=> \@_,
    	'spec'		=> {
    		'filename'  => { 'type' => SCALAR },
    		'mode'      => { 'type' => SCALAR,  'default' => '>>', 'regex' => qr/^>{1,2}$/ },
			'perms'	    => { 'type' => SCALAR,  'default' => 0666 },
			'umask'	    => { 'type' => SCALAR,  'optional' => 1 },
			'flock'     => { 'type' => BOOLEAN, 'default' => 1 },
			'autoflush' => { 'type' => BOOLEAN, 'default' => 1 },
			'close_after_write' => { 'type' => BOOLEAN, 'default' => 0 },
			'close_after_modperl_request' => { 'type' => BOOLEAN, 'default' => 0 },
		},
		'allow_extra' => 1,
	);
	$self->{'filename'}  = $p{'filename'};
	$self->{'perms'}     = $p{'perms'} | 0200; # Make sure that at least this process can write to the file.
	$self->{'umask'}     = $p{'umask'};
	$self->{'flock'}     = $p{'flock'};
	$self->{'autoflush'} = $p{'autoflush'};
	$self->{'close_after_write'} = $p{'close_after_write'};
	if ($self->{'close_after_write'}) {
		$self->{'mode'} = '>>';
	}
    else {
		$self->{'mode'} = $p{'mode'};
    }
	if ($p{'close_after_modperl_request'}) {
		{
			if ($self->{'close_after_write'}) {
				local $Carp::CarpLevel = $Carp::CarpLevel + 1;
				carp("Option 'close_after_modperl_request' ignored because 'close_after_write' is true.");
				last;
			}
			unless($MOD_PERL) {
				local $Carp::CarpLevel = $Carp::CarpLevel + 1;
				carp("Option 'close_after_modperl_request' ignored because mod_perl was not detected.");
				last;
			}
			if ($MOD_PERL == 2) {
				# Check that the request object can be fetched. Requires 'SetHandler perl-script' or 'PerlOptions +GlobalRequest'
				eval {
					require Apache2::RequestUtil;
					Apache2::RequestUtil->request();
				};
				if ($@) {
					local $Carp::CarpLevel = $Carp::CarpLevel + 1;
					croak("Can't use option 'close_after_modperl_request' (requires 'SetHandler perl-script' or 'PerlOptions +GlobalRequest'): $@");
				}
			}
			elsif ($MOD_PERL > 2) {
				die("Fix me because I don't support mod_perl $MOD_PERL yet.");
			}

			# This is a boolean switch. This is used to check if the handler as already been pushed.
			# This technique is used instead of get_handlers() because the latter segfaults with anonymous subs (in mod_perl 2.02)
			$self->{'modperl_cleanup_handler_pushed'} = 0;

			# Create cleanup code ref.
			# Use a weak self reference so that a circular reference memory leak isn't caused.
			# See also http://www.perl.com/pub/a/2002/08/07/proxyobject.html?page=2
			my $weakself = $self;
			Scalar::Util::weaken($weakself);
			$self->{'modperl_cleanup_handler'} = sub {
				if (defined($weakself)) { # Will be undef if $self was garbage collected, which is ok.
					$weakself->_close_handle();
					$weakself->{'modperl_cleanup_handler_pushed'} = 0;
				}
			}
		}
	}
}




sub log_message {
	my $self = shift;
	my %p = @_;
	my $h = $self->_get_handle();
	my $use_flock = $self->{'flock'};
	if ($use_flock) {
		unless($self->_lock_handle($h)) {
			# Oops failed to aquire lock.
			# If it was important, then at least it will appear in STDERR.
			warn($p{'message'});
			return;
		}
	}
	print $h $p{'message'};
	if ($self->{'close_after_write'}) {
		$self->_close_handle(); # automatically unlocks too
	}
	elsif($use_flock) {
		flock($h, LOCK_UN); # automatically flushes too.
	}
}




sub _get_handle {
    my $self = shift;
    my $h = $self->{'h'};
    unless($h) {
    	my $filename = $self->{'filename'};
    	my $new_umask = $self->{'umask'};
    	my $old_umask;
    	if (defined($new_umask)) {
    		$old_umask = umask($new_umask);
    	}
    	my $mode = O_WRONLY | O_CREAT;
    	if ($self->{'mode'} eq '>>') {
    		$mode |= O_APPEND;
    	}
    	my $rc = sysopen($h, $filename, $mode, $self->{'perms'});
    	if (defined($old_umask)) {
    		umask($old_umask);
    	}
    	unless($rc) {
			die(sprintf('Failed to open("%s%s"): %s', $self->{'mode'}, $filename, $!));
		}
		if ($self->{'autoflush'}) {
			my $oldh = select($h); $| = 1; select($oldh);
		}
		if ($MOD_PERL && (my $cleanup_handler = $self->{'modperl_cleanup_handler'}) && !$self->{'modperl_cleanup_handler_pushed'}) {
			if ($MOD_PERL == 2) {
				# Requires 'SetHandler perl-script' or 'PerlOptions +GlobalRequest'
				Apache2::RequestUtil->request()->push_handlers('PerlCleanupHandler' => $cleanup_handler);
			}
			elsif ($MOD_PERL == 1) {
				Apache->request()->register_cleanup($cleanup_handler);
			}
			else {
				die("Fix me because I don't support mod_perl $MOD_PERL yet.");
			}
			$self->{'modperl_cleanup_handler_pushed'} = 1;
		}
		$self->{'h'} = $h;
	}
	return $h;
}



sub _close_handle {
	my $self = shift;
	if (my $h = $self->{'h'}) {
		close($h);
		undef($self->{'h'});
	}
}



sub _lock_handle {
	my $self = shift;
	my $h = shift;
    # First try to get a non-blocking lock.
	# Only if that fails, try a blocking lock in an eval which is slower.
	unless(flock($h, LOCK_EX | LOCK_NB)) {
		{
			if ($SIG{ALRM} && ($SIG{ALRM} ne 'DEFAULT')) {
				# This is a dilemma.
				# Not locking could cause the log file to be corrupted.
				# The caller has probably called alarm(), and calling it here could disrupt the caller's alarm() call.
				# First try a short loop with 1ms sleeps to get a non-blocking loop.
				# If that doesn't work, then try a blocking lock with a timeout.
				my $locked = 0;
				for (my $i=0; $i<5; $i++) {
					Time::HiRes::usleep(1000);
					if (flock($h, LOCK_EX | LOCK_NB)) {
						# Yippie! It worked.
						$locked = 1;
						last;
					}
				}
				if ($locked) {
					last;
				}
				warn("Setting local \$SIG{ALRM} even though it has been set already.");
			}
			eval {
    			local $SIG{ALRM} = sub { die(__PACKAGE__ . ".ALRM\n"); };
    			# Wait practically long enough, between 1 and 2 seconds.
    			# Any shorter can cause a premature timeout.
    			# Any longer can help cause a DoS if too may processes have to wait too long.
    			alarm 2;
    			flock($h, LOCK_EX);
    			alarm 0;
   			};
   			alarm 0;
   			if ($@) {
   				close($h);
   				if ($@ eq __PACKAGE__ . ".ALRM\n") {
   					# This is a dilemma too.
					warn(sprintf("Timeout waiting for lock on '%s'.", $self->{'filename'}));
					return 0;
				}
				else {
					die($@);
				}
			}
		}
	}
	# Just in case there was an append while we waited for the lock.
	seek($h,0,2);
	return 1;
}



1;

__END__

=head1 NAME

Log::Dispatch::FileShared - Log::Dispatch output class for logging to shared files.

=head1 SYNOPSIS

  use Log::Dispatch::FileShared;

  my $output = Log::Dispatch::FileShared->new(
  	name      => 'test',
  	min_level => 'info',
  	filename  => 'application.log',
  );

  $output->log( level => 'emerg', message => 'Time to die.' );

=head1 DESCRIPTION

This module provides an output class for logging to shared files under the Log::Dispatch system.

Log messages are written using the flock file locking mechanism on a per
write basis which means that this module is suitable for sharing a log file in a multitasking
environment.

This class descends directly from L<Log::Dispatch::Output|Log::Dispatch::Output>.

=head1 OTHER SIMILAR CLASSES

L<Log::Dispatch::File|Log::Dispatch::File> doesn't provide any locking mechanism which makes it
unsuitable for sharing log files between multiple processes
(unless you don't mind having corrupt log messages on rare occasions).

L<Log::Dispatch::File::Locked|Log::Dispatch::File::Locked> does implement locking, but on a per open handle basis
which means that only a single process can log to the file as long as the file is open. All other processes will
block. The only way to prevent other processes from blocking is to close the handle after every write which
degrades logging performance very much. Therefore this class too is unsuitable for sharing log files between multiple processes.

=head1 METHODS

=over 4

=item * new(%p)

This method takes a hash of parameters.  The following options are
valid:

=over 8

=item * name ($)

The name of the object (not the filename!).  Required.

=item * min_level ($)

The minimum logging level this object will accept.  See the
Log::Dispatch documentation on L<Log Levels|Log::Dispatch/"Log Levels"> for more information.  Required.

=item * max_level ($)

The maximum logging level this obejct will accept.  See the
Log::Dispatch documentation on L<Log Levels|Log::Dispatch/"Log Levels"> for more information.  This is not
required.  By default the maximum is the highest possible level (which
means functionally that the object has no maximum).

=item * filename ($)

The filename to be opened for appending.

=item * mode ($)

The mode the file should be opened with.  Valid options are '>' (write) and '>>' (append).
The default is '>>' (append).

=item * perms ($)

If the file does not already exist, the permissions that it should
be created with.  Optional.  The argument passed must be a valid
octal value, such as 0600. It is affected by the current or given umask.

=item * umask ($)

The optional umask to use when the file is created for the first time.

=item * flock ($)

Whether or not log writes should be wrapped in a flock.
Defaults to true. If true, then for each logged message,
a non-blocking flock is attempted first, and if that fails,
then a blocking flock is attemped with a timeout.

=item * close_after_write ($)

Whether or not the file should be closed after each write.
This defaults to false. If set to true, then the mode will aways be append,
so that the file is not re-written for each new message.

Note: opening and closing a file for each write is a relatively
slow process (especially on windoze systems) as demonstrated in
the performance L<benchmarks|/"BENCHMARKS">.

=item * close_after_modperl_request ($)

Only applicable for code running in a mod_perl (1 or 2) environment and
defaults to false. Set this to true if the file should be closed after each
mod_perl request which is useful if you're using a persistent Log::Dispatch
object and intend to periodically roll your log files without having to
restart your web server each time.

=item * autoflush ($)

Whether or not the file should be autoflushed. This defaults to true.
If L<flock> is true, then flushing always occurs no matter what this is set to.

=item * callbacks( \& or [ \&, \&, ... ] )

This parameter may be a single subroutine reference or an array
reference of subroutine references.  These callbacks will be called in
the order they are given and passed a hash containing the following keys:

 ( message => $log_message, level => $log_level )

The callbacks are expected to modify the message and then return a
single scalar containing that modified message.  These callbacks will
be called when either the C<log> or C<log_to> methods are called and
will only be applied to a given message once.

=back

=item * log_message( message => $ )

Sends a message to the appropriate output.  Generally this shouldn't
be called directly but should be called through the C<log()> method
(in Log::Dispatch::Output).

=back

=head1 BENCHMARKS

=over 4

=item FreeBSD 6.1 with a single Intel(R) Xeon(TM) CPU 3.60GHz

 Measuring 10000 logs of using defaults...
         Log::Dispatch::FileShared... 0.739 seconds   (avg 0.00007)
         Log::Dispatch::File...       0.622 seconds   (avg 0.00006)
 Measuring 10000 logs of using autoflush=0, flock=0...
         Log::Dispatch::FileShared... 0.575 seconds   (avg 0.00006)
         Log::Dispatch::File...       0.574 seconds   (avg 0.00006)
 Measuring 10000 logs of using autoflush=1, flock=0...
         Log::Dispatch::FileShared... 0.618 seconds   (avg 0.00006)
         Log::Dispatch::File...       0.623 seconds   (avg 0.00006)
 Measuring 10000 logs of using flock=1...
         Log::Dispatch::FileShared... 0.739 seconds   (avg 0.00007)

 Measuring 10000 logs of using close_after_write=1, flock=0...
         Log::Dispatch::FileShared... 1.080 seconds   (avg 0.00011)
         Log::Dispatch::File...       1.035 seconds   (avg 0.00010)
 Measuring 10000 logs of using close_after_modperl_request=1, flock=1...
         Log::Dispatch::FileShared... 0.768 seconds	(avg 0.00008)

=item MSWin32 with a Pentium CPU 3.0GHz

 Measuring 10000 logs of using defaults...
         Log::Dispatch::FileShared... 1.235 seconds   (avg 0.00012)
         Log::Dispatch::File...       1.047 seconds   (avg 0.00010)
 Measuring 10000 logs of using autoflush=0, flock=0...
         Log::Dispatch::FileShared... 0.875 seconds   (avg 0.00009)
         Log::Dispatch::File...       0.907 seconds   (avg 0.00009)
 Measuring 10000 logs of using autoflush=1, flock=0...
         Log::Dispatch::FileShared... 1.063 seconds   (avg 0.00011)
         Log::Dispatch::File...       1.047 seconds   (avg 0.00010)
 Measuring 10000 logs of using flock=1...
         Log::Dispatch::FileShared... 1.251 seconds   (avg 0.00013)

 Measuring 10000 logs of using close_after_write=1, flock=0...
         Log::Dispatch::FileShared... 74.128 seconds  (avg 0.00741)
         Log::Dispatch::File...       79.660 seconds  (avg 0.00797)

Note how rediculously slow MSWin32 is when close_after_write=1 is used.

=back

=head1 SEE ALSO

L<Log::Dispatch::File|Log::Dispatch::File>.

=head1 AUTHOR

Craig Manley

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Craig Manley
This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
