#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang;

use strict qw(vars refs subs);
use Meta::Baseline::Utils qw();

our($VERSION,@ISA);
$VERSION="0.21";
@ISA=qw();

#sub new($);
#sub create_file($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	return($self);
}

sub create_file($$) {
	my($self,$file)=@_;
	Meta::Baseline::Utils::file_emblem($file);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Lang - module to help to sort through all available languages.

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

	MANIFEST: Lang.pm
	PROJECT: meta
	VERSION: 0.21

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang qw();
	my($lang)=Meta::Baseline::Lang->new();
	$lang->create_file("my.pm");

=head1 DESCRIPTION

This is the base class to all language modules.

=head1 FUNCTIONS

	new($)
	create_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is the constructor.

=item B<create_file($$)>

This method will create a stub template file.

=item B<TEST($)>

Test suite for this module.

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

	0.00 MV perl quality change
	0.01 MV perl code quality
	0.02 MV more perl quality
	0.03 MV more perl quality
	0.04 MV perl documentation
	0.05 MV more perl quality
	0.06 MV perl qulity code
	0.07 MV more perl code quality
	0.08 MV revision change
	0.09 MV languages.pl test online
	0.10 MV upload system revamp
	0.11 MV perl packaging
	0.12 MV md5 project
	0.13 MV database
	0.14 MV perl module versions in files
	0.15 MV movies and small fixes
	0.16 MV thumbnail user interface
	0.17 MV more thumbnail issues
	0.18 MV website construction
	0.19 MV web site automation
	0.20 MV SEE ALSO section fix
	0.21 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Utils(3), strict(3)

=head1 TODO

Nothing.
