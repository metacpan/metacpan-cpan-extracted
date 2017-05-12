#!/bin/echo This is a perl module and should not be run

package Meta::Pdmt::Shell;

use strict qw(vars refs subs);
use Meta::Shell::Shell qw();
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Meta::Shell::Shell);

#sub BEGIN();
#sub pre($);
#sub process($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_graph",
		-java=>"_pdmt",
	);
}

sub pre($) {
	my($self)=@_;
	my($attribs)=$self->Attribs();
	$attribs->{completion_entry_function}=$attribs->{list_completion_function};
	$attribs->{completion_word}=[qw(
		stats
		build_all
		add_files
		clear
		node_can_remove
	)];
}

sub process($$) {
	my($self,$line)=@_;
	my($doit)=0;
	if($line eq "stats") {
		$doit=1;
		my($graph)=$self->get_graph();
		Meta::Utils::Output::verbose($self->get_verbose(),"graph has [".$graph->vertices_num()."] nodes\n");
		Meta::Utils::Output::verbose($self->get_verbose(),"graph has [".$graph->edges_num()."] edges\n");
	}
	if($line eq "build_all") {
		$doit=1;
		$self->get_graph()->build_all();
	}
	if($line eq "add_files") {
		$doit=1;
		$self->get_pdmt()->add_files();
	}
	if($line eq "clear") {
		$doit=1;
		$self->get_graph()->nodes_delete_all();
	}
	if($line=~/^node_can_remove\s+(.*)\s*$/) {
		$doit=1;
		my($text)=($line=~/^node_can_remove\s+(.*)\s*$/);
		my(@list)=split(/\s+/,$text);
		for(my($i)=0;$i<=$#list;$i++) {
			my($curr)=$list[$i];
			#Meta::Utils::Output::verbose($self->get_verbose(),"[".$i."] is [".$curr."]\n");
		}
	}
	if(!$doit) {
		Meta::Utils::Output::verbose($self->get_verbose(),"unknown command [".$line."]\n");
	}
	$self->SUPER::process($line);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Pdmt::Shell - provide a shell to interact with PDMT.

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

	MANIFEST: Shell.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Pdmt::Shell qw();
	my($object)=Meta::Pdmt::Shell->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class which is a derviative of Meta::Shell::Shell is a shell for
PDMT interaction.

You can do various things with it:
0. Inspect the pdmt graph.
1. Modify the pdmt graph.
2. Build various nodes.
3. Inspect last errors.
And more...

=head1 FUNCTIONS

	BEGIN()
	pre($)
	process($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This is a bootstrap method to create accessors for the following attributes:
0. graph - this is the underlying PDMT graph.
1. pdmt - this is the underlying PDMT object itself.

=item B<pre($)>

This the "before running" override method. It currently sets up completion
for PDMTs set of commands.

=item B<process($$)>

This is the method which does all the real processing. See the documentation
of Meta::Shell::Shell to understand it's role.

=item B<TEST($)>

This is a testing suite for the Meta::Pdmt::Shell module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

Currently this test does nothing.

=back

=head1 SUPER CLASSES

Meta::Shell::Shell(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV teachers project
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Shell::Shell(3), strict(3)

=head1 TODO

Nothing.
