
package File::Flock::Forking;

require Exporter;
@ISA = qw(Exporter);

use strict;
use Config;

die "Import File::Flock::Forking before importing File::Flock"
	if defined $File::Flock::VERSION;

if ((!$Config{d_flock} && ! ($ENV{FLOCK_FORKING_USE} || '') eq 'flock')
	|| (($ENV{FLOCK_FORKING_USE} || '') eq 'subprocess'))
{
	$File::Flock::Forking::SubprocessEnabled = 1;
	require File::Flock::Subprocess;
}

1;

__END__

=head1 NAME

 File::Flock::Forking - adjust File::Flock to handle fork()

=head1 SYNOPSIS

 use File::Flock::Forking;
 use File::Flock;

=head1 DESCRIPTION

The purpose of File::Flock::Forking is to change the implementation
of L<File::Flock> to handle locking on systems that do not hold
locks across calls to fork().

If you are using L<File::Flock> or any module that uses L<File::Flock>
then and your program uses fork(), then you should import
File::Flock::Forking before you import L<File::Flock> or any module that
uses L<File::Flock>.

On most operating systems, File::Flock::Forking does nothing.  On
Solaris, it changes the behavior of L<File::Flock> to be implemented
by L<File::Flock::Subprocess>.

You can also force it to use L<FIle::Flock::Subprocess> by with

	$ENV{FLOCK_FORKING_USE} = 'subprocess'

Or force it to use L<File::Flock> with

	$ENV{FLOCK_FORKING_USE} = 'flock'

=head1 LICENSE

Copyright (C) 2013 Google, Inc.
This module may be used/copied/etc on the same terms as Perl itself.
