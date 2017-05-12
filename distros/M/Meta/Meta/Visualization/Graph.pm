#!/bin/echo This is a perl module and should not be run

package Meta::Visualization::Graph;

use strict qw(vars refs subs);
use Meta::Info::Enum qw();
use GraphViz qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.08";
@ISA=qw(GraphViz);

#sub BEGIN();
#sub as_type($$$);
#sub get_enum();
#sub TEST($);

#__DATA__

our($enum);

sub BEGIN() {
	$enum=Meta::Info::Enum->new();
	$enum->set_name("output_type");
	$enum->set_description("types of outputs from GraphViz");
	$enum->insert("canon","canon");
	$enum->insert("text","text");
	$enum->insert("ps","ps");
	$enum->insert("hpgl","hpgl");
	$enum->insert("pcl","pcl");
	$enum->insert("mif","mif");
	$enum->insert("pic","pic");
	$enum->insert("gd","gd");
	$enum->insert("gd2","gd2");
	$enum->insert("gif","gif");
	$enum->insert("jpeg","jpeg");
	$enum->insert("png","png");
	$enum->insert("wbmp","wbmp");
	$enum->insert("ismap","ismap");
	$enum->insert("imap","imap");
	$enum->insert("vrml","vrml");
	$enum->insert("vtx","vtx");
	$enum->insert("mp","mp");
	$enum->insert("fig","fig");
	$enum->insert("svg","svg");
	$enum->insert("plain","plain");
	$enum->set_default("svg");
}

sub get_enum() {
	return($enum);
}

sub as_type($$$) {
	my($self,$type,$file)=@_;
	$enum->check_elem($type);
	if($type eq "canon") {
		return($self->as_canon($file));
	}
	if($type eq "text") {
		return($self->as_text($file));
	}
	if($type eq "ps") {
		return($self->as_ps($file));
	}
	if($type eq "hpgl") {
		return($self->as_hgpl($file));
	}
	if($type eq "pcl") {
		return($self->as_pcl($file));
	}
	if($type eq "mif") {
		return($self->as_mif($file));
	}
	if($type eq "pic") {
		return($self->as_pic($file));
	}
	if($type eq "gd") {
		return($self->as_gd($file));
	}
	if($type eq "gd2") {
		return($self->as_gd2($file));
	}
	if($type eq "gif") {
		return($self->as_gif($file));
	}
	if($type eq "jpeg") {
		return($self->as_jpeg($file));
	}
	if($type eq "png") {
		return($self->as_png($file));
	}
	if($type eq "wbmp") {
		return($self->as_wbmp($file));
	}
	if($type eq "ismap") {
		return($self->as_ismap($file));
	}
	if($type eq "imap") {
		return($self->as_imap($file));
	}
	if($type eq "vrml") {
		return($self->as_vrml($file));
	}
	if($type eq "vtx") {
		return($self->as_vtx($file));
	}
	if($type eq "mp") {
		return($self->as_mp($file));
	}
	if($type eq "fig") {
		return($self->as_fig($file));
	}
	if($type eq "svg") {
		return($self->as_svg($file));
	}
	if($type eq "plain") {
		return($self->as_plain($file));
	}
	throw Meta::Error::Simple("you shouldnt be here");
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Visualization::Graph - add some capabilities to GraphViz.

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

	MANIFEST: Graph.pm
	PROJECT: meta
	VERSION: 0.08

=head1 SYNOPSIS

	package foo;
	use Meta::Visualization::Graph qw();
	my($object)=Meta::Visualization::Graph->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module adds some capabilities to the GraphViz package.

=head1 FUNCTIONS

	BEGIN()
	get_enum($)
	as_type($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<$enum>

This is the enum object that is created once at BEGIN time.

=item B<BEGIN>

This is a constructor for the Meta::Visualization::Graph object.

=item B<get_enum($)>

This method returns the enum object which contains the list of types
that visualization currently supports.

=item B<as_type($$$)>

This method receives a Visualization object and a type to emit and
emits that type.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

GraphViz(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV graph visualization
	0.01 MV thumbnail user interface
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV finish papers
	0.07 MV teachers project
	0.08 MV md5 issues

=head1 SEE ALSO

Error(3), GraphViz(3), Meta::Info::Enum(3), strict(3)

=head1 TODO

Nothing.
