#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Dos;

use strict qw(vars refs subs);

our($VERSION,@ISA);
$VERSION="0.26";
@ISA=qw();

#sub to_unix_text($$);
#sub to_dosx_text($$);
#sub to_unix_file($$$);
#sub to_dosx_file($$$);
#sub to_unix($$);
#sub to_dosx($$);
#sub visual_file($$);
#sub visual($);
#sub TEST($);

#__DATA__

sub to_unix_text($$) {
	my($text,$verb)=@_;
	$text=~s/\r\n/\n/g;
	return($text);
}

sub to_dosx_text($$) {
	my($text,$verb)=@_;
	$text=~s/\n/\r\n/g;
	return($text);
}

sub to_unix_file($$$) {
	my($orig,$dest,$verb)=@_;
	my($text);
	if(!Meta::Utils::File::File::load_nodie($orig,\$text)) {
		return(0);
	}
	$text=to_unix_text($text,$verb);
	return(Meta::Utils::File::File::save_nodie($dest,$text));
}

sub to_dosx_file($$$) {
	my($orig,$dest)=@_;
	my($text);
	if(!Meta::Utils::File::File::load_nodie($orig,\$text)) {
		return(0);
	}
	$text=to_dosx_text($text,0);
	return(Meta::Utils::File::File::save_nodie($dest,$text));
}

sub to_unix($$) {
	my($file,$verb)=@_;
	return(to_unix_file($file,$file,$verb));
}

sub to_dosx($$) {
	my($file,$verb)=@_;
	return(to_dosx_file($file,$file,$verb));
}

sub to_unix_list($$) {
	my($list,$verb)=@_;
	my($scod)=1;
	for(my($i)=0;$i<=$#$list;$i++) {
		my($curr)=$list->[$i];
		if(!to_unix($curr,$verb)) {
			$scod=0;
		}
	}
	return($scod);
}

sub to_dosx_list($$) {
	my($list,$verb)=@_;
	my($scod)=1;
	for(my($i)=0;$i<=$#$list;$i++) {
		my($curr)=$list->[$i];
		if(!to_dosx($curr,$verb)) {
			$scod=0;
		}
	}
	return($scod);
}

sub visual_file($$) {
	my($orig,$dest)=@_;
	my($text);
	if(!Meta::Utils::File::File::load_nodie($orig,\$text)) {
		return(0);
	}
	$text=to_unix_text($text,0);
	my(@line)=split("\n",$text);
	$text=join("\n",@line[1..$#line]);
	return(Meta::Utils::File::File::save_nodie($dest,$text));
}

sub visual($) {
	my($file)=@_;
	return(visual_file($file,$file));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Dos - Handle dos to UNIX conversions.

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

	MANIFEST: Dos.pm
	PROJECT: meta
	VERSION: 0.26

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Dos qw();
	my($error_code)=Meta::Utils::Dos::to_unix($file);

=head1 DESCRIPTION

This library helps you in converting brain damaged dos text files to normal
files and helping you with getting ridd of stuff that the visual
compiler leaves in. It also helps you in figuring out if a certain file
name is "DOS certified" (in that he has allowed dos characters and it is
not too long...) etc...

=head1 FUNCTIONS

	to_unix_text($$)
	to_dosx_text($$)
	to_unix_file($$$)
	to_dosx_file($$$)
	to_unix($$)
	to_dosx($$)
	to_unix_list($$)
	to_dosx_list($$)
	visual_file($$)
	visual($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<to_unix_text($$)>

This routine translates unix text to dos text.
The parameters are:
0. The text to do the conversion on.
1. Vebosity flag.

=item B<to_dosx_text($$)>

This routine translates dos text to unix text.
The parameters are:
0. The text to do the conversion on.
1. Vebosity flag.

=item B<to_unix_file($$$)>

This routine receives an origin file and a destination file.
The routine assumes the origin file is in dos text format.
The routine translates the text to unix text format and writes the output
into the destination file.
The routine returns a valid error bit.

=item B<to_dosx_file($$$)>

This routine receives an origin file and a destination file.
The routine assumes the origin file is in unix text format.
The routine translates the text to dos text format and writes the output
into the destination file.
The routine returns a valid error bit.

=item B<to_unix($$)>

This routine does a dos to unix convertion of a file into the same file.
The parameters are:
0. The name of the file.
1. Verbosity flag.

=item B<to_dosx($$)>

This routine does a unix to dos convertion of a file into the same file.
The parameters are:
0. The name of the file.
1. Verbosity flag.

=item B<to_unix_list($$)>

This routine will convert a list of files to unix format.

=item B<to_dosx_list($$)>

This routine will convert a list of files to dos format.

=item B<visual_file($)>

This routine receives a file and does exactly the same as the B<to_unix>
routine, except it also cuts the first like which is just a reiteration
by the Visual C++ compiler of which file it's compiling (why it's doing
that is beyond me...).

=item B<visual($)>

Same as the visual_file routine but doing the operation on the same file.

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

	0.00 MV initial code brought in
	0.01 MV make quality checks on perl code
	0.02 MV more perl checks
	0.03 MV make Meta::Utils::Opts object oriented
	0.04 MV check that all uses have qw
	0.05 MV fix todo items look in pod documentation
	0.06 MV more on tests/more checks to perl
	0.07 MV perl code quality
	0.08 MV more perl quality
	0.09 MV more perl quality
	0.10 MV perl documentation
	0.11 MV more perl quality
	0.12 MV perl qulity code
	0.13 MV more perl code quality
	0.14 MV revision change
	0.15 MV languages.pl test online
	0.16 MV perl packaging
	0.17 MV md5 project
	0.18 MV database
	0.19 MV perl module versions in files
	0.20 MV movies and small fixes
	0.21 MV thumbnail user interface
	0.22 MV more thumbnail issues
	0.23 MV website construction
	0.24 MV web site automation
	0.25 MV SEE ALSO section fix
	0.26 MV md5 issues

=head1 SEE ALSO

strict(3)

=head1 TODO

Nothing.
