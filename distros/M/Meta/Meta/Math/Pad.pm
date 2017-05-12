#!/bin/echo This is a perl module and should not be run

package Meta::Math::Pad;

use strict qw(vars refs subs);
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw();

#sub pad_easy($$);
#sub pad($$);
#sub unpad($);
#sub TEST($);

#__DATA__

sub pad_easy($$) {
	my($numb,$digi)=@_;
	my($retu)=$numb;
	while(length($retu)<$digi) {
		$retu="0".$retu;
	}
	return($retu);
}

sub pad($$) {
	my($numb,$digi)=@_;
	if(length($numb)>$digi) {
		throw Meta::Error::Simple("length of number received already more than required number of digits [".$numb."] [".$digi."]");
	}
	return(&pad_easy($numb,$digi));
}

sub unpad($) {
	my($numb)=@_;
	#Meta::Utils::Output::print("got [".$numb."]\n");
	my($res)=CORE::int($numb);
	#Meta::Utils::Output::print("returning [".$res."]\n");
	return($res);
}

sub TEST($) {
	my($context)=@_;
	my($number)="19";
	my($padded)=pad($number,4);
	my($res);
	if($padded eq "0019") {
		$res=1;
	} else {
		$res=0;
	}
	return(1);
}

1;

__END__

=head1 NAME

Meta::Math::Pad - pad numbers with zeros.

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

	MANIFEST: Pad.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Math::Pad qw();
	my($number)="19";
	my($padded)=Meta::Math::Pad::pad($number,4);
	# $padded should now be "0019"

=head1 DESCRIPTION

This module handles padding numbers to achieve a certain presentation. This module currently
provides just a single function but may provide decimal point padding and other functions
in the future.

=head1 FUNCTIONS

	pad_easy($$)
	pad($$)
	unpad($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<pad_easy($$)>

This function will pad a number to the required number of digits.
If the number is longer then it will do nothing.

=item B<pad($$)>

This function will pad a number to the required number of digits.
If the number is longer then it will raise an exception.

=item B<unpad($)>

This function will "unpad" a number. If you give it something "002"
it will give you "2".

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

	0.00 MV multi image viewer
	0.01 MV perl packaging
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV weblog issues
	0.12 MV md5 issues

=head1 SEE ALSO

Error(3), strict(3)

=head1 TODO

-any faster way to do this ? (faster way to generate a string in perl with n occurances of the character 'c')

-provide decimal point padding.

-provide padding with spaces instead of 0's.
