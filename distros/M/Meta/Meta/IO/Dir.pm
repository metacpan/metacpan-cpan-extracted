#!/bin/echo This is a perl module and should not be run

package Meta::IO::Dir;

use strict qw(vars refs subs);
use IO::Dir qw();
use Error qw(:try);
use Meta::Baseline::Aegis qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.00";
@ISA=qw();

#sub new($$);
#sub next($);
#sub get_over($);
#sub get_curr($);
#sub close($);
#sub TEST($);

#__DATA__

sub new($$) {
	my($class,$dir)=@_;
	my($self)={};
	my($io)=IO::Dir->new($dir);;
	if(!defined($io)) {
		throw Meta::Error::Simple("error in creating IO::Dir for [".$dir."]");
	}
	$self->{HANDLE}=$io;
	bless($self,$class);
	$self->next();
	return($self);
}

sub next($) {
	my($self)=@_;
	# the following is done in two separate lines because IO::Dir::read will
	# return a list in a list content and we want to force it into a scalar
	# context
	my($res);
	$res=$self->{HANDLE}->read();
	#skip . and ..
	while(defined($res) && ($res eq "." || $res eq "..")) {
		$res=$self->{HANDLE}->read();
	}
	if(defined($res)) {
		$self->{CURR}=$res;
	} else {
		$self->{OVER}=1;
	}
}

sub get_over($) {
	my($self)=@_;
	return($self->{OVER});
}

sub get_curr($) {
	my($self)=@_;
	return($self->{CURR});
}

sub close($) {
	my($self)=@_;
	$self->{HANDLE}->close();
}

sub TEST($) {
	my($context)=@_;
	my($io)=Meta::IO::Dir->new(Meta::Baseline::Aegis::baseline()."/data");
	while(!$io->get_over()) {
		my($curr)=$io->get_curr();
		Meta::Utils::Output::print("curr is [".$curr."]\n");
		$io->next();
	}
	$io->close();
	return(1);
}

1;

__END__

=head1 NAME

Meta::IO::Dir - extend IO::Dir.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Dir.pm
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	package foo;
	use Meta::IO::Dir qw();
	my($object)=Meta::IO::Dir->new("/etc");
	while(!$object->get_over()) {
		my($current)=$object->get_curr();
		# do something with $current
		$object->next();
	}
	$object->close();

=head1 DESCRIPTION

This class extends IO::Dir by adding exception handling to the class
and a more object oriented style (look at the synopsis).

=head1 FUNCTIONS

	new($$)
	next($)
	get_over($)
	get_curr($)
	close($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($$)>

This is a constructor for the Meta::IO::Dir object. It overrides the default IO::Dir
constructor and throws an exception if any initialization problems occured (no need to
check return value).

=item B<next($)>

Moves to the next value in the directory.

=item B<get_over($)>

Returns whether the directory handle is over.

=item B<get_curr($)>

Returns the current value the directory handle is pointing at.

=item B<close($)>

Closes the current directory handle.

=item B<TEST($)>

This is a testing suite for the Meta::IO::Dir module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.
This test currently opens a directory in the baseline and prints the entries in
it.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV md5 issues

=head1 SEE ALSO

Error(3), IO::Dir(3), Meta::Baseline::Aegis(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

Nothing.
