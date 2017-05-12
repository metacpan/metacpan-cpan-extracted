#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Dtd::Html;

use strict qw(vars refs subs);
use XML::Handler::Dtd2Html qw();
use Meta::Utils::File::File qw();
use Meta::Lang::Xml::Resolver qw();
use Meta::Utils::Utils qw();
#use XML::SAX::PurePerl qw();
#use XML::LibXML::SAX qw();
#use XML::SAX::Expat qw();
use XML::Parser::PerlSAX qw();

our($VERSION,@ISA);
$VERSION="0.04";
@ISA=qw();

#sub c2html($);
#sub c2html_basic($);
#sub TEST($);

#__DATA__

sub c2html($) {
	my($build)=@_;
	my($src)=$build->get_srcx();
	my($targ)=$build->get_targ();
	return(c2html_basic($src,$targ));
}

sub c2html_basic($$) {
	my($src,$targ)=@_;
	my($handler)=XML::Handler::Dtd2Html->new();
	my($resolver)=Meta::Lang::Xml::Resolver->new();
#	my($parser)=XML::SAX::PurePerl->new(
#		Handler=>$handler,
#		ParseParamEnt=>1,
#		EntityResolver=>$resolver,
#	);
#	my($parser)=XML::LibXML::SAX->new(
#		Handler=>$handler,
#		ParseParamEnt=>1,
#		EntityResolver=>$resolver,
#	);
#	my($parser)=XML::SAX::Expat->new(
#		Handler=>$handler,
#		ParseParamEnt=>1,
#		EntityResolver=>$resolver,
#	);
	my($parser)=XML::Parser::PerlSAX->new(
		Handler=>$handler,
		ParseParamEnt=>1,
		EntityResolver=>$resolver,
	);
	my($content);
	Meta::Utils::File::File::load($src,\$content);
	my($string)=$content=~m/EMPTY\n([[:ascii:]\n]*)\n-->$/;
	my($opts_t)=undef;
	my($opts_s)=undef;
	my(@array)=();
	my($opts_e)=\@array;
	my($opts_C)=1;
	my($opts_h)=0;
	my($opts_M)=0;
	my($opts_Z)=0;
	my($doc)=$parser->parse(Source=>{String=>$string});

	my($no_suff_target)=Meta::Utils::Utils::remove_suffix($targ);
	$doc->generateHTML(
		$no_suff_target,#this needs to be without the suffix which is added automatically
		$opts_t,#the title
		$opts_s,#supply a custom style sheet or not
		$opts_e,#examples
		$opts_C,#translate comments in the body of the dtd (thats the whole point isnt it.
		$opts_h,#h refs
		$opts_M,#no multi comments (just single comment per element)
		$opts_Z,#do not delete zombi elements
	);
}

sub TEST($) {
	my($context)=@_;
	my($source)="dtdx/temp/dtdx/deve/xml/def.dtd";
	my($out)=Meta::Utils::Utils::get_temp_file();
	&c2html_basic($source,$out);
	Meta::Utils::File::Remove::rm($out);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Dtd::Html - handle conversion of DTDs to HTMLs.

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
	VERSION: 0.04

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Dtd::Html qw();
	my($build)=...
	Meta::Lang::Dtd::Html::c2html($build);

=head1 DESCRIPTION

This module knows how to translate DTD files to html documentation
derived from XML comments embedded in them. It uses XML::Handler::Dtd2Html
to do it's thing. There are more options in XML::Handler::Dtd2Html to be
able to emit frames output (this will mean that each html output will be
put in several files). Fortunately - the default is that the output is
a single HTML.

=head1 FUNCTIONS

	c2html($)
	c2html_basic($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<c2html($)>

This is the method which does all of the work.

=item B<c2html_basic($)>

This is the basic procedure which does the work.

=item B<TEST($)>

This is a testing suite for the Meta::Lang::Dtd::Html module.
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

	0.00 MV move tests into modules
	0.01 MV weblog issues
	0.02 MV teachers project
	0.03 MV more pdmt stuff
	0.04 MV md5 issues

=head1 SEE ALSO

Meta::Lang::Xml::Resolver(3), Meta::Utils::File::File(3), Meta::Utils::Utils(3), XML::Handler::Dtd2Html(3), XML::Parser::PerlSAX(3), strict(3)

=head1 TODO

Nothing.
