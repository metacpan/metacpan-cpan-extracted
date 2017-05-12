package Device::ParallelPort::drv::auto;
use strict;
use Carp;

=head1 NAME

Device::ParallelPort::drv::auto - Automatically choose driver.

=head1 SYNOPSIS

	use Device::ParallelPort;
	my $pp = Device::ParallelPort->new('auto:0');

=head1 DESCRIPTION

This module should be used if you do not care what driver is used.
It is very handy for writing cross platform applications in that it
will autoamtically determine which parallel port driver is appropriate.

See L<Device::ParallelPort> for full details.

=head1 DEVELOPMENT

The current nature of it requires modifications to this module to add new 
drivers. Longer term it would be better if it tried each driver installed on 
the system in turn allowing new drivers to add their own interfaces.

As such, the current version only detects between three drivers.

	* parport - If linux and has a writable /dev/parportX
	* linux - If linux and running as root (and no parport)
	* win32 - If running on windows

NOTE - You MUST have the driver mentioned above loaded on your system for this
to work. They are each SEPARATELY available in CPAN.

=head1 COPYRIGHT

Copyright (c) 2002,2003,2004 Scott Penrose. All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Scott Penrose L<scottp@dd.com.au>, L<http://linux.dd.com.au/>

=head1 SEE ALSO

L<Device::ParallelPort>

=cut

sub new {
	my ($this, $str, @params) = @_;

	# Try and find us who we are...
	if ($^O =~ /linux/i) {
		# Do we have 'parport' support ?
		if (-e "/dev/parport0" || -e "/dev/ppuser00") {
			# Check the permissions
			if ((-w "/dev/parport" . $str) || (-w "/dev/ppuser0" .  $str)) {
				return _load('parport', $str, @params);
			} else {
				return _error(
					"automatically detected linux parport support."
					. "but unabel to write to /dev/parport$str or /dev/ppuser0$str ."
					. "Install 'Device::ParallelPort::drv::parport' from CPAN "
					. "OR Fix access to parport in linux "
					. "OR use driver 'linux:0' "
				);
			}
		} else {
			# Check we are root and report problems if not
			if ($> == 0) {
				return _load('linux', $str, @params);
			} else {
				return _error(
					"automatically detected linux support."
					. "but you are not root. Either use parport support "
					. "(see Device::ParallelPort::drv::parport) or run as root"
				);
			}
		}
	} elsif ($^O =~ /win32/i) {
		# Load library - that should 
		return _load('win32', $str, @params);
	} else {
		_error(
			"Unable to automatically detect a parllel port\n"
			. "(currently only auto detect windows and linux drivers).\n"
			. "You are running $^O"
		);
	}
}

sub _load {
	my ($drv, $str, @params) = @_;
	my $this = undef;
        eval qq{
                use Device::ParallelPort::drv::$drv;
                \$this = Device::ParallelPort::drv::$drv->new(\$str, \@params);
        };
	if ($@) {
		_error(
			"failed to load $drv - $@."
			. " Make sure you have loaded and installed Device::ParallelPort::drv::$drv"
			. " from CPAN. Install Device::ParallelPort::drv::(linux|parport|win32) and try again"
		);
	}
	return $this;
}

sub _error {
	my ($msg) = @_;
        croak "Device::ParallelPort::drv::auto (auto detect) error\n$msg";
}

1;
