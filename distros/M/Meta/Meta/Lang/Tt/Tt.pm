#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Tt::Tt;

use strict qw(vars refs subs);
use Meta::Development::Deps qw();
use Meta::Utils::Parse::Text qw();
use Meta::Pdmt::BuildInfo qw();

our($VERSION,@ISA);
$VERSION="0.02";
@ISA=qw();

#sub c2deps($);
#sub TEST($);

#__DATA__

sub c2deps($) {
	my($buil)=@_;
	my($grap)=Meta::Development::Deps->new();
	#scan the file and get the dependency information
	$grap->node_insert($buil->get_modu());
	my($parser)=Meta::Utils::Parse::Text->new();
	$parser->init_file($buil->get_srcx());
	while(!$parser->get_over()) {
		my($curr)=$parser->get_line();
		#Meta::Utils::Output::print("line is [".$curr."]\n");
		if($curr=~/\[\%\s*INCLUDE\s+.*\s*\%\]/) {
			my($file_name)=($curr=~/\[\%\s*INCLUDE\s+(.*)\s*\%\]/);
			$grap->node_insert($file_name);
			$grap->edge_insert($buil->get_modu(),$file_name);
		}
		$parser->next();
	}
	$parser->fini();
	return($grap);
}

sub TEST($) {
	my($context)=@_;
#	my($file)="temp/sdfds";
#	my($build_info)=Meta::Pdmt::BuildInfo->new();
#	$build_info->set_srcx($file);
#	my($graph)=c2deps($build_info);
	# print the graph
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Tt::Tt - handle Template Toolkit tasks.

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

	MANIFEST: Tt.pm
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Tt::Tt qw();
	my($deps)=Meta::Lang::Tt::Tt::c2deps($build_info);

=head1 DESCRIPTION

This module will handle Template Toolkit type tasks.
For instance - getting dependencies from Template Tooklit files.

=head1 FUNCTIONS

	c2deps($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2deps($)>

Extract dependency information from Template Toolkit files.

=item B<TEST($)>

This is a test for the modules correct working. Why is a test a part of a modules ?
Thats a big question but the idea is to keep tests close to the code they are testing
so they could be correlated with the code and not become out of data. Also this eases
the dependency handling since when you update the file you are also (inadvertantly or
not) updating the test and higher level systems can detect that and run the tests again
(as they should).

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

Meta::Development::Deps(3), Meta::Pdmt::BuildInfo(3), Meta::Utils::Parse::Text(3), strict(3)

=head1 TODO

-the way I'm calculating deps for template files is not right. Use the native TT2 grammer file which is distributed with it and create a parser based on the real grammer.
