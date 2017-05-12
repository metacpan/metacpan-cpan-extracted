#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Html::Html;

use strict qw(vars refs subs);
use Meta::Utils::Output qw();
use HTML::LinkExtor qw();
use File::Basename qw();
use File::Spec::Functions qw();
use Meta::Utils::File::Dir qw();
use XML::Handler::BuildDOM qw();
use XML::Driver::HTML qw();

our($VERSION,@ISA);
$VERSION="0.07";
@ISA=qw();

#sub c2deps($);
#sub c2dom($);
#sub c2dom_io($);
#sub TEST($);

#__DATA__

sub c2deps($) {
	my($buil)=@_;
	my($srcx)=$buil->get_srcx();
	my($modu)=$buil->get_modu();
	my($callback)=undef;#this is what LinkExtor wants
	my($base_url)=undef;#this is what LinkExtor wants
	my($parser)=HTML::LinkExtor->new($callback,$base_url);
	$parser->parse_file($srcx);
	my(@links)=$parser->links();
	my($graph)=Meta::Development::Deps->new();
	$graph->node_insert($modu);
	#this is to handle relative links
	my($dire)=File::Basename::dirname($modu);
	my($linkarray);
	foreach $linkarray (@links) {
		my(@element)=@$linkarray;
		my($name0)=$element[0];
		my($name1)=$element[1];
		my($name2)=$element[2];
#		Meta::Utils::Output::print("name0 is [".$name0."]\n");
#		Meta::Utils::Output::print("name1 is [".$name1."]\n");
#		Meta::Utils::Output::print("name2 is [".$name2."]\n");
		# a is for regular links and link is for the link tag in the meta area
		if($name0 eq "a" || $name0 eq "link") {
#			Meta::Utils::Output::print("in a\n");
			if($name1 eq "href") {
#				Meta::Utils::Output::print("in href\n");
				my($doit)=1;
				if($name2=~/^http/) {
					$doit=0;
				}
				if($name2=~/^mailto/) {
					$doit=0;
				}
				if($name2=~/^ftp/) {
					$doit=0;
				}
				if($doit) {
#					Meta::Utils::Output::print("in http\n");
					#this is to handle relative links
					#resolve name according to modu directory.
					my($full)=File::Spec::Functions::catfile($dire,$name2);
					my($cano)=Meta::Utils::File::Dir::fixdir($full);
					#$graph->node_insert($name2);
					$graph->node_insert($cano);
					$graph->edge_insert($modu,$cano);
				}
			}
		}
	}
	return($graph);
}

sub c2dom($) {
	my($html)=@_;
	my($builder)=XML::Handler::BuildDOM->new();
	my($html)=XML::Driver::HTML->new(
		'Handler'=>$builder,
		'Source'=>{
			'String'=>$html,
		}
	);
	my($dom)=$html->parse();
	return($dom);
}

sub c2dom_io($) {
	my($io)=@_;
	my($builder)=XML::Handler::BuildDOM->new();
	my($html)=XML::Driver::HTML->new(
		'Handler'=>$builder,
		'Source'=>{
			'ByteStream'=>$io,
		}
	);
	my($dom)=$html->parse();
	return($dom);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Html::Html - help you with HTML related tasks.

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

	MANIFEST: Html.pm
	PROJECT: meta
	VERSION: 0.07

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Html::Html qw();

=head1 DESCRIPTION

This module will help you with HTML related tasks.
It knows how to:
1. Generate HTML dependencies.
2. Move from relative to absolute links.
3. Move from absolute to relative links.
4. Transpose a set of files which are correctly linked to a new set.
5. Add last time modified tags to htmls and revision.

=head1 FUNCTIONS

	c2deps($)
	c2dom($)
	c2dom_io($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2deps($)>

This method will examine the file using HTML helper classes and will generate
a dependency object for that file.

=item B<c2dom($)>

This method converts an HTML string to a DOM object using the SAX modules.

=item B<c2dom_io($)>

This method converts an HTML io handle to a DOM object using the SAX modules.

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

	0.00 MV more Class method generation
	0.01 MV thumbnail user interface
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV teachers project
	0.07 MV md5 issues

=head1 SEE ALSO

File::Basename(3), File::Spec::Functions(3), HTML::LinkExtor(3), Meta::Utils::File::Dir(3), Meta::Utils::Output(3), XML::Driver::HTML(3), XML::Handler::BuildDOM(3), strict(3)

=head1 TODO

Nothing.
