#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Text::Checker;

use strict qw(vars refs subs);
use Meta::Utils::Parse::Text qw();
use Meta::Baseline::Aegis qw();

our($VERSION,@ISA);
$VERSION="0.02";
@ISA=qw();

#sub length_check($$);

#__DATA__

sub length_check($$) {
	my($file,$size)=@_;
	my($parser)=Meta::Utils::Parse::Text->new();
	$parser->init_file($file);
	my($res)=1;
	my($stop)=0;
	while(!$parser->get_over()) {
#	while(!$parser->get_over() && !$stop) {
		my($curr)=$parser->get_line();
		my($pnum)=$parser->get_numb()+1;
		my($temp)=$curr;
		$temp=~s/\t/\s\s\s\s\s\s\s\s/g;
		if(length($temp)>=$size) {
			$res=0;
			$stop=1;
			Meta::Utils::Output::print("line [".$pnum."] [".$curr."]\n");
		}
		$parser->next();
	}
	$parser->fini();
	return($res);
}

sub TEST($) {
	my($context)=@_;
	my($file)=Meta::Baseline::Aegis::which("data/baseline/cook/opts.txt");
	my($res)=length_check($file,80);
	return($res);
}

1;

__END__

=head1 NAME

Meta::Utils::Text::Checker - check text files for various attributes.

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

	MANIFEST: Checker.pm
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Text::Checker qw();
	my($res)=Meta::Utils::Text::Checker::length_check("/etc/passwd",80);

=head1 DESCRIPTION

Use this module to check text files for various things.
The only check that is currently implemented is checking a text
file for not having very long lines (you dictate the maximum line
length).

=head1 FUNCTIONS

	length_check($$)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<length_check($$)>

This method receives a file name and a maximum line size allowed and checks
that all lines in the files wrap before that size is reached. The return
value is the success of the check.

=item B<TEST($)>

This is a testing suite for the Meta::Utils::Text::Checker module.
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

	0.00 MV web site automation
	0.01 MV SEE ALSO section fix
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Utils::Parse::Text(3), strict(3)

=head1 TODO

Nothing.
