#!/bin/echo This is a perl module and should not be run

package Meta::Template::Sub;

use strict qw(vars refs subs);
use Meta::Baseline::Aegis qw();
use Meta::Math::Pad qw();
use Meta::Utils::Utils qw();
use Meta::Utils::Time qw();
use Meta::Template qw();
use Meta::Utils::Output qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw();

#sub interpolate($);
#sub TEST($);

#__DATA__

sub interpolate($) {
	my($string)=@_;
	my($vars)={
		"project",Meta::Baseline::Aegis::project(),
		"change",Meta::Math::Pad::pad(Meta::Baseline::Aegis::change(),3),
		"architecture",Meta::Baseline::Aegis::architecture(),
		"developer",Meta::Baseline::Aegis::developer(),
		"home_dir",Meta::Utils::Utils::get_home_dir(),
		"time",Meta::Utils::Time::now_string(),
	};
	my($template)=Meta::Template->new();
	my($result);
	$template->process(\$string,$vars,\$result);
	return($result);
}

sub TEST($) {
	my($context)=@_;
	my($result)=&interpolate("[% project %]");
	Meta::Utils::Output::print("result is [".$result."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Template::Sub - perform TT2 substitutions for development easily.

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

	MANIFEST: Sub.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Template::Sub qw();
	my($object)=Meta::Template::Sub->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module provides easy method for string substitution using the TT2 toolkit.
You can easily refer to variables that have to do with development issues in strings
and by working them over with methods from this module have variables that have
to do with development appear in the strings.

=head1 FUNCTIONS

	interpolate($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<interpolate($)>

This is the only interpolation method currently supported and it too supports only
a small range of variables. Here they are:
[% project %] - current project name.
[% change %] - current change number.
[% architecture %] - current architecture.
[% developer %] - current developer name.
[% home_dir %] - current users home directory.
[% time %] - current time (in UNIX epoch seconds).

=item B<TEST($)>

This is a testing suite for the Meta::Template::Sub module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

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

	0.00 MV web site development
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Math::Pad(3), Meta::Template(3), Meta::Utils::Output(3), Meta::Utils::Time(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

Nothing.
