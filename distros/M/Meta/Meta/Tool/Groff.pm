#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Groff;

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Utils qw();
use Meta::Utils::File::File qw();
use Meta::Utils::File::Remove qw();
use Compress::Zlib qw();
use Meta::Utils::File::Patho qw();
use Meta::Error::Simple qw();

our($VERSION,@ISA);
$VERSION="0.07";
@ISA=qw();

#sub BEGIN();
#sub process($$);
#sub get_oneliner($);
#sub TEST($);

#__DATA__

our($tool_path);

sub BEGIN() {
	my($patho)=Meta::Utils::File::Patho->new_path();
	$tool_path=$patho->resolve("groff");
}

sub process($$) {
	my($data,$device)=@_;
	# check that device is one of "ascii","ps","dvi","html"
	my($file)=Meta::Utils::Utils::get_temp_file();
	Meta::Utils::File::File::save($file,$data);
	# the -W w stuff is to inhibit warnings. It's not documented in groff so don't
	# look for it. It's from the source.
	# the -m mandoc is to tell groff to use the groff manual page macros to
	# do its work.
	my($out)=Meta::Utils::System::system_out($tool_path,["-m","mandoc","-W","w","-T",$device,$file]);
	Meta::Utils::File::Remove::rm($file);
	return($$out);
}

sub get_oneliner($) {
	my($text)=@_;
	#match newlines two
	#get the first .SH match.
	$text=~s/\n//g;
	my($name1)=($text=~/\.SH "NAME"(.*)\.SH/);
	if(defined($name1)) {
		return($name1);
	}
	my($name2)=($text=~/\.SH NAME(.*)\.SH/);
	if(defined($name2)) {
		return($name2);
	}
	throw Meta::Error::Simple("could not get one line description");
}

sub TEST($) {
	my($context)=@_;
	my($file)="/usr/share/man/man1/ls.1.bz2";
	my($content);
	Meta::Utils::File::File::load($file,\$content);
	my($full)=Compress::Bzip2::decompress($content);
	my($liner)=get_oneliner($full);
	Meta::Utils::Output::print("liner is [".$liner."]\n");
	if($liner eq "list directory contents") {
		return(1);
	} else {
		return(0);
	}
}

1;

__END__

=head1 NAME

Meta::Tool::Groff - run groff for you.

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

	MANIFEST: Groff.pm
	PROJECT: meta
	VERSION: 0.07

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Groff qw();
	my($object)=Meta::Tool::Groff->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module eases the job of running groff for you.

=head1 FUNCTIONS

	BEGIN()
	process($$)
	get_oneliner($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method for finding your groff executable.

=item B<process($$)>

This method will run groff on a piece of data and will return the result.
The other input is the device to render to.

=item B<get_oneliner($)>

This method will get the one line description from the content of a manual page.
If this method is unable to extract the one line description (problem with
the content of the troff manual page) then it will return "undef".

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

	0.00 MV import tests
	0.01 MV dbman package creation
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV download scripts
	0.07 MV md5 issues

=head1 SEE ALSO

Compress::Zlib(3), Meta::Error::Simple(3), Meta::Utils::File::File(3), Meta::Utils::File::Patho(3), Meta::Utils::File::Remove(3), Meta::Utils::System(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-is there a way (using a CPAN module?) to feed the string into Groff without writing it first into a file ?

-the oneliner method doesn't work right - get it to work right.

-grohtml (the underlying tool doing the html conversion) is leaving junk if it crashes. Take care of it.
